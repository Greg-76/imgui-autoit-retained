// K.2 — RadioButtonGroup state + widget. See radio_group_extras.h.

#include "radio_group_extras.h"

#include <Windows.h>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

namespace {
    // Group id → current value. Lazy-created on first Get/Set call.
    std::unordered_map<std::string, int> g_groups;
}

namespace radio_group_state {

int Get(const std::string& group_id)
{
    auto it = g_groups.find(group_id);
    return (it == g_groups.end()) ? -1 : it->second;
}

void Set(const std::string& group_id, int value)
{
    g_groups[group_id] = value;
}

void Reset()
{
    g_groups.clear();
}

} // namespace radio_group_state

// ---- Render -----------------------------------------------------------------

void RadioButtonGroupWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    // Selected iff this widget's value matches the group's current value.
    // Default group state is -1 (set by Get on missing key) ; that never
    // matches a valid positive my_value, so all members render unselected
    // until someone clicks or _ImGui_SetRadioGroupValue is called.
    const int  current  = radio_group_state::Get(group_id);
    const bool selected = (current == my_value);
    const char* lbl = label.empty() ? id.c_str() : label.c_str();
    if (ImGui::RadioButton(lbl, selected)) {
        radio_group_state::Set(group_id, my_value);
        clicked = true;
    }
    if (!enabled) ImGui::EndDisabled();
}

// ---- C-ABI exports ----------------------------------------------------------

// Create. Optional $bDefaultActive : if True AND the group has no value yet,
// initialise the group to this widget's my_value so it renders selected on
// first frame. Subsequent CreateRadioButtonGroup calls referencing the same
// group_id with $bDefaultActive=True silently no-op (the first wins) — they
// never overwrite an existing value.
API_EXPORT int __cdecl ImGui_CreateRadioButtonGroup(const wchar_t* id,
                                                     const wchar_t* label,
                                                     const wchar_t* group_id,
                                                     int my_value,
                                                     int default_active)
{
    if (!id || !*id || !group_id || !*group_id) return 1;
    std::string uid   = WideToUtf8(id);
    std::string ulbl  = WideToUtf8(label ? label : L"");
    std::string ugrp  = WideToUtf8(group_id);
    if (uid.empty() || ugrp.empty()) return 1;
    auto w = std::make_unique<RadioButtonGroupWidget>();
    w->id       = uid;
    w->label    = ulbl;
    w->group_id = ugrp;
    w->my_value = my_value;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    if (default_active != 0 && radio_group_state::Get(ugrp) == -1) {
        radio_group_state::Set(ugrp, my_value);
    }
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

// Read the group's current value. Returns -1 if the group doesn't exist yet
// (no widget has been created, no SetRadioGroupValue has run). out_value
// receives the value ; the return code mirrors the rest of the codebase
// (0=OK, 1=bad args). Caller distinguishes "no group" via out_value == -1.
API_EXPORT int __cdecl ImGui_GetRadioGroupValue(const wchar_t* group_id, int* out_value)
{
    if (!group_id || !*group_id || !out_value) return 1;
    std::string ugrp = WideToUtf8(group_id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    *out_value = radio_group_state::Get(ugrp);
    return 0;
}

// Programmatic group value setter. Never latches the clicked flag on any
// widget (strict semantics) — only a user click in Render() does.
API_EXPORT int __cdecl ImGui_SetRadioGroupValue(const wchar_t* group_id, int value)
{
    if (!group_id || !*group_id) return 1;
    std::string ugrp = WideToUtf8(group_id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    radio_group_state::Set(ugrp, value);
    return 0;
}
