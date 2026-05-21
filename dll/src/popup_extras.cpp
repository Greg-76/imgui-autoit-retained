// Popups (E.1) â€” hand-written widgets. See popup_extras.h for the field
// rationale.
//
// All C-ABI exports here run on the AutoIt thread under g_tree.mtx. They
// mutate the widget's pending_* fields ; the render thread consumes those
// during the next Render() pass (also under the same mutex).

#include "popup_extras.h"

#include <Windows.h>
#include <memory>
#include <string>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

// ---- Render -----------------------------------------------------------------

void PopupWidget::Render()
{
    if (!visible) {
        is_popup_open       = false;
        pending_close_dirty = false;   // drop stale close requests
        return;
    }

    if (pending_open_dirty) {
        ImGui::OpenPopup(id.c_str());
        pending_open_dirty = false;
    }

    if (ImGui::BeginPopup(id.c_str(), flags)) {
        is_popup_open = true;
        for (auto& child : children) child->RenderAndQueryState();
        if (pending_close_dirty) {
            ImGui::CloseCurrentPopup();
            pending_close_dirty = false;
        }
        ImGui::EndPopup();
    } else {
        is_popup_open       = false;
        // The popup isn't open right now ; a queued close is meaningless.
        pending_close_dirty = false;
    }
}

void ContextPopupWidget::Render()
{
    if (!visible) {
        is_popup_open       = false;
        pending_close_dirty = false;
        return;
    }

    // Same pattern as PopupWidget : an explicit _ImGui_OpenPopup call fires
    // ImGui::OpenPopup BEFORE the BeginPopupContext* call. The right-click
    // detection is handled inside BeginPopupContext* itself, so manual open
    // and click-open coexist without conflict.
    if (pending_open_dirty) {
        ImGui::OpenPopup(id.c_str());
        pending_open_dirty = false;
    }

    bool open = false;
    switch (kind) {
        case 1: open = ImGui::BeginPopupContextWindow(id.c_str(), flags); break;
        case 2: open = ImGui::BeginPopupContextVoid  (id.c_str(), flags); break;
        case 0:  // Item is the default
        default: open = ImGui::BeginPopupContextItem (id.c_str(), flags); break;
    }

    if (open) {
        is_popup_open = true;
        for (auto& child : children) child->RenderAndQueryState();
        if (pending_close_dirty) {
            ImGui::CloseCurrentPopup();
            pending_close_dirty = false;
        }
        ImGui::EndPopup();
    } else {
        is_popup_open       = false;
        pending_close_dirty = false;
    }
}

void OpenPopupOnItemClickWidget::Render()
{
    if (!visible || target_popup_id.empty()) return;

    // Extract mouse button from popup flags. Default (mask=0) matches ImGui
    // 1.92.6+ convention : Right button.
    const int mb_field = (flags & ImGuiPopupFlags_MouseButtonMask_);
    ImGuiMouseButton mb = ImGuiMouseButton_Right;
    if      (mb_field == ImGuiPopupFlags_MouseButtonLeft)   mb = ImGuiMouseButton_Left;
    else if (mb_field == ImGuiPopupFlags_MouseButtonMiddle) mb = ImGuiMouseButton_Middle;

    // ImGui::IsItemHovered() reads g.LastItemData, which still refers to the
    // previous sibling because this widget rendered nothing. RenderAndQueryState
    // on the previous sibling does Render() then IsItem*() reads â€” neither
    // touches LastItemData beyond the original item, so the chain works.
    if (!ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenBlockedByPopup)) return;
    if (!ImGui::IsMouseReleased(mb)) return;

    // Direct routing : set pending_open_dirty on the target popup widget. The
    // tree mutex is already held by the render thread for this pass, so
    // g_tree.Find is safe to call without a recursive lock.
    Widget* w = g_tree.Find(target_popup_id);
    if (!w) return;
    if      (auto* p = dynamic_cast<PopupWidget*>(w))         p->pending_open_dirty = true;
    else if (auto* m = dynamic_cast<PopupModalWidget*>(w))    m->pending_open_dirty = true;
    else if (auto* c = dynamic_cast<ContextPopupWidget*>(w))  c->pending_open_dirty = true;
}

void PopupModalWidget::Render()
{
    // Consume pending_open FIRST â€” and reset visible to true so the &visible
    // overload reads as "I want to be open" on this very frame. Without this,
    // re-opening a previously-X-closed modal would no-op (visible=false â†’
    // BeginPopupModal returns false immediately).
    if (pending_open_dirty) {
        visible = true;
        ImGui::OpenPopup(id.c_str());
        pending_open_dirty = false;
    }

    if (!visible) {
        is_popup_open       = false;
        pending_close_dirty = false;
        return;
    }

    // Construct the display string : "label##id" when label is non-empty so
    // the title bar shows the friendly label while ImGui's popup ID hashes
    // off our stable widget id. OpenPopup above used id.c_str() â€” keep them
    // consistent by ALSO passing id.c_str() here. ImGui matches popups by
    // hashed id regardless of the displayed text.
    const bool open = (closable != 0)
        ? ImGui::BeginPopupModal(id.c_str(), &visible, flags)
        : ImGui::BeginPopupModal(id.c_str(), nullptr,  flags);

    if (open) {
        is_popup_open = true;
        // If label is non-empty, render it as a centered header inside the
        // body. We can't override the title bar without ## tricks that change
        // the popup id, so we put the friendly title as the first body line.
        // Keep things simple : the user can always create their own Text
        // widget at the top of the children list if they want a header.
        for (auto& child : children) child->RenderAndQueryState();
        if (pending_close_dirty) {
            ImGui::CloseCurrentPopup();
            pending_close_dirty = false;
        }
        ImGui::EndPopup();
    } else {
        is_popup_open       = false;
        pending_close_dirty = false;
    }
}

// ---- C-ABI exports ----------------------------------------------------------

// Returns: 0 = OK, 1 = id invalid, 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreatePopup(const wchar_t* id, const wchar_t* label, int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto widget = std::make_unique<PopupWidget>();
    widget->id    = uid;
    widget->label = ulbl;
    widget->flags = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreatePopupModal(const wchar_t* id, const wchar_t* label,
                                                int closable, int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto widget = std::make_unique<PopupModalWidget>();
    widget->id       = uid;
    widget->label    = ulbl;
    widget->closable = closable;
    widget->flags    = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

// kind : 0=Item, 1=Window, 2=Void. Out-of-range falls back to Item.
// Returns: 0 = OK, 1 = id invalid, 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreateContextPopup(const wchar_t* id, const wchar_t* label,
                                                  int kind, int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto widget = std::make_unique<ContextPopupWidget>();
    widget->id    = uid;
    widget->label = ulbl;
    widget->kind  = (kind >= 0 && kind <= 2) ? kind : 0;
    widget->flags = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

// target_popup_id : the str_id of the popup (PopupWidget / PopupModalWidget /
// ContextPopupWidget) that ImGui::OpenPopupOnItemClick will open on click.
// We do NOT validate it here ; the popup might be created later, and ImGui's
// hash-based id system tolerates that. AutoIt-side typo will simply silently
// no-op (no crash).
// Returns: 0 = OK, 1 = id null/empty, 2 = duplicate id, 3 = target empty.
API_EXPORT int __cdecl ImGui_CreateOpenPopupOnItemClick(const wchar_t* id,
                                                          const wchar_t* target_popup_id,
                                                          int flags)
{
    if (!id || !*id) return 1;
    if (!target_popup_id || !*target_popup_id) return 3;
    std::string uid    = WideToUtf8(id);
    std::string utgt   = WideToUtf8(target_popup_id);
    if (uid.empty()) return 1;
    if (utgt.empty()) return 3;
    auto widget = std::make_unique<OpenPopupOnItemClickWidget>();
    widget->id              = uid;
    widget->target_popup_id = utgt;
    widget->flags           = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

// Helper : find a Popup* or PopupModal*, route via dynamic_cast. Returns the
// pending_*_dirty / is_popup_open pointer pair, or a tag indicating "neither".
// Inline lambda style to keep the exports below short.
namespace {
struct PopupView {
    bool* pending_open;
    bool* pending_close;
    bool* is_open;
};

PopupView FindPopupView(const std::string& uid)
{
    Widget* w = g_tree.Find(uid);
    if (!w) return { nullptr, nullptr, nullptr };
    if (auto* p = dynamic_cast<PopupWidget*>(w))
        return { &p->pending_open_dirty, &p->pending_close_dirty, &p->is_popup_open };
    if (auto* m = dynamic_cast<PopupModalWidget*>(w))
        return { &m->pending_open_dirty, &m->pending_close_dirty, &m->is_popup_open };
    if (auto* c = dynamic_cast<ContextPopupWidget*>(w))
        return { &c->pending_open_dirty, &c->pending_close_dirty, &c->is_popup_open };
    return { nullptr, nullptr, nullptr };
}
}  // namespace

// Returns: 0 = OK, 1 = id null/empty, 2 = unknown id, 3 = not a popup.
API_EXPORT int __cdecl ImGui_OpenPopup(const wchar_t* id)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    if (!g_tree.Find(uid)) return 2;
    PopupView v = FindPopupView(uid);
    if (!v.pending_open) return 3;
    *v.pending_open = true;
    return 0;
}

API_EXPORT int __cdecl ImGui_ClosePopup(const wchar_t* id)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    if (!g_tree.Find(uid)) return 2;
    PopupView v = FindPopupView(uid);
    if (!v.pending_close) return 3;
    *v.pending_close = true;
    return 0;
}

// Read-only. Returns 0/1. Unknown id or non-popup â†’ 0 (no error code, same
// convention as the generic IsHovered/IsActive/IsFocused exports).
API_EXPORT int __cdecl ImGui_IsPopupOpen(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    PopupView v = FindPopupView(uid);
    return (v.is_open && *v.is_open) ? 1 : 0;
}

// ============================================================================
// Phase M.4 — PopupOpenMousePosWidget.
// ============================================================================

void PopupOpenMousePosWidget::Render()
{
    if (!visible) return;
    // ImGui::GetMousePosOnOpeningCurrentPopup() returns g.IO.MousePos when the
    // BeginPopup stack is empty — useless from the AutoIt thread. Here we're
    // a child of a popup widget so this Render fires while ImGui is inside
    // the popup body : the stack is non-empty and the function returns the
    // frozen open-position as intended.
    const ImVec2 p = ImGui::GetMousePosOnOpeningCurrentPopup();
    pos_x = p.x;
    pos_y = p.y;
}

// Returns: 0 = OK, 1 = id invalid, 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreatePopupOpenMousePos(const wchar_t* id)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto widget = std::make_unique<PopupOpenMousePosWidget>();
    widget->id = uid;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

// out_xy[0]=x, out_xy[1]=y in screen-space pixels. Returns 0=OK, 1=bad args,
// 2=unknown id, 3=widget is not a PopupOpenMousePos marker.
API_EXPORT int __cdecl ImGui_GetPopupOpenMousePos(const wchar_t* id, float* out_xy)
{
    if (!id || !*id || !out_xy) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    auto* m = dynamic_cast<PopupOpenMousePosWidget*>(w);
    if (!m) return 3;
    out_xy[0] = m->pos_x;
    out_xy[1] = m->pos_y;
    return 0;
}
