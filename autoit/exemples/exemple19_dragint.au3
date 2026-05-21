#cs
================================================================================
 Example 19 : _ImGui_CreateDragInt
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateDragInt      Click-and-drag integer input (no track)
   _ImGui_GetValueInt        Read the current int value
   _ImGui_SetValueInt        Set the value programmatically (no latch)

 Integer counterpart of DragFloat (exemple18). Same UX, integer storage.
 $fSpeed is still a float -- it controls fractional pixel-to-value
 mapping ; the displayed value is rounded to an int every frame.

 Click semantics + strict semantics : see exemple5_button.au3 + exemple16.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple19_dragint.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple19_dragint.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 19 : _ImGui_CreateDragInt", 620, 400) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateDragInt  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateDragInt($sId, $sLabel = "", $fSpeed = 1.0,
;                                   $iMin = 0, $iMax = 0,
;                                   $iDefault = 0, $sFormat = "%d")
;
;   Click-and-drag integer input. Behaviour identical to DragFloat (drag,
;   Ctrl+click for typed input, Shift/Alt drag modifiers) but stored as
;   an int. $fSpeed remains a float -- it lets you drag, say, 0.5 pixels
;   per integer step (a 2-pixel drag = 1 unit).
;
;   $iMin / $iMax : both 0 -> unbounded. Otherwise clamped to range.
;
;   Read APIs (same as SliderInt) :
;     _ImGui_GetValueInt($sId)              -> int
;     _ImGui_SetValueInt($sId, $iValue)     -> no OnChange fired
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  three DragInts with different speeds + ranges
; ==============================================================================
_ImGui_CreateText("t_title", "DragInt demo  --  click and drag horizontally")
_ImGui_CreateText("t_hint",  "Hold Shift while dragging for fine control, Alt for fast.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_a_hdr", "Bounded [0..100], speed 1.0 (1 unit per pixel) :")
_ImGui_CreateDragInt("dr_pct", "Percent", 1.0, 0, 100, 50, "%d %%")
_ImGui_CreateText("t_a", "Read-back %% : 50")

_ImGui_CreateText("t_b_hdr", "Bounded [-50..50], speed 0.5 (1 unit per 2 pixels = fine) :")
_ImGui_CreateDragInt("dr_off", "Offset", 0.5, -50, 50, 0, "%+d px")
_ImGui_CreateText("t_b", "Read-back offset : +0 px")

_ImGui_CreateText("t_c_hdr", "Unbounded, speed 10 (large steps) :")
_ImGui_CreateDragInt("dr_big", "Big", 10.0, 0, 0, 0, "%d")
_ImGui_CreateText("t_c", "Read-back big : 0")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_reset", "Reset all to default (SetValueInt, no OnChange)")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("dr_pct", "_OnDragChanged")
_ImGui_SetOnChange("dr_off", "_OnDragChanged")
_ImGui_SetOnChange("dr_big", "_OnDragChanged")
_ImGui_SetOnClick("btn_reset", "_OnReset")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnDragChanged($sId)
    Local $iValue = _ImGui_GetValueInt($sId)
    Switch $sId
        Case "dr_pct"
            _ImGui_SetText("t_a", "Read-back %% : " & $iValue)
        Case "dr_off"
            _ImGui_SetText("t_b", StringFormat("Read-back offset : %+d px", $iValue))
        Case "dr_big"
            _ImGui_SetText("t_c", "Read-back big : " & $iValue)
    EndSwitch
EndFunc

Func _OnReset($sId)
    _ImGui_SetValueInt("dr_pct", 50)
    _ImGui_SetValueInt("dr_off", 0)
    _ImGui_SetValueInt("dr_big", 0)
    _ImGui_SetText("t_a", "Read-back %% : 50 (reset)")
    _ImGui_SetText("t_b", "Read-back offset : +0 px (reset)")
    _ImGui_SetText("t_c", "Read-back big : 0 (reset)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
