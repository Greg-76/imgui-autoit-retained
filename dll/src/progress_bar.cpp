// ProgressBar — display-only float value widget. ImGui::ProgressBar(fraction,
// size, overlay). Hand-written because the shape is unique (no interaction,
// optional overlay string).

#include "widget.h"
#include "imgui.h"
#include <cfloat>

void ProgressBarWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    // size_x < 0 → use ImGui's "stretch to width" sentinel.
    const float sx = (size_x < 0.0f) ? -FLT_MIN : size_x;
    const char* ov = overlay.empty() ? nullptr : overlay.c_str();
    ImGui::ProgressBar(value, ImVec2(sx, size_y), ov);
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}
