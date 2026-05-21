#include "widget.h"
#include "imgui.h"

void TextWidget::Render()
{
    if (!visible) return;
    // TextUnformatted bypasses printf parsing — safer for user-provided strings.
    ImGui::TextUnformatted(label.c_str());
}

void Widget::RenderAndQueryState()
{
    Render();
    if (!visible) {
        // Hidden widgets never report interaction state. The "current item"
        // in ImGui is whatever was rendered before us — we must not latch it.
        is_hovered = is_active = is_focused = false;
        is_clicked = is_edited = false;
        is_activated = is_deactivated = is_deactivated_after_edit = false;
        is_visible = false;
        rect_min_x = rect_min_y = rect_max_x = rect_max_y = 0.0f;
        return;
    }
    // ImGui::IsItem*() reads the state of the LAST item rendered. For widgets
    // that don't produce an interactive item (Indent, SameLine, NewLine,
    // Spacing, style-stack widgets), this latches whatever the previous
    // widget left behind — benign, since nobody polls those for hover. For
    // containers like Window/Child/Group, IsItem* refers to the container
    // area after End*, which is the correct "is the user pointing at this
    // container" semantic.
    is_hovered = ImGui::IsItemHovered();
    is_active  = ImGui::IsItemActive();
    is_focused = ImGui::IsItemFocused();

    // Extended frame-state queries (D.1). All read-only — these do NOT
    // consume on read (unlike WasClicked/HasChanged); they reflect the
    // raw ImGui state from this very frame. IsItemClicked() defaults to
    // left mouse button (0), which matches the WasClicked contract.
    is_clicked                = ImGui::IsItemClicked();
    is_edited                 = ImGui::IsItemEdited();
    is_activated              = ImGui::IsItemActivated();
    is_deactivated            = ImGui::IsItemDeactivated();
    is_deactivated_after_edit = ImGui::IsItemDeactivatedAfterEdit();
    is_visible                = ImGui::IsItemVisible();

    const ImVec2 rmin = ImGui::GetItemRectMin();
    const ImVec2 rmax = ImGui::GetItemRectMax();
    rect_min_x = rmin.x; rect_min_y = rmin.y;
    rect_max_x = rmax.x; rect_max_y = rmax.y;

    // Render the tooltip on hover. SetTooltip uses printf — pass %s with the
    // string so % characters in user content don't get formatted.
    if (is_hovered && !tooltip.empty()) {
        ImGui::SetTooltip("%s", tooltip.c_str());
    }
}
