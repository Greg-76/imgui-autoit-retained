#cs
================================================================================
 Example 26 : _ImGui_CreateDragIntRange2
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateDragIntRange2    Two ints (min, max) tracked as a pair
   _ImGui_GetValueIntN           Read the 2-component int vector
   _ImGui_SetValueIntN           Set the 2-component int vector

 Integer counterpart of DragFloatRange2 (exemple25). Same UX, integer
 storage, integer format strings.

 Click semantics + strict semantics : see exemple5_button.au3 + exemple16.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple26_dragintrange2.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple26_dragintrange2.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 26 : _ImGui_CreateDragIntRange2", 620, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateDragIntRange2  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateDragIntRange2($sId, $sLabel = "",
;                                         $iVMin = 0, $iVMax = 0,
;                                         $fSpeed = 1.0,
;                                         $iDefMin = 0, $iDefMax = 0,
;                                         $sFormat = "%d",
;                                         $sFormatMax = "",
;                                         $iFlags = 0)
;
;   Two DragInts side by side, min <= max enforced. $fSpeed is a float
;   (controls drag sensitivity in pixels-per-unit) ; the values
;   themselves are ints.
;
;   $iVMin / $iVMax = 0 -> unbounded. Otherwise the pair is clamped
;   inside the hard range.
;
;   Read APIs (vector-2) :
;     _ImGui_GetValueIntN($sId, 2)         -> AutoIt array [min, max]
;     _ImGui_SetValueIntN($sId, $aMinMax)  -> no OnChange fired
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  HTTP port range pattern
; ==============================================================================
_ImGui_CreateText("t_title", "DragIntRange2 demo  --  port range")
_ImGui_CreateText("t_hint",  "Drag either handle. Width below is computed live.")
_ImGui_CreateSeparator("sep1")

; Hard range 1024..65535 (the standard unprivileged port band), default
; 8000..9000, speed 5 (so a 10-pixel drag moves by 50 ports).
_ImGui_CreateDragIntRange2("rg_ports", "TCP ports",          _
                            1024, 65535,                      _
                            5.0,                              _
                            8000, 9000,                       _
                            "%d", "%d",                       _
                            0)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read", "Read-back : low=8000, high=9000, width=1001 ports")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_reset", "Reset to (8000, 9000)  -- SetValueIntN, no OnChange")
_ImGui_CreateButton("btn_web",   "Web (80, 443)")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("rg_ports", "_OnRangeChanged")
_ImGui_SetOnClick("btn_reset", "_OnReset")
_ImGui_SetOnClick("btn_web",   "_OnWeb")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnRangeChanged($sId)
    Local $aVal = _ImGui_GetValueIntN($sId, 2)
    If @error Or Not IsArray($aVal) Then Return
    _ImGui_SetText("t_read", StringFormat("Read-back : low=%d, high=%d, width=%d ports", _
        $aVal[0], $aVal[1], $aVal[1] - $aVal[0] + 1))
EndFunc

Func _OnReset($sId)
    Local $aNew[2] = [8000, 9000]
    _ImGui_SetValueIntN("rg_ports", $aNew)
    _ImGui_SetText("t_read", "Read-back : low=8000, high=9000, width=1001 ports (reset)")
EndFunc

Func _OnWeb($sId)
    ; Note : 80 is below the hard min of 1024 ; ImGui will clamp it to 1024.
    Local $aNew[2] = [80, 443]
    _ImGui_SetValueIntN("rg_ports", $aNew)
    _ImGui_SetText("t_read", "Read-back : ImGui clamped to [1024, 443] then re-ordered (preset)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
