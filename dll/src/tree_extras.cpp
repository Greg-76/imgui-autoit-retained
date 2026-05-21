// TreeNode + CollapsingHeader hand-written widgets (Phase D.6). See
// tree_extras.h for the field rationale.
//
// All C-ABI exports here run on the AutoIt thread under g_tree.mtx. They
// mutate the widget's pending_* fields ; the render thread consumes those
// during the next Render() pass (also under the same mutex).

#include "tree_extras.h"

#include <Windows.h>
#include <memory>
#include <string>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

// ---- Render -----------------------------------------------------------------

void TreeNodeWidget::Render()
{
    if (!visible) {
        is_toggled_open = false;
        return;
    }

    if (pending_open_dirty) {
        ImGui::SetNextItemOpen(pending_open, static_cast<ImGuiCond>(pending_open_cond));
        pending_open_dirty = false;
    }

    // TreeNodeEx(str_id, flags, fmt, ...) â€” id stays the stable widget key,
    // the displayed text comes from label (falls back to id when empty).
    // Matches the old generated call site (which used TreeNode with the same
    // (id, "%s", text) shape) except we now route through TreeNodeEx so the
    // flags parameter is honored.
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    const bool open   = ImGui::TreeNodeEx(id.c_str(), flags, "%s", shown);

    // Latch IsItemToggledOpen() immediately after the TreeNodeEx call,
    // BEFORE walking children â€” a child's last-item state would otherwise
    // shadow this probe.
    is_toggled_open = ImGui::IsItemToggledOpen();

    if (open) {
        for (auto& child : children) child->RenderAndQueryState();
        // ImGui::TreeNodeFlags_NoTreePushOnOpen skips the internal TreePush,
        // in which case TreePop must NOT be called. The generator's old code
        // also didn't handle that ; we keep parity for now (flags users who
        // pass NoTreePushOnOpen need to be aware). Standard usage : leave
        // NoTreePushOnOpen off and TreePop is the matching call.
        if (!(flags & ImGuiTreeNodeFlags_NoTreePushOnOpen)) {
            ImGui::TreePop();
        }
    }
}

void CollapsingHeaderWidget::Render()
{
    if (!visible) {
        is_toggled_open = false;
        return;
    }

    if (pending_open_dirty) {
        ImGui::SetNextItemOpen(pending_open, static_cast<ImGuiCond>(pending_open_cond));
        pending_open_dirty = false;
    }

    const char* shown = label.empty() ? id.c_str() : label.c_str();
    // closable != 0 : use the (label, bool* p_visible, flags) overload â€” ImGui
    // shows an X close button on the upper right ; clicking it writes false
    // into *p_visible (= our Widget::visible). At the next frame, the
    // early-return above hides the whole subtree until the script calls
    // _ImGui_SetVisible($id, True) to bring it back.
    const bool open = (closable != 0)
        ? ImGui::CollapsingHeader(shown, &visible, flags)
        : ImGui::CollapsingHeader(shown, flags);

    is_toggled_open = ImGui::IsItemToggledOpen();

    if (open) {
        for (auto& child : children) child->RenderAndQueryState();
    }
    // CollapsingHeader is conditional_no_end : no End/TreePop needed (ImGui
    // documents it as such â€” "doesn't indent nor push on ID stack").
}

// ---- C-ABI exports ----------------------------------------------------------

// Create â€” matches the old generated signature (id, label) plus the new int
// flags. Old 2-arg AutoIt callers continue to work via the wrapper's default.
// Returns: 0 = OK, 1 = id invalid, 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreateTreeNode(const wchar_t* id, const wchar_t* label,
                                             int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto widget = std::make_unique<TreeNodeWidget>();
    widget->id    = uid;
    widget->label = ulbl;
    widget->flags = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

// Create â€” adds closable (int 0/1) and flags on top of the old (id, label) pair.
// Returns: 0 = OK, 1 = id invalid, 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreateCollapsingHeader(const wchar_t* id, const wchar_t* label,
                                                     int closable, int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto widget = std::make_unique<CollapsingHeaderWidget>();
    widget->id       = uid;
    widget->label    = ulbl;
    widget->closable = closable;
    widget->flags    = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

// --- SetNextItemOpen + IsToggledOpen : single export each, dynamic_cast routes
// to either widget type. Returns 3 if the widget exists but is neither a
// TreeNode nor a CollapsingHeader.

API_EXPORT int __cdecl ImGui_SetNextItemOpen(const wchar_t* id, int b_open, int cond)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    if (auto* t = dynamic_cast<TreeNodeWidget*>(w)) {
        t->pending_open       = (b_open != 0);
        t->pending_open_cond  = cond;
        t->pending_open_dirty = true;
        return 0;
    }
    if (auto* c = dynamic_cast<CollapsingHeaderWidget*>(w)) {
        c->pending_open       = (b_open != 0);
        c->pending_open_cond  = cond;
        c->pending_open_dirty = true;
        return 0;
    }
    return 3;
}

API_EXPORT int __cdecl ImGui_IsToggledOpen(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    if (auto* t = dynamic_cast<TreeNodeWidget*>(w))         return t->is_toggled_open ? 1 : 0;
    if (auto* c = dynamic_cast<CollapsingHeaderWidget*>(w)) return c->is_toggled_open ? 1 : 0;
    return 0;
}
