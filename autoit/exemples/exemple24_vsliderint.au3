#cs
================================================================================
 Example 24 : _ImGui_CreateVSliderInt
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateVSliderInt    Vertical integer slider
   _ImGui_GetValueInt         Read the current int value
   _ImGui_SetValueInt         Set the value programmatically

 Integer counterpart of VSliderFloat (exemple23). Same UX, int storage.

 Click semantics + strict semantics : see exemple5_button.au3 + exemple16.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple24_vsliderint.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple24_vsliderint.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 24 : _ImGui_CreateVSliderInt", 520, 360) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateVSliderInt  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateVSliderInt($sId, $sLabel = "", $fW = 18.0,
;                                      $fH = 160.0, $iVMin = 0,
;                                      $iVMax = 100, $iDefault = 0,
;                                      $sFormat = "%d", $iFlags = 0)
;
;   Vertical slider with int storage. Identical layout / interaction to
;   VSliderFloat. Format string follows printf int conventions
;   (%d, %5d, %02X, ...).
;
;   Read APIs (same as SliderInt) :
;     _ImGui_GetValueInt($sId)
;     _ImGui_SetValueInt($sId, $iValue)
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  EQ-style band gain : three faders -12..+12 dB
; ==============================================================================
_ImGui_CreateText("t_title", "VSliderInt demo  --  3-band EQ")
_ImGui_CreateText("t_hint",  "Drag UP/DOWN. Each fader shows its dB value below.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateVSliderInt("vs_lo", "Low",  50.0, 140.0, -12, 12, 0, "%+d dB")
_ImGui_CreateSameLine("vs_lo_md")
_ImGui_CreateVSliderInt("vs_md", "Mid",  50.0, 140.0, -12, 12, 0, "%+d dB")
_ImGui_CreateSameLine("vs_md_hi")
_ImGui_CreateVSliderInt("vs_hi", "High", 50.0, 140.0, -12, 12, 0, "%+d dB")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_lo", "Low  : +0 dB")
_ImGui_CreateText("t_md", "Mid  : +0 dB")
_ImGui_CreateText("t_hi", "High : +0 dB")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_flat",  "Flatten EQ (all 0 dB) -- SetValueInt, no OnChange")
_ImGui_CreateButton("btn_smile", "Smile curve (-3, +6, -3 dB)")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("vs_lo", "_OnBandChanged")
_ImGui_SetOnChange("vs_md", "_OnBandChanged")
_ImGui_SetOnChange("vs_hi", "_OnBandChanged")
_ImGui_SetOnClick("btn_flat",  "_OnFlat")
_ImGui_SetOnClick("btn_smile", "_OnSmile")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnBandChanged($sId)
    Local $iValue = _ImGui_GetValueInt($sId)
    Switch $sId
        Case "vs_lo"
            _ImGui_SetText("t_lo", StringFormat("Low  : %+d dB", $iValue))
        Case "vs_md"
            _ImGui_SetText("t_md", StringFormat("Mid  : %+d dB", $iValue))
        Case "vs_hi"
            _ImGui_SetText("t_hi", StringFormat("High : %+d dB", $iValue))
    EndSwitch
EndFunc

Func _OnFlat($sId)
    _ImGui_SetValueInt("vs_lo", 0)
    _ImGui_SetValueInt("vs_md", 0)
    _ImGui_SetValueInt("vs_hi", 0)
    _ImGui_SetText("t_lo", "Low  : +0 dB (preset)")
    _ImGui_SetText("t_md", "Mid  : +0 dB (preset)")
    _ImGui_SetText("t_hi", "High : +0 dB (preset)")
EndFunc

Func _OnSmile($sId)
    _ImGui_SetValueInt("vs_lo", -3)
    _ImGui_SetValueInt("vs_md",  6)
    _ImGui_SetValueInt("vs_hi", -3)
    _ImGui_SetText("t_lo", "Low  : -3 dB (preset)")
    _ImGui_SetText("t_md", "Mid  : +6 dB (preset)")
    _ImGui_SetText("t_hi", "High : -3 dB (preset)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
