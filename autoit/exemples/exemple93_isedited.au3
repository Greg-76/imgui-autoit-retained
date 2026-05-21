#cs
================================================================================
 Example 93 : _ImGui_IsEdited
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsEdited   Report whether the widget's value changed this frame

 PITFALL (same as IsClicked in exemple92) : IsEdited is an EDGE-FRAME
 query, True for ONE FRAME ONLY on the frame the value mutated.
 Polling at 50 ms can miss edits.

 RELIABLE ALTERNATIVES :
   - _ImGui_SetOnChange($sId, "handler")   -- wrapper's event API.
     Driven internally by _ImGui_HasChanged which is consume-and-reset
     (latch persists across polls until consumed).
   - _ImGui_HasChanged($sId) called directly in your own polling.

 Use _ImGui_IsEdited only when you specifically need frame-state
 (custom one-frame predicate, integration with a frame-rate renderer).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple93_isedited.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple93_isedited.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 93 : _ImGui_IsEdited", 620, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsEdited  --  doc block
; ==============================================================================
; Signature : _ImGui_IsEdited($sId)
;
;   Returns True ONLY on the frame the widget's value changed. False
;   every other frame.
;
;   Not consumed by reading. Refreshes every frame.
;
;   Same cadence pitfall as IsClicked : a 16 ms tick catches most
;   edits, but _ImGui_SetOnChange / _ImGui_HasChanged are the reliable
;   way to detect changes from script-side code.


; ==============================================================================
; Demo widgets  --  one Slider tracked both ways : polling IsEdited at 16 ms
;                  vs SetOnChange. Compare the counters.
; ==============================================================================
_ImGui_CreateText("t_title", "IsEdited demo  --  frame-state vs latched change event")
_ImGui_CreateText("t_hint",  "Drag the slider a few times. Compare the two counters.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateSliderFloat("tg_sl", "Target slider (tracked by both methods)", 0.0, 1.0, 0.5, "%.3f")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Counters :")
_ImGui_CreateText("t_a_count", "  IsEdited polling (16 ms tick)       : 0")
_ImGui_CreateText("t_b_count", "  SetOnChange event (consume-and-reset) : 0")
_ImGui_CreateText("t_diff",    "  Difference A - B                    : 0  (negative = polling missed edits)")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iCountA = 0
Global $g_iCountB = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("tg_sl",   "_OnSliderChanged")
_ImGui_SetOnClick ("btn_quit","_OnQuit")
_ImGui_SetOnTick  ("_OnPollIsEdited", 16)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollIsEdited()
    If _ImGui_IsEdited("tg_sl") Then
        $g_iCountA += 1
        _ImGui_SetText("t_a_count", "  IsEdited polling (16 ms tick)       : " & $g_iCountA)
        _ImGui_SetText("t_diff",    "  Difference A - B                    : " & ($g_iCountA - $g_iCountB))
    EndIf
EndFunc

Func _OnSliderChanged($sId)
    $g_iCountB += 1
    _ImGui_SetText("t_b_count", "  SetOnChange event (consume-and-reset) : " & $g_iCountB)
    _ImGui_SetText("t_diff",    "  Difference A - B                    : " & ($g_iCountA - $g_iCountB))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
