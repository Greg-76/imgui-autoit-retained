#cs
================================================================================
 Example 22 : _ImGui_CreateSliderAngle
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateSliderAngle    Angle slider (radians stored, degrees shown)
   _ImGui_GetValueFloat        Read the stored radian value
   _ImGui_SetValueFloat        Set the radian value programmatically

 SliderAngle is a regular SliderFloat with a built-in radian/degree
 conversion : you give it degree bounds, the stored value is in radians,
 and the display shows degrees by default. The radian storage is what
 every trigonometry function (Sin, Cos, Tan, ...) expects, so the
 widget removes a manual conversion step.

 Click semantics + strict semantics : see exemple5_button.au3 + exemple16.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple22_sliderangle.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple22_sliderangle.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 22 : _ImGui_CreateSliderAngle", 600, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSliderAngle  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSliderAngle($sId, $sLabel = "", $fDegMin = -360.0,
;                                       $fDegMax = 360.0,
;                                       $fDefaultRad = 0.0,
;                                       $sFormat = "%.0f deg",
;                                       $iFlags = 0)
;
;   Internal storage : RADIANS. Min/max input : DEGREES. Display : driven
;   by $sFormat which receives the value already converted to degrees.
;
;   Why : ImGui already converts both ways internally so the user can
;   work in human degrees while the script gets the math-friendly radian
;   value via _ImGui_GetValueFloat.
;
;   Initial value is given in radians ($fDefaultRad). $fDegMin /
;   $fDegMax are in degrees. Make sure the range covers your default --
;   ImGui will clamp otherwise.
;
;   $iFlags : bitmask of $ImGuiSliderFlags_* (e.g. Logarithmic, AlwaysClamp).
;
;   Read APIs (same as SliderFloat) :
;     _ImGui_GetValueFloat($sId)         -> RADIANS
;     _ImGui_SetValueFloat($sId, $fRad)  -> set in RADIANS, no OnChange
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets
; ==============================================================================
_ImGui_CreateText("t_title", "SliderAngle demo")
_ImGui_CreateText("t_hint",  "Drag the slider. We display BOTH the radian storage and the degree value live.")
_ImGui_CreateSeparator("sep1")

; Range [-180, 180] degrees, default 0 rad. Format hides the radian
; intermediate -- user sees degrees only.
_ImGui_CreateSliderAngle("sl_angle", "Angle", -180.0, 180.0, 0.0, "%.1f deg")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_rad", "Radians : 0.000")
_ImGui_CreateText("t_deg", "Degrees : 0.0")
_ImGui_CreateText("t_sin", "sin(t)  : 0.000")
_ImGui_CreateText("t_cos", "cos(t)  : 1.000")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_preset_hdr", "Presets (SetValueFloat in radians, no OnChange) :")
_ImGui_CreateButton("btn_0",   "0 deg")
_ImGui_CreateButton("btn_90",  "90 deg")
_ImGui_CreateButton("btn_180", "180 deg")
_ImGui_CreateButton("btn_n45", "-45 deg")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Script-side constants ---------------------------------------------------
; Conversion : 1 rad = 180/pi degrees ~= 57.2957795 degrees.
; Declared BEFORE the bindings so the handlers can reference it from their
; first invocation -- file-scope statements are only executed once when
; the script reaches them, and the handlers fire from inside the main loop.
Global Const $g_fDegPerRad = 180.0 / 3.14159265358979


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("sl_angle", "_OnAngleChanged")
_ImGui_SetOnClick("btn_0",     "_OnPreset")
_ImGui_SetOnClick("btn_90",    "_OnPreset")
_ImGui_SetOnClick("btn_180",   "_OnPreset")
_ImGui_SetOnClick("btn_n45",   "_OnPreset")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _UpdateReadouts($fRad)
    Local $fDeg = $fRad * $g_fDegPerRad
    _ImGui_SetText("t_rad", StringFormat("Radians : %.3f", $fRad))
    _ImGui_SetText("t_deg", StringFormat("Degrees : %.1f", $fDeg))
    _ImGui_SetText("t_sin", StringFormat("sin(t)  : %.3f", Sin($fRad)))
    _ImGui_SetText("t_cos", StringFormat("cos(t)  : %.3f", Cos($fRad)))
EndFunc

Func _OnAngleChanged($sId)
    _UpdateReadouts(_ImGui_GetValueFloat($sId))
EndFunc

Func _OnPreset($sId)
    Local $fRad = 0.0
    Switch $sId
        Case "btn_0"
            $fRad = 0.0
        Case "btn_90"
            $fRad = 3.14159265358979 / 2     ; pi/2
        Case "btn_180"
            $fRad = 3.14159265358979         ; pi
        Case "btn_n45"
            $fRad = -3.14159265358979 / 4    ; -pi/4
    EndSwitch
    _ImGui_SetValueFloat("sl_angle", $fRad)
    _UpdateReadouts($fRad)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
