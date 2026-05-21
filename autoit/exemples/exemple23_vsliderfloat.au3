#cs
================================================================================
 Example 23 : _ImGui_CreateVSliderFloat
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateVSliderFloat    Vertical float slider
   _ImGui_GetValueFloat         Read the current value
   _ImGui_SetValueFloat         Set the value programmatically

 Vertical counterpart of SliderFloat (exemple16). Drag UP increases the
 value, DOWN decreases. Useful for level meters, mixer-style controls,
 and anything that visually maps "high = high value".

 Click semantics + strict semantics : see exemple5_button.au3 + exemple16.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple23_vsliderfloat.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple23_vsliderfloat.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 23 : _ImGui_CreateVSliderFloat", 520, 360) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateVSliderFloat  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateVSliderFloat($sId, $sLabel = "", $fW = 18.0,
;                                        $fH = 160.0, $fVMin = 0.0,
;                                        $fVMax = 1.0, $fDefault = 0.0,
;                                        $sFormat = "%.3f", $iFlags = 0)
;
;   Vertical slider. $fW / $fH set the rendered box ; the ImGui demo
;   uses 18 x 160 px (defaults). The label is drawn BELOW the slider.
;
;   Drag UP = value goes UP (matches y-axis-up intuition for level
;   meters). Drag DOWN = value DOWN. Ctrl+click pops a typed input.
;
;   $iFlags : same $ImGuiSliderFlags_* bitmask as SliderFloat
;   (Logarithmic, AlwaysClamp, NoInput, ...).
;
;   Read APIs (same as SliderFloat) :
;     _ImGui_GetValueFloat($sId)
;     _ImGui_SetValueFloat($sId, $fValue)
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  three VSliders side by side, like a mini mixer
; ==============================================================================
_ImGui_CreateText("t_title", "VSliderFloat demo  --  vertical sliders")
_ImGui_CreateText("t_hint",  "Drag UP/DOWN. Three faders below display their values live next to them.")
_ImGui_CreateSeparator("sep1")

; Default size 18 x 160. We pick 24 x 140 here so all three fit
; comfortably and the labels are easier to read.
_ImGui_CreateVSliderFloat("vs_a", "L", 50.0, 140.0, 0.0, 1.0, 0.5, "%.2f")
_ImGui_CreateSameLine("vs_a_b")
_ImGui_CreateVSliderFloat("vs_b", "M", 50.0, 140.0, 0.0, 1.0, 0.5, "%.2f")
_ImGui_CreateSameLine("vs_b_c")
_ImGui_CreateVSliderFloat("vs_c", "R", 50.0, 140.0, 0.0, 1.0, 0.5, "%.2f")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_a", "L = 0.50")
_ImGui_CreateText("t_b", "M = 0.50")
_ImGui_CreateText("t_c", "R = 0.50")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_zero", "Zero all faders (SetValueFloat, no OnChange)")
_ImGui_CreateButton("btn_max",  "Max  all faders")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("vs_a", "_OnFaderChanged")
_ImGui_SetOnChange("vs_b", "_OnFaderChanged")
_ImGui_SetOnChange("vs_c", "_OnFaderChanged")
_ImGui_SetOnClick("btn_zero", "_OnZero")
_ImGui_SetOnClick("btn_max",  "_OnMax")
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnFaderChanged($sId)
    Local $fValue = _ImGui_GetValueFloat($sId)
    Switch $sId
        Case "vs_a"
            _ImGui_SetText("t_a", StringFormat("L = %.2f", $fValue))
        Case "vs_b"
            _ImGui_SetText("t_b", StringFormat("M = %.2f", $fValue))
        Case "vs_c"
            _ImGui_SetText("t_c", StringFormat("R = %.2f", $fValue))
    EndSwitch
EndFunc

Func _OnZero($sId)
    _ImGui_SetValueFloat("vs_a", 0.0)
    _ImGui_SetValueFloat("vs_b", 0.0)
    _ImGui_SetValueFloat("vs_c", 0.0)
    _ImGui_SetText("t_a", "L = 0.00 (preset)")
    _ImGui_SetText("t_b", "M = 0.00 (preset)")
    _ImGui_SetText("t_c", "R = 0.00 (preset)")
EndFunc

Func _OnMax($sId)
    _ImGui_SetValueFloat("vs_a", 1.0)
    _ImGui_SetValueFloat("vs_b", 1.0)
    _ImGui_SetValueFloat("vs_c", 1.0)
    _ImGui_SetText("t_a", "L = 1.00 (preset)")
    _ImGui_SetText("t_b", "M = 1.00 (preset)")
    _ImGui_SetText("t_c", "R = 1.00 (preset)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
