#cs
================================================================================
 Example 97 : _ImGui_IsVisible
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsVisible   Report whether a widget is currently rendered (not clipped)

 IsVisible is True for the frames the widget actually produced draw
 output -- i.e. not clipped by a parent (scroll region, PushClipRect,
 small window). False for widgets that scrolled off the visible area
 or were otherwise clipped.

 PERSISTENT state -- polling at 50 ms is reliable.

 Typical use case : skip expensive per-widget logic for items
 currently off-screen in a long scrollable list. Combine with a
 scrollable Child window for the canonical pattern -- here we keep
 the demo simple by laying widgets out with big Dummy gaps so the
 ImGui window scrolls naturally.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple97_isvisible.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple97_isvisible.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init -- start with a SMALL window so the bottom widgets are clipped ----
If Not _ImGui_Init("Example 97 : _ImGui_IsVisible", 540, 320) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsVisible  --  doc block
; ==============================================================================
; Signature : _ImGui_IsVisible($sId)
;
;   Returns True if the widget produced draw output during the last
;   rendered frame. False if it was clipped, scrolled out of view, or
;   hidden by an unopened section.
;
;   Persistent state ; 50 ms polling is reliable.
;
;   Use case : in a long scrollable list, check IsVisible before
;   running expensive per-row computation (formatting, network
;   fetches, ...). Off-screen rows can be skipped this frame.
;
;   Hidden / unknown widgets return False silently.


; ==============================================================================
; Demo widgets  --  status panel + 5 numbered targets with large vertical gaps
;                  so the smaller-than-default window forces scrolling.
; ==============================================================================
_ImGui_CreateText("t_title", "IsVisible demo  --  scroll to see widgets clip in / out of view")
_ImGui_CreateText("t_hint",  "Resize the window vertically OR scroll inside it. The status panel shows which numbered widgets are currently visible.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_status_hdr", "Visibility status (~20 Hz poll) :")
_ImGui_CreateText("t_v1", "  Widget #1 : visible")
_ImGui_CreateText("t_v2", "  Widget #2 : visible")
_ImGui_CreateText("t_v3", "  Widget #3 : visible")
_ImGui_CreateText("t_v4", "  Widget #4 : visible")
_ImGui_CreateText("t_v5", "  Widget #5 : visible")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_targets_hdr", "Targets (each separated by a 60-px Dummy so the window scrolls) :")

_ImGui_CreateButton("tg_w1", "Widget #1 (near the top)")
_ImGui_CreateDummy("d_1", 0.0, 60.0)
_ImGui_CreateButton("tg_w2", "Widget #2")
_ImGui_CreateDummy("d_2", 0.0, 60.0)
_ImGui_CreateButton("tg_w3", "Widget #3 (middle)")
_ImGui_CreateDummy("d_3", 0.0, 60.0)
_ImGui_CreateButton("tg_w4", "Widget #4")
_ImGui_CreateDummy("d_4", 0.0, 60.0)
_ImGui_CreateButton("tg_w5", "Widget #5 (near the bottom)")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollVisible", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollVisible()
    _ImGui_SetText("t_v1", "  Widget #1 : " & (_ImGui_IsVisible("tg_w1") ? "VISIBLE" : "clipped / off-screen"))
    _ImGui_SetText("t_v2", "  Widget #2 : " & (_ImGui_IsVisible("tg_w2") ? "VISIBLE" : "clipped / off-screen"))
    _ImGui_SetText("t_v3", "  Widget #3 : " & (_ImGui_IsVisible("tg_w3") ? "VISIBLE" : "clipped / off-screen"))
    _ImGui_SetText("t_v4", "  Widget #4 : " & (_ImGui_IsVisible("tg_w4") ? "VISIBLE" : "clipped / off-screen"))
    _ImGui_SetText("t_v5", "  Widget #5 : " & (_ImGui_IsVisible("tg_w5") ? "VISIBLE" : "clipped / off-screen"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
