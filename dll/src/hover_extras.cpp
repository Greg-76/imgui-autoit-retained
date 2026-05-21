// K.1 — IsItemHoveredEx marker + GetItemHoveredEx query. See hover_extras.h
// for the ordering constraint (must be immediate next sibling of target).

#include "hover_extras.h"

#include <Windows.h>
#include <memory>
#include <mutex>
#include <string>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

void IsItemHoveredExWidget::Render()
{
    if (!visible) {
        result = false;
        return;
    }
    result = ImGui::IsItemHovered(flags);
}

// Create marker. Place as immediate sibling AFTER the target widget.
// Returns : 0 = OK, 1 = bad args, 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreateIsItemHoveredEx(const wchar_t* id, int flags)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto w = std::make_unique<IsItemHoveredExWidget>();
    w->id    = uid;
    w->flags = flags;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

// Read latched hover result. Returns 0/1, with 0 also covering unknown id or
// widget-type mismatch (same convention as the generic IsHovered/IsActive).
API_EXPORT int __cdecl ImGui_GetItemHoveredEx(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    auto* h = dynamic_cast<IsItemHoveredExWidget*>(w);
    return (h && h->result) ? 1 : 0;
}
