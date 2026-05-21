#cs
================================================================================
 Example 92 : _ImGui_IsClicked
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsClicked   Report whether the widget was just clicked this frame

 PITFALL (very important) : IsClicked is an EDGE-FRAME query. It is
 True for ONE FRAME ONLY, the frame on which the mouse button went
 down on the widget. Adjacent frames return False.

 Polling at 50 ms (default _ImGui_SetOnTick) CAN MISS the click :
 ImGui renders at ~60 fps, so the True window lasts about 16 ms --
 less than one poll cycle. The demo below uses a 16 ms tick to catch
 most clicks reliably, but still cannot guarantee 100 %.

 RELIABLE ALTERNATIVES :
   - _ImGui_SetOnClick($sId, "handler")     -- wrapper's event API.
     The wrapper internally uses _ImGui_WasClicked which IS
     consume-and-reset (latch persists until consumed).
   - _ImGui_WasClicked($sId) called directly in your own polling.

 Use _ImGui_IsClicked only when you specifically need frame-state
 (e.g. inside a custom one-frame predicate, or when integrating with
 a renderer that polls at frame rate).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple92_isclicked.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple92_isclicked.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 92 : _ImGui_IsClicked", 620, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsClicked  --  doc block
; ==============================================================================
; Signature : _ImGui_IsClicked($sId)
;
;   Returns True ONLY on the click frame (mouse-down edge on the
;   widget). False every other frame.
;
;   Not consumed by reading. Refreshes every frame.
;
;   Polling cadence matters : 50 ms poll may miss the click because
;   the True window lasts ~16 ms (one render frame at 60 Hz). Either
;   poll at <= 16 ms, or use _ImGui_SetOnClick / _ImGui_WasClicked
;   which have consume-and-reset latches that persist between polls.
;
;   Hidden / unknown widgets return False silently (no @error).


; ==============================================================================
; Demo widgets  --  two targets : one tracked with IsClicked (may miss),
;                  one tracked with SetOnClick (reliable). Compare counters.
; ==============================================================================
_ImGui_CreateText("t_title", "IsClicked demo  --  frame-state vs latched event")
_ImGui_CreateText("t_hint",  "Click both buttons a few times. Compare the two counters at the bottom.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateButton("tg_poll",  "Target A : tracked by IsClicked polling (may miss clicks)")
_ImGui_CreateButton("tg_event", "Target B : tracked by _ImGui_SetOnClick (reliable)")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Counters :")
_ImGui_CreateText("t_a_count", "  A (IsClicked polling, 16 ms tick) : 0")
_ImGui_CreateText("t_b_count", "  B (SetOnClick event)              : 0")
_ImGui_CreateText("t_diff",    "  Difference A - B                  : 0  (negative = polling missed clicks)")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iCountA = 0
Global $g_iCountB = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("tg_event", "_OnB_Clicked")
_ImGui_SetOnClick("btn_quit", "_OnQuit")
; 16 ms tick to catch the edge-frame True window (~one render frame at 60 Hz).
_ImGui_SetOnTick ("_OnPollIsClicked", 16)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollIsClicked()
    If _ImGui_IsClicked("tg_poll") Then
        $g_iCountA += 1
        _ImGui_SetText("t_a_count", "  A (IsClicked polling, 16 ms tick) : " & $g_iCountA)
        _ImGui_SetText("t_diff",    "  Difference A - B                  : " & ($g_iCountA - $g_iCountB))
    EndIf
EndFunc

Func _OnB_Clicked($sId)
    $g_iCountB += 1
    _ImGui_SetText("t_b_count", "  B (SetOnClick event)              : " & $g_iCountB)
    _ImGui_SetText("t_diff",    "  Difference A - B                  : " & ($g_iCountA - $g_iCountB))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
