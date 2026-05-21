#cs
================================================================================
 Example 44 : _ImGui_CreateInputInt2
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateInputInt2   Two-component int text-input widget
   _ImGui_GetValueIntN      Read the 2-component vector
   _ImGui_SetValueIntN      Set the 2-component vector

 InputInt2 = two editable int fields, keyboard-driven, no drag.
 No $fSpeed, no $iMin/$iMax.

 PITFALL : unlike InputFloat*N, InputInt*N has NO $sFormat argument
 in the wrapper. Integers are always displayed as plain "%d". If you
 need hex / binary / padded display, format it yourself in a separate
 Text widget driven by OnChange (see exemple46_inputint4.au3).

 Strict semantics : see exemple21_inputint.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple44_inputint2.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple44_inputint2.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 44 : _ImGui_CreateInputInt2", 600, 360) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateInputInt2  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateInputInt2($sId, $sLabel = "",
;                                     $iD0 = 0, $iD1 = 0)
;
;   Two editable int text fields on a single row. NO format argument
;   (always %d). The widget commits and fires OnChange on Enter / Tab /
;   focus loss.
;
;   Read / write the pair as an AutoIt array of size 2 :
;     _ImGui_GetValueIntN($sId, 2)        -> [v0, v1]
;     _ImGui_SetValueIntN($sId, $aVals)   -> 1D array of size 2 ; no OnChange
;
;   Bind user commits with _ImGui_SetOnChange (IntVec2ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  on-screen window position (x, y) in pixels
; ==============================================================================
_ImGui_CreateText("t_title", "InputInt2 demo  --  window position (x, y) in screen pixels")
_ImGui_CreateText("t_hint",  "Type integers then Enter or Tab to commit. Negative values are allowed (multi-monitor setups).")
_ImGui_CreateSeparator("sep1")

; Default (100, 100).
_ImGui_CreateInputInt2("in_pos", "Window pos (x, y)", 100, 100)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : x=100, y=100, manhattan=200")
_ImGui_CreateText("t_count", "User commits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueIntN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_origin",   "Top-left      (0, 0)")
_ImGui_CreateButton("btn_default",  "Default       (100, 100)")
_ImGui_CreateButton("btn_offmain",  "Off main mon. (-1920, 0)")
_ImGui_CreateButton("btn_offscr",   "Off-screen    (9999, 9999)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",     "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iCommitCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("in_pos",       "_OnPosChanged")
_ImGui_SetOnClick ("btn_origin",   "_OnOrigin")
_ImGui_SetOnClick ("btn_default",  "_OnDefault")
_ImGui_SetOnClick ("btn_offmain",  "_OnOffMain")
_ImGui_SetOnClick ("btn_offscr",   "_OnOffScr")
_ImGui_SetOnClick ("btn_quit",     "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPosChanged($sId)
    Local $aVal = _ImGui_GetValueIntN($sId, 2)
    If @error Or Not IsArray($aVal) Then Return
    $g_iCommitCount += 1
    Local $iMan = Abs($aVal[0]) + Abs($aVal[1])
    _ImGui_SetText("t_read",  StringFormat("Read-back : x=%d, y=%d, manhattan=%d", _
                                            $aVal[0], $aVal[1], $iMan))
    _ImGui_SetText("t_count", "User commits : " & $g_iCommitCount)
EndFunc

Func _OnOrigin($sId)
    _ApplyPreset(0, 0, "top-left")
EndFunc

Func _OnDefault($sId)
    _ApplyPreset(100, 100, "default")
EndFunc

Func _OnOffMain($sId)
    _ApplyPreset(-1920, 0, "off main monitor")
EndFunc

Func _OnOffScr($sId)
    _ApplyPreset(9999, 9999, "off-screen")
EndFunc

Func _ApplyPreset($iX, $iY, $sTag)
    Local $aNew[2] = [$iX, $iY]
    _ImGui_SetValueIntN("in_pos", $aNew)
    Local $iMan = Abs($iX) + Abs($iY)
    _ImGui_SetText("t_read", StringFormat("Read-back : x=%d, y=%d, manhattan=%d (%s)", _
                                          $iX, $iY, $iMan, $sTag))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
