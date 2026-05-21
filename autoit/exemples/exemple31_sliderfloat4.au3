#cs
================================================================================
 Example 31 : _ImGui_CreateSliderFloat4
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateSliderFloat4   Four-component float slider (single widget row)
   _ImGui_GetValueFloatN       Read the 4-component vector
   _ImGui_SetValueFloatN       Set the 4-component vector

 SliderFloat4 packs four independent float sliders into a single widget
 row, all sharing the same [$fMin, $fMax]. Typical use : quaternions,
 rectangles (l, t, r, b), generic 4-channel parameters.

 NOTE : for RGBA color editing use ColorEdit4 / ColorPicker4 (Color
 family) -- they bring picker, HEX, drag-and-drop. SliderFloat4 is the
 right choice when the four components don't form a color.

 Strict semantics : see exemple16_sliderfloat.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple31_sliderfloat4.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple31_sliderfloat4.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 31 : _ImGui_CreateSliderFloat4", 620, 400) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSliderFloat4  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSliderFloat4($sId, $sLabel = "",
;                                        $fMin = 0.0, $fMax = 1.0,
;                                        $fD0 = 0.0, $fD1 = 0.0,
;                                        $fD2 = 0.0, $fD3 = 0.0,
;                                        $sFormat = "%.3f")
;
;   Four horizontal slider handles on a single row, sharing the hard
;   range [$fMin, $fMax]. $fD0..3 are the initial values per component.
;
;   Read / write the quad as an AutoIt array of size 4 :
;     _ImGui_GetValueFloatN($sId, 4)        -> [v0, v1, v2, v3]
;     _ImGui_SetValueFloatN($sId, $aVals)   -> 1D array of size 4 ; no OnChange
;
;   Bind user edits with _ImGui_SetOnChange (FloatVec4ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  quaternion-like (w, x, y, z) in [-1, 1]
; ==============================================================================
_ImGui_CreateText("t_title", "SliderFloat4 demo  --  edit a quaternion-like (w, x, y, z) in [-1, 1]")
_ImGui_CreateText("t_hint",  "Drag any handle. Identity preset writes (1, 0, 0, 0).")
_ImGui_CreateSeparator("sep1")

; Range -1..1, defaults : identity quaternion (w=1, x=y=z=0).
_ImGui_CreateSliderFloat4("sl_q", "Quaternion (w, x, y, z)", _
                          -1.0, 1.0, _
                          1.0, 0.0, 0.0, 0.0, _
                          "%.3f")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : w=1.000, x=0.000, y=0.000, z=0.000  (|q|=1.000)")
_ImGui_CreateText("t_count", "User edits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueFloatN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_id",     "Identity        ( 1.0,  0.0,  0.0,  0.0)")
_ImGui_CreateButton("btn_zero",   "Zero            ( 0.0,  0.0,  0.0,  0.0)")
_ImGui_CreateButton("btn_rotx",   "90 deg around X (0.707,  0.707,  0.0,  0.0)")
_ImGui_CreateButton("btn_negate", "Negate q (same rotation, opposite hemisphere)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",   "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iEditCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("sl_q",      "_OnQuatChanged")
_ImGui_SetOnClick ("btn_id",    "_OnIdentity")
_ImGui_SetOnClick ("btn_zero",  "_OnZero")
_ImGui_SetOnClick ("btn_rotx",  "_OnRotX")
_ImGui_SetOnClick ("btn_negate","_OnNegate")
_ImGui_SetOnClick ("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnQuatChanged($sId)
    Local $aVal = _ImGui_GetValueFloatN($sId, 4)
    If @error Or Not IsArray($aVal) Then Return
    $g_iEditCount += 1
    Local $fNorm = Sqrt($aVal[0]*$aVal[0] + $aVal[1]*$aVal[1] _
                      + $aVal[2]*$aVal[2] + $aVal[3]*$aVal[3])
    _ImGui_SetText("t_read",  StringFormat("Read-back : w=%.3f, x=%.3f, y=%.3f, z=%.3f  (|q|=%.3f)", _
                                            $aVal[0], $aVal[1], $aVal[2], $aVal[3], $fNorm))
    _ImGui_SetText("t_count", "User edits : " & $g_iEditCount)
EndFunc

Func _OnIdentity($sId)
    _ApplyPreset(1.0, 0.0, 0.0, 0.0, "identity")
EndFunc

Func _OnZero($sId)
    _ApplyPreset(0.0, 0.0, 0.0, 0.0, "zero")
EndFunc

Func _OnRotX($sId)
    ; cos(45 deg) = sin(45 deg) ~ 0.7071
    _ApplyPreset(0.7071, 0.7071, 0.0, 0.0, "90 deg around X")
EndFunc

Func _OnNegate($sId)
    Local $aVal = _ImGui_GetValueFloatN("sl_q", 4)
    If @error Or Not IsArray($aVal) Then Return
    _ApplyPreset(-$aVal[0], -$aVal[1], -$aVal[2], -$aVal[3], "negated")
EndFunc

Func _ApplyPreset($f0, $f1, $f2, $f3, $sTag)
    Local $aNew[4] = [$f0, $f1, $f2, $f3]
    _ImGui_SetValueFloatN("sl_q", $aNew)
    Local $fNorm = Sqrt($f0*$f0 + $f1*$f1 + $f2*$f2 + $f3*$f3)
    _ImGui_SetText("t_read", StringFormat("Read-back : w=%.3f, x=%.3f, y=%.3f, z=%.3f  (|q|=%.3f, %s)", _
                                          $f0, $f1, $f2, $f3, $fNorm, $sTag))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
