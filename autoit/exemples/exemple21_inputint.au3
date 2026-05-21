#cs
================================================================================
 Example 21 : _ImGui_CreateInputInt
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateInputInt     Typed integer input with optional +/- buttons
   _ImGui_GetValueInt        Read the current int value
   _ImGui_SetValueInt        Set the value programmatically (no latch)

 Integer counterpart of InputFloat (exemple20). Same commit-on-Enter
 semantics, integer storage. Defaults for $iStep and $iStepFast are 1
 and 100 -- different from InputFloat which defaults both to 0 (no
 step buttons).

 Click semantics + strict semantics : see exemple5_button.au3 + exemple16.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple21_inputint.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple21_inputint.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 21 : _ImGui_CreateInputInt", 620, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateInputInt  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateInputInt($sId, $sLabel = "", $iDefault = 0,
;                                    $iStep = 1, $iStepFast = 100)
;
;   Editable integer field. By default the widget has +/- buttons :
;     +/-       : add/subtract $iStep      (default 1)
;     Ctrl + +/-: add/subtract $iStepFast  (default 100)
;
;   Pass $iStep = 0 to HIDE the buttons (text-only input). $iStepFast = 0
;   disables the Ctrl-step but the regular buttons keep working.
;
;   No format string and no min/max. Use SliderInt (exemple17) if you
;   need clamping.
;
;   Read APIs :
;     _ImGui_GetValueInt($sId)              -> int
;     _ImGui_SetValueInt($sId, $iValue)     -> no OnChange fired
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  three InputInts with different step setups
; ==============================================================================
_ImGui_CreateText("t_title", "InputInt demo  --  type a number, press Enter to commit")
_ImGui_CreateText("t_hint",  "Or click +/- (Ctrl+click for the fast step).")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_a_hdr", "Default (step=1, fast=100) :")
_ImGui_CreateInputInt("in_def",   "Default",   42)
_ImGui_CreateText("t_a", "Read-back default : 42")

_ImGui_CreateText("t_b_hdr", "No step buttons (step=0) :")
_ImGui_CreateInputInt("in_plain", "No buttons", 0,  0,   0)
_ImGui_CreateText("t_b", "Read-back plain : 0")

_ImGui_CreateText("t_c_hdr", "Step=10, fast=1000 (e.g. byte count edit) :")
_ImGui_CreateInputInt("in_big",   "Bytes",     1024, 10, 1000)
_ImGui_CreateText("t_c", "Read-back bytes : 1024")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_reset", "Reset all to default (SetValueInt, no OnChange)")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("in_def",   "_OnInputChanged")
_ImGui_SetOnChange("in_plain", "_OnInputChanged")
_ImGui_SetOnChange("in_big",   "_OnInputChanged")
_ImGui_SetOnClick("btn_reset", "_OnReset")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnInputChanged($sId)
    Local $iValue = _ImGui_GetValueInt($sId)
    Switch $sId
        Case "in_def"
            _ImGui_SetText("t_a", "Read-back default : " & $iValue)
        Case "in_plain"
            _ImGui_SetText("t_b", "Read-back plain : " & $iValue)
        Case "in_big"
            _ImGui_SetText("t_c", "Read-back bytes : " & $iValue)
    EndSwitch
EndFunc

Func _OnReset($sId)
    _ImGui_SetValueInt("in_def",   42)
    _ImGui_SetValueInt("in_plain", 0)
    _ImGui_SetValueInt("in_big",   1024)
    _ImGui_SetText("t_a", "Read-back default : 42 (reset)")
    _ImGui_SetText("t_b", "Read-back plain : 0 (reset)")
    _ImGui_SetText("t_c", "Read-back bytes : 1024 (reset)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
