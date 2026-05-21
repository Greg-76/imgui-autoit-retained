// L.2 — TextLinkOpenURL with strict http/https whitelist. See text_link_extras.h.

#include "text_link_extras.h"

#include <Windows.h>
#include <shellapi.h>
#include <memory>
#include <mutex>
#include <string>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

void TextLinkOpenURLWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* link_text = label.empty() ? id.c_str() : label.c_str();
    if (ImGui::TextLink(link_text)) {
        clicked = true;
        // Whitelist : only http:// and https:// schemes proceed. Comparison
        // is case-sensitive on the scheme — typical use stores the URL in
        // lower-case ; mixed-case "Http://" would be rejected. That's fine,
        // strict-by-default is correct here.
        const bool is_http  = url.rfind("http://",  0) == 0;
        const bool is_https = url.rfind("https://", 0) == 0;
        if (is_http || is_https) {
            // ShellExecuteW for unicode safety. We have the URL stored as
            // UTF-8 ; convert back to UTF-16 for the API. Function returns
            // an HINSTANCE that we don't use — failure is non-fatal (e.g.
            // no default browser registered) ; we silently ignore.
            std::wstring wurl = Utf8ToWide(url.c_str());
            ::ShellExecuteW(nullptr, L"open", wurl.c_str(),
                             nullptr, nullptr, SW_SHOWNORMAL);
        }
        // Other schemes silently ignored ; the AutoIt script can still see
        // the click via _ImGui_WasClicked and react however it wants.
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

// Create. The URL is stored as UTF-8 internally ; pass an UTF-16 string from
// AutoIt (DllCall "wstr"). Returns 0=OK / 1=bad args / 2=duplicate id.
API_EXPORT int __cdecl ImGui_CreateTextLinkOpenURL(const wchar_t* id, const wchar_t* label,
                                                     const wchar_t* url)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    std::string uurl = WideToUtf8(url   ? url   : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<TextLinkOpenURLWidget>();
    w->id    = uid;
    w->label = ulbl;
    w->url   = uurl;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}
