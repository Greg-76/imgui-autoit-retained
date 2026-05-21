#cs
================================================================================
 Example 43 : _ImGui_CreateInputFloat4
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateInputFloat4   Four-component float text-input widget
   _ImGui_GetValueFloatN      Read the 4-component vector
   _ImGui_SetValueFloatN      Set the 4-component vector

 InputFloat4 = four editable float fields, keyboard-driven, no drag.
 No $fSpeed, no $fMin/$fMax. Strict semantics : see exemple20.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple43_inputfloat4.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple43_inputfloat4.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 43 : _ImGui_CreateInputFloat4", 660, 400) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateInputFloat4  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateInputFloat4($sId, $sLabel = "",
;                                       $fD0 = 0.0, $fD1 = 0.0,
;                                       $fD2 = 0.0, $fD3 = 0.0,
;                                       $sFormat = "%.3f")
;
;   Four editable float text fields, sharing the same display format.
;   Commits (and fires OnChange) on Enter / Tab / focus loss.
;
;   Read / write the quad as an AutoIt array of size 4 :
;     _ImGui_GetValueFloatN($sId, 4)        -> [v0, v1, v2, v3]
;     _ImGui_SetValueFloatN($sId, $aVals)   -> 1D array of size 4 ; no OnChange
;
;   Bind user commits with _ImGui_SetOnChange (FloatVec4ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  plane equation a*x + b*y + c*z + d = 0
; ==============================================================================
_ImGui_CreateText("t_title", "InputFloat4 demo  --  plane equation a*x + b*y + c*z + d = 0")
_ImGui_CreateText("t_hint",  "Edit the four coefficients. The readout writes the full plane equation in human-readable form.")
_ImGui_CreateSeparator("sep1")

; Default : XY plane at z = 0, i.e. 0*x + 0*y + 1*z + 0 = 0.
_ImGui_CreateInputFloat4("in_plane", "Plane (a, b, c, d)", 0.0, 0.0, 1.0, 0.0, "%.3f")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : a=0.000, b=0.000, c=1.000, d=0.000")
_ImGui_CreateText("t_eqn",   "Plane equation : 0.000x + 0.000y + 1.000z + 0.000 = 0  (normal magnitude : 1.000)")
_ImGui_CreateText("t_count", "User commits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueFloatN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_xy",     "XY plane  (a=0, b=0, c=1, d=0)")
_ImGui_CreateButton("btn_xz",     "XZ plane  (a=0, b=1, c=0, d=0)")
_ImGui_CreateButton("btn_yz",     "YZ plane  (a=1, b=0, c=0, d=0)")
_ImGui_CreateButton("btn_offset", "z = 5     (a=0, b=0, c=1, d=-5)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",   "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iCommitCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("in_plane",   "_OnPlaneChanged")
_ImGui_SetOnClick ("btn_xy",     "_OnXY")
_ImGui_SetOnClick ("btn_xz",     "_OnXZ")
_ImGui_SetOnClick ("btn_yz",     "_OnYZ")
_ImGui_SetOnClick ("btn_offset", "_OnOffset")
_ImGui_SetOnClick ("btn_quit",   "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPlaneChanged($sId)
    Local $aVal = _ImGui_GetValueFloatN($sId, 4)
    If @error Or Not IsArray($aVal) Then Return
    $g_iCommitCount += 1
    _UpdateReadout($aVal[0], $aVal[1], $aVal[2], $aVal[3], "")
    _ImGui_SetText("t_count", "User commits : " & $g_iCommitCount)
EndFunc

Func _OnXY($sId)
    _ApplyPreset(0.0, 0.0, 1.0, 0.0, "XY plane")
EndFunc

Func _OnXZ($sId)
    _ApplyPreset(0.0, 1.0, 0.0, 0.0, "XZ plane")
EndFunc

Func _OnYZ($sId)
    _ApplyPreset(1.0, 0.0, 0.0, 0.0, "YZ plane")
EndFunc

Func _OnOffset($sId)
    _ApplyPreset(0.0, 0.0, 1.0, -5.0, "z = 5")
EndFunc

Func _ApplyPreset($fA, $fB, $fC, $fD, $sTag)
    Local $aNew[4] = [$fA, $fB, $fC, $fD]
    _ImGui_SetValueFloatN("in_plane", $aNew)
    _UpdateReadout($fA, $fB, $fC, $fD, $sTag)
EndFunc

Func _UpdateReadout($fA, $fB, $fC, $fD, $sTag)
    Local $fMag = Sqrt($fA*$fA + $fB*$fB + $fC*$fC)
    Local $sSuffix = ($sTag = "") ? "" : (" (" & $sTag & ")")
    _ImGui_SetText("t_read", StringFormat("Read-back : a=%.3f, b=%.3f, c=%.3f, d=%.3f%s", _
                                          $fA, $fB, $fC, $fD, $sSuffix))
    _ImGui_SetText("t_eqn",  StringFormat("Plane equation : %.3fx + %.3fy + %.3fz + %.3f = 0  (normal magnitude : %.3f)", _
                                          $fA, $fB, $fC, $fD, $fMag))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
