#pragma once
#include "widget.h"

// Popups (E.1) — hand-written top-level container widgets. Same plumbing as
// WindowWidget : rendered OUTSIDE the host Begin/End (IsTopLevelWindow=true),
// per-widget pending-state setters for open/close, latched is_popup_open query.
//
// Two variants : a regular floating popup (no title bar, dismiss on click-out
// or via ClosePopup) and a modal (dim background, optional title bar X close).

struct PopupWidget : Widget {
    int  flags = 0;                  // ImGuiWindowFlags forwarded to BeginPopup

    // Pending one-shots. pending_open_dirty is consumed BEFORE BeginPopup ;
    // pending_close_dirty is consumed INSIDE the BeginPopup body, where
    // ImGui::CloseCurrentPopup expects to be called per docs.
    bool pending_open_dirty  = false;
    bool pending_close_dirty = false;

    // Latched : updated each frame after BeginPopup() returns. Read via
    // _ImGui_IsPopupOpen($id). Falls back to false when visible=false.
    bool is_popup_open = false;

    void Render() override;
    bool IsTopLevelWindow() const override { return true; }
};

struct PopupModalWidget : Widget {
    int  flags    = 0;               // ImGuiWindowFlags
    // 0 = no X (BeginPopupModal with NULL p_open)
    // 1 = X visible (BeginPopupModal with &visible). User click X → ImGui
    //     writes false to *p_open AND closes the popup internally. Same
    //     pattern as WindowWidget/TabItem/CollapsingHeader closable.
    int  closable = 0;

    bool pending_open_dirty  = false;
    bool pending_close_dirty = false;

    bool is_popup_open = false;

    void Render() override;
    bool IsTopLevelWindow() const override { return true; }
};

// E.1.x — Context popup container. Inline (NOT top-level) because the popup id
// is hashed against the current ImGui window at the call site, and the trigger
// semantic depends on tree position :
//   - kind=Item (0)  : right-click on the PREVIOUS sibling rendered in the
//                      same children[] vector ; the widget must be placed as
//                      the next child after its target.
//   - kind=Window(1) : right-click anywhere in the enclosing ImGui window.
//   - kind=Void  (2) : right-click in void area (no window hovered).
//
// Same pending_open/close + is_popup_open contract as PopupWidget : the
// generic _ImGui_OpenPopup / _ImGui_ClosePopup / _ImGui_IsPopupOpen exports
// route to this widget through the extended FindPopupView() helper.
struct ContextPopupWidget : Widget {
    int  kind  = 0;                  // 0=Item, 1=Window, 2=Void
    int  flags = 0;                  // ImGuiPopupFlags

    bool pending_open_dirty  = false;
    bool pending_close_dirty = false;
    bool is_popup_open       = false;

    void Render() override;
};

// E.1.x — Pure trigger marker. Renders nothing visible ; on each frame it
// checks "was the previous item clicked with the right mouse button?" and
// if so sets pending_open_dirty=true on the target popup widget (looked up
// via g_tree.Find). This direct routing bypasses ImGui's id-hashing entirely,
// so the marker (Pass 1 / inside host) can chain to any popup type at any
// tree position — top-level PopupWidget (Pass 2) or inline ContextPopupWidget
// — without the cross-pass hash mismatch ImGui::OpenPopupOnItemClick would hit.
//
// Placement rule mirrors ContextPopup kind=Item : insert as the next child
// after the item you want to attach the click to. Mouse button comes from
// the ImGuiPopupFlags_MouseButton* bits (default = Right, matching ImGui's
// 1.92.6 default).
struct OpenPopupOnItemClickWidget : Widget {
    std::string target_popup_id;
    int         flags = 0;           // ImGuiPopupFlags

    void Render() override;
};

// M.4 — Marker widget that latches ImGui::GetMousePosOnOpeningCurrentPopup()
// during the popup's Render. MUST live as a child of a Popup / PopupModal /
// ContextPopup so it only renders when ImGui is inside a BeginPopup* block —
// that's the only moment GetMousePosOnOpeningCurrentPopup returns the frozen
// "captured at open time" value. Called from the AutoIt thread between frames,
// the free function ImGui::GetMousePosOnOpeningCurrentPopup falls back to
// g.IO.MousePos (current cursor) which isn't useful for "where was the user
// when they opened this popup", hence the marker pattern instead of a free
// function export. AutoIt reads the latched values with _ImGui_GetPopupOpenMousePos.
struct PopupOpenMousePosWidget : Widget {
    float pos_x = 0.0f;
    float pos_y = 0.0f;
    void Render() override;
};
