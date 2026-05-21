#cs
================================================================================
 Example 180 : _ImGui_CreateSetCursorScreenPos
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateSetCursorScreenPos   Marker : move the layout cursor
                                     to an absolute screen-space (x, y)

 Counterpart of `_ImGui_CreateSetCursorPos` (exemple179, window-local)
 but in SCREEN-SPACE coords -- the same coordinate system used by
 _ImGui_GetMousePos (exemple150), _ImGui_GetItemRectMin (exemple98),
 _ImGui_IsMouseHoveringRect (exemple152).

 Use cases :
   * Pin a widget to an absolute on-screen position regardless of
     window scroll / content offsets.
   * Align widgets across different windows by computing absolute
     anchors.
   * Position overlays computed from mouse pos (exemple141
     PopupOpenMousePos).

 Same sibling-order rule as the window-local variants (Decisions log
 entry "Sibling-order-dependent markers"). The widget created AFTER
 the marker in tree order will start at the requested screen-space
 coords.

 Borrowed widgets : GetMousePos (exemple150) for screen-space
 reference, GetCursorPos (exemple178), Button, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple180_setcursorscreenpos.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple180_setcursorscreenpos.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 180 : SetCursorScreenPos", 760, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSetCursorScreenPos  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSetCursorScreenPos($sId,
;                                              $fScreenX = 0.0,
;                                              $fScreenY = 0.0)
;
;   Screen-space pixels (NOT window-local). (0, 0) is the top-left of
;   the OS window's client area. Same coordinate system as
;   _ImGui_GetMousePos / _ImGui_GetItemRectMin / _ImGui_IsMouseHoveringRect.
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "SetCursorScreenPos demo  --  absolute screen-space placement")
_ImGui_CreateText("t_hint",  "Two buttons below are placed at fixed screen-space points (200, 200) and (400, 300).")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Live mouse pos readout  --  reminds the user what screen-space looks like
; ==============================================================================
_ImGui_CreateText("t_mouse", "Live mouse pos (screen-space) : (waiting)")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Button A pinned at screen (200, 200)
; ==============================================================================
_ImGui_CreateSetCursorScreenPos("set_a", 200.0, 200.0)
_ImGui_CreateButton("btn_a", "Pinned at screen (200, 200)")
_ImGui_CreateGetCursorPos("mark_a")
_ImGui_CreateText("t_a_check", "  GetCursorPos right after (WINDOW-local, not screen) : (waiting)")
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Button B pinned at screen (400, 300)
; ==============================================================================
_ImGui_CreateSetCursorScreenPos("set_b", 400.0, 300.0)
_ImGui_CreateButton("btn_b", "Pinned at screen (400, 300)")
_ImGui_CreateGetCursorPos("mark_b")
_ImGui_CreateText("t_b_check", "  GetCursorPos right after (WINDOW-local, not screen) : (waiting)")

_ImGui_CreateSeparator("sep3")
_ImGui_CreateText("t_note", "Note : GetCursorPos returns WINDOW-local coords, so the values above will differ from the screen coords requested.")
_ImGui_CreateSeparator("sep4")
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
    Local $aMouse = _ImGui_GetMousePos()
    If IsArray($aMouse) Then
        _ImGui_SetText("t_mouse", StringFormat("Live mouse pos (screen-space) : (%.1f, %.1f)", $aMouse[0], $aMouse[1]))
    EndIf
    _Show("mark_a", "t_a_check")
    _Show("mark_b", "t_b_check")
EndFunc

Func _Show($sMarker, $sStatus)
    Local $aXY = _ImGui_GetCursorPos($sMarker)
    If IsArray($aXY) Then
        _ImGui_SetText($sStatus, StringFormat("  GetCursorPos right after (WINDOW-local, not screen) : (%.1f, %.1f)", $aXY[0], $aXY[1]))
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
