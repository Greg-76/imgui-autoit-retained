#pragma once
#include "widget.h"

// H.2 — Rich tooltip container.
//
// Distinct from the simple Widget::tooltip string (set via _ImGui_SetTooltip,
// shown as a single-line ImGui::SetTooltip after the parent's render). This
// widget OPENS A TOOLTIP and renders its children inside, so the caller can
// nest Text + Separator + Image + any combination — i.e. rich Windows-style
// tooltips.
//
// Render() uses ImGui::BeginItemTooltip(), which is "open this tooltip iff
// the LAST rendered ImGui item is hovered AND the ForTooltip delay has
// elapsed". That means this widget MUST be the immediate next sibling after
// the target widget in the same parent's children list. Wrong order = the
// tooltip never opens (or opens on the wrong item).
struct ItemTooltipWidget : Widget {
    void Render() override;
};

// M.3 — Unconditional tooltip container. Calls ImGui::BeginTooltip() every
// frame it's visible, regardless of any "previous item hovered" state. Distinct
// from ItemTooltipWidget (which only opens iff the prior item is hovered for
// long enough). Display gating is the caller's job — toggle Widget::visible
// from AutoIt via _ImGui_SetVisible based on whatever custom condition (timer,
// custom hit area, programmatic trigger, …).
//
// Children render inside the tooltip popup ; full nested layout works the same
// way as ItemTooltipWidget (Text + Separator + Image + whatever).
struct TooltipWidget : Widget {
    void Render() override;
};
