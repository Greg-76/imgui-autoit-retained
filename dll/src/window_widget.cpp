// Hand-written WindowWidget (Phase D.3 extensions) â€” pending-state setters,
// window-level latched queries, ImGui::SetNextWindow*() pre-Begin plumbing.
// See window_widget.h for the field rationale.
//
// All C-ABI exports here run on the AutoIt thread under g_tree.mtx. They
// mutate the WindowWidget's pending_* fields ; the render thread consumes
// those during the next Render() pass (also under the same mutex).

#include "window_widget.h"

#include <Windows.h>
#include <memory>
#include <string>
#include <cfloat>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

// ---- ScrollableState (H.1) --------------------------------------------------

void ScrollableState::ConsumeBeforeEnd()
{
    // Order : SetScroll{X,Y} then SetScrollHere{X,Y} then SetScrollFromPos{X,Y}.
    // ImGui applies the LAST call to win in case of conflict — the order here
    // gives priority to the "from pos" variants if multiple are queued in the
    // same frame (unlikely but well-defined).
    if (pending_scroll_x)        { ImGui::SetScrollX(pending_scroll_x_v);        pending_scroll_x        = false; }
    if (pending_scroll_y)        { ImGui::SetScrollY(pending_scroll_y_v);        pending_scroll_y        = false; }
    if (pending_scroll_here_x)   { ImGui::SetScrollHereX(pending_scroll_here_x_r);   pending_scroll_here_x   = false; }
    if (pending_scroll_here_y)   { ImGui::SetScrollHereY(pending_scroll_here_y_r);   pending_scroll_here_y   = false; }
    if (pending_scroll_from_x)   { ImGui::SetScrollFromPosX(pending_scroll_from_x_p, pending_scroll_from_x_r); pending_scroll_from_x = false; }
    if (pending_scroll_from_y)   { ImGui::SetScrollFromPosY(pending_scroll_from_y_p, pending_scroll_from_y_r); pending_scroll_from_y = false; }
}

void ScrollableState::LatchAtEnd()
{
    scroll_x     = ImGui::GetScrollX();
    scroll_y     = ImGui::GetScrollY();
    scroll_max_x = ImGui::GetScrollMaxX();
    scroll_max_y = ImGui::GetScrollMaxY();
}

void ScrollableState::ClearWhenHidden()
{
    scroll_x = scroll_y = scroll_max_x = scroll_max_y = 0.0f;
}

// ---- Render -----------------------------------------------------------------

void WindowWidget::Render()
{
    if (!visible) {
        // Hidden â€” also clear latched queries so polls don't return stale info.
        is_appearing = is_window_collapsed = is_window_focused = is_window_hovered = false;
        is_window_hovered_ex = false;
        window_pos_x = window_pos_y = window_size_x = window_size_y = 0.0f;
        scroll.ClearWhenHidden();
        return;
    }

    // --- Apply pending one-shot ImGui::SetNextWindow*() calls.
    if (pending_pos_dirty) {
        ImGui::SetNextWindowPos(ImVec2(pending_pos_x, pending_pos_y),
                                static_cast<ImGuiCond>(pending_pos_cond));
        pending_pos_dirty = false;
    }
    if (pending_size_dirty) {
        ImGui::SetNextWindowSize(ImVec2(pending_size_w, pending_size_h),
                                 static_cast<ImGuiCond>(pending_size_cond));
        pending_size_dirty = false;
    }
    if (pending_collapsed_dirty) {
        ImGui::SetNextWindowCollapsed(pending_collapsed,
                                      static_cast<ImGuiCond>(pending_collapsed_cond));
        pending_collapsed_dirty = false;
    }
    if (pending_focus_dirty) {
        ImGui::SetNextWindowFocus();
        pending_focus_dirty = false;
    }
    if (pending_bg_alpha_dirty) {
        ImGui::SetNextWindowBgAlpha(pending_bg_alpha);
        pending_bg_alpha_dirty = false;
    }
    if (pending_size_constraints_dirty) {
        ImGui::SetNextWindowSizeConstraints(ImVec2(pending_min_w, pending_min_h),
                                            ImVec2(pending_max_w, pending_max_h));
        pending_size_constraints_dirty = false;
    }
    if (pending_content_size_dirty) {
        ImGui::SetNextWindowContentSize(ImVec2(pending_content_w, pending_content_h));
        pending_content_size_dirty = false;
    }
    if (pending_next_scroll_dirty) {
        ImGui::SetNextWindowScroll(ImVec2(pending_next_scroll_x, pending_next_scroll_y));
        pending_next_scroll_dirty = false;
    }

    // --- The actual Begin/End block. End() is ALWAYS called (matches the
    // generator's old conditional_children_always_end pattern) so the ImGui
    // window stack is balanced even when the window is collapsed.
    const bool open = ImGui::Begin(label.empty() ? id.c_str() : label.c_str(),
                                    closable != 0 ? &visible : nullptr,
                                    flags);

    // --- Latch window-level queries while still inside Begin/End. These work
    // even when the window is collapsed (IsWindowCollapsed will be true, the
    // others will be valid for the title-bar). Same applies to GetWindowPos/Size.
    is_appearing        = ImGui::IsWindowAppearing();
    is_window_collapsed = ImGui::IsWindowCollapsed();
    is_window_focused   = ImGui::IsWindowFocused();
    is_window_hovered   = ImGui::IsWindowHovered();
    is_window_hovered_ex = (window_hovered_flags != 0)
        ? ImGui::IsWindowHovered(window_hovered_flags)
        : is_window_hovered;
    const ImVec2 wpos   = ImGui::GetWindowPos();
    const ImVec2 wsize  = ImGui::GetWindowSize();
    window_pos_x  = wpos.x;  window_pos_y  = wpos.y;
    window_size_x = wsize.x; window_size_y = wsize.y;

    if (open) {
        for (auto& child : children) child->RenderAndQueryState();
        // H.1 — apply pending SetScroll* (after children, so SetScrollHere uses
        // the cursor's final position) and latch GetScroll* for AutoIt to read.
        scroll.ConsumeBeforeEnd();
        scroll.LatchAtEnd();
    } else {
        // Window collapsed / not open : scroll state isn't observable, clear
        // so polls don't return stale values from a previous expanded frame.
        scroll.ClearWhenHidden();
    }
    ImGui::End();
}

// ---- ChildWidget (H.1, split out from the generator) -----------------------

void ChildWidget::Render()
{
    if (!visible) {
        scroll.ClearWhenHidden();
        return;
    }
    if (!enabled) ImGui::BeginDisabled();
    // BeginChild returns false when culled (out of clip) — we still must call
    // EndChild (conditional_children_always_end semantics, parity with the
    // old generator output). The border bit maps to ImGuiChildFlags_Borders.
    const bool open = ImGui::BeginChild(id.c_str(),
                                        ImVec2(w, h),
                                        border != 0 ? ImGuiChildFlags_Borders
                                                    : ImGuiChildFlags_None);
    if (open) {
        for (auto& child : children) child->RenderAndQueryState();
        scroll.ConsumeBeforeEnd();
        scroll.LatchAtEnd();
    } else {
        scroll.ClearWhenHidden();
    }
    ImGui::EndChild();
    if (!enabled) ImGui::EndDisabled();
}

// ---- ChildWidget C-ABI export (replaces the old generator one) -------------

// Same signature as the previous generated ImGui_CreateChild — existing AutoIt
// scripts continue to work without modification. The label arg is accepted for
// signature parity (matches the container generator output) but ignored — Child
// doesn't display a label.
API_EXPORT int __cdecl ImGui_CreateChild(const wchar_t* id, const wchar_t* /*label*/,
                                          float w, float h, int border)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto widget = std::make_unique<ChildWidget>();
    widget->id     = uid;
    widget->w      = w;
    widget->h      = h;
    widget->border = border;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

// ---- C-ABI exports ----------------------------------------------------------

// Create â€” same signature as the old generated export (id, title, closable, flags)
// so existing AutoIt scripts that call _ImGui_CreateWindow continue to work.
// Returns: 0 = OK, 1 = id invalid, 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreateWindow(const wchar_t* id, const wchar_t* label,
                                           int closable, int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto widget = std::make_unique<WindowWidget>();
    widget->id       = uid;
    widget->label    = ulbl;
    widget->closable = closable;
    widget->flags    = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

// --- Helpers : find a WindowWidget by id, returns nullptr on mismatch -------
// (Locked by the caller.)
static WindowWidget* FindWindow(const std::string& uid)
{
    Widget* w = g_tree.Find(uid);
    return dynamic_cast<WindowWidget*>(w);
}

// --- Pending-state setters (D.3) --------------------------------------------
// Common return code: 0 = OK, 1 = id null/empty, 2 = unknown id, 3 = not a window.

API_EXPORT int __cdecl ImGui_SetWindowPos(const wchar_t* id, float x, float y, int cond)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* w = FindWindow(uid);
    if (!w) return g_tree.Find(uid) ? 3 : 2;
    w->pending_pos_x     = x;
    w->pending_pos_y     = y;
    w->pending_pos_cond  = cond;
    w->pending_pos_dirty = true;
    return 0;
}

API_EXPORT int __cdecl ImGui_SetWindowSize(const wchar_t* id, float w_, float h, int cond)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* w = FindWindow(uid);
    if (!w) return g_tree.Find(uid) ? 3 : 2;
    w->pending_size_w     = w_;
    w->pending_size_h     = h;
    w->pending_size_cond  = cond;
    w->pending_size_dirty = true;
    return 0;
}

API_EXPORT int __cdecl ImGui_SetWindowCollapsed(const wchar_t* id, int collapsed, int cond)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* w = FindWindow(uid);
    if (!w) return g_tree.Find(uid) ? 3 : 2;
    w->pending_collapsed       = (collapsed != 0);
    w->pending_collapsed_cond  = cond;
    w->pending_collapsed_dirty = true;
    return 0;
}

API_EXPORT int __cdecl ImGui_SetWindowFocus(const wchar_t* id)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* w = FindWindow(uid);
    if (!w) return g_tree.Find(uid) ? 3 : 2;
    w->pending_focus_dirty = true;
    return 0;
}

API_EXPORT int __cdecl ImGui_SetWindowBgAlpha(const wchar_t* id, float alpha)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* w = FindWindow(uid);
    if (!w) return g_tree.Find(uid) ? 3 : 2;
    if (alpha < 0.0f) alpha = 0.0f;
    if (alpha > 1.0f) alpha = 1.0f;
    w->pending_bg_alpha       = alpha;
    w->pending_bg_alpha_dirty = true;
    return 0;
}

// J.3 — Pin the content-size hint used to compute scrollbars when ScrollX/Y is
// active. Pass 0 on an axis to let ImGui auto-fit. Equivalent to
// ImGui::SetNextWindowContentSize but applied at the next Render() of this
// specific window (one-shot ; the setter must be re-called each frame to keep
// the override active, matching ImGui's own SetNextWindow* contract).
API_EXPORT int __cdecl ImGui_SetWindowContentSize(const wchar_t* id, float w, float h)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* win = FindWindow(uid);
    if (!win) return g_tree.Find(uid) ? 3 : 2;
    win->pending_content_w     = w;
    win->pending_content_h     = h;
    win->pending_content_size_dirty = true;
    return 0;
}

// J.3 — One-shot scroll override applied BEFORE Begin via SetNextWindowScroll.
// Distinct from _ImGui_SetScrollX/Y (H.1) which fires AFTER the children render
// (canonical "scroll to bottom" semantics) ; this one is best for "restore the
// saved scroll position when the window opens".
API_EXPORT int __cdecl ImGui_SetWindowScroll(const wchar_t* id, float x, float y)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* win = FindWindow(uid);
    if (!win) return g_tree.Find(uid) ? 3 : 2;
    win->pending_next_scroll_x     = x;
    win->pending_next_scroll_y     = y;
    win->pending_next_scroll_dirty = true;
    return 0;
}

// max_w/max_h: pass FLT_MAX (caller can omit/pass 0 ; we map any non-positive
// value to FLT_MAX so AutoIt scripts don't need to know about FLT_MAX).
API_EXPORT int __cdecl ImGui_SetWindowSizeConstraints(const wchar_t* id,
                                                       float min_w, float min_h,
                                                       float max_w, float max_h)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* w = FindWindow(uid);
    if (!w) return g_tree.Find(uid) ? 3 : 2;
    if (max_w <= 0.0f) max_w = FLT_MAX;
    if (max_h <= 0.0f) max_h = FLT_MAX;
    w->pending_min_w = min_w;
    w->pending_min_h = min_h;
    w->pending_max_w = max_w;
    w->pending_max_h = max_h;
    w->pending_size_constraints_dirty = true;
    return 0;
}

// --- Latched window-level queries (D.3) -------------------------------------
// 0 / 1 returned. Unknown id or non-Window widget returns 0 (no @error,
// same convention as the generic IsHovered/IsActive/IsFocused exports).

API_EXPORT int __cdecl ImGui_IsWindowAppearing(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* w = FindWindow(uid);
    return (w && w->is_appearing) ? 1 : 0;
}

API_EXPORT int __cdecl ImGui_IsWindowCollapsed(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* w = FindWindow(uid);
    return (w && w->is_window_collapsed) ? 1 : 0;
}

API_EXPORT int __cdecl ImGui_IsWindowFocused(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* w = FindWindow(uid);
    return (w && w->is_window_focused) ? 1 : 0;
}

API_EXPORT int __cdecl ImGui_IsWindowHovered(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* w = FindWindow(uid);
    return (w && w->is_window_hovered) ? 1 : 0;
}

// K.1 — Set the ImGuiHoveredFlags mask for the next IsWindowHoveredEx latch.
// Pass 0 to reset (equivalent to IsWindowHovered() with no flags = same value
// as is_window_hovered). Returns 0=OK / 1=bad args / 2=unknown / 3=not a window.
API_EXPORT int __cdecl ImGui_SetWindowHoveredFlags(const wchar_t* id, int flags)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* w = FindWindow(uid);
    if (!w) return g_tree.Find(uid) ? 3 : 2;
    w->window_hovered_flags = flags;
    return 0;
}

API_EXPORT int __cdecl ImGui_IsWindowHoveredEx(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* w = FindWindow(uid);
    return (w && w->is_window_hovered_ex) ? 1 : 0;
}

// Out-param 2 floats. 0 = OK (out written), 1 = id/out null, 2 = unknown id,
// 3 = not a window.
API_EXPORT int __cdecl ImGui_GetWindowPos(const wchar_t* id, float* out_xy)
{
    if (!id || !*id || !out_xy) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* w = FindWindow(uid);
    if (!w) return g_tree.Find(uid) ? 3 : 2;
    out_xy[0] = w->window_pos_x;
    out_xy[1] = w->window_pos_y;
    return 0;
}

API_EXPORT int __cdecl ImGui_GetWindowSize(const wchar_t* id, float* out_wh)
{
    if (!id || !*id || !out_wh) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    WindowWidget* w = FindWindow(uid);
    if (!w) return g_tree.Find(uid) ? 3 : 2;
    out_wh[0] = w->window_size_x;
    out_wh[1] = w->window_size_y;
    return 0;
}

// ============================================================================
// H.1 — Scroll helpers (work on Window and Child widgets via GetScrollable())
// ============================================================================
//
// All routed through Widget::GetScrollable() — returns &scroll on Window/Child,
// nullptr on every other widget type. Common return codes :
//   0 = OK, 1 = id/out null, 2 = unknown id, 3 = widget is not scrollable.
//
// Setters are one-shot pending : the next Render of the target widget consumes
// the pending value (between children walk and End/EndChild) and clears the
// flag. Programmatic setters never latch the widget's `changed` (same strict
// semantics as other Set* in this codebase).

static ScrollableState* FindScrollable(const std::string& uid, Widget** out_widget)
{
    Widget* w = g_tree.Find(uid);
    if (out_widget) *out_widget = w;
    return w ? w->GetScrollable() : nullptr;
}

API_EXPORT int __cdecl ImGui_GetScrollX(const wchar_t* id, float* out)
{
    if (!id || !*id || !out) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = nullptr;
    ScrollableState* ss = FindScrollable(uid, &w);
    if (!ss) return w ? 3 : 2;
    *out = ss->scroll_x;
    return 0;
}

API_EXPORT int __cdecl ImGui_GetScrollY(const wchar_t* id, float* out)
{
    if (!id || !*id || !out) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = nullptr;
    ScrollableState* ss = FindScrollable(uid, &w);
    if (!ss) return w ? 3 : 2;
    *out = ss->scroll_y;
    return 0;
}

API_EXPORT int __cdecl ImGui_GetScrollMaxX(const wchar_t* id, float* out)
{
    if (!id || !*id || !out) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = nullptr;
    ScrollableState* ss = FindScrollable(uid, &w);
    if (!ss) return w ? 3 : 2;
    *out = ss->scroll_max_x;
    return 0;
}

API_EXPORT int __cdecl ImGui_GetScrollMaxY(const wchar_t* id, float* out)
{
    if (!id || !*id || !out) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = nullptr;
    ScrollableState* ss = FindScrollable(uid, &w);
    if (!ss) return w ? 3 : 2;
    *out = ss->scroll_max_y;
    return 0;
}

API_EXPORT int __cdecl ImGui_SetScrollX(const wchar_t* id, float v)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = nullptr;
    ScrollableState* ss = FindScrollable(uid, &w);
    if (!ss) return w ? 3 : 2;
    ss->pending_scroll_x_v = v;
    ss->pending_scroll_x   = true;
    return 0;
}

API_EXPORT int __cdecl ImGui_SetScrollY(const wchar_t* id, float v)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = nullptr;
    ScrollableState* ss = FindScrollable(uid, &w);
    if (!ss) return w ? 3 : 2;
    ss->pending_scroll_y_v = v;
    ss->pending_scroll_y   = true;
    return 0;
}

API_EXPORT int __cdecl ImGui_SetScrollHereX(const wchar_t* id, float center_ratio)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = nullptr;
    ScrollableState* ss = FindScrollable(uid, &w);
    if (!ss) return w ? 3 : 2;
    ss->pending_scroll_here_x_r = center_ratio;
    ss->pending_scroll_here_x   = true;
    return 0;
}

API_EXPORT int __cdecl ImGui_SetScrollHereY(const wchar_t* id, float center_ratio)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = nullptr;
    ScrollableState* ss = FindScrollable(uid, &w);
    if (!ss) return w ? 3 : 2;
    ss->pending_scroll_here_y_r = center_ratio;
    ss->pending_scroll_here_y   = true;
    return 0;
}

API_EXPORT int __cdecl ImGui_SetScrollFromPosX(const wchar_t* id, float local_x, float center_ratio)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = nullptr;
    ScrollableState* ss = FindScrollable(uid, &w);
    if (!ss) return w ? 3 : 2;
    ss->pending_scroll_from_x_p = local_x;
    ss->pending_scroll_from_x_r = center_ratio;
    ss->pending_scroll_from_x   = true;
    return 0;
}

API_EXPORT int __cdecl ImGui_SetScrollFromPosY(const wchar_t* id, float local_y, float center_ratio)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = nullptr;
    ScrollableState* ss = FindScrollable(uid, &w);
    if (!ss) return w ? 3 : 2;
    ss->pending_scroll_from_y_p = local_y;
    ss->pending_scroll_from_y_r = center_ratio;
    ss->pending_scroll_from_y   = true;
    return 0;
}
