// Text input widgets — hand-written.
//
// Single-line and multi-line share the same StringValueWidget base (buffer,
// flags, changed, Get/SetValueString); only Render() differs because ImGui
// exposes them as two distinct functions:
//
//   ImGui::InputText         (label, buf, buf_size, flags)
//   ImGui::InputTextMultiline(label, buf, buf_size, ImVec2 size, flags)
//
// Bottom line: same retained state, two Render() bodies.

#include "widget.h"
#include "imgui.h"

void InputTextWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    // ImGui owns the buffer in-place while the user is typing; we just hand
    // it the pointer + capacity. `changed` latches on user edit only — same
    // strict semantics as every other value widget.
    if (ImGui::InputText(shown, buffer.data(), buffer.size(),
                         static_cast<ImGuiInputTextFlags>(flags))) {
        changed = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

void InputTextMultilineWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    if (ImGui::InputTextMultiline(shown, buffer.data(), buffer.size(),
                                  ImVec2(size_x, size_y),
                                  static_cast<ImGuiInputTextFlags>(flags))) {
        changed = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}
