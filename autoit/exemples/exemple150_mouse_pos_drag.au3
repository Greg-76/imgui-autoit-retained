#cs
================================================================================
 Example 150 : _ImGui_GetMousePos
                (+ _ImGui_GetMouseDragDelta + _ImGui_ResetMouseDragDelta
                 + _ImGui_IsMousePosValid)
================================================================================
 Covers 4 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_GetMousePos          array[2] = (x, y) in ImGui screen-space
   _ImGui_GetMouseDragDelta    array[2] = (dx, dy) for a given button
   _ImGui_ResetMouseDragDelta  zero the accumulated drag delta
   _ImGui_IsMousePosValid      cheap pre-check (mouse on-screen ?)

 Mouse pos / drag delta are READ-only queries -- they reflect ImGui's
 per-frame input snapshot. Poll at 50 ms here (persistent ; no edge-
 frame issue). Reset takes effect from the next frame onward and is
 the canonical "consume the drag in chunks" pattern -- e.g. pan a
 canvas by the current delta, then reset so the next frame's delta
 is the incremental move.

 Cluster bundling : the four exports are inseparable for a working
 demo (read pos, read drag, reset drag, validate pos) -- same rule as
 exemple100 (CreateWindow + verbs) and exemple137 (Popup verbs).

 Note vs AutoIt's MouseGetPos : these queries reflect ImGui's input
 state. They only return meaningful values while OUR window has focus
 and the click was not consumed by a widget. Off-window / out-of-
 capture states are reported via IsMousePosValid = False.

 Borrowed widgets : Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple150_mouse_pos_drag.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple150_mouse_pos_drag.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 150 : _ImGui_GetMousePos + drag", 760, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 4-export cluster
; ==============================================================================
; _ImGui_GetMousePos()                       -> array[2] = (x, y)
;   Returns 0 with @error on DLL failure (1, 2, 3).
;
; _ImGui_GetMouseDragDelta($iButton = 0)     -> array[2] = (dx, dy)
;   $iButton : 0 = Left (default), 1 = Right, 2 = Middle. (0, 0) when
;   the button is not currently dragging.
;
; _ImGui_ResetMouseDragDelta($iButton = 0)   -> True / False
;   Zeros the accumulator so the next frame's GetDragDelta starts from
;   the current mouse position. Idiomatic to call once per "chunk" of
;   consumed drag.
;
; _ImGui_IsMousePosValid()                   -> True / False
;   False when the mouse is lost / off-screen / off-window. Cheap
;   pre-check before reading GetMousePos.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "GetMousePos / GetMouseDragDelta / ResetMouseDragDelta / IsMousePosValid")
_ImGui_CreateText("t_hint",  "Move + drag inside this window. Use 'Reset' to zero a drag accumulator mid-drag.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Live status panel
; ==============================================================================
_ImGui_CreateText("t_valid", "IsMousePosValid : (waiting)")
_ImGui_CreateText("t_pos",   "GetMousePos     : (x, y) = (0.0, 0.0)")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_drag_hdr", "GetMouseDragDelta per button :")
_ImGui_CreateText("t_drag_l",   "  LEFT   : dx, dy = (0.0, 0.0)")
_ImGui_CreateText("t_drag_r",   "  RIGHT  : dx, dy = (0.0, 0.0)")
_ImGui_CreateText("t_drag_m",   "  MIDDLE : dx, dy = (0.0, 0.0)")
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Reset buttons  --  consume the drag in chunks
; ==============================================================================
_ImGui_CreateText("t_reset_hdr", "Reset accumulators (canonical 'consume drag in chunks' pattern) :")
_ImGui_CreateButton("btn_reset_l", "Reset LEFT drag")
_ImGui_CreateButton("btn_reset_r", "Reset RIGHT drag")
_ImGui_CreateButton("btn_reset_m", "Reset MIDDLE drag")
_ImGui_CreateButton("btn_reset_a", "Reset ALL three at once")

_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_reset_l", "_OnResetLeft")
_ImGui_SetOnClick("btn_reset_r", "_OnResetRight")
_ImGui_SetOnClick("btn_reset_m", "_OnResetMiddle")
_ImGui_SetOnClick("btn_reset_a", "_OnResetAll")
_ImGui_SetOnClick("btn_quit",    "_OnQuit")
_ImGui_SetOnTick("_OnPollMouse", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollMouse()
    Local $bValid = _ImGui_IsMousePosValid()
    _ImGui_SetText("t_valid", "IsMousePosValid : " & ($bValid ? "True (on-screen)" : "False (lost / off-window)"))

    Local $aPos = _ImGui_GetMousePos()
    If IsArray($aPos) Then
        _ImGui_SetText("t_pos", StringFormat("GetMousePos     : (x, y) = (%.1f, %.1f)", $aPos[0], $aPos[1]))
    EndIf

    Local $aL = _ImGui_GetMouseDragDelta(0)
    Local $aR = _ImGui_GetMouseDragDelta(1)
    Local $aM = _ImGui_GetMouseDragDelta(2)
    If IsArray($aL) Then _ImGui_SetText("t_drag_l", StringFormat("  LEFT   : dx, dy = (%.1f, %.1f)", $aL[0], $aL[1]))
    If IsArray($aR) Then _ImGui_SetText("t_drag_r", StringFormat("  RIGHT  : dx, dy = (%.1f, %.1f)", $aR[0], $aR[1]))
    If IsArray($aM) Then _ImGui_SetText("t_drag_m", StringFormat("  MIDDLE : dx, dy = (%.1f, %.1f)", $aM[0], $aM[1]))
EndFunc

Func _OnResetLeft($sId)
    _ImGui_ResetMouseDragDelta(0)
EndFunc

Func _OnResetRight($sId)
    _ImGui_ResetMouseDragDelta(1)
EndFunc

Func _OnResetMiddle($sId)
    _ImGui_ResetMouseDragDelta(2)
EndFunc

Func _OnResetAll($sId)
    _ImGui_ResetMouseDragDelta(0)
    _ImGui_ResetMouseDragDelta(1)
    _ImGui_ResetMouseDragDelta(2)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
