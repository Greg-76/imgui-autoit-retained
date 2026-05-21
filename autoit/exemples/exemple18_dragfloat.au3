#cs
================================================================================
 Example 18 : _ImGui_CreateDragFloat
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateDragFloat    Click-and-drag float input (no track)
   _ImGui_GetValueFloat      Read the current value
   _ImGui_SetValueFloat      Set the value programmatically (no latch)

 DragFloat is a "click and drag horizontally" input. Unlike SliderFloat
 it does NOT render a track ; the value just changes as you drag the
 widget area. Useful when the range is huge (or unbounded) and a track
 would not be meaningful.

 Click semantics + strict semantics : see exemple5_button.au3 + exemple16.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple18_dragfloat.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple18_dragfloat.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 18 : _ImGui_CreateDragFloat", 620, 400) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateDragFloat  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateDragFloat($sId, $sLabel = "", $fSpeed = 1.0,
;                                     $fMin = 0.0, $fMax = 0.0,
;                                     $fDefault = 0.0, $sFormat = "%.3f")
;
;   "Click and drag horizontally" float input. Behaviour :
;     - Click+drag : value changes by ($fSpeed * pixels-dragged) per frame.
;     - Ctrl+click : pop a typed input (just like SliderFloat).
;     - Double-click : also pop the typed input.
;
;   $fSpeed controls how fast the value moves per mouse pixel. Tune it to
;   the value's magnitude :
;     - small range (0..1)     -> 0.005 or 0.01
;     - medium range (0..100)  -> 0.5 or 1.0  (default)
;     - large range (millions) -> 1000 or more
;     - Hold Shift while dragging for 0.1x speed, Alt for 10x speed
;       (override via $ImGuiSliderFlags_NoSpeedTweaks).
;
;   $fMin / $fMax : if both are 0.0 the value is UNBOUNDED. Otherwise the
;   value is clamped to [$fMin, $fMax]. The unbounded case is exactly why
;   Drag exists -- use SliderFloat when you have a meaningful range.
;
;   Read APIs (same as SliderFloat) :
;     _ImGui_GetValueFloat($sId)         -> float
;     _ImGui_SetValueFloat($sId, $fVal)  -> no OnChange fired
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  three Drags with progressively wider speeds + ranges
; ==============================================================================
_ImGui_CreateText("t_title", "DragFloat demo  --  click and drag horizontally")
_ImGui_CreateText("t_hint",  "Hold Shift while dragging for fine control, Alt for fast.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_a_hdr", "Bounded [0..1], slow speed 0.01 :")
_ImGui_CreateDragFloat("dr_small", "Small",  0.01,   0.0,    1.0,   0.5,  "%.3f")
_ImGui_CreateText("t_a", "Read-back small : 0.500")

_ImGui_CreateText("t_b_hdr", "Bounded [-180..180], speed 1.0, degrees format :")
_ImGui_CreateDragFloat("dr_angle", "Angle",  1.0,   -180.0,  180.0,  0.0,  "%.1f deg")
_ImGui_CreateText("t_b", "Read-back angle : 0.0 deg")

_ImGui_CreateText("t_c_hdr", "Unbounded (min=max=0), speed 100.0 :")
_ImGui_CreateDragFloat("dr_open", "Free",   100.0,  0.0,    0.0,    0.0,  "%.0f")
_ImGui_CreateText("t_c", "Read-back free : 0")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_reset", "Reset all to default (SetValueFloat, no OnChange)")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("dr_small", "_OnDragChanged")
_ImGui_SetOnChange("dr_angle", "_OnDragChanged")
_ImGui_SetOnChange("dr_open",  "_OnDragChanged")
_ImGui_SetOnClick("btn_reset", "_OnReset")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnDragChanged($sId)
    Local $fValue = _ImGui_GetValueFloat($sId)
    Switch $sId
        Case "dr_small"
            _ImGui_SetText("t_a", StringFormat("Read-back small : %.3f", $fValue))
        Case "dr_angle"
            _ImGui_SetText("t_b", StringFormat("Read-back angle : %.1f deg", $fValue))
        Case "dr_open"
            _ImGui_SetText("t_c", StringFormat("Read-back free : %.0f", $fValue))
    EndSwitch
EndFunc

Func _OnReset($sId)
    _ImGui_SetValueFloat("dr_small", 0.5)
    _ImGui_SetValueFloat("dr_angle", 0.0)
    _ImGui_SetValueFloat("dr_open",  0.0)
    _ImGui_SetText("t_a", "Read-back small : 0.500 (reset)")
    _ImGui_SetText("t_b", "Read-back angle : 0.0 deg (reset)")
    _ImGui_SetText("t_c", "Read-back free : 0 (reset)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
