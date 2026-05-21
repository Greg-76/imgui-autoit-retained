#pragma once
#include "widget.h"

// K.1 — IsItemHovered(flags) marker widget.
//
// In retained mode we can't expose IsItemHovered(flags) as a free function :
// the call is meaningful only DURING a Render(), immediately after the target
// item submitted its primary ImGui item — the same constraint as the rest of
// the IsItem* family. The base `is_hovered` field on Widget latches the
// no-flags variant (IsItemHovered()) ; this widget latches IsItemHovered(flags)
// for an explicit caller-provided $ImGuiHoveredFlags_* mask.
//
// Place AS THE IMMEDIATE NEXT SIBLING after the target widget in the same
// parent's children list (identical contract to ItemTooltipWidget H.2). The
// Render() latches the result into `result` ; AutoIt polls via
// _ImGui_GetItemHoveredEx.
struct IsItemHoveredExWidget : Widget {
    int  flags  = 0;
    bool result = false;
    void Render() override;
};
