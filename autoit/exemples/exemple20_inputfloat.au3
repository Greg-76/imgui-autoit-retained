#cs
================================================================================
 Example 20 : _ImGui_CreateInputFloat
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateInputFloat    Typed float input with optional +/- buttons
   _ImGui_GetValueFloat       Read the current value
   _ImGui_SetValueFloat       Set the value programmatically (no latch)

 InputFloat is a text-input field bound to a float. When $fStep > 0 it
 also gets two small +/- buttons next to the field that increment by
 $fStep (or $fStepFast when Ctrl-clicked).

 Click semantics + strict semantics : see exemple5_button.au3 + exemple16.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple20_inputfloat.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple20_inputfloat.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 20 : _ImGui_CreateInputFloat", 620, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateInputFloat  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateInputFloat($sId, $sLabel = "", $fDefault = 0.0,
;                                      $fStep = 0.0, $fStepFast = 0.0,
;                                      $sFormat = "%.3f")
;
;   Renders an editable float field. The user types a number ; the widget
;   only commits the new value on Enter or focus-loss (NOT on every
;   keystroke). That means OnChange / HasChanged fires once per commit,
;   not 7 times when you type "3.14159".
;
;   $fStep   > 0 -> small "+"/"-" buttons appear, each click adds/subtracts $fStep.
;                  = 0 -> no buttons (just the text field).
;   $fStepFast      Ctrl+click on +/- uses this larger step. Defaults to 0.
;
;   $sFormat  : printf-style format used to DISPLAY the value when the
;   field is not being edited. Editing always uses a plain decimal repr
;   so the user can type any precision.
;
;   No min/max -- the value is unbounded. Use SliderFloat (exemple16) if
;   you need clamping.
;
;   Read APIs :
;     _ImGui_GetValueFloat($sId)         -> float
;     _ImGui_SetValueFloat($sId, $fVal)  -> no OnChange fired
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  three InputFloats, different step / format setups
; ==============================================================================
_ImGui_CreateText("t_title", "InputFloat demo  --  type a number, press Enter to commit")
_ImGui_CreateText("t_hint1", "Click the +/- buttons (when shown) ; Ctrl+click them for the fast step.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_a_hdr", "No step buttons (just typed input) :")
_ImGui_CreateInputFloat("in_plain", "Plain", 3.14, 0.0, 0.0, "%.3f")
_ImGui_CreateText("t_a", "Read-back plain : 3.140")

_ImGui_CreateText("t_b_hdr", "With step buttons (step = 0.1, fast = 1.0) :")
_ImGui_CreateInputFloat("in_step", "Stepped", 0.0, 0.1, 1.0, "%.2f")
_ImGui_CreateText("t_b", "Read-back stepped : 0.00")

_ImGui_CreateText("t_c_hdr", "Scientific format (%.4e) :")
_ImGui_CreateInputFloat("in_sci", "Scientific", 1.0e-3, 1.0e-4, 1.0e-2, "%.4e")
_ImGui_CreateText("t_c", "Read-back scientific : 1.0000e-003")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_reset", "Reset all to default (SetValueFloat, no OnChange)")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("in_plain", "_OnInputChanged")
_ImGui_SetOnChange("in_step",  "_OnInputChanged")
_ImGui_SetOnChange("in_sci",   "_OnInputChanged")
_ImGui_SetOnClick("btn_reset", "_OnReset")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnInputChanged($sId)
    Local $fValue = _ImGui_GetValueFloat($sId)
    Switch $sId
        Case "in_plain"
            _ImGui_SetText("t_a", StringFormat("Read-back plain : %.3f", $fValue))
        Case "in_step"
            _ImGui_SetText("t_b", StringFormat("Read-back stepped : %.2f", $fValue))
        Case "in_sci"
            _ImGui_SetText("t_c", StringFormat("Read-back scientific : %.4e", $fValue))
    EndSwitch
EndFunc

Func _OnReset($sId)
    _ImGui_SetValueFloat("in_plain", 3.14)
    _ImGui_SetValueFloat("in_step",  0.0)
    _ImGui_SetValueFloat("in_sci",   1.0e-3)
    _ImGui_SetText("t_a", "Read-back plain : 3.140 (reset)")
    _ImGui_SetText("t_b", "Read-back stepped : 0.00 (reset)")
    _ImGui_SetText("t_c", "Read-back scientific : 1.0000e-003 (reset)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
