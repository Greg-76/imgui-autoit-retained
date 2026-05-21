// H.2 — Rich tooltip container (BeginItemTooltip + children + EndTooltip).
// See tooltip_extras.h for the design rationale and ordering constraint.

#include "tooltip_extras.h"

#include <Windows.h>
#include <memory>
#include <string>
#include <mutex>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

void ItemTooltipWidget::Render()
{
    if (!visible) return;
    // BeginItemTooltip returns true only if the previous item is hovered AND
    // the tooltip-delay has elapsed (uses ImGuiHoveredFlags_ForTooltip). When
    // false there's no open tooltip ; skip children, don't call EndTooltip.
    if (ImGui::BeginItemTooltip()) {
        for (auto& c : children) c->RenderAndQueryState();
        ImGui::EndTooltip();
    }
}

// Create export — no label, no extra params (the widget is just a container).
// Returns: 0 = OK, 1 = id invalid, 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreateItemTooltip(const wchar_t* id)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto widget = std::make_unique<ItemTooltipWidget>();
    widget->id = uid;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

// M.3 — Unconditional tooltip. Render() opens BeginTooltip() every frame
// `visible` is true ; AutoIt gates display by toggling visible (or by adding
// the widget conditionally to the tree, though toggling visible is the
// canonical pattern). EndTooltip only when BeginTooltip returned true, same
// discipline as ItemTooltipWidget.
void TooltipWidget::Render()
{
    if (!visible) return;
    if (ImGui::BeginTooltip()) {
        for (auto& c : children) c->RenderAndQueryState();
        ImGui::EndTooltip();
    }
}

// Returns: 0 = OK, 1 = id invalid, 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreateTooltip(const wchar_t* id)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto widget = std::make_unique<TooltipWidget>();
    widget->id = uid;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}
