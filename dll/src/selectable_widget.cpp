// Selectable — hand-written. Hybrid widget : persistent `selected` state
// (inherited BoolValueWidget::value) + a latched click event (`clicked`).
//
// Rendering : the bool* overload of ImGui::Selectable toggles `value` in-place
// and returns true on user click. We latch both `changed` and `clicked` in
// that branch — the script picks whichever polling primitive fits the use
// case (state-change tracking vs click-event tracking).

#include "widget.h"
#include "imgui.h"

void SelectableWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    if (ImGui::Selectable(shown, &value,
                          static_cast<ImGuiSelectableFlags>(flags),
                          ImVec2(size_x, size_y))) {
        changed = true;
        clicked = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}
