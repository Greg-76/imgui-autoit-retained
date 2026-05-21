#pragma once
#include "widget.h"

// Tab extensions (D.7) — hand-written widgets that used to live in the
// container generator. Same reason as D.6's tree_extras : TabItem gained the
// optional X close button (via the p_open overload, reusing Widget::visible
// as the bool*), constructor flags, and a per-widget pending state
// (SetTabItemClosed consumed at the start of the next Render). TabItemButton
// is brand new — a clickable inline tab with no body.

// TabItemWidget : a single tab inside a TabBar. Holds children that get
// rendered between BeginTabItem/EndTabItem when the tab is selected.
struct TabItemWidget : Widget {
    int  flags    = 0;             // ImGuiTabItemFlags (creation-time constant)
    // 0 = no X (use the (label, NULL, flags) overload)
    // 1 = X visible — pass &visible as p_open. When user clicks X, ImGui
    //     writes false into *p_open (= Widget::visible). The next frame's
    //     early-return on !visible hides the tab and its body. Script can
    //     restore it via _ImGui_SetVisible($id, True).
    int  closable = 0;

    // Pending one-shot SetTabItemClosed. Consumed at the very first line of
    // Render() — which still runs INSIDE the parent TabBar's Begin/End block
    // (we're a child of TabBarWidget). That's exactly where
    // ImGui::SetTabItemClosed expects to be called, per its docs.
    bool pending_closed = false;

    void Render() override;
};

// TabItemButtonWidget : a tab-shaped clickable button that doesn't carry a
// body and isn't sticky-selectable. Renders inline in the TabBar's flow ;
// Leading / Trailing flags pin it to either side of the bar. Hand-written
// because it's a leaf widget that lives in a container's children list —
// the clickable generator's category targets top-level widgets, not children
// of TabBar.
struct TabItemButtonWidget : ClickableWidget {
    int flags = 0;                 // ImGuiTabItemFlags
    void Render() override;
};
