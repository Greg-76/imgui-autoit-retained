#pragma once
#include "widget.h"
#include <string>

// K.2 — RadioButtonGroup : a RadioButton that participates in a shared-state
// "group" identified by a string key. Clicking one member of the group sets
// the group's current value to `my_value` ; every other member with a different
// value renders unselected. This composes the canonical ImGui RadioButton
// pattern (manual exclusive selection via passing the same int*) into a single
// retained-mode widget.
//
// Group state lifecycle :
//   - Lazy-created on first reference (Create or Get).
//   - Wiped by render_thread::Stop() during teardown (same shape as
//     font_registry::Reset). A subsequent _ImGui_Init starts fresh.
//
// Strict-changed semantics : programmatic _ImGui_SetRadioGroupValue does NOT
// latch any per-widget click flag ; only a user click in Render() does.

namespace radio_group_state {
    // Get the current value of a group ; returns -1 if the group doesn't exist
    // (no widget has been created or no _ImGui_SetRadioGroupValue has run).
    int  Get(const std::string& group_id);
    // Set the current value of a group (creates the entry if absent).
    void Set(const std::string& group_id, int value);
    // Wipe everything — called by render_thread::Stop().
    void Reset();
}

struct RadioButtonGroupWidget : ClickableWidget {
    std::string group_id;
    int         my_value = 0;

    void Render() override;
};
