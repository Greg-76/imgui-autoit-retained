// L.1 + L.4 — Inline debug helpers + Value() helpers. See debug_inline_extras.h.

#include "debug_inline_extras.h"

#include <Windows.h>
#include <memory>
#include <mutex>
#include <string>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

// ---- L.1 Show* helpers -----------------------------------------------------

void ShowStyleSelectorWidget::Render()
{
    if (!visible) return;
    ImGui::ShowStyleSelector(label.empty() ? id.c_str() : label.c_str());
}

void ShowFontSelectorWidget::Render()
{
    if (!visible) return;
    ImGui::ShowFontSelector(label.empty() ? id.c_str() : label.c_str());
}

void ShowUserGuideWidget::Render()
{
    if (!visible) return;
    ImGui::ShowUserGuide();
}

// ---- L.4 Value() helpers ---------------------------------------------------

void ValueBoolWidget::Render()
{
    if (!visible) return;
    ImGui::Value(label.empty() ? id.c_str() : label.c_str(), value);
}

void ValueIntWidget::Render()
{
    if (!visible) return;
    ImGui::Value(label.empty() ? id.c_str() : label.c_str(), value);
}

void ValueFloatWidget::Render()
{
    if (!visible) return;
    const char* fmtstr = fmt.empty() ? "%.3f" : fmt.c_str();
    ImGui::Value(label.empty() ? id.c_str() : label.c_str(), value, fmtstr);
}

// ---- C-ABI exports : L.1 ---------------------------------------------------

API_EXPORT int __cdecl ImGui_CreateShowStyleSelector(const wchar_t* id, const wchar_t* label)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<ShowStyleSelectorWidget>();
    w->id    = uid;
    w->label = ulbl;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateShowFontSelector(const wchar_t* id, const wchar_t* label)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<ShowFontSelectorWidget>();
    w->id    = uid;
    w->label = ulbl;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateShowUserGuide(const wchar_t* id)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto w = std::make_unique<ShowUserGuideWidget>();
    w->id = uid;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

// ---- C-ABI exports : L.4 ---------------------------------------------------
// Value updates go through the polymorphic _ImGui_SetValueBool/Int/Float
// generic exports — no need for type-specific setters here. Each create
// takes the prefix (Widget::label) + initial value.

API_EXPORT int __cdecl ImGui_CreateValueBool(const wchar_t* id, const wchar_t* prefix,
                                               int initial_value)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(prefix ? prefix : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<ValueBoolWidget>();
    w->id    = uid;
    w->label = ulbl;
    w->value = (initial_value != 0);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateValueInt(const wchar_t* id, const wchar_t* prefix,
                                              int initial_value)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(prefix ? prefix : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<ValueIntWidget>();
    w->id    = uid;
    w->label = ulbl;
    w->value = initial_value;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateValueFloat(const wchar_t* id, const wchar_t* prefix,
                                                float initial_value, const wchar_t* format)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(prefix ? prefix : L"");
    std::string ufmt = WideToUtf8(format ? format : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<ValueFloatWidget>();
    w->id    = uid;
    w->label = ulbl;
    w->value = initial_value;
    w->fmt   = ufmt;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}
