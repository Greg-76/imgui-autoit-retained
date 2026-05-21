#cs
================================================================================
 Example 42 : _ImGui_CreateInputFloat3
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateInputFloat3   Three-component float text-input widget
   _ImGui_GetValueFloatN      Read the 3-component vector
   _ImGui_SetValueFloatN      Set the 3-component vector

 InputFloat3 = three editable float fields, keyboard-driven, no drag.
 No $fSpeed, no $fMin/$fMax. Strict semantics : see exemple20.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple42_inputfloat3.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple42_inputfloat3.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 42 : _ImGui_CreateInputFloat3", 620, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateInputFloat3  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateInputFloat3($sId, $sLabel = "",
;                                       $fD0 = 0.0, $fD1 = 0.0, $fD2 = 0.0,
;                                       $sFormat = "%.3f")
;
;   Three editable float text fields. The widget commits (fires
;   OnChange) when the user presses Enter / Tab or focus leaves the
;   field -- not on each keystroke. $sFormat only affects rendering.
;
;   Read / write the triple as an AutoIt array of size 3 :
;     _ImGui_GetValueFloatN($sId, 3)        -> [v0, v1, v2]
;     _ImGui_SetValueFloatN($sId, $aVals)   -> 1D array of size 3 ; no OnChange
;
;   Bind user commits with _ImGui_SetOnChange (FloatVec3ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  3D normal vector, default (0, 1, 0) = world up
; ==============================================================================
_ImGui_CreateText("t_title", "InputFloat3 demo  --  3D normal vector with magnitude readout")
_ImGui_CreateText("t_hint",  "Type values then Enter/Tab. The readout shows whether the vector is unit-length.")
_ImGui_CreateSeparator("sep1")

; Default (0, 1, 0) = world-up normal.
_ImGui_CreateInputFloat3("in_n", "Normal (nx, ny, nz)", 0.0, 1.0, 0.0, "%.4f")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : nx=0.0000, ny=1.0000, nz=0.0000  (|n|=1.0000, unit : yes)")
_ImGui_CreateText("t_count", "User commits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueFloatN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_up",     "World up    ( 0,  1,  0)")
_ImGui_CreateButton("btn_right",  "World right ( 1,  0,  0)")
_ImGui_CreateButton("btn_fwd",    "World fwd   ( 0,  0,  1)")
_ImGui_CreateButton("btn_diag",   "Diagonal    ( 1,  1,  1) -- not unit on purpose")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",   "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iCommitCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("in_n",       "_OnNormalChanged")
_ImGui_SetOnClick ("btn_up",     "_OnUp")
_ImGui_SetOnClick ("btn_right",  "_OnRight")
_ImGui_SetOnClick ("btn_fwd",    "_OnForward")
_ImGui_SetOnClick ("btn_diag",   "_OnDiag")
_ImGui_SetOnClick ("btn_quit",   "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnNormalChanged($sId)
    Local $aVal = _ImGui_GetValueFloatN($sId, 3)
    If @error Or Not IsArray($aVal) Then Return
    $g_iCommitCount += 1
    Local $fNorm = Sqrt($aVal[0]*$aVal[0] + $aVal[1]*$aVal[1] + $aVal[2]*$aVal[2])
    Local $bUnit = (Abs($fNorm - 1.0) < 0.001)
    _ImGui_SetText("t_read",  StringFormat("Read-back : nx=%.4f, ny=%.4f, nz=%.4f  (|n|=%.4f, unit : %s)", _
                                            $aVal[0], $aVal[1], $aVal[2], $fNorm, ($bUnit ? "yes" : "no")))
    _ImGui_SetText("t_count", "User commits : " & $g_iCommitCount)
EndFunc

Func _OnUp($sId)
    _ApplyPreset(0.0, 1.0, 0.0, "world up")
EndFunc

Func _OnRight($sId)
    _ApplyPreset(1.0, 0.0, 0.0, "world right")
EndFunc

Func _OnForward($sId)
    _ApplyPreset(0.0, 0.0, 1.0, "world forward")
EndFunc

Func _OnDiag($sId)
    _ApplyPreset(1.0, 1.0, 1.0, "diagonal, not unit")
EndFunc

Func _ApplyPreset($f0, $f1, $f2, $sTag)
    Local $aNew[3] = [$f0, $f1, $f2]
    _ImGui_SetValueFloatN("in_n", $aNew)
    Local $fNorm = Sqrt($f0*$f0 + $f1*$f1 + $f2*$f2)
    Local $bUnit = (Abs($fNorm - 1.0) < 0.001)
    _ImGui_SetText("t_read", StringFormat("Read-back : nx=%.4f, ny=%.4f, nz=%.4f  (|n|=%.4f, unit : %s, %s)", _
                                          $f0, $f1, $f2, $fNorm, ($bUnit ? "yes" : "no"), $sTag))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
