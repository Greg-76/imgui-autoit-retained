#cs
================================================================================
 Example 179 : SetCursorPos cluster (window-local)
================================================================================
 Covers 3 exports of imgui_autoit.dll (inseparable cluster -- all
 three move the LAYOUT cursor in window-local coords) :

   _ImGui_CreateSetCursorPos    Marker : move cursor to (x, y)
   _ImGui_CreateSetCursorPosX   Marker : move X only ; Y unchanged
   _ImGui_CreateSetCursorPosY   Marker : move Y only ; X unchanged

 The three are markers that mutate the LAYOUT CURSOR at render time
 (where the NEXT widget will be placed). All three operate in
 WINDOW-LOCAL pixels -- (0, 0) is the top-left of the current window
 / child's content region. For screen-space placement see exemple180
 (SetCursorScreenPos).

 Placement RULE (same sibling-order trap class -- Decisions log
 2026-05-21 "Sibling-order-dependent markers") : the marker MUST
 appear at the layout point where it should fire ; widgets created
 AFTER it (in tree order) will start at the requested cursor pos.

 Use cases :
   * SetCursorPos       -- absolute 2D placement (e.g. badge overlay)
   * SetCursorPosX      -- right-align a widget by jumping X near
                           window edge (no need to recompute Y)
   * SetCursorPosY      -- vertically pad a section without inserting
                           Spacing widgets

 Demo : a button positioned 3 different ways below the header.

 Borrowed widgets : GetCursorPos (exemple178) for verification,
 Button, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple179_setcursorpos.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple179_setcursorpos.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 179 : SetCursorPos cluster", 760, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 3-export cluster
; ==============================================================================
; CreateSetCursorPos($sId, $fX = 0.0, $fY = 0.0)
;   Marker. Move BOTH components of the layout cursor.
;
; CreateSetCursorPosX($sId, $fX = 0.0)
;   Marker. Move X only ; Y stays at whatever the current layout flow
;   produced.
;
; CreateSetCursorPosY($sId, $fY = 0.0)
;   Marker. Move Y only ; X stays put (typically 0 if no Indent /
;   SameLine).
;
; Window-local pixels. (0, 0) is the top-left of the current Begin()
; window or Child scope.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "SetCursorPos cluster  --  absolute 2D / X-only / Y-only placement of the layout cursor")
_ImGui_CreateText("t_hint",  "Three buttons below are each preceded by a different cursor-setting marker.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; 1) SetCursorPos absolute (250, 100)  --  the marker is at the layout
;    point in tree order, the next widget jumps to the requested coords.
; ==============================================================================
_ImGui_CreateText("t_1_hdr", "1) CreateSetCursorPos(250, 100) :")
_ImGui_CreateSetCursorPos("set_abs", 250.0, 100.0)
_ImGui_CreateButton("btn_abs", "I jumped to (250, 100)")
; Verify with a GetCursorPos right after.
_ImGui_CreateGetCursorPos("mark_abs")
_ImGui_CreateText("t_abs_check", "  GetCursorPos right after: (waiting)")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; 2) SetCursorPosX 500  --  right-shift X only ; layout flow continues
;    downward as usual.
; ==============================================================================
_ImGui_CreateText("t_2_hdr", "2) CreateSetCursorPosX(500)  --  right-align style :")
_ImGui_CreateSetCursorPosX("set_x", 500.0)
_ImGui_CreateButton("btn_x", "X shifted to 500")
_ImGui_CreateGetCursorPos("mark_x")
_ImGui_CreateText("t_x_check", "  GetCursorPos right after: (waiting)")
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; 3) SetCursorPosY +80 from current  --  vertical padding gap.
;    NOTE : SetCursorPosY uses ABSOLUTE Y, not delta. We compute the
;    target by reading the current cursor + offset via GetCursorPos
;    before this marker -- but since the marker is read at script-
;    load time, we just pick a reasonable absolute value.
; ==============================================================================
_ImGui_CreateText("t_3_hdr", "3) CreateSetCursorPosY(400)  --  push Y down ; X stays at 0 :")
_ImGui_CreateSetCursorPosY("set_y", 400.0)
_ImGui_CreateButton("btn_y", "Y forced to 400")
_ImGui_CreateGetCursorPos("mark_y")
_ImGui_CreateText("t_y_check", "  GetCursorPos right after: (waiting)")
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
    _Show("mark_abs", "t_abs_check")
    _Show("mark_x",   "t_x_check")
    _Show("mark_y",   "t_y_check")
EndFunc

Func _Show($sMarker, $sStatus)
    Local $aXY = _ImGui_GetCursorPos($sMarker)
    If IsArray($aXY) Then
        _ImGui_SetText($sStatus, StringFormat("  GetCursorPos right after: (x, y) = (%.1f, %.1f)", $aXY[0], $aXY[1]))
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
