#cs
================================================================================
 Example 72 : _ImGui_CreatePopStyleColor
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePopStyleColor   Pop one or more color overrides off the stack

 PopStyleColor removes the topmost N color overrides from the style
 stack, restoring whatever was there before the matching pushes. The
 $iCount argument makes a single call equivalent to N individual pops
 -- useful (and idiomatic) when you pushed several colors at the start
 of a section and want to pop them all at once at the end.

 Pairing rule (same as Indent/Unindent and Push/PopStyleVar) :
   - The total number of pops MUST match the total number of pushes,
     globally, across all sections.
   - An over-pop or under-pop silently drifts the style for every
     widget added later. The wrapper does not enforce balancing.

 This file focuses on Pop, especially the $iCount fast-path. Pushes
 are included as supporting setup ; see exemple71 for the Push side.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple72_popstylecolor.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple72_popstylecolor.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 72 : _ImGui_CreatePopStyleColor", 620, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePopStyleColor  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePopStyleColor($sId, $iCount = 1)
;
;   $iCount : number of style colors to pop, default 1. Pass the same
;             value as the number of pushes you want to balance in this
;             call. Out-of-range counts (e.g. popping more than was
;             pushed) cause the underlying ImGui stack to underflow --
;             ImGui will assert in debug builds, undefined in release.
;
;   Stack semantics : pops act in reverse push order. The most recent
;   Push is undone first.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three Pop patterns side by side : individual pops,
;                  one counted pop, and a "push 5 / pop 5" stress test.
; ==============================================================================
_ImGui_CreateText("t_title", "PopStyleColor demo  --  individual pops vs the $iCount fast-path")
_ImGui_CreateText("t_hint",  "All three sections push 5 colors in total. The Pop strategy differs ; the visual result is identical.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Individual Pops (5 calls of count=1) --------------------------------
_ImGui_CreateText("a_hdr", "(A) 5 Pushes balanced by 5 individual Pops (count=1 each) :")
_ImGui_CreatePushStyleColor("psc_a1", $ImGuiCol_Button,        0.70, 0.20, 0.20, 1.0)
_ImGui_CreatePushStyleColor("psc_a2", $ImGuiCol_ButtonHovered, 0.85, 0.30, 0.30, 1.0)
_ImGui_CreatePushStyleColor("psc_a3", $ImGuiCol_ButtonActive,  1.00, 0.40, 0.40, 1.0)
_ImGui_CreatePushStyleColor("psc_a4", $ImGuiCol_Text,          1.00, 1.00, 1.00, 1.0)
_ImGui_CreatePushStyleColor("psc_a5", $ImGuiCol_FrameBg,       0.20, 0.10, 0.10, 1.0)
_ImGui_CreateButton("a_b", "Styled button (5 overrides active)")
; -- 5 individual pops --
_ImGui_CreatePopStyleColor("ppc_a1", 1)
_ImGui_CreatePopStyleColor("ppc_a2", 1)
_ImGui_CreatePopStyleColor("ppc_a3", 1)
_ImGui_CreatePopStyleColor("ppc_a4", 1)
_ImGui_CreatePopStyleColor("ppc_a5", 1)
_ImGui_CreateButton("a_after", "Default theme button (after 5 individual pops)")
_ImGui_CreateSeparator("sep_a")

; --- (B) Single counted Pop (one call with count=5) --------------------------
_ImGui_CreateText("b_hdr", "(B) Same 5 Pushes balanced by ONE PopStyleColor(count=5) :")
_ImGui_CreatePushStyleColor("psc_b1", $ImGuiCol_Button,        0.20, 0.20, 0.70, 1.0)
_ImGui_CreatePushStyleColor("psc_b2", $ImGuiCol_ButtonHovered, 0.30, 0.30, 0.85, 1.0)
_ImGui_CreatePushStyleColor("psc_b3", $ImGuiCol_ButtonActive,  0.40, 0.40, 1.00, 1.0)
_ImGui_CreatePushStyleColor("psc_b4", $ImGuiCol_Text,          1.00, 1.00, 1.00, 1.0)
_ImGui_CreatePushStyleColor("psc_b5", $ImGuiCol_FrameBg,       0.10, 0.10, 0.20, 1.0)
_ImGui_CreateButton("b_b", "Styled button (5 overrides active)")
_ImGui_CreatePopStyleColor("ppc_b_all", 5)   ; -- one counted pop --
_ImGui_CreateButton("b_after", "Default theme button (after PopStyleColor(5))")
_ImGui_CreateSeparator("sep_b")

; --- (C) Stress test : push many, pop many ----------------------------------
_ImGui_CreateText("c_hdr", "(C) Stack stress test : 8 Pushes followed by Pop(8) :")
_ImGui_CreatePushStyleColor("psc_c1", $ImGuiCol_Text,          1.0, 0.95, 0.20, 1.0)
_ImGui_CreatePushStyleColor("psc_c2", $ImGuiCol_Button,        0.20, 0.70, 0.20, 1.0)
_ImGui_CreatePushStyleColor("psc_c3", $ImGuiCol_ButtonHovered, 0.30, 0.85, 0.30, 1.0)
_ImGui_CreatePushStyleColor("psc_c4", $ImGuiCol_ButtonActive,  0.40, 1.00, 0.40, 1.0)
_ImGui_CreatePushStyleColor("psc_c5", $ImGuiCol_FrameBg,       0.05, 0.20, 0.05, 1.0)
_ImGui_CreatePushStyleColor("psc_c6", $ImGuiCol_FrameBgHovered,0.10, 0.30, 0.10, 1.0)
_ImGui_CreatePushStyleColor("psc_c7", $ImGuiCol_CheckMark,     1.00, 0.80, 0.30, 1.0)
_ImGui_CreatePushStyleColor("psc_c8", $ImGuiCol_Border,        0.40, 0.80, 0.40, 1.0)
_ImGui_CreateButton("c_b1", "Styled button (8 overrides active)")
_ImGui_CreateCheckbox("c_cb", "Styled checkbox", True)
_ImGui_CreatePopStyleColor("ppc_c_all", 8)
_ImGui_CreateButton("c_after", "Default theme (after Pop(8))")
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
