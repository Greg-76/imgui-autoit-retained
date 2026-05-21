#cs
================================================================================
 Example 46 : _ImGui_CreateInputInt4
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateInputInt4   Four-component int text-input widget
   _ImGui_GetValueIntN      Read the 4-component vector
   _ImGui_SetValueIntN      Set the 4-component vector

 InputInt4 = four editable int fields, keyboard-driven, no drag.

 PITFALLS demonstrated :
   - InputInt*N has NO $sFormat argument (always "%d"). To show hex,
     compose the string yourself in a separate Text widget.
   - The widget has no built-in range, so out-of-range input must be
     clamped in the OnChange handler (same pattern as exemple39).
     Strict semantics keeps the corrective SetValueIntN from re-firing
     OnChange -- safe.

 Strict semantics : see exemple21_inputint.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple46_inputint4.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple46_inputint4.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 46 : _ImGui_CreateInputInt4", 660, 420) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateInputInt4  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateInputInt4($sId, $sLabel = "",
;                                     $iD0 = 0, $iD1 = 0, $iD2 = 0, $iD3 = 0)
;
;   Four editable int text fields, "%d" formatting only (no $sFormat in
;   the wrapper). Commit on Enter / Tab / focus loss.
;
;   Read / write the quad as an AutoIt array of size 4 :
;     _ImGui_GetValueIntN($sId, 4)        -> [v0, v1, v2, v3]
;     _ImGui_SetValueIntN($sId, $aVals)   -> 1D array of size 4 ; no OnChange
;
;   Bind user commits with _ImGui_SetOnChange (IntVec4ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  last 4 bytes of a MAC-like identifier, 0..255 each,
;                   clamped in OnChange, hex view computed by the script
; ==============================================================================
_ImGui_CreateText("t_title", "InputInt4 demo  --  4-byte identifier (0..255 each, clamped) + hex readout")
_ImGui_CreateText("t_hint",  "Type integers ; bytes outside [0..255] snap back. The hex string is composed by the script.")
_ImGui_CreateSeparator("sep1")

; Default : 0xDE 0xAD 0xBE 0xEF.
_ImGui_CreateInputInt4("in_bytes", "Bytes (b0, b1, b2, b3)", 222, 173, 190, 239)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read", "Read-back : b0=222, b1=173, b2=190, b3=239 (clamped : no, valid)")
_ImGui_CreateText("t_hex",  "Hex view  : DE-AD-BE-EF")
_ImGui_CreateText("t_count","User commits : 0   Clamp events : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueIntN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_zero",  "All zero   ( 0,  0,  0,  0)")
_ImGui_CreateButton("btn_max",   "All max    (255, 255, 255, 255)")
_ImGui_CreateButton("btn_dead",  "DEADBEEF   (222, 173, 190, 239)")
_ImGui_CreateButton("btn_bad",   "Bad values (-1, 256, 999, 100)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Script-side state + per-component bounds --------------------------------
Global $g_iCommitCount = 0
Global $g_iClampCount  = 0
Const  $g_iBLo = 0, $g_iBHi = 255


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("in_bytes",  "_OnBytesChanged")
_ImGui_SetOnClick ("btn_zero",  "_OnZero")
_ImGui_SetOnClick ("btn_max",   "_OnMax")
_ImGui_SetOnClick ("btn_dead",  "_OnDead")
_ImGui_SetOnClick ("btn_bad",   "_OnBad")
_ImGui_SetOnClick ("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnBytesChanged($sId)
    Local $aVal = _ImGui_GetValueIntN($sId, 4)
    If @error Or Not IsArray($aVal) Then Return
    $g_iCommitCount += 1

    Local $i0 = $aVal[0], $i1 = $aVal[1], $i2 = $aVal[2], $i3 = $aVal[3]
    Local $i0c = _Clamp($i0, $g_iBLo, $g_iBHi)
    Local $i1c = _Clamp($i1, $g_iBLo, $g_iBHi)
    Local $i2c = _Clamp($i2, $g_iBLo, $g_iBHi)
    Local $i3c = _Clamp($i3, $g_iBLo, $g_iBHi)

    Local $bClamped = ($i0c <> $i0) Or ($i1c <> $i1) Or ($i2c <> $i2) Or ($i3c <> $i3)
    If $bClamped Then
        Local $aFixed[4] = [$i0c, $i1c, $i2c, $i3c]
        _ImGui_SetValueIntN("in_bytes", $aFixed)
        $g_iClampCount += 1
    EndIf

    _UpdateReadout($i0c, $i1c, $i2c, $i3c, ($bClamped ? "yes" : "no, valid"))
    _ImGui_SetText("t_count", StringFormat("User commits : %d   Clamp events : %d", _
                                            $g_iCommitCount, $g_iClampCount))
EndFunc

Func _OnZero($sId)
    _ApplyPreset(0, 0, 0, 0, "all zero")
EndFunc

Func _OnMax($sId)
    _ApplyPreset(255, 255, 255, 255, "all max")
EndFunc

Func _OnDead($sId)
    _ApplyPreset(222, 173, 190, 239, "DEADBEEF")
EndFunc

Func _OnBad($sId)
    ; Raw out-of-range -- SetValueIntN does NOT fire OnChange, so no clamping
    ; happens here. Commit any field in the widget afterwards to trigger the
    ; clamp pass.
    _ApplyPreset(-1, 256, 999, 100, "raw out-of-range")
EndFunc

Func _ApplyPreset($i0, $i1, $i2, $i3, $sTag)
    Local $aNew[4] = [$i0, $i1, $i2, $i3]
    _ImGui_SetValueIntN("in_bytes", $aNew)
    _UpdateReadout($i0, $i1, $i2, $i3, "preset : " & $sTag)
EndFunc

Func _UpdateReadout($i0, $i1, $i2, $i3, $sNote)
    _ImGui_SetText("t_read", StringFormat("Read-back : b0=%d, b1=%d, b2=%d, b3=%d (clamped : %s)", _
                                          $i0, $i1, $i2, $i3, $sNote))
    ; Hex view : compose with %02X. For values outside 0..255, %02X just
    ; pads to 2 chars and may emit longer strings -- that's expected.
    _ImGui_SetText("t_hex",  StringFormat("Hex view  : %02X-%02X-%02X-%02X", $i0, $i1, $i2, $i3))
EndFunc

Func _Clamp($iVal, $iLo, $iHi)
    If $iVal < $iLo Then Return $iLo
    If $iVal > $iHi Then Return $iHi
    Return $iVal
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
