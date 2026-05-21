#pragma once
#include "widget.h"
#include <string>
#include <vector>

// Phase I — Tables.
//
// Three concepts :
//   - TableWidget         : container around BeginTable/EndTable. Children are
//                            row/column markers + content widgets, all rendered
//                            inside the table region. Conditional_pair pattern :
//                            BeginTable returns bool, EndTable iff true.
//   - TableNextRow        : marker — calls ImGui::TableNextRow().
//   - TableNextColumn     : marker — calls ImGui::TableNextColumn().
//   - TableSetColumnIndex : marker — calls ImGui::TableSetColumnIndex(N).
//   - TableHeadersRow     : marker — calls ImGui::TableHeadersRow() (I.2).
//
// Cells are NOT containers : content widgets (Text, Button, …) live as siblings
// AFTER the matching TableNextColumn / TableSetColumnIndex marker, at the table
// parent level. This mirrors how ImGui's table API actually works ("move
// cursor to next cell, then submit content there") and keeps the children
// tree flat — no double-nesting per cell.
//
// Phase I.2 adds column setup (TableSetupColumn called between BeginTable and
// the children walk) ; Phase I.3 adds sort-spec latching ; Phase I.4 adds
// scroll-freeze.

struct ColumnConfig {
    std::string label;
    int         flags                = 0;     // ImGuiTableColumnFlags_
    float       init_width_or_weight = 0.0f;  // 0 = ImGui default
};

struct TableWidget : Widget {
    int   column_count = 1;
    int   flags        = 0;    // ImGuiTableFlags_
    float outer_w      = 0.0f; // 0 = stretch to available width
    float outer_h      = 0.0f; // 0 = auto height
    float inner_width  = 0.0f; // ScrollX content width (0 = use outer)

    // I.2 column setup — populated by _ImGui_TableSetupColumn calls.
    std::vector<ColumnConfig> columns;

    // I.3 latched sort spec, written each frame after the table renders.
    // sort_col_index = -1 when no sort active (table not Sortable, or no
    // column has a sort priority).
    int sort_col_index = -1;
    int sort_direction = 0;    // 0 = None, 1 = Asc, 2 = Desc (ImGuiSortDirection_)

    // J.6 — Multi-column sort spec, latched each frame in parallel to the
    // I.3 single-col fields above. Empty when no sort is active. Each entry =
    // (column index, direction). Index 0 of this vector matches the single-col
    // fields for forward compat.
    struct SortSpecEntry { int col_index; int direction; };
    std::vector<SortSpecEntry> sort_specs_multi;

    // I.4 scroll freeze — applied right after BeginTable.
    int freeze_cols = 0;
    int freeze_rows = 0;

    // J.5 — TableSetColumnEnabled : one-shot pending toggles applied inside the
    // BeginTable scope at Render() start. Reset (dirty=false) after consumption.
    struct PendingColEnable { int col; int enabled; bool dirty; };
    std::vector<PendingColEnable> pending_col_enables;

    // M.1 — Column count latched each frame at the top of Render() after
    // BeginTable returns true. Read by ImGui_TableGetColumnCount. 0 when the
    // table is hidden or culled (BeginTable returned false).
    int latched_column_count = 0;

    void Render() override;
};

// J.5 — TableSetBgColor marker. Placed as a sibling in TableWidget::children
// immediately after the targeted TableNextRow / TableNextColumn marker so the
// ImGui::TableSetBgColor() call lands on the correct row/cell (semantics are
// "apply to current row/cell as of this call site").
struct TableSetBgColorWidget : Widget {
    int          target   = 0;   // ImGuiTableBgTarget_RowBg0/RowBg1/CellBg
    unsigned int color    = 0;   // ImU32 packed (0xAABBGGRR)
    int          column_n = -1;  // -1 = current cell (target=CellBg) / current row (RowBg*)
    void Render() override;
};

// J.5 — Single-column header emitter. Distinct from TableHeadersRow (which
// emits the whole row in one call) ; this one lets AutoIt build a custom
// header row by hand : TableNextRow(Headers) + per-cell TableNextColumn +
// per-cell TableHeader(label).
struct TableHeaderWidget : Widget {
    // label = Widget::label.
    void Render() override;
};

// J.5 — Zero-arg marker, calls ImGui::TableAngledHeadersRow(). Requires at
// least one column with $ImGuiTableColumnFlags_AngledHeader to produce visible
// output.
struct TableAngledHeadersRowWidget : Widget {
    void Render() override;
};

struct TableNextRowWidget : Widget {
    int   row_flags      = 0;     // ImGuiTableRowFlags_
    float min_row_height = 0.0f;
    void Render() override;
};

struct TableNextColumnWidget : Widget {
    void Render() override;
};

struct TableSetColumnIndexWidget : Widget {
    int column_index = 0;
    void Render() override;
};

struct TableHeadersRowWidget : Widget {
    void Render() override;
};

// M.1 — Per-cell column info latch. Placed as a sibling of the table's row /
// column markers, AFTER a TableNextColumn (or TableSetColumnIndex) targeting
// the column to query — same positional convention as TableSetBgColorWidget
// (J.5). Render() runs inside the BeginTable/EndTable scope so the
// ImGui::TableGetColumn* calls are safe (current column is well-defined).
//
// `query_column_n` = -1 means "use the current column" (whatever the latest
// TableNextColumn moved to). Any non-negative value queries that explicit
// column index regardless of cursor position. AutoIt reads back the latched
// values with ImGui_GetTableColumnIndex / Flags / Name keyed on the marker id.
struct TableGetColumnInfoWidget : Widget {
    int  query_column_n  = -1;
    int  latched_index   = -1;
    int  latched_flags   = 0;
    std::string latched_name;   // utf-8, empty when column has no name or doesn't exist
    void Render() override;
};
