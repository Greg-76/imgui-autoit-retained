// Hand-written bool-related widgets that don't fit the generator's clean
// shape :
//
//   - RadioButton : ClickableWidget + a persistent `active` bool exposed via
//     Get/SetValueBool. The generator's `clickable` category only handles
//     widgets with no extra mutable state.
//   - CheckboxFlags : a checkbox that toggles a single bit of an int mask.
//     Doesn't fit value_bool (whose generator emits a bool* binding) â€” needs
//     its own state model.
//   - MenuItem (D.5) : moved from the clickable generator when shortcut
//     hints + persistent selected state were added. Same double-latch as
//     Selectable (click event + bool value).

#include <Windows.h>
#include <memory>
#include <string>
#include "widget.h"
#include "widget_tree.h"
#include "utf.h"
#include "imgui.h"

#define API_EXPORT extern "C" __declspec(dllexport)

void RadioButtonWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    if (ImGui::RadioButton(shown, active)) {
        clicked = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

void CheckboxFlagsWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    // CheckboxFlags overload : (label, int* flags, int flags_value).
    // Returns true when the user toggled the bit.
    if (ImGui::CheckboxFlags(shown, &value, flags_value)) {
        changed = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

void MenuItemWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    // Use the (label, shortcut, bool*, enabled) overload â€” passes nullptr for
    // shortcut when empty (ImGui then renders nothing on the right side).
    // Pass true for the 4th `enabled` arg because our BeginDisabled wrapper
    // already greys/blocks input ; double-disabling is harmless but redundant.
    const char* sc = shortcut.empty() ? nullptr : shortcut.c_str();
    if (ImGui::MenuItem(shown, sc, &value, /*enabled=*/true)) {
        clicked = true;
        changed = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

// Create export â€” replaces the old generator-emitted ImGui_CreateMenuItem.
// New ABI: takes shortcut (wstr, may be NULL/empty), selected (int 0/1) and
// enabled (int 0/1) on top of the original (id, label) pair. Old AutoIt
// callers that pass only 2 args will fail at the DllCall layer â€” the wrapper
// fills sensible defaults for them ("", False, True).
//
// Returns: 0 = OK, 1 = id invalid, 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreateMenuItem(const wchar_t* id, const wchar_t* label,
                                              const wchar_t* shortcut,
                                              int selected, int enabled)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label    ? label    : L"");
    std::string usc  = WideToUtf8(shortcut ? shortcut : L"");
    if (uid.empty()) return 1;

    auto widget = std::make_unique<MenuItemWidget>();
    widget->id       = uid;
    widget->label    = ulbl;
    widget->shortcut = usc;
    widget->value    = (selected != 0);
    widget->enabled  = (enabled != 0);

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}
