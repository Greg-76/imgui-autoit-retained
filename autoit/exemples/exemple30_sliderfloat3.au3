#cs
================================================================================
 Example 30 : _ImGui_CreateSliderFloat3
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateSliderFloat3   Three-component float slider (single widget row)
   _ImGui_GetValueFloatN       Read the 3-component vector
   _ImGui_SetValueFloatN       Set the 3-component vector

 SliderFloat3 packs three independent float sliders into a single widget
 row. Each component is clamped to the same [$fMin, $fMax]. Typical use :
 3D direction vectors, Euler angles, generic 3-channel parameters.

 NOTE : if you want to edit an RGB color, use the Color family
 (ColorEdit3 / ColorPicker3) instead -- they include a color preview swatch
 and HSV/HEX modes. SliderFloat3 is the right pick when "the three numbers
 happen to be three numbers" and not specifically a color.

 Strict semantics : see exemple16_sliderfloat.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple30_sliderfloat3.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple30_sliderfloat3.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 30 : _ImGui_CreateSliderFloat3", 600, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSliderFloat3  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSliderFloat3($sId, $sLabel = "",
;                                        $fMin = 0.0, $fMax = 1.0,
;                                        $fD0 = 0.0, $fD1 = 0.0, $fD2 = 0.0,
;                                        $sFormat = "%.3f")
;
;   Three horizontal slider handles on a single row. All three share the
;   same hard range [$fMin, $fMax]. $fD0 / $fD1 / $fD2 are the initial
;   values for components 0 / 1 / 2.
;
;   Read / write the triple as an AutoIt array of size 3 :
;     _ImGui_GetValueFloatN($sId, 3)        -> [v0, v1, v2]
;     _ImGui_SetValueFloatN($sId, $aVals)   -> 1D array of size 3 ; no OnChange
;
;   Bind user edits with _ImGui_SetOnChange (FloatVec3ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  3D direction vector (x, y, z) in [-1, 1]
; ==============================================================================
_ImGui_CreateText("t_title", "SliderFloat3 demo  --  edit a 3D vector in [-1, 1]")
_ImGui_CreateText("t_hint",  "Drag any handle. Try the presets to see SetValueFloatN bypassing OnChange.")
_ImGui_CreateSeparator("sep1")

; Range -1..1, defaults (0, 0, 0).
_ImGui_CreateSliderFloat3("sl_vec", "Vector (x, y, z)", -1.0, 1.0, 0.0, 0.0, 0.0, "%.3f")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : x=0.000, y=0.000, z=0.000  (|v|=0.000)")
_ImGui_CreateText("t_count", "User edits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueFloatN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_zero", "Zero      ( 0.0,  0.0,  0.0)")
_ImGui_CreateButton("btn_x",    "Unit X    ( 1.0,  0.0,  0.0)")
_ImGui_CreateButton("btn_y",    "Unit Y    ( 0.0,  1.0,  0.0)")
_ImGui_CreateButton("btn_z",    "Unit Z    ( 0.0,  0.0,  1.0)")
_ImGui_CreateButton("btn_neg",  "Negate (-x, -y, -z) from current value")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iEditCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("sl_vec",   "_OnVecChanged")
_ImGui_SetOnClick ("btn_zero", "_OnZero")
_ImGui_SetOnClick ("btn_x",    "_OnUnitX")
_ImGui_SetOnClick ("btn_y",    "_OnUnitY")
_ImGui_SetOnClick ("btn_z",    "_OnUnitZ")
_ImGui_SetOnClick ("btn_neg",  "_OnNegate")
_ImGui_SetOnClick ("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnVecChanged($sId)
    Local $aVal = _ImGui_GetValueFloatN($sId, 3)
    If @error Or Not IsArray($aVal) Then Return
    $g_iEditCount += 1
    Local $fNorm = Sqrt($aVal[0]*$aVal[0] + $aVal[1]*$aVal[1] + $aVal[2]*$aVal[2])
    _ImGui_SetText("t_read",  StringFormat("Read-back : x=%.3f, y=%.3f, z=%.3f  (|v|=%.3f)", _
                                            $aVal[0], $aVal[1], $aVal[2], $fNorm))
    _ImGui_SetText("t_count", "User edits : " & $g_iEditCount)
EndFunc

Func _OnZero($sId)
    _ApplyPreset(0.0, 0.0, 0.0, "zero")
EndFunc

Func _OnUnitX($sId)
    _ApplyPreset(1.0, 0.0, 0.0, "unit X")
EndFunc

Func _OnUnitY($sId)
    _ApplyPreset(0.0, 1.0, 0.0, "unit Y")
EndFunc

Func _OnUnitZ($sId)
    _ApplyPreset(0.0, 0.0, 1.0, "unit Z")
EndFunc

Func _OnNegate($sId)
    Local $aVal = _ImGui_GetValueFloatN("sl_vec", 3)
    If @error Or Not IsArray($aVal) Then Return
    _ApplyPreset(-$aVal[0], -$aVal[1], -$aVal[2], "negated")
EndFunc

Func _ApplyPreset($f0, $f1, $f2, $sTag)
    Local $aNew[3] = [$f0, $f1, $f2]
    _ImGui_SetValueFloatN("sl_vec", $aNew)
    Local $fNorm = Sqrt($f0*$f0 + $f1*$f1 + $f2*$f2)
    _ImGui_SetText("t_read", StringFormat("Read-back : x=%.3f, y=%.3f, z=%.3f  (|v|=%.3f, %s)", _
                                          $f0, $f1, $f2, $fNorm, $sTag))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
