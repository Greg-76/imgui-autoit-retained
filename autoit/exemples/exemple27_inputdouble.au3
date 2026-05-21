#cs
================================================================================
 Example 27 : _ImGui_CreateInputDouble
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateInputDouble    Typed double-precision input
   _ImGui_GetValueDouble       Read the current double value
   _ImGui_SetValueDouble       Set the value programmatically

 Double-precision counterpart of InputFloat (exemple20). Distinct
 because the storage type is different : 8 bytes instead of 4, ~15
 significant decimal digits instead of ~7. Use it when you genuinely
 need that precision (financial sums, scientific computation,
 geospatial coords, ...).

 Click semantics + strict semantics : see exemple5_button.au3 + exemple16.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple27_inputdouble.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple27_inputdouble.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 27 : _ImGui_CreateInputDouble", 620, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateInputDouble  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateInputDouble($sId, $sLabel, $fDefault,
;                                       $fStep = 0.0, $fStepFast = 0.0,
;                                       $sFormat = "", $iFlags = 0)
;
;   Editable double-precision field. Same commit-on-Enter semantics as
;   InputFloat ; same +/- step buttons when $fStep > 0.
;
;   $sFormat empty -> ImGui default for doubles (typically "%.6f"). Pass
;   something like "%.15g" to see the full precision of a double, or
;   "%.2f USD" to format a currency amount.
;
;   $iFlags : bitmask of $ImGuiInputTextFlags_* (e.g.
;   CharsScientific to allow "1.23e-7", ReadOnly to show but not edit).
;
;   IMPORTANT : Get/Set are SPECIFIC to double. Get/SetValueFloat does
;   NOT work here (they'd return @error=3 incompatible type).
;
;   Read APIs :
;     _ImGui_GetValueDouble($sId)             -> double (Number variant in AutoIt)
;     _ImGui_SetValueDouble($sId, $fValue)    -> no OnChange fired
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  high-precision values where float would lose information
; ==============================================================================
_ImGui_CreateText("t_title", "InputDouble demo  --  high-precision typed input")
_ImGui_CreateText("t_hint",  "Type a number, press Enter. Note the %% .15g format keeps full double precision.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_a_hdr", "Full-precision display (%%.15g) :")
_ImGui_CreateInputDouble("in_pi",   "pi (15 digits)", 3.141592653589793, 0.0, 0.0, "%.15g")
_ImGui_CreateText("t_a", "Read-back pi : 3.141592653589793")

_ImGui_CreateText("t_b_hdr", "Currency (%%.2f $) with step buttons :")
_ImGui_CreateInputDouble("in_eur",  "Account",        1234567.89, 0.01, 100.0, "%.2f $")
_ImGui_CreateText("t_b", "Read-back account : 1234567.89")

_ImGui_CreateText("t_c_hdr", "Scientific (CharsScientific flag) :")
_ImGui_CreateInputDouble("in_sci",  "Planck h",       6.62607015e-34, 0.0, 0.0, "%.6e", $ImGuiInputTextFlags_CharsScientific)
_ImGui_CreateText("t_c", "Read-back h : 6.62607015e-34")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_reset", "Reset all to default (SetValueDouble, no OnChange)")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("in_pi",  "_OnInputChanged")
_ImGui_SetOnChange("in_eur", "_OnInputChanged")
_ImGui_SetOnChange("in_sci", "_OnInputChanged")
_ImGui_SetOnClick("btn_reset", "_OnReset")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnInputChanged($sId)
    Local $fValue = _ImGui_GetValueDouble($sId)
    Switch $sId
        Case "in_pi"
            _ImGui_SetText("t_a", StringFormat("Read-back pi : %.15g", $fValue))
        Case "in_eur"
            _ImGui_SetText("t_b", StringFormat("Read-back account : %.2f", $fValue))
        Case "in_sci"
            _ImGui_SetText("t_c", StringFormat("Read-back h : %.6e", $fValue))
    EndSwitch
EndFunc

Func _OnReset($sId)
    _ImGui_SetValueDouble("in_pi",  3.141592653589793)
    _ImGui_SetValueDouble("in_eur", 1234567.89)
    _ImGui_SetValueDouble("in_sci", 6.62607015e-34)
    _ImGui_SetText("t_a", "Read-back pi : 3.141592653589793 (reset)")
    _ImGui_SetText("t_b", "Read-back account : 1234567.89 (reset)")
    _ImGui_SetText("t_c", "Read-back h : 6.62607015e-34 (reset)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
