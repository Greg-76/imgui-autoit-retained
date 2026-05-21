// Phase E.2 â€” Numeric / Color extras. See e2_extras.h for the field rationale.
//
// All C-ABI exports here run on the AutoIt thread under g_tree.mtx. The
// Render() bodies run on the render thread, also under the same mutex.

#include "e2_extras.h"

#include <Windows.h>
#include <memory>
#include <string>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

// ---- Render -----------------------------------------------------------------

void DragFloatRange2Widget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown   = label.empty() ? id.c_str() : label.c_str();
    const char* fmt     = format.empty()     ? "%.3f" : format.c_str();
    const char* fmt_max = format_max.empty() ? nullptr : format_max.c_str();
    if (ImGui::DragFloatRange2(shown, &values[0], &values[1],
                                v_speed, v_min, v_max, fmt, fmt_max, flags)) {
        changed = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

void DragIntRange2Widget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown   = label.empty() ? id.c_str() : label.c_str();
    const char* fmt     = format.empty()     ? "%d" : format.c_str();
    const char* fmt_max = format_max.empty() ? nullptr : format_max.c_str();
    if (ImGui::DragIntRange2(shown, &values[0], &values[1],
                              v_speed, v_min, v_max, fmt, fmt_max, flags)) {
        changed = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

void SliderAngleWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    const char* fmt   = format.empty() ? "%.0f deg" : format.c_str();
    if (ImGui::SliderAngle(shown, &value, v_degrees_min, v_degrees_max, fmt, flags)) {
        changed = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

void VSliderFloatWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    const char* fmt   = format.empty() ? "%.3f" : format.c_str();
    if (ImGui::VSliderFloat(shown, ImVec2(size_x, size_y),
                             &value, v_min, v_max, fmt, flags)) {
        changed = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

void VSliderIntWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    const char* fmt   = format.empty() ? "%d" : format.c_str();
    if (ImGui::VSliderInt(shown, ImVec2(size_x, size_y),
                           &value, v_min, v_max, fmt, flags)) {
        changed = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

void InputTextWithHintWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    if (ImGui::InputTextWithHint(shown, hint.c_str(),
                                  buffer.data(), buffer.size(), flags)) {
        changed = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

void ColorButtonWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    const ImVec4 c(color[0], color[1], color[2], color[3]);
    if (ImGui::ColorButton(shown, c, flags, ImVec2(size_x, size_y))) {
        clicked = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

// ---- C-ABI exports ----------------------------------------------------------

API_EXPORT int __cdecl ImGui_CreateDragFloatRange2(const wchar_t* id, const wchar_t* label,
                                                    float v_min, float v_max, float v_speed,
                                                    float def_min, float def_max,
                                                    const wchar_t* format, const wchar_t* format_max,
                                                    int flags)
{
    if (!id || !*id) return 1;
    std::string uid     = WideToUtf8(id);
    std::string ulbl    = WideToUtf8(label ? label : L"");
    std::string ufmt    = WideToUtf8(format     && *format     ? format     : L"");
    std::string ufmtmax = WideToUtf8(format_max && *format_max ? format_max : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<DragFloatRange2Widget>();
    w->id = uid; w->label = ulbl;
    w->v_min   = v_min;   w->v_max   = v_max;   w->v_speed = v_speed;
    w->values[0] = def_min; w->values[1] = def_max;
    w->format     = ufmt;
    w->format_max = ufmtmax;
    w->flags      = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateDragIntRange2(const wchar_t* id, const wchar_t* label,
                                                  int v_min, int v_max, float v_speed,
                                                  int def_min, int def_max,
                                                  const wchar_t* format, const wchar_t* format_max,
                                                  int flags)
{
    if (!id || !*id) return 1;
    std::string uid     = WideToUtf8(id);
    std::string ulbl    = WideToUtf8(label ? label : L"");
    std::string ufmt    = WideToUtf8(format     && *format     ? format     : L"");
    std::string ufmtmax = WideToUtf8(format_max && *format_max ? format_max : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<DragIntRange2Widget>();
    w->id = uid; w->label = ulbl;
    w->v_min   = v_min;   w->v_max   = v_max;   w->v_speed = v_speed;
    w->values[0] = def_min; w->values[1] = def_max;
    w->format     = ufmt;
    w->format_max = ufmtmax;
    w->flags      = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateSliderAngle(const wchar_t* id, const wchar_t* label,
                                                float v_degrees_min, float v_degrees_max,
                                                float default_rad,
                                                const wchar_t* format, int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    std::string ufmt = WideToUtf8(format && *format ? format : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<SliderAngleWidget>();
    w->id = uid; w->label = ulbl;
    w->v_degrees_min = v_degrees_min;
    w->v_degrees_max = v_degrees_max;
    w->value         = default_rad;
    w->format        = ufmt;
    w->flags         = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateVSliderFloat(const wchar_t* id, const wchar_t* label,
                                                 float w_, float h_,
                                                 float v_min, float v_max, float default_value,
                                                 const wchar_t* format, int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    std::string ufmt = WideToUtf8(format && *format ? format : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<VSliderFloatWidget>();
    w->id = uid; w->label = ulbl;
    w->size_x = w_; w->size_y = h_;
    w->v_min = v_min; w->v_max = v_max; w->value = default_value;
    w->format = ufmt; w->flags = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateVSliderInt(const wchar_t* id, const wchar_t* label,
                                               float w_, float h_,
                                               int v_min, int v_max, int default_value,
                                               const wchar_t* format, int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    std::string ufmt = WideToUtf8(format && *format ? format : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<VSliderIntWidget>();
    w->id = uid; w->label = ulbl;
    w->size_x = w_; w->size_y = h_;
    w->v_min = v_min; w->v_max = v_max; w->value = default_value;
    w->format = ufmt; w->flags = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateInputTextWithHint(const wchar_t* id, const wchar_t* label,
                                                      const wchar_t* hint,
                                                      const wchar_t* default_value,
                                                      int max_length, int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    std::string uhint = WideToUtf8(hint ? hint : L"");
    std::string udef  = WideToUtf8(default_value ? default_value : L"");
    if (uid.empty()) return 1;
    if (max_length < 1) max_length = 1;
    auto w = std::make_unique<InputTextWithHintWidget>();
    w->id    = uid;
    w->label = ulbl;
    w->hint  = uhint;
    w->flags = flags;
    w->buffer.assign(static_cast<size_t>(max_length) + 1, '\0');
    // Seed the buffer with the default value, truncating to fit.
    const size_t cap = w->buffer.size();
    const size_t n   = (udef.size() >= cap) ? cap - 1 : udef.size();
    std::memcpy(w->buffer.data(), udef.data(), n);
    w->buffer[n] = '\0';
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateColorButton(const wchar_t* id, const wchar_t* label,
                                                float r, float g, float b, float a,
                                                int flags, float w_, float h_)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<ColorButtonWidget>();
    w->id = uid; w->label = ulbl;
    w->color[0] = r; w->color[1] = g; w->color[2] = b; w->color[3] = a;
    w->flags = flags;
    w->size_x = w_; w->size_y = h_;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}
