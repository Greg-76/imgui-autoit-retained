#cs
================================================================================
 Example 17 : _ImGui_CreateSliderInt
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateSliderInt    Bounded integer slider
   _ImGui_GetValueInt        Read the current int value
   _ImGui_SetValueInt        Set the value programmatically (no latch)

 Integer counterpart of SliderFloat (exemple16). Same UX, same OnChange
 mechanic ; the value is clamped to an integer range and the format
 string follows printf conventions (%d, %5d, %02X, ...).

 Click semantics + strict semantics : see exemple5_button.au3 + exemple16.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple17_sliderint.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple17_sliderint.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 17 : _ImGui_CreateSliderInt", 600, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSliderInt  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSliderInt($sId, $sLabel = "", $iMin = 0,
;                                     $iMax = 100, $iDefault = 0,
;                                     $sFormat = "%d")
;
;   Horizontal slider bounded to [$iMin, $iMax] (both inclusive). Internal
;   value is an int ; the format string controls only the on-screen text,
;   not the storage type.
;
;   Common $sFormat values :
;     "%d"          default -- decimal integer ("42")
;     "%5d"         width 5, right-aligned ("   42")
;     "%05d"        width 5, zero-padded ("00042")
;     "%02X"        2-digit hex, uppercase ("2A")
;     "%d ms"       with units ("250 ms")
;     "Vol %d/10"   with prefix ("Vol 7/10")
;
;   Read APIs (same shape as SliderFloat) :
;     _ImGui_GetValueInt($sId)              -> int (SetError if non-int widget)
;     _ImGui_SetValueInt($sId, $iValue)     -> no OnChange fired
;
;   Return : True on success, False on failure (@error = 1 not initialised,
;   2 duplicate id, 3 DllCall failed).


; ==============================================================================
; Demo widgets  --  three sliders showcasing different format strings
; ==============================================================================
_ImGui_CreateText("t_title", "SliderInt demo")
_ImGui_CreateText("t_hint",  "Drag any slider. Same handler discriminates via $sId.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateSliderInt("sl_pct",  "Percent",     0,    100,  50,  "%d %%")
_ImGui_CreateText("t_pct", "Read-back %% : 50")

_ImGui_CreateSliderInt("sl_vol",  "Volume",      0,     10,   7,  "Vol %d/10")
_ImGui_CreateText("t_vol", "Read-back vol : 7")

_ImGui_CreateSliderInt("sl_hex",  "Byte (hex)",  0,    255, 128,  "0x%02X")
_ImGui_CreateText("t_hex", "Read-back byte : 128 / 0x80")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_zero",  "Zero all sliders (SetValueInt, no OnChange)")
_ImGui_CreateButton("btn_max",   "Max  all sliders")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("sl_pct",  "_OnChange")
_ImGui_SetOnChange("sl_vol",  "_OnChange")
_ImGui_SetOnChange("sl_hex",  "_OnChange")
_ImGui_SetOnClick("btn_zero", "_OnZero")
_ImGui_SetOnClick("btn_max",  "_OnMax")
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnChange($sId)
    Local $iValue = _ImGui_GetValueInt($sId)
    Switch $sId
        Case "sl_pct"
            _ImGui_SetText("t_pct", "Read-back %% : " & $iValue)
        Case "sl_vol"
            _ImGui_SetText("t_vol", "Read-back vol : " & $iValue)
        Case "sl_hex"
            _ImGui_SetText("t_hex", StringFormat("Read-back byte : %d / 0x%02X", $iValue, $iValue))
    EndSwitch
EndFunc

Func _OnZero($sId)
    _ImGui_SetValueInt("sl_pct", 0)
    _ImGui_SetValueInt("sl_vol", 0)
    _ImGui_SetValueInt("sl_hex", 0)
    _ImGui_SetText("t_pct", "Read-back %% : 0 (preset)")
    _ImGui_SetText("t_vol", "Read-back vol : 0 (preset)")
    _ImGui_SetText("t_hex", "Read-back byte : 0 / 0x00 (preset)")
EndFunc

Func _OnMax($sId)
    _ImGui_SetValueInt("sl_pct", 100)
    _ImGui_SetValueInt("sl_vol", 10)
    _ImGui_SetValueInt("sl_hex", 255)
    _ImGui_SetText("t_pct", "Read-back %% : 100 (preset)")
    _ImGui_SetText("t_vol", "Read-back vol : 10 (preset)")
    _ImGui_SetText("t_hex", "Read-back byte : 255 / 0xFF (preset)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
