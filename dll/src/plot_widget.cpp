// Plot widgets — PlotLines (line graph) and PlotHistogram (vertical bars).
// Both store a float vector ; the script pushes new content via
// _ImGui_SetPlotValues. Display-only, no interaction.
//
// scale_min/scale_max = FLT_MAX means "auto-scale to data range" — the ImGui
// sentinel for that behavior.

#include "widget.h"
#include "imgui.h"

void PlotLinesWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    const float* data = values.empty() ? nullptr : values.data();
    const int    n    = static_cast<int>(values.size());
    const char*  ov   = overlay.empty() ? nullptr : overlay.c_str();
    ImGui::PlotLines(shown, data, n, 0, ov, scale_min, scale_max,
                     ImVec2(size_x, size_y));
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

void PlotHistogramWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    const float* data = values.empty() ? nullptr : values.data();
    const int    n    = static_cast<int>(values.size());
    const char*  ov   = overlay.empty() ? nullptr : overlay.c_str();
    ImGui::PlotHistogram(shown, data, n, 0, ov, scale_min, scale_max,
                         ImVec2(size_x, size_y));
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}
