#cs
================================================================================
 Example 178 : _ImGui_CreateGetCursorPos (+ _ImGui_GetCursorPos)
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_CreateGetCursorPos   Invisible marker that latches the current
                               window-local cursor position at render time
   _ImGui_GetCursorPos         Read the latched (x, y) from the marker

 The ImGui "cursor" is the LAYOUT cursor -- the (x, y) where the next
 widget would be drawn inside the current window / child. It's
 distinct from the MOUSE cursor (exemple150 GetMousePos).

 Coordinates are WINDOW-LOCAL : (0, 0) is the top-left of the
 enclosing window's content region, NOT screen-space. For screen-
 space coordinates use `_ImGui_CreateSetCursorScreenPos` (exemple180)
 or `_ImGui_GetItemRectMin` (exemple98).

 Place the marker as a SIBLING after the widget whose post-render
 position you want -- the same sibling-order trap class as
 ContextPopup kind=Item (Decisions log 2026-05-21 "Sibling-order-
 dependent markers"). Polling 100 ms is fine ; the latched position
 stays put while widgets above the marker don't move.

 Demo : 3 markers placed at different points in the layout, each
 reads back a different (x, y) -- top of window, after a Separator,
 after a SameLine cluster.

 Borrowed widgets : Button, Text + Separator + SameLine.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple178_getcursorpos.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple178_getcursorpos.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 178 : GetCursorPos cluster", 720, 500) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 2-export cluster
; ==============================================================================
; CreateGetCursorPos($sId)
;   Invisible marker. Place as a sibling at the layout point you want
;   to sample. Read back via GetCursorPos($sId).
;
; GetCursorPos($sId) -> array[2] = (x, y)
;   Window-local pixels (NOT screen-space). Returns 0 with @error on
;   failure (1=DLL not loaded, 2=DllCall failed, 3=unknown id).


; ==============================================================================
; Host header  --  marker #1 goes right at the top
; ==============================================================================
_ImGui_CreateText("t_title", "GetCursorPos demo  --  3 markers latching the layout cursor at different layout points")
_ImGui_CreateText("t_hint",  "Each line below shows where its associated marker landed in window-local coords.")
_ImGui_CreateSeparator("sep0")

; Marker #1 : after the header block, before the readouts.
_ImGui_CreateGetCursorPos("mark_a")
_ImGui_CreateText("t_a", "  marker A (right after the header Separator) : (waiting)")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Marker #2  --  after a SameLine cluster of 3 buttons
; ==============================================================================
_ImGui_CreateText("t_b_hdr", "Marker B : after a SameLine triple of buttons.")
_ImGui_CreateButton("btn_x", "X")
_ImGui_CreateSameLine("sl_x")
_ImGui_CreateButton("btn_y", "Y")
_ImGui_CreateSameLine("sl_y")
_ImGui_CreateButton("btn_z", "Z")
_ImGui_CreateGetCursorPos("mark_b")
_ImGui_CreateText("t_b", "  marker B (just after the 3 inline buttons) : (waiting)")
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Marker #3  --  deep in the layout, after several Text rows
; ==============================================================================
_ImGui_CreateText("t_c_pad1", "  ... filler text ...")
_ImGui_CreateText("t_c_pad2", "  ... more filler ...")
_ImGui_CreateText("t_c_pad3", "  ... even more filler ...")
_ImGui_CreateGetCursorPos("mark_c")
_ImGui_CreateText("t_c", "  marker C (after 3 filler Text rows) : (waiting)")

_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPoll", 200)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPoll()
    _Show("mark_a", "t_a", "marker A (right after the header Separator)")
    _Show("mark_b", "t_b", "marker B (just after the 3 inline buttons)")
    _Show("mark_c", "t_c", "marker C (after 3 filler Text rows)")
EndFunc

Func _Show($sMarker, $sStatus, $sLabel)
    Local $aXY = _ImGui_GetCursorPos($sMarker)
    If IsArray($aXY) Then
        _ImGui_SetText($sStatus, StringFormat("  %s : (x, y) = (%.1f, %.1f)", $sLabel, $aXY[0], $aXY[1]))
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
