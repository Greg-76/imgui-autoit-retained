// Dropdown combo — hand-written. State + ApplyItems live on
// IndexedSelectionWidget (shared with ListWidget); only Render() is here.
//
// Wraps ImGui::BeginCombo/EndCombo. The preview string shown when the combo
// is closed is items[selected_index] (or empty when nothing is selected).
// Inside the popup, items render as Selectables — same per-row PushID dance
// as the list, so the popup keeps its scroll position across re-renders.

#include "widget.h"
#include "imgui.h"

void ComboWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();

    ImGui::PushID(id.c_str());
    const char* shown   = label.empty() ? id.c_str() : label.c_str();
    const char* preview = (selected_index >= 0 && selected_index < static_cast<int>(items.size()))
                          ? items[selected_index].c_str()
                          : "";

    if (ImGui::BeginCombo(shown, preview, static_cast<ImGuiComboFlags>(flags))) {
        for (size_t i = 0; i < items.size(); ++i) {
            ImGui::PushID(static_cast<int>(i));
            const bool sel = (static_cast<int>(i) == selected_index);
            if (ImGui::Selectable(items[i].c_str(), sel)) {
                selected_index = static_cast<int>(i);
                selected_value = items[i];
                changed = true;
            }
            // Keep the keyboard/gamepad focus on the current selection when
            // the popup opens, so arrow-key navigation feels natural.
            if (sel) ImGui::SetItemDefaultFocus();
            ImGui::PopID();
        }
        ImGui::EndCombo();
    }

    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}
