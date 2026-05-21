#cs
================================================================================
 Example 68 : _ImGui_CreateUnindent
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateUnindent   Pull the cursor left by an indent width

 Unindent is the inverse of Indent (exemple67). Each Unindent shifts
 the left margin back by $fIndentW pixels (or the default
 IndentSpacing if 0 is passed). Indent and Unindent must be paired :

     - One Indent  followed by one Unindent  = back to origin
     - Two Indents followed by one Unindent  = still indented by one
     - One Indent  followed by two Unindents = SHIFTED LEFT past the
       window edge (everything after that scrolls or clips)

 PITFALL : unbalanced Indent/Unindent silently drifts the layout for
 every later widget in the window. There is no warning. Always pair
 them ; if you mix custom widths, use the SAME width on both sides of
 the pair, or the drift accumulates float by float.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple68_unindent.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple68_unindent.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 68 : _ImGui_CreateUnindent", 620, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateUnindent  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateUnindent($sId, $fIndentW = 0.0)
;
;   $fIndentW : amount to shift back, in pixels. 0 = the same default
;               as Indent (~21 px on the dark theme).
;
;   Mirror of _ImGui_CreateIndent. Pair them carefully -- the wrapper
;   does NOT enforce balancing.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three sections : balanced (correct), missing Unindent
;                  (drift right), and extra Unindent (drift left).
; ==============================================================================
_ImGui_CreateText("t_title", "Unindent demo  --  the pairing rule, with visible drift if you break it")
_ImGui_CreateText("t_hint",  "Section A shows the correct pairing. B intentionally leaves Indent open. C intentionally adds an extra Unindent.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Balanced : 1 Indent / 1 Unindent ------------------------------------
_ImGui_CreateText("a_hdr",  "(A) Balanced :")
_ImGui_CreateText("a_pre",  "  Before Indent : on the left edge")
_ImGui_CreateIndent("ind_a")
_ImGui_CreateText("a_in",   "  After Indent  : pushed right")
_ImGui_CreateUnindent("uni_a")
_ImGui_CreateText("a_post", "  After matching Unindent : back on the left edge")
_ImGui_CreateSeparator("sep_a")

; --- (B) Indent without Unindent -- intentional drift ------------------------
_ImGui_CreateText("b_hdr",  "(B) ! Missing Unindent (everything after stays shifted right) :")
_ImGui_CreateText("b_pre",  "  Before Indent : on the left edge")
_ImGui_CreateIndent("ind_b")
_ImGui_CreateText("b_in",   "  After Indent  : pushed right (no Unindent paired)")
; -- no Unindent here on purpose --
; FIX THE DRIFT explicitly so the rest of this script does not stay shifted.
_ImGui_CreateUnindent("uni_b_fix")
_ImGui_CreateText("b_fix",  "  (recovered by a corrective Unindent in the demo script)")
_ImGui_CreateSeparator("sep_b")

; --- (C) Unindent without Indent -- drift left -------------------------------
_ImGui_CreateText("c_hdr",  "(C) ! Extra Unindent (everything after drifts left, possibly off-window) :")
_ImGui_CreateText("c_pre",  "  Before stray Unindent : on the left edge")
_ImGui_CreateUnindent("uni_c_stray", 30.0)
_ImGui_CreateText("c_post", "  After stray Unindent  : visibly shifted LEFT (may clip)")
; Recover so the bottom of the demo is readable.
_ImGui_CreateIndent("ind_c_fix", 30.0)
_ImGui_CreateText("c_fix",  "  (recovered by a corrective Indent in the demo script)")
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
