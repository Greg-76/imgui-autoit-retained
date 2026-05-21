#cs
================================================================================
 Example 151 : Mouse button queries (7-export cluster)
================================================================================
 Covers 7 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_IsMouseDown         (button held this frame ?)        persistent
   _ImGui_IsMouseClicked      (button just clicked ?)           edge-frame
   _ImGui_IsMouseReleased     (button just released ?)          edge-frame
   _ImGui_IsMouseDoubleClicked (button double-clicked ?)        edge-frame
   _ImGui_IsMouseDragging     (currently dragging ?)            persistent
   _ImGui_GetMouseClickedCount (n clicks in DoubleClickTime)   integer
   _ImGui_IsAnyMouseDown      (any button held ?)               persistent

 All seven are polled in a single 16 ms tick. The edge-frame queries
 (Clicked / Released / DoubleClicked) need 16 ms polling -- 50 ms
 would miss most events (same trap class as IsClicked / IsEdited /
 IsActivated, see Decisions log "Item-query semantics split into TWO
 families"). Persistent queries (Down / Dragging / AnyDown) are safe
 to read at any rate but we share the same tick for symmetry.

 The demo lays out a 3x6 grid : three button slots (LEFT / RIGHT /
 MIDDLE) crossed with six per-button status lines (Down / Click /
 Release / DoubleClick / Drag / ClickedCount) plus a global
 IsAnyMouseDown line. Edge-frame events are accumulated as counters
 ; persistent states are displayed as live True/False ; ClickedCount
 reflects the current ImGui io.MouseDoubleClickTime burst.

 NOTE : these are ImGui-side queries. They only fire while OUR window
 has focus AND the click was not consumed by a widget. Click on the
 empty host area to bump the counters ; clicking on the Quit button
 below WILL be consumed by the button (no counter increment).

 Borrowed widgets : Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple151_mouse_buttons.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple151_mouse_buttons.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 151 : Mouse button queries", 800, 640) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  semantics summary
; ==============================================================================
; $iButton : 0 = Left (default), 1 = Right, 2 = Middle.
;
; PERSISTENT queries (safe at any poll rate) :
;   IsMouseDown / IsMouseDragging / IsAnyMouseDown
;
; EDGE-FRAME queries (one frame True ; poll at 16 ms !) :
;   IsMouseClicked / IsMouseReleased / IsMouseDoubleClicked
;
; IsMouseClicked accepts a second $bRepeat arg (default False) ; True
; replays the click while the button is held using io.KeyRepeatRate.
;
; IsMouseDragging accepts a second $fThreshold (default -1 = use
; io.MouseDragThreshold ~6 px). Useful to filter out micro-jitters.
;
; GetMouseClickedCount returns the burst length within
; io.MouseDoubleClickTime (1 = single, 2 = double, 3 = triple).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "Mouse button queries  --  3 buttons x 7 queries polled at 16 ms")
_ImGui_CreateText("t_hint",  "Click / drag / double-click in the empty area below the host widgets to bump counters.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Status grid  --  three button slots, six queries each
; ==============================================================================
_ImGui_CreateText("t_hdr_left",   "LEFT (button 0) :")
_ImGui_CreateText("t_l_down",     "  IsDown          : False")
_ImGui_CreateText("t_l_click",    "  IsClicked       : 0 events")
_ImGui_CreateText("t_l_release",  "  IsReleased      : 0 events")
_ImGui_CreateText("t_l_dbl",      "  IsDoubleClicked : 0 events")
_ImGui_CreateText("t_l_drag",     "  IsDragging      : False")
_ImGui_CreateText("t_l_count",    "  GetMouseClickedCount : 0")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_hdr_right",  "RIGHT (button 1) :")
_ImGui_CreateText("t_r_down",     "  IsDown          : False")
_ImGui_CreateText("t_r_click",    "  IsClicked       : 0 events")
_ImGui_CreateText("t_r_release",  "  IsReleased      : 0 events")
_ImGui_CreateText("t_r_dbl",      "  IsDoubleClicked : 0 events")
_ImGui_CreateText("t_r_drag",     "  IsDragging      : False")
_ImGui_CreateText("t_r_count",    "  GetMouseClickedCount : 0")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_hdr_mid",    "MIDDLE (button 2) :")
_ImGui_CreateText("t_m_down",     "  IsDown          : False")
_ImGui_CreateText("t_m_click",    "  IsClicked       : 0 events")
_ImGui_CreateText("t_m_release",  "  IsReleased      : 0 events")
_ImGui_CreateText("t_m_dbl",      "  IsDoubleClicked : 0 events")
_ImGui_CreateText("t_m_drag",     "  IsDragging      : False")
_ImGui_CreateText("t_m_count",    "  GetMouseClickedCount : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_any",        "IsAnyMouseDown : False")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters (edge-frame events) -------------------------------------------
Global $g_iClickL = 0, $g_iClickR = 0, $g_iClickM = 0
Global $g_iRelL   = 0, $g_iRelR   = 0, $g_iRelM   = 0
Global $g_iDblL   = 0, $g_iDblR   = 0, $g_iDblM   = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
; 16 ms polling -- catches edge-frame events most of the time.
_ImGui_SetOnTick("_OnPollMouse", 16)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollMouse()
    ; Edge-frame accumulators ------------------------------------------------
    If _ImGui_IsMouseClicked(0)       Then $g_iClickL += 1
    If _ImGui_IsMouseClicked(1)       Then $g_iClickR += 1
    If _ImGui_IsMouseClicked(2)       Then $g_iClickM += 1
    If _ImGui_IsMouseReleased(0)      Then $g_iRelL   += 1
    If _ImGui_IsMouseReleased(1)      Then $g_iRelR   += 1
    If _ImGui_IsMouseReleased(2)      Then $g_iRelM   += 1
    If _ImGui_IsMouseDoubleClicked(0) Then $g_iDblL   += 1
    If _ImGui_IsMouseDoubleClicked(1) Then $g_iDblR   += 1
    If _ImGui_IsMouseDoubleClicked(2) Then $g_iDblM   += 1

    ; LEFT row
    _ImGui_SetText("t_l_down",    "  IsDown          : " & (_ImGui_IsMouseDown(0)     ? "True " : "False"))
    _ImGui_SetText("t_l_click",   "  IsClicked       : " & $g_iClickL & " events")
    _ImGui_SetText("t_l_release", "  IsReleased      : " & $g_iRelL   & " events")
    _ImGui_SetText("t_l_dbl",     "  IsDoubleClicked : " & $g_iDblL   & " events")
    _ImGui_SetText("t_l_drag",    "  IsDragging      : " & (_ImGui_IsMouseDragging(0) ? "True " : "False"))
    _ImGui_SetText("t_l_count",   "  GetMouseClickedCount : " & _ImGui_GetMouseClickedCount(0))

    ; RIGHT row
    _ImGui_SetText("t_r_down",    "  IsDown          : " & (_ImGui_IsMouseDown(1)     ? "True " : "False"))
    _ImGui_SetText("t_r_click",   "  IsClicked       : " & $g_iClickR & " events")
    _ImGui_SetText("t_r_release", "  IsReleased      : " & $g_iRelR   & " events")
    _ImGui_SetText("t_r_dbl",     "  IsDoubleClicked : " & $g_iDblR   & " events")
    _ImGui_SetText("t_r_drag",    "  IsDragging      : " & (_ImGui_IsMouseDragging(1) ? "True " : "False"))
    _ImGui_SetText("t_r_count",   "  GetMouseClickedCount : " & _ImGui_GetMouseClickedCount(1))

    ; MIDDLE row
    _ImGui_SetText("t_m_down",    "  IsDown          : " & (_ImGui_IsMouseDown(2)     ? "True " : "False"))
    _ImGui_SetText("t_m_click",   "  IsClicked       : " & $g_iClickM & " events")
    _ImGui_SetText("t_m_release", "  IsReleased      : " & $g_iRelM   & " events")
    _ImGui_SetText("t_m_dbl",     "  IsDoubleClicked : " & $g_iDblM   & " events")
    _ImGui_SetText("t_m_drag",    "  IsDragging      : " & (_ImGui_IsMouseDragging(2) ? "True " : "False"))
    _ImGui_SetText("t_m_count",   "  GetMouseClickedCount : " & _ImGui_GetMouseClickedCount(2))

    ; Global ANY flag
    _ImGui_SetText("t_any",       "IsAnyMouseDown : " & (_ImGui_IsAnyMouseDown() ? "True " : "False"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
