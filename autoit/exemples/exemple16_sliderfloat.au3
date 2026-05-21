#cs
================================================================================
 Example 16 : _ImGui_CreateSliderFloat
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateSliderFloat    Bounded float slider with printf-style format
   _ImGui_GetValueFloat        Read the current value
   _ImGui_SetValueFloat        Set the value programmatically (no latch)

 Drag the sliders, or click their preset buttons. Format strings change
 how the value is displayed inside the slider track.

 Borrowed widgets (each detailed in its own example) :
   - _ImGui_CreateText / _ImGui_SetText
   - _ImGui_CreateButton
   - _ImGui_CreateSeparator

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple16_sliderfloat.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple16_sliderfloat.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 16 : _ImGui_CreateSliderFloat", 600, 400) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSliderFloat  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSliderFloat($sId, $sLabel = "", $fMin = 0.0,
;                                       $fMax = 1.0, $fDefault = 0.0,
;                                       $sFormat = "%.3f")
;
;   Renders a horizontal slider for a float bounded to [$fMin, $fMax]. The
;   track is filled from left to the current value ; the value itself is
;   drawn on top using $sFormat (printf-style).
;
;   Common $sFormat values :
;     "%.3f"   default -- 3 decimal places (e.g. "0.500")
;     "%.0f"   integer-looking float (e.g. "42")
;     "%.2f %%"   percent (e.g. "75.00 %%")  -- note doubled %% in AutoIt
;     "%.1f Hz"   units (e.g. "440.0 Hz")
;     "%4.0f px"  width 4, no decimals + units (e.g. "  64 px")
;
;   Reading the value : _ImGui_GetValueFloat($sId) returns the float
;   directly. SetError(2) if the id is unknown, SetError(3) if the widget
;   is not float-valued.
;
;   Setting programmatically : _ImGui_SetValueFloat($sId, $fValue). This
;   does NOT fire OnChange (strict semantics) so cascading presets are
;   safe -- no loop possible.
;
;   Return : True on success, False on failure (@error = 1 not initialised,
;   2 duplicate id, 3 DllCall failed).


; ==============================================================================
; Demo widgets  --  three sliders showcasing different format strings
; ==============================================================================
_ImGui_CreateText("t_title", "SliderFloat demo")
_ImGui_CreateText("t_hint",  "Drag any slider, or click a preset to set the first one programmatically.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateSliderFloat("sl_a", "Default (%.3f)",        0.0, 1.0, 0.5, "%.3f")
_ImGui_CreateText("t_a", "Read-back A : 0.500")

_ImGui_CreateSliderFloat("sl_b", "Percent (%.1f %%%%)",  0.0, 100.0, 50.0, "%.1f %%")
_ImGui_CreateText("t_b", "Read-back B : 50.0")

_ImGui_CreateSliderFloat("sl_c", "Frequency (%.0f Hz)",  20.0, 20000.0, 440.0, "%.0f Hz")
_ImGui_CreateText("t_c", "Read-back C : 440")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_preset_hdr", "Presets for slider A (SetValueFloat, no OnChange fired) :")
_ImGui_CreateButton("btn_0",   "0.00")
_ImGui_CreateButton("btn_25",  "0.25")
_ImGui_CreateButton("btn_50",  "0.50")
_ImGui_CreateButton("btn_75",  "0.75")
_ImGui_CreateButton("btn_100", "1.00")

_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("sl_a", "_OnSliderChanged")
_ImGui_SetOnChange("sl_b", "_OnSliderChanged")
_ImGui_SetOnChange("sl_c", "_OnSliderChanged")
_ImGui_SetOnClick("btn_0",    "_OnPreset")
_ImGui_SetOnClick("btn_25",   "_OnPreset")
_ImGui_SetOnClick("btn_50",   "_OnPreset")
_ImGui_SetOnClick("btn_75",   "_OnPreset")
_ImGui_SetOnClick("btn_100",  "_OnPreset")
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnSliderChanged($sId)
    Local $fValue = _ImGui_GetValueFloat($sId)
    Switch $sId
        Case "sl_a"
            _ImGui_SetText("t_a", StringFormat("Read-back A : %.3f", $fValue))
        Case "sl_b"
            _ImGui_SetText("t_b", StringFormat("Read-back B : %.1f", $fValue))
        Case "sl_c"
            _ImGui_SetText("t_c", StringFormat("Read-back C : %.0f", $fValue))
    EndSwitch
EndFunc

Func _OnPreset($sId)
    Local $fValue = 0.0
    Switch $sId
        Case "btn_0"
            $fValue = 0.00
        Case "btn_25"
            $fValue = 0.25
        Case "btn_50"
            $fValue = 0.50
        Case "btn_75"
            $fValue = 0.75
        Case "btn_100"
            $fValue = 1.00
    EndSwitch
    ; Mirror into slider A. Programmatic SetValueFloat does not fire OnChange,
    ; so we manually update the read-back text afterwards.
    _ImGui_SetValueFloat("sl_a", $fValue)
    _ImGui_SetText("t_a", StringFormat("Read-back A : %.3f (set via preset)", $fValue))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
