#cs
================================================================================
 Example 188 : _ImGui_CreateShowStyleSelector
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateShowStyleSelector   Combo widget that swaps the active
                                    ImGui style theme (Dark / Light / Classic)

 Widget-flavored counterpart to the imperative _ImGui_SetStyleTheme
 (exemple191). Same trap class as the LogTo* / LogButtons pair
 (exemples 183 vs 185) :

   * exemple188 (widget)        in-tree Combo, USER picks the theme
                                from a dropdown ; selection is handled
                                inside ImGui ; no AutoIt-side binding.
   * exemple191 (imperative)    SCRIPT picks the theme, typically
                                driven by user preferences or a
                                CLI flag at startup.

 Selection persists through ImGui's internal style state (no AutoIt-
 side latch needed). It also re-applies the multi-viewport tweak
 (opaque WindowBg + zero WindowRounding) so dragged-out sub-windows
 stay clean -- same as the imperative variant.

 Borrowed widgets : SliderFloat, Button, Checkbox, ColorEdit4,
 CollapsingHeader, Text + Separator (visual richness so the theme
 effect is obvious).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple188_showstyle_selector.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple188_showstyle_selector.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 188 : ShowStyleSelector", 760, 560) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateShowStyleSelector  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateShowStyleSelector($sId, $sLabel = "Style")
;
;   $sId    : stable widget identifier.
;   $sLabel : displayed combo label (default "Style").
;
;   Return : True on success, False on failure (@error = 1, 2).
;
;   Behavior : renders a Combo with three entries (Dark / Light /
;   Classic). Clicks INSIDE the Combo internally call
;   ImGui::StyleColorsDark / Light / Classic. No SetOnClick /
;   SetOnChange binding -- the widget owns its handler in C++.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "ShowStyleSelector demo  --  in-tree Combo that swaps the active theme")
_ImGui_CreateText("t_hint",  "Pick a theme below ; every widget on this screen will re-render in the new palette.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; The widget itself
; ==============================================================================
_ImGui_CreateShowStyleSelector("ss_picker", "Theme")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Sample widgets  --  show the theme effect visually
; ==============================================================================
_ImGui_CreateText("t_sample_hdr", "Sample widgets (re-rendered with the active theme) :")

_ImGui_CreateButton("btn_action", "Sample button")
_ImGui_CreateCheckbox("cb_toggle", "Sample checkbox", True)
_ImGui_CreateSliderFloat("sl_demo", "Slider", 0.0, 1.0, 0.5, "%.2f")
_ImGui_CreateColorEdit4("ce_sample", "Color edit", 0.3, 0.7, 0.9, 1.0, 0)

_ImGui_CreateCollapsingHeader("ch_section", "Collapsing header (open me to see nested colors)", 0)
_ImGui_CreateText("t_nested1", "  Nested text 1")
_ImGui_CreateText("t_nested2", "  Nested text 2")
_ImGui_CreateSliderInt("sl_nested", "Nested slider", 0, 100, 42, "%d")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------
Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
