#cs
================================================================================
 Example 85 : _ImGui_CreatePopClipRect
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePopClipRect   Pop ONE clip-rect frame off the stack

 Mirror of PushClipRect (exemple84). Removes the topmost clipping
 rectangle, restoring the previous clip region.

 PITFALL : ImGui asserts AT END OF FRAME if Push/Pop counts do not
 match. Unlike Indent/Unindent (silent drift), an unbalanced clip
 stack triggers an explicit assertion in debug builds. This is the
 most visible failure mode in the Push/Pop family -- treat clip rect
 pairing as the strictest of the bunch.

 No $iCount argument here either : one Pop per Push.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple85_popcliprect.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple85_popcliprect.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 85 : _ImGui_CreatePopClipRect", 700, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePopClipRect  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePopClipRect($sId)
;
;   No $iCount : pops exactly ONE frame off the clip-rect stack.
;
;   Pairing is strictly enforced by ImGui at end-of-frame -- a
;   mismatched stack triggers an assertion (debug builds) instead of
;   the silent drift seen in Indent/Unindent.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  nested Push/Pop : outer wide rect, inner narrow rect,
;                  then back to outer, then back to default.
; ==============================================================================
_ImGui_CreateText("t_title", "PopClipRect demo  --  nested clip rects unwound LIFO")
_ImGui_CreateText("t_hint",  "Each inner clip intersects with the outer one (default $bIntersect=True) ; the narrowest active clip wins.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Outer Push : 300 px wide --------------------------------------------
_ImGui_CreateText("a_hdr", "(A) Outer PushClipRect(0, 0, 300, 999) -- 300 px from screen left :")
_ImGui_CreatePushClipRect("pcr_outer", 0.0, 0.0, 300.0, 999.0, 1)
_ImGui_CreateButton("a_b_outer", "Outer scope -- a fairly long label that gets clipped near 300 px")
_ImGui_CreateSeparator("sep_a")

; --- (B) Inner Push (intersect mode) : 180 px wide ---------------------------
_ImGui_CreateText("b_hdr", "(B) Inner PushClipRect(0, 0, 180, 999) -- intersects with outer, effective clip = min(180, 300) :")
_ImGui_CreatePushClipRect("pcr_inner", 0.0, 0.0, 180.0, 999.0, 1)
_ImGui_CreateButton("b_b_inner", "Inner scope -- now clipped at 180 px instead of 300")
_ImGui_CreatePopClipRect("pcr_inner_pop")
_ImGui_CreateSeparator("sep_b")

; --- (C) After Pop -- back to outer (300 px) ---------------------------------
_ImGui_CreateText("c_hdr", "(C) After ONE Pop -- outer clip (300 px) is back :")
_ImGui_CreateButton("c_b_back", "Back to outer -- same widget clipped at 300 px")
_ImGui_CreatePopClipRect("pcr_outer_pop")
_ImGui_CreateSeparator("sep_c")

; --- (D) After second Pop -- default (no clip) ------------------------------
_ImGui_CreateText("d_hdr", "(D) After SECOND Pop -- no clip, full width again :")
_ImGui_CreateButton("d_b_default", "Same widget unclipped -- nothing is cut off now")
_ImGui_CreateSeparator("sep_d")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
