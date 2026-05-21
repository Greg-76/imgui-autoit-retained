#cs
================================================================================
 Example 79 : _ImGui_CreatePopItemWidth
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePopItemWidth   Pop ONE item-width frame off the stack

 Mirror of PushItemWidth (exemple78). Removes the topmost item-width
 override.

 PITFALL vs PopStyleColor / PopStyleVar : PopItemWidth does NOT take a
 $iCount argument. Each Push must be balanced by exactly ONE Pop call.
 If you pushed several item widths in a row, you must call
 PopItemWidth that many times -- there is no fast-path.

 This file focuses on Pop, especially the contrast with the counted
 Pop fast-path available for StyleColor / StyleVar.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple79_popitemwidth.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple79_popitemwidth.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 79 : _ImGui_CreatePopItemWidth", 620, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePopItemWidth  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePopItemWidth($sId)
;
;   No $iCount : pops exactly ONE frame off the item-width stack. To
;   undo N pushes, call PopItemWidth N times.
;
;   Stack semantics : same LIFO behavior as the other Pop* helpers.
;   Most recent Push is undone first.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  Two patterns side by side : the "stacked block" approach
;                  (push N, pop N), and a "single Push, single Pop" canonical
;                  form. Plus a deliberate mismatch demo (recovered) to show
;                  what happens on under-pop.
; ==============================================================================
_ImGui_CreateText("t_title", "PopItemWidth demo  --  no $iCount fast-path ; one Pop per Push")
_ImGui_CreateText("t_hint",  "Each section pushes 3 widths and pops them. Watch the bottom row of each : it should be at default width.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Three Pushes followed by THREE separate Pops ------------------------
_ImGui_CreateText("a_hdr", "(A) Push x3 -> Pop x3 (one Pop per Push, no count fast-path) :")
_ImGui_CreatePushItemWidth("piw_a1", 100.0)
_ImGui_CreatePushItemWidth("piw_a2", 200.0)   ; this one wins (most recent)
_ImGui_CreatePushItemWidth("piw_a3", 300.0)   ; this one wins now
_ImGui_CreateInputText("a_in_top", "##a_top", "topmost push : 300 px", 64, 0)
_ImGui_CreatePopItemWidth("ppw_a3")
_ImGui_CreateInputText("a_in_mid", "##a_mid", "after one Pop : 200 px (was the 2nd push)", 64, 0)
_ImGui_CreatePopItemWidth("ppw_a2")
_ImGui_CreateInputText("a_in_bot", "##a_bot", "after another Pop : 100 px (was the 1st push)", 64, 0)
_ImGui_CreatePopItemWidth("ppw_a1")
_ImGui_CreateInputText("a_in_end", "##a_end", "after final Pop : default width", 64, 0)
_ImGui_CreateSeparator("sep_a")

; --- (B) Canonical idiom : Push once at top, Pop once at bottom of block -----
_ImGui_CreateText("b_hdr", "(B) Canonical idiom : single Push at top, single Pop at bottom, all widgets share the width :")
_ImGui_CreatePushItemWidth("piw_b", 220.0)
_ImGui_CreateInputText("b_in1", "##b1", "shared width : 220 px", 64, 0)
_ImGui_CreateInputText("b_in2", "##b2", "shared width : 220 px", 64, 0)
_ImGui_CreateSliderFloat("b_sl", "##b_sl", 0.0, 1.0, 0.5, "%.2f")
_ImGui_CreateInputText("b_in3", "##b3", "shared width : 220 px", 64, 0)
_ImGui_CreatePopItemWidth("ppw_b")
_ImGui_CreateInputText("b_after", "##b_after", "default width (after one Pop)", 64, 0)
_ImGui_CreateSeparator("sep_b")

; --- (C) Reminder : NO counted Pop for item width ----------------------------
_ImGui_CreateText("c_hdr", "(C) Reminder : NO PopItemWidth($iCount) overload exists.")
_ImGui_CreateText("c_hint1","    PopStyleColor / PopStyleVar accept $iCount. PopItemWidth does NOT.")
_ImGui_CreateText("c_hint2","    Calling PopItemWidth 3 times to undo 3 Pushes is the only option here.")
_ImGui_CreateSeparator("sep_c")

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
