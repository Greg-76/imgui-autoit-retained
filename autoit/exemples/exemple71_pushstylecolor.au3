#cs
================================================================================
 Example 71 : _ImGui_CreatePushStyleColor
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePushStyleColor   Push a color override onto the style stack

 PushStyleColor temporarily replaces ONE of the 63 named slots of the
 ImGui color theme ($ImGuiCol_Text, $ImGuiCol_Button, etc.). The
 override stays active for every widget added to the tree until a
 matching PopStyleColor pops it back (exemple72).

 Push/Pop MUST be balanced. An extra Push without matching Pop bleeds
 the override into the rest of the window. Same silent-drift trap as
 Indent/Unindent (exemple67/68).

 This file focuses on Push : it demonstrates several color overrides
 and ALWAYS includes the matching PopStyleColor immediately after.
 The PopStyleColor is incidental supporting code here ; see
 exemple72 for the Pop side, including the $iCount fast-path.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple71_pushstylecolor.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple71_pushstylecolor.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 71 : _ImGui_CreatePushStyleColor", 620, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePushStyleColor  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePushStyleColor($sId, $iCol = 0,
;                                          $fR = 1.0, $fG = 1.0,
;                                          $fB = 1.0, $fA = 1.0)
;
;   $iCol  : one of the $ImGuiCol_* constants (0..62). Sentinel
;            $ImGuiCol_COUNT (63) is INVALID. Common targets :
;              $ImGuiCol_Text         = 0
;              $ImGuiCol_Button       = 22
;              $ImGuiCol_ButtonHovered= 23
;              $ImGuiCol_ButtonActive = 24
;              $ImGuiCol_FrameBg      = 7
;              $ImGuiCol_Header       = 25
;
;   $fR / $fG / $fB / $fA : color components in [0.0, 1.0].
;
;   Stack semantics : each Push adds one frame to the stack. The
;   override applies to all subsequent widgets until a matching
;   PopStyleColor removes that frame. Stacks can nest -- the innermost
;   override wins for a given slot.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  four sections, each pushing a different style color
;                  and popping it before moving on
; ==============================================================================
_ImGui_CreateText("t_title", "PushStyleColor demo  --  per-slot color overrides")
_ImGui_CreateText("t_hint",  "Each section pushes one color, draws a few widgets, then pops it. Compare the styled blocks against the default-themed sentinel widgets between them.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Push Button color = red ---------------------------------------------
_ImGui_CreateText("a_hdr", "(A) PushStyleColor(Button, red 0.8/0.2/0.2/1.0) :")
_ImGui_CreatePushStyleColor("psc_a", $ImGuiCol_Button, 0.80, 0.20, 0.20, 1.0)
_ImGui_CreateButton("a_b1", "I am red")
_ImGui_CreateButton("a_b2", "Me too")
_ImGui_CreatePopStyleColor("ppc_a", 1)
_ImGui_CreateButton("a_b3", "I am the default theme again (Pop happened)")
_ImGui_CreateSeparator("sep_a")

; --- (B) Push Text color = yellow --------------------------------------------
_ImGui_CreateText("b_hdr", "(B) PushStyleColor(Text, yellow 1.0/0.95/0.2/1.0) -- affects Text + Button label :")
_ImGui_CreatePushStyleColor("psc_b", $ImGuiCol_Text, 1.0, 0.95, 0.20, 1.0)
_ImGui_CreateText("b_t1",  "Plain Text now rendered in yellow")
_ImGui_CreateButton("b_btn","Button caption is also yellow")
_ImGui_CreatePopStyleColor("ppc_b", 1)
_ImGui_CreateText("b_t2",  "Default Text color is back")
_ImGui_CreateSeparator("sep_b")

; --- (C) Push FrameBg + FrameBgHovered ---------------------------------------
_ImGui_CreateText("c_hdr", "(C) Push two slots in one section (FrameBg + FrameBgHovered) :")
_ImGui_CreatePushStyleColor("psc_c1", $ImGuiCol_FrameBg,        0.10, 0.30, 0.10, 1.0)
_ImGui_CreatePushStyleColor("psc_c2", $ImGuiCol_FrameBgHovered, 0.20, 0.55, 0.20, 1.0)
_ImGui_CreateCheckbox("c_cb1", "Green checkbox background", False)
_ImGui_CreateCheckbox("c_cb2", "Hover me to see the brighter green", False)
_ImGui_CreatePopStyleColor("ppc_c", 2)   ; pop BOTH in one call -- see exemple72
_ImGui_CreateCheckbox("c_cb3", "Default-themed checkbox (after Pop count=2)", False)
_ImGui_CreateSeparator("sep_c")

; --- (D) Nested pushes : inner override wins ----------------------------------
_ImGui_CreateText("d_hdr", "(D) Nested PushStyleColor : inner overrides win for the same slot :")
_ImGui_CreatePushStyleColor("psc_d1", $ImGuiCol_Button, 0.20, 0.20, 0.70, 1.0)   ; blue
_ImGui_CreateButton("d_b1", "Outer scope : I am blue")
_ImGui_CreatePushStyleColor("psc_d2", $ImGuiCol_Button, 0.20, 0.70, 0.20, 1.0)   ; green
_ImGui_CreateButton("d_b2", "Inner scope : I am green (overrides outer)")
_ImGui_CreatePopStyleColor("ppc_d2", 1)
_ImGui_CreateButton("d_b3", "Back to outer scope : blue again")
_ImGui_CreatePopStyleColor("ppc_d1", 1)
_ImGui_CreateButton("d_b4", "Both pops done : default theme")
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
