// Inline scrollable list — hand-written widget. State (items, selected_index,
// selected_value, changed) lives on IndexedSelectionWidget so it can be shared
// with ComboWidget; only the Render() body differs (BeginChild + Selectable
// loop here, BeginCombo popup over in combo_widget.cpp).
//
// Rendering: each item is an ImGui::Selectable inside a BeginChild keyed on
// the widget id. PushID(index) inside the loop gives ImGui a stable per-row
// identity even when the item set changes — that's what preserves scroll and
// keeps Selectable hover/active state from glitching across SetListItems().

#include "widget.h"
#include "imgui.h"

void ListWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();

    ImGui::PushID(id.c_str());
    // size (0,0) = fill remaining content region. Borders make the box visible
    // even when empty, which avoids "did I call SetListItems?" confusion.
    ImGui::BeginChild("##listbody", ImVec2(size_x, size_y),
                      ImGuiChildFlags_Borders, ImGuiWindowFlags_None);

    for (size_t i = 0; i < items.size(); ++i) {
        ImGui::PushID(static_cast<int>(i));
        const bool sel = (static_cast<int>(i) == selected_index);
        // Empty-string items are legal — Selectable("") still occupies a row.
        if (ImGui::Selectable(items[i].c_str(), sel)) {
            selected_index = static_cast<int>(i);
            selected_value = items[i];
            changed = true;
        }
        ImGui::PopID();
    }

    ImGui::EndChild();
    ImGui::PopID();

    if (!enabled) ImGui::EndDisabled();
}

void IndexedSelectionWidget::ApplyItems(std::vector<std::string> new_items)
{
    items = std::move(new_items);

    // By-content preservation: if the user's prior selection is still in the
    // new list, keep it (remapped to its new index). Otherwise clear.
    // Programmatic update — never latches `changed`.
    if (selected_index < 0 || selected_value.empty()) {
        selected_index = -1;
        selected_value.clear();
        return;
    }
    for (size_t i = 0; i < items.size(); ++i) {
        if (items[i] == selected_value) {
            selected_index = static_cast<int>(i);
            return;
        }
    }
    selected_index = -1;
    selected_value.clear();
}

bool IndexedSelectionWidget::SetValueInt(int v)
{
    // Clamp: -1 clears, valid index sets, out-of-range clears (defensive — the
    // bot might write the index before pushing the matching items). No latch.
    if (v < 0 || v >= static_cast<int>(items.size())) {
        selected_index = -1;
        selected_value.clear();
    } else {
        selected_index = v;
        selected_value = items[v];
    }
    return true;
}
