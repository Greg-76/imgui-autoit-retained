#pragma once
#include "widget.h"

// TreeNode + CollapsingHeader (D.6) — hand-written widgets, used to live in
// the container generator. Pulled out for the same reason WindowWidget was in
// D.3 : both gain a per-widget pending state (SetNextItemOpen) and additional
// latched queries (IsItemToggledOpen) that don't fit the container generator's
// four template_kinds.
//
// Naming : the C-ABI export names (ImGui_CreateTreeNode, ImGui_CreateCollapsingHeader)
// match the old generator output, so existing AutoIt scripts keep working —
// the new flags / closable parameters get sensible defaults (0).

struct TreeNodeWidget : Widget {
    int  flags = 0;                  // ImGuiTreeNodeFlags (creation-time constant)

    // --- Pending one-shot SetNextItemOpen — same plumbing as WindowWidget's
    // pending_pos_dirty etc. Set from AutoIt via ImGui_SetNextItemOpen($id, ...)
    // ; consumed once at the start of the next Render(). Strict semantics :
    // programmatic open/close NEVER latches is_toggled_open.
    bool pending_open_dirty = false;
    bool pending_open       = false;
    int  pending_open_cond  = 0;     // 0 = Always (functionally identical to None)

    // --- Latched query : IsItemToggledOpen(). True for exactly one frame
    // when the user clicks the arrow to open/close the node. Reset to false
    // when the widget is hidden, same rule as Widget::is_clicked etc.
    bool is_toggled_open = false;

    void Render() override;
};

struct CollapsingHeaderWidget : Widget {
    int  flags    = 0;               // ImGuiTreeNodeFlags
    // 0 = use the no-X overload (ImGui::CollapsingHeader(label, flags))
    // 1 = use the p_visible overload — clicking the X writes false into
    //     Widget::visible (same bool we use for SetVisible). On the next
    //     frame, the early-return at the top of Render() hides everything.
    int  closable = 0;

    bool pending_open_dirty = false;
    bool pending_open       = false;
    int  pending_open_cond  = 0;

    bool is_toggled_open = false;

    void Render() override;
};
