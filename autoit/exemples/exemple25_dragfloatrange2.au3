#cs
================================================================================
 Example 25 : _ImGui_CreateDragFloatRange2
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateDragFloatRange2    Two floats (min, max) tracked as a pair
   _ImGui_GetValueFloatN           Read the 2-component vector (min, max)
   _ImGui_SetValueFloatN           Set the 2-component vector

 DragFloatRange2 is two DragFloats side by side that always satisfy
 min <= max -- if you drag one past the other, the widget pushes the
 second one along. Perfect for editing intervals (gain ranges, time
 windows, slider min/max, ...).

 Click semantics + strict semantics : see exemple5_button.au3 + exemple16.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple25_dragfloatrange2.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple25_dragfloatrange2.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 25 : _ImGui_CreateDragFloatRange2", 620, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateDragFloatRange2  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateDragFloatRange2($sId, $sLabel = "",
;                                           $fVMin = 0.0, $fVMax = 0.0,
;                                           $fSpeed = 1.0,
;                                           $fDefMin = 0.0, $fDefMax = 0.0,
;                                           $sFormat = "%.3f",
;                                           $sFormatMax = "",
;                                           $iFlags = 0)
;
;   Two DragFloats labelled "Min" and "Max" sharing a hard range
;   [$fVMin, $fVMax] (both 0 = unbounded). The widget enforces
;   min <= max at all times -- drag past the other handle and it gets
;   pushed.
;
;   $sFormatMax = "" reuses $sFormat for both handles. Pass a different
;   string if you want, say, the max to show as "max %.2f" while the min
;   shows "min %.2f".
;
;   $iFlags : $ImGuiSliderFlags_* (same as DragFloat).
;
;   Read APIs (vector-2) :
;     _ImGui_GetValueFloatN($sId, 2)         -> AutoIt array [min, max]
;     _ImGui_SetValueFloatN($sId, $aMinMax)  -> 1D array of size 2
;     Programmatic SetValueFloatN does NOT fire OnChange.
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets
; ==============================================================================
_ImGui_CreateText("t_title", "DragFloatRange2 demo  --  intervals (min/max pair)")
_ImGui_CreateText("t_hint",  "Drag either handle. Min stays <= Max ; ImGui pushes the other one if needed.")
_ImGui_CreateSeparator("sep1")

; Range 0..10, drag speed 0.1, default 2..8.
_ImGui_CreateDragFloatRange2("rg_band", "Frequency band (kHz)", _
                              0.0, 10.0,            _    ; hard min/max
                              0.1,                   _    ; speed
                              2.0, 8.0,              _    ; default min, max
                              "min %.2f", "max %.2f", _   ; per-handle formats
                              0)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read", "Read-back : min=2.00, max=8.00, width=6.00")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_reset", "Reset to (2.0, 8.0)  -- SetValueFloatN, no OnChange")
_ImGui_CreateButton("btn_full",  "Maximize to (0.0, 10.0)")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("rg_band", "_OnRangeChanged")
_ImGui_SetOnClick("btn_reset", "_OnReset")
_ImGui_SetOnClick("btn_full",  "_OnFull")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnRangeChanged($sId)
    Local $aVal = _ImGui_GetValueFloatN($sId, 2)
    If @error Or Not IsArray($aVal) Then Return
    _ImGui_SetText("t_read", StringFormat("Read-back : min=%.2f, max=%.2f, width=%.2f", _
        $aVal[0], $aVal[1], $aVal[1] - $aVal[0]))
EndFunc

Func _OnReset($sId)
    Local $aNew[2] = [2.0, 8.0]
    _ImGui_SetValueFloatN("rg_band", $aNew)
    _ImGui_SetText("t_read", "Read-back : min=2.00, max=8.00, width=6.00 (reset)")
EndFunc

Func _OnFull($sId)
    Local $aNew[2] = [0.0, 10.0]
    _ImGui_SetValueFloatN("rg_band", $aNew)
    _ImGui_SetText("t_read", "Read-back : min=0.00, max=10.00, width=10.00 (preset)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
