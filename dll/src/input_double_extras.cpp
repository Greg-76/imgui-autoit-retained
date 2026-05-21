// K.2 — InputDouble : double-precision text input widget.

#include "input_double_extras.h"

#include <Windows.h>
#include <memory>
#include <mutex>
#include <string>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

void InputDoubleWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    const char* lbl = label.empty() ? id.c_str() : label.c_str();
    const char* fmt = format.empty() ? "%.6f" : format.c_str();
    if (ImGui::InputDouble(lbl, &value, step, step_fast, fmt, flags)) {
        changed = true;
    }
    if (!enabled) ImGui::EndDisabled();
}

// Create. Default $sFormat = "" → "%.6f" inside the widget. Returns
// 0=OK / 1=bad args / 2=duplicate id.
API_EXPORT int __cdecl ImGui_CreateInputDouble(const wchar_t* id, const wchar_t* label,
                                                 double default_value,
                                                 double step, double step_fast,
                                                 const wchar_t* format, int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    std::string ufmt = WideToUtf8(format ? format : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<InputDoubleWidget>();
    w->id        = uid;
    w->label     = ulbl;
    w->value     = default_value;
    w->step      = step;
    w->step_fast = step_fast;
    w->format    = ufmt;
    w->flags     = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

// Polymorphic getter. out is a double*. Returns 0=OK / 1=bad args /
// 2=unknown id / 3=widget is not a DoubleValueWidget.
API_EXPORT int __cdecl ImGui_GetValueDouble(const wchar_t* id, double* out)
{
    if (!id || !*id || !out) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    return w->GetValueDouble(out) ? 0 : 3;
}

API_EXPORT int __cdecl ImGui_SetValueDouble(const wchar_t* id, double v)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    return w->SetValueDouble(v) ? 0 : 3;
}
