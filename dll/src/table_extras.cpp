// Phase I — Tables : TableWidget + row/column markers + headers + sort latch
// + scroll freeze, plus all the C-ABI exports.
//
// Flow per Render() of TableWidget :
//   1. BeginTable(id, column_count, flags, outer_size, inner_width).
//      If false (culled / window collapsed) → skip everything, no EndTable.
//   2. For each ColumnConfig : TableSetupColumn(label, flags, weight).
//   3. TableSetupScrollFreeze(freeze_cols, freeze_rows) — no-op when both 0.
//   4. Walk children — they're a mix of TableNextRow / TableNextColumn /
//      TableSetColumnIndex / TableHeadersRow markers, and content widgets
//      (Text, Button, Selectable, …). Each content widget renders into the
//      cell pointed to by the most recent column marker.
//   5. Latch sort spec from ImGui::TableGetSortSpecs() for AutoIt to poll.
//   6. EndTable().

#include "table_extras.h"

#include <Windows.h>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

// ---- Widget Render() -------------------------------------------------------

void TableWidget::Render()
{
    if (!visible) {
        // Hidden : also clear any latched sort spec so polls don't read stale.
        sort_col_index = -1;
        sort_direction = 0;
        sort_specs_multi.clear();
        latched_column_count = 0;
        return;
    }
    const bool open = ImGui::BeginTable(id.c_str(), column_count,
                                         static_cast<ImGuiTableFlags>(flags),
                                         ImVec2(outer_w, outer_h),
                                         inner_width);
    if (!open) {
        // Culled by ImGui (e.g. parent window collapsed). Don't latch / walk.
        sort_col_index = -1;
        sort_direction = 0;
        sort_specs_multi.clear();
        latched_column_count = 0;
        return;
    }

    // M.1 — latch the column count for AutoIt to poll. Constant for the frame
    // (BeginTable fixes it) ; freshness across frames is guaranteed by
    // re-latching here every time we open the table.
    latched_column_count = ImGui::TableGetColumnCount();

    // I.2 — apply column setup. Done BEFORE any child renders (the order is
    // mandated by ImGui : every TableSetupColumn must come before the first
    // row).
    for (const auto& c : columns) {
        ImGui::TableSetupColumn(c.label.c_str(),
                                 static_cast<ImGuiTableColumnFlags>(c.flags),
                                 c.init_width_or_weight);
    }

    // I.4 — apply scroll freeze (no-op when both 0). Must also come before
    // the first row, after TableSetupColumn calls.
    if (freeze_cols > 0 || freeze_rows > 0) {
        ImGui::TableSetupScrollFreeze(freeze_cols, freeze_rows);
    }

    // J.5 — Apply any pending TableSetColumnEnabled toggles. Must be called
    // inside a BeginTable/EndTable scope. Reset each entry's dirty flag after
    // application (the user is expected to re-call the setter per session, not
    // per frame, but the dirty-clear keeps each setter genuinely one-shot).
    for (auto& pe : pending_col_enables) {
        if (pe.dirty) {
            ImGui::TableSetColumnEnabled(pe.col, pe.enabled != 0);
            pe.dirty = false;
        }
    }

    // Walk children — markers + content widgets, mixed at the same level.
    for (auto& child : children) child->RenderAndQueryState();

    // I.3 + J.6 — latch sort spec(s). When the table is not Sortable,
    // GetSortSpecs returns NULL → we clear everything. Otherwise we fill BOTH
    // the single-col (I.3 compat) fields and the multi-col vector (J.6).
    sort_specs_multi.clear();
    if (ImGuiTableSortSpecs* specs = ImGui::TableGetSortSpecs()) {
        if (specs->SpecsCount > 0 && specs->Specs) {
            sort_specs_multi.reserve(specs->SpecsCount);
            for (int i = 0; i < specs->SpecsCount; ++i) {
                const ImGuiTableColumnSortSpecs& s = specs->Specs[i];
                sort_specs_multi.push_back({ s.ColumnIndex,
                                              static_cast<int>(s.SortDirection) });
            }
            sort_col_index = sort_specs_multi[0].col_index;
            sort_direction = sort_specs_multi[0].direction;
        } else {
            sort_col_index = -1;
            sort_direction = 0;
        }
    } else {
        sort_col_index = -1;
        sort_direction = 0;
    }

    ImGui::EndTable();
}

void TableNextRowWidget::Render()
{
    if (!visible) return;
    ImGui::TableNextRow(static_cast<ImGuiTableRowFlags>(row_flags), min_row_height);
}

void TableNextColumnWidget::Render()
{
    if (!visible) return;
    ImGui::TableNextColumn();
}

void TableSetColumnIndexWidget::Render()
{
    if (!visible) return;
    ImGui::TableSetColumnIndex(column_index);
}

void TableHeadersRowWidget::Render()
{
    if (!visible) return;
    ImGui::TableHeadersRow();
}

void TableSetBgColorWidget::Render()
{
    if (!visible) return;
    ImGui::TableSetBgColor(static_cast<ImGuiTableBgTarget>(target),
                            static_cast<ImU32>(color),
                            column_n);
}

void TableHeaderWidget::Render()
{
    if (!visible) return;
    ImGui::TableHeader(label.empty() ? id.c_str() : label.c_str());
}

void TableAngledHeadersRowWidget::Render()
{
    if (!visible) return;
    ImGui::TableAngledHeadersRow();
}

void TableGetColumnInfoWidget::Render()
{
    if (!visible) {
        // Don't clear : a hidden marker simply doesn't refresh — last known
        // values stay until the next time it renders. Matches GetCursorPosWidget
        // semantics (G.5) ; an explicit "no data" can be detected by index=-1
        // which is also what ImGui returns outside any column scope.
        return;
    }
    // We're rendered as a child of TableWidget, so we're inside BeginTable/
    // EndTable when this fires. ImGui::TableGetColumn* are safe here :
    //   - column_n = -1 → uses current column (latest TableNextColumn target)
    //   - explicit index → queries that column directly
    // Outside any TableNextColumn scope (e.g. before the first one), current
    // column = -1 and ImGui falls back gracefully (flags=0, name="").
    const int col = (query_column_n < 0)
                  ? ImGui::TableGetColumnIndex()
                  : query_column_n;
    latched_index = col;
    latched_flags = ImGui::TableGetColumnFlags(col);
    const char* n = ImGui::TableGetColumnName(col);
    latched_name  = n ? n : "";
}

// ---- C-ABI : create exports ------------------------------------------------

API_EXPORT int __cdecl ImGui_CreateTable(const wchar_t* id, int columns, int flags,
                                          float outer_w, float outer_h, float inner_width)
{
    if (!id || !*id || columns < 1) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto w = std::make_unique<TableWidget>();
    w->id            = uid;
    w->column_count  = columns;
    w->flags         = flags;
    w->outer_w       = outer_w;
    w->outer_h       = outer_h;
    w->inner_width   = inner_width;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateTableNextRow(const wchar_t* id, int row_flags, float min_row_height)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto w = std::make_unique<TableNextRowWidget>();
    w->id             = uid;
    w->row_flags      = row_flags;
    w->min_row_height = min_row_height;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateTableNextColumn(const wchar_t* id)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto w = std::make_unique<TableNextColumnWidget>();
    w->id = uid;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateTableSetColumnIndex(const wchar_t* id, int column_index)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto w = std::make_unique<TableSetColumnIndexWidget>();
    w->id           = uid;
    w->column_index = column_index;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateTableHeadersRow(const wchar_t* id)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto w = std::make_unique<TableHeadersRowWidget>();
    w->id = uid;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

// ---- C-ABI : column setup (I.2) -------------------------------------------

// Append a column config to the target TableWidget. Must be called AFTER
// _ImGui_CreateTable and BEFORE any child widget is added to the table —
// the configs are emitted in order during BeginTable, so the order matters.
// Returns : 0 = OK, 1 = bad args, 2 = unknown id, 3 = widget is not a table.
API_EXPORT int __cdecl ImGui_TableSetupColumn(const wchar_t* table_id, const wchar_t* label,
                                                int flags, float init_width_or_weight)
{
    if (!table_id || !*table_id) return 1;
    std::string tid  = WideToUtf8(table_id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(tid);
    if (!w) return 2;
    TableWidget* table = dynamic_cast<TableWidget*>(w);
    if (!table) return 3;
    ColumnConfig c{};
    c.label = ulbl;
    c.flags = flags;
    c.init_width_or_weight = init_width_or_weight;
    table->columns.push_back(c);
    return 0;
}

// ---- C-ABI : sort spec query (I.3) -----------------------------------------

// Out_spec[0] = column index sorted by (-1 = no sort active),
// Out_spec[1] = direction (0=None / 1=Asc / 2=Desc).
// Returns : 0 = OK, 1 = bad args, 2 = unknown id, 3 = widget is not a table.
API_EXPORT int __cdecl ImGui_TableGetSortSpecs(const wchar_t* table_id, int* out_spec)
{
    if (!table_id || !*table_id || !out_spec) return 1;
    std::string tid = WideToUtf8(table_id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(tid);
    if (!w) return 2;
    TableWidget* table = dynamic_cast<TableWidget*>(w);
    if (!table) return 3;
    out_spec[0] = table->sort_col_index;
    out_spec[1] = table->sort_direction;
    return 0;
}

// ---- C-ABI : scroll freeze setter (I.4) ------------------------------------

// Lock cols columns on the left + rows rows at the top so they stay visible
// during ScrollX/ScrollY. Persists across frames — set once after Create.
// Returns : 0 = OK, 1 = bad args, 2 = unknown id, 3 = widget is not a table.
API_EXPORT int __cdecl ImGui_TableSetupScrollFreeze(const wchar_t* table_id, int cols, int rows)
{
    if (!table_id || !*table_id || cols < 0 || rows < 0) return 1;
    std::string tid = WideToUtf8(table_id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(tid);
    if (!w) return 2;
    TableWidget* table = dynamic_cast<TableWidget*>(w);
    if (!table) return 3;
    table->freeze_cols = cols;
    table->freeze_rows = rows;
    return 0;
}

// ============================================================================
// Phase J.5 — Runtime tables extras.
// ============================================================================

// Toggle a column's enabled state at runtime. Queues a pending action ; the
// next BeginTable() scope picks it up and calls ImGui::TableSetColumnEnabled.
// If the same column is toggled twice before any frame consumes the first
// pending, we coalesce in-place rather than queueing two entries — saves a
// vector grow on rapid clicks. Returns 0/1/2/3 (1=bad args, 2=unknown, 3=not table).
API_EXPORT int __cdecl ImGui_TableSetColumnEnabled(const wchar_t* table_id,
                                                     int column_index, int enabled)
{
    if (!table_id || !*table_id || column_index < 0) return 1;
    std::string tid = WideToUtf8(table_id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(tid);
    if (!w) return 2;
    TableWidget* table = dynamic_cast<TableWidget*>(w);
    if (!table) return 3;
    // Coalesce : if there's already a pending entry for this column, overwrite.
    for (auto& pe : table->pending_col_enables) {
        if (pe.col == column_index) {
            pe.enabled = (enabled != 0) ? 1 : 0;
            pe.dirty   = true;
            return 0;
        }
    }
    table->pending_col_enables.push_back({ column_index, (enabled != 0) ? 1 : 0, true });
    return 0;
}

// TableSetBgColor marker widget. Place it as a sibling in the table's
// children, immediately after the targeted TableNextRow / TableNextColumn so
// ImGui::TableSetBgColor() lands on the right row/cell.
// Returns : 0 = OK, 1 = bad args, 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreateTableSetBgColor(const wchar_t* id, int target,
                                                    unsigned int u32_color, int column_n)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto w = std::make_unique<TableSetBgColorWidget>();
    w->id       = uid;
    w->target   = target;
    w->color    = u32_color;
    w->column_n = column_n;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

// Single-cell header. Place after a TableNextRow($ImGuiTableRowFlags_Headers)
// + a TableNextColumn / TableSetColumnIndex.
API_EXPORT int __cdecl ImGui_CreateTableHeader(const wchar_t* id, const wchar_t* label)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<TableHeaderWidget>();
    w->id    = uid;
    w->label = ulbl;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

// Zero-arg marker — emits an angled headers row. Requires at least one column
// configured with $ImGuiTableColumnFlags_AngledHeader to render visibly.
API_EXPORT int __cdecl ImGui_CreateTableAngledHeadersRow(const wchar_t* id)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto w = std::make_unique<TableAngledHeadersRowWidget>();
    w->id = uid;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

// ============================================================================
// Phase J.6 — Multi-column sort spec query.
// ============================================================================
//
// out_pairs receives flat int pairs : [col0, dir0, col1, dir1, ...]. The
// return value (>=0) is the number of pairs actually written, capped by
// max_pairs. 0 = no sort active. Negative return = error (mapped from the
// AutoIt wrapper to SetError).
API_EXPORT int __cdecl ImGui_TableGetSortSpecsN(const wchar_t* table_id,
                                                  int* out_pairs, int max_pairs)
{
    if (!table_id || !*table_id || !out_pairs || max_pairs < 1) return -1;
    std::string tid = WideToUtf8(table_id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(tid);
    if (!w) return -2;
    TableWidget* table = dynamic_cast<TableWidget*>(w);
    if (!table) return -3;
    int n = static_cast<int>(table->sort_specs_multi.size());
    if (n > max_pairs) n = max_pairs;
    for (int i = 0; i < n; ++i) {
        out_pairs[i * 2 + 0] = table->sort_specs_multi[i].col_index;
        out_pairs[i * 2 + 1] = table->sort_specs_multi[i].direction;
    }
    return n;
}

// ============================================================================
// Phase M.1 — Column queries (count, per-cell index/flags/name).
// ============================================================================

// Constant for the frame once BeginTable opened. Returns the latched value
// (>=0) on success ; on error returns a signed sentinel : -1=bad args,
// -2=unknown id, -3=widget is not a table.
API_EXPORT int __cdecl ImGui_TableGetColumnCount(const wchar_t* table_id)
{
    if (!table_id || !*table_id) return -1;
    std::string tid = WideToUtf8(table_id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(tid);
    if (!w) return -2;
    TableWidget* table = dynamic_cast<TableWidget*>(w);
    if (!table) return -3;
    return table->latched_column_count;
}

// Marker create. Place it as a child of TableWidget, AFTER the TableNextColumn
// (or TableSetColumnIndex) targeting the column to query — same convention as
// TableSetBgColorWidget (J.5). column_n = -1 means "use current column" ;
// any non-negative value queries that explicit index regardless of cursor.
API_EXPORT int __cdecl ImGui_CreateTableGetColumnInfo(const wchar_t* id, int column_n)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto w = std::make_unique<TableGetColumnInfoWidget>();
    w->id             = uid;
    w->query_column_n = column_n;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

// Read the latched column index. Returns the index (>=0), or -1 when the
// latest Render was outside any TableNextColumn scope (ImGui's natural default).
// Signed sentinel on error : -2=unknown id, -3=widget is not a column-info marker.
API_EXPORT int __cdecl ImGui_GetTableColumnIndex(const wchar_t* marker_id)
{
    if (!marker_id || !*marker_id) return -1;
    std::string uid = WideToUtf8(marker_id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return -2;
    auto* m = dynamic_cast<TableGetColumnInfoWidget*>(w);
    if (!m) return -3;
    return m->latched_index;
}

// Flags returned by out-param so the caller can distinguish flags=0 ("no
// flags set" — perfectly valid) from an error condition.
// Returns : 0=OK, 1=bad args, 2=unknown id, 3=widget is not a column-info marker.
API_EXPORT int __cdecl ImGui_GetTableColumnFlags(const wchar_t* marker_id, int* out_flags)
{
    if (!marker_id || !*marker_id || !out_flags) return 1;
    std::string uid = WideToUtf8(marker_id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    auto* m = dynamic_cast<TableGetColumnInfoWidget*>(w);
    if (!m) return 3;
    *out_flags = m->latched_flags;
    return 0;
}

// Read the latched column name into out_buf (UTF-16). Empty when the column
// has no name (TableSetupColumn called with empty label or no setup at all).
// Returns : 0=OK, 1=bad args, 2=unknown id, 3=not a marker, 4=truncated
// (string still null-terminated up to buf_cap-1).
API_EXPORT int __cdecl ImGui_GetTableColumnName(const wchar_t* marker_id,
                                                  wchar_t* out_buf, int buf_cap)
{
    if (!marker_id || !*marker_id || !out_buf || buf_cap <= 0) return 1;
    out_buf[0] = L'\0';
    std::string uid = WideToUtf8(marker_id);
    std::string name_copy;
    {
        std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
        Widget* w = g_tree.Find(uid);
        if (!w) return 2;
        auto* m = dynamic_cast<TableGetColumnInfoWidget*>(w);
        if (!m) return 3;
        name_copy = m->latched_name;
    }
    if (name_copy.empty()) return 0;
    std::wstring wide = Utf8ToWide(name_copy.c_str());
    const size_t cap  = static_cast<size_t>(buf_cap);
    const bool   fits = wide.size() + 1 <= cap;
    const size_t copy = fits ? wide.size() : cap - 1;
    std::memcpy(out_buf, wide.data(), copy * sizeof(wchar_t));
    out_buf[copy] = L'\0';
    return fits ? 0 : 4;
}
