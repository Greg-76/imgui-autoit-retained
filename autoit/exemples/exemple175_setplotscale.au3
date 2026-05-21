#cs
================================================================================
 Example 175 : _ImGui_SetPlotScale
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetPlotScale   Update the vertical [min, max] range of a
                         PlotLines / PlotHistogram widget at runtime

 Counterpart of the $fScaleMin / $fScaleMax args of CreatePlotLines /
 CreatePlotHistogram (exemples 173 / 174). $FLT_MAX is the sentinel
 for "auto-scale on this side" -- pass it on either or both bounds
 for partial auto behavior :
   * (FLT_MAX, FLT_MAX) = full auto (recompute min and max each frame)
   * (0, FLT_MAX)        = floor at 0, top auto-scales
   * (-1.0, 1.0)         = fully fixed range

 Demo : THREE PlotLines side by side fed with the SAME sine-wave
 data, each with a different scale policy :
   * t_auto  : full auto-scale (default behavior)
   * t_fixed : fixed [-1.0, 1.0] (the natural sine range)
   * t_dyn   : runtime range driven by two sliders -- SetPlotScale
               called from the OnChange handlers

 Borrowed widgets : PlotLines + SetPlotValues (exemple173),
 SliderFloat, Button, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple175_setplotscale.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple175_setplotscale.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 175 : _ImGui_SetPlotScale", 720, 620) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetPlotScale  --  doc block
; ==============================================================================
; Signature : _ImGui_SetPlotScale($sId, $fScaleMin = $FLT_MAX,
;                                       $fScaleMax = $FLT_MAX)
;
;   $fScaleMin / $fScaleMax : new range. $FLT_MAX sentinel = auto on
;                             that side ; concrete value = fixed.
;
;   Applies to PlotLines AND PlotHistogram widgets uniformly.
;
;   Return : True on success, False on failure (@error = 1, 2, 3 if
;            $sId is unknown or not a plot widget).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "SetPlotScale  --  same sine data, three scale policies side by side")
_ImGui_CreateText("t_hint",  "Drag the two sliders below to drive the third plot's range live.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Three PlotLines sharing the same data, different scales
; ==============================================================================
_ImGui_CreateText("t_auto_hdr",  "1) Auto-scale (FLT_MAX, FLT_MAX)  --  recomputes [min, max] each frame :")
_ImGui_CreatePlotLines("p_auto", "auto", "", 0, 90)   ; default scales = FLT_MAX

_ImGui_CreateText("t_fixed_hdr", "2) Fixed [-1.0, 1.0]  --  the natural sine range :")
_ImGui_CreatePlotLines("p_fixed", "fixed", "[-1, 1]", 0, 90, -1.0, 1.0)

_ImGui_CreateText("t_dyn_hdr",   "3) Dynamic range driven by sliders (SetPlotScale on OnChange) :")
_ImGui_CreatePlotLines("p_dyn",   "dyn", "", 0, 90, -1.5, 1.5)

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Sliders that drive p_dyn's scale
; ==============================================================================
_ImGui_CreateText("t_ctrl_hdr", "Sliders for p_dyn :")
_ImGui_CreateSliderFloat("sl_min", "$fScaleMin", -3.0, 0.0, -1.5, "%.2f")
_ImGui_CreateSliderFloat("sl_max", "$fScaleMax",  0.0, 3.0,  1.5, "%.2f")
_ImGui_CreateButton("btn_auto",     "Reset p_dyn to FULL AUTO (FLT_MAX both)")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Seed the three plots with the SAME data so the visual difference is purely
; due to the scale policy.
; ==============================================================================
Local $aSine[80]
For $i = 0 To 79
    $aSine[$i] = Sin($i * 0.20)
Next
_ImGui_SetPlotValues("p_auto",  $aSine)
_ImGui_SetPlotValues("p_fixed", $aSine)
_ImGui_SetPlotValues("p_dyn",   $aSine)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("sl_min",   "_OnSlider")
_ImGui_SetOnChange("sl_max",   "_OnSlider")
_ImGui_SetOnClick ("btn_auto", "_OnResetAuto")
_ImGui_SetOnClick ("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnSlider($sId)
    Local $fMin = _ImGui_GetValueFloat("sl_min")
    Local $fMax = _ImGui_GetValueFloat("sl_max")
    ; Guard against a degenerate range (min >= max) -- ImGui handles it but the
    ; visual would be nonsensical.
    If $fMin >= $fMax Then $fMax = $fMin + 0.05
    _ImGui_SetPlotScale("p_dyn", $fMin, $fMax)
EndFunc

Func _OnResetAuto($sId)
    _ImGui_SetPlotScale("p_dyn", $FLT_MAX, $FLT_MAX)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
