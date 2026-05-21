#pragma once
#include "widget.h"

// H.1 — Per-window scroll state shared by WindowWidget and ChildWidget.
// `scroll_*` are latched after children render (read by AutoIt via _ImGui_GetScroll*).
// `pending_*` are one-shot setters queued by AutoIt and consumed in
// ConsumeBeforeEnd(), called right before End/EndChild. Placing Set after
// children means SetScrollHere uses the cursor's final position — natural
// "scroll to bottom" semantics for a log panel.
struct ScrollableState {
    float scroll_x     = 0.0f, scroll_y     = 0.0f;
    float scroll_max_x = 0.0f, scroll_max_y = 0.0f;

    bool  pending_scroll_x        = false;  float pending_scroll_x_v        = 0.0f;
    bool  pending_scroll_y        = false;  float pending_scroll_y_v        = 0.0f;
    bool  pending_scroll_here_x   = false;  float pending_scroll_here_x_r   = 0.5f;
    bool  pending_scroll_here_y   = false;  float pending_scroll_here_y_r   = 0.5f;
    bool  pending_scroll_from_x   = false;  float pending_scroll_from_x_p   = 0.0f;
                                            float pending_scroll_from_x_r   = 0.5f;
    bool  pending_scroll_from_y   = false;  float pending_scroll_from_y_p   = 0.0f;
                                            float pending_scroll_from_y_r   = 0.5f;

    void ConsumeBeforeEnd();   // applies all pending Set* and clears flags
    void LatchAtEnd();         // reads ImGui::GetScroll* into the 4 fields
    void ClearWhenHidden();    // zeroes everything (called by Render when !visible)
};

// Top-level floating ImGui window. Hand-written (used to be in the container
// generator) because Phase D.3 introduced a runtime-mutable pending-state set
// + window-level latched queries that don't fit the four template_kinds the
// container generator supports.
//
// The X close button is driven by passing `&visible` to ImGui::Begin when
// `closable != 0` ; when the user clicks X, *p_open becomes false (i.e.
// `visible` becomes false), the next-frame early-return then hides the window.
struct WindowWidget : Widget {
    int   closable = 1;     // 0 = no X button (no closable contract)
    int   flags    = 0;     // ImGuiWindowFlags

    // --- Pending state (consumed at most once per Render). Each setter from
    // AutoIt flips the corresponding dirty flag ; Render() then issues the
    // matching ImGui::SetNextWindow*() call and clears the flag. This mirrors
    // the strict-changed semantics elsewhere: programmatic writes don't latch
    // user-facing flags, they just queue a one-shot ImGui call.

    bool  pending_pos_dirty            = false;
    float pending_pos_x                = 0.0f;
    float pending_pos_y                = 0.0f;
    int   pending_pos_cond             = 0;   // ImGuiCond_None = Always semantically

    bool  pending_size_dirty           = false;
    float pending_size_w               = 0.0f;
    float pending_size_h               = 0.0f;
    int   pending_size_cond            = 0;

    bool  pending_collapsed_dirty      = false;
    bool  pending_collapsed            = false;
    int   pending_collapsed_cond       = 0;

    bool  pending_focus_dirty          = false;   // no value — one-shot SetNextWindowFocus

    bool  pending_bg_alpha_dirty       = false;
    float pending_bg_alpha             = 1.0f;

    bool  pending_size_constraints_dirty = false;
    float pending_min_w                = 0.0f;
    float pending_min_h                = 0.0f;
    float pending_max_w                = 0.0f;    // FLT_MAX is the "no limit" sentinel
    float pending_max_h                = 0.0f;

    // J.3 — SetNextWindowContentSize + SetNextWindowScroll. Distinct from
    // ScrollableState::pending_scroll_* which fires AFTER children render
    // (canonical "scroll to bottom" semantics). The pending_next_scroll_*
    // here calls SetNextWindowScroll BEFORE Begin (initial frame-wide scroll
    // override, useful to restore a saved position at boot).
    bool  pending_content_size_dirty   = false;
    float pending_content_w            = 0.0f;
    float pending_content_h            = 0.0f;

    bool  pending_next_scroll_dirty    = false;
    float pending_next_scroll_x        = 0.0f;
    float pending_next_scroll_y        = 0.0f;

    // --- Latched window-level queries (updated each frame between Begin/End).
    // These differ from Widget::is_hovered/is_active/is_focused which are
    // ImGui::IsItem*() probes (the window as the LAST item, i.e. its title
    // bar / body). Window-level queries (IsWindow*) include child contents
    // and obey window-flags. Reset to false / 0 when the widget is hidden.
    bool  is_appearing        = false;
    bool  is_window_collapsed = false;
    bool  is_window_focused   = false;
    bool  is_window_hovered   = false;
    float window_pos_x        = 0.0f;
    float window_pos_y        = 0.0f;
    float window_size_x       = 0.0f;
    float window_size_y       = 0.0f;

    // K.1 — IsWindowHovered(flags) extended latch. The flags-less variant above
    // (`is_window_hovered`) is kept for backward compat ; this one runs with a
    // user-provided ImGuiHoveredFlags_* mask, set via _ImGui_SetWindowHoveredFlags.
    int  window_hovered_flags    = 0;
    bool is_window_hovered_ex    = false;

    // H.1 — Scroll state, populated by ImGui::GetScroll* between Begin/End and
    // consumed by SetScroll* calls. Routes through the Widget virtual.
    ScrollableState scroll;
    ScrollableState* GetScrollable() override { return &scroll; }

    void Render() override;
    bool IsTopLevelWindow() const override { return true; }
};

// H.1 — ChildWidget hand-written (split out from the generator, like TreeNode/Tab/Popup).
// Split out to allow embedding ScrollableState — the generator's conditional_children_always_end
// pattern doesn't allow injecting code before End. Render() maps one-to-one to
// the old container generator (3 params w/h/border, EndChild always called).
struct ChildWidget : Widget {
    float w      = 0.0f;
    float h      = 0.0f;
    int   border = 0;     // ImGuiChildFlags_Borders bit when non-zero

    ScrollableState scroll;
    ScrollableState* GetScrollable() override { return &scroll; }

    void Render() override;
};
