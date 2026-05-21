// Tab extensions (D.7) â€” hand-written widgets. See tab_extras.h for the field
// rationale.
//
// All C-ABI exports here run on the AutoIt thread under g_tree.mtx. They
// mutate the widget's pending_* fields ; the render thread consumes those
// during the next Render() pass (also under the same mutex).

#include "tab_extras.h"

#include <Windows.h>
#include <memory>
#include <string>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

// ---- Render -----------------------------------------------------------------

void TabItemWidget::Render()
{
    // Consume SetTabItemClosed FIRST â€” even before the !visible early-return.
    // We're a child of TabBarWidget, so its BeginTabBar is already on the
    // ImGui stack when this Render() runs. ImGui::SetTabItemClosed expects to
    // be called there, BEFORE we'd otherwise submit BeginTabItem.
    if (pending_closed) {
        ImGui::SetTabItemClosed(label.empty() ? id.c_str() : label.c_str());
        pending_closed = false;
        // The setter already set visible=false ; reset again here for safety
        // (in case the setter and the next Render() happened across a brief
        // race where the script was mid-write).
        visible = false;
        return;   // don't submit the tab this frame
    }

    if (!visible) return;

    const char* shown = label.empty() ? id.c_str() : label.c_str();
    const bool open = (closable != 0)
        ? ImGui::BeginTabItem(shown, &visible, flags)
        : ImGui::BeginTabItem(shown, nullptr, flags);
    if (open) {
        for (auto& child : children) child->RenderAndQueryState();
        ImGui::EndTabItem();
    }
}

void TabItemButtonWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    // ImGui::TabItemButton returns true on click. Latch the standard
    // ClickableWidget `clicked` flag so the script can read it with the
    // generic _ImGui_WasClicked. Strict semantics â€” no programmatic path
    // sets `clicked`.
    if (ImGui::TabItemButton(shown, flags)) {
        clicked = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

// ---- C-ABI exports ----------------------------------------------------------

// Create â€” extends the old generator signature (id, label) with closable +
// flags. Old 2-arg AutoIt callers stay compatible via the wrapper defaults.
// Returns: 0 = OK, 1 = id invalid, 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreateTabItem(const wchar_t* id, const wchar_t* label,
                                            int closable, int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto widget = std::make_unique<TabItemWidget>();
    widget->id       = uid;
    widget->label    = ulbl;
    widget->closable = closable;
    widget->flags    = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

// Create â€” brand new in D.7. Renders an inline clickable tab in the TabBar
// flow (no body). Common usage : a "+" button with Trailing to append tabs,
// or a "â‰¡" hamburger with Leading. Read clicks via _ImGui_WasClicked($id).
API_EXPORT int __cdecl ImGui_CreateTabItemButton(const wchar_t* id, const wchar_t* label,
                                                  int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto widget = std::make_unique<TabItemButtonWidget>();
    widget->id    = uid;
    widget->label = ulbl;
    widget->flags = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

// Mark a tab as closing â€” flushes both the pending_closed flag (so the next
// Render emits ImGui::SetTabItemClosed for anti-flicker) and visible=false
// (so subsequent frames stop submitting the tab). One atomic operation under
// the tree mutex.
// Returns: 0 = OK, 1 = id null/empty, 2 = unknown id, 3 = not a TabItem.
API_EXPORT int __cdecl ImGui_SetTabItemClosed(const wchar_t* id)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    auto* t = dynamic_cast<TabItemWidget*>(w);
    if (!t) return 3;
    t->pending_closed = true;
    t->visible        = false;
    return 0;
}
