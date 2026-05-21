#cs
================================================================================
 Example 64 : _ImGui_CreateSpacing
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateSpacing   Insert a small vertical gap

 Spacing is the smallest of the three vertical-gap markers :

     Spacing  --  ~ItemSpacing.y pixels of vertical advance, no line
     NewLine  --  one full line height (frame-padded)
     Separator -- gap + a drawn horizontal line

 Spacing is the right choice when you want to "breathe" a bit between
 two visual groups WITHOUT drawing a divider and WITHOUT creating a
 fully empty row. Multiple Spacings can be chained to widen the gap.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple64_spacing.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple64_spacing.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 64 : _ImGui_CreateSpacing", 560, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSpacing  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSpacing($sId)
;
;   Advances the cursor by ItemSpacing.y of the current style (no drawn
;   content). Chain several Spacings if you want a wider gap.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  four sections : no gap / Spacing / NewLine / Separator,
;                  with a triple-Spacing variant to show stacking.
; ==============================================================================
_ImGui_CreateText("t_title", "Spacing demo  --  vertical gap intensity ladder")
_ImGui_CreateText("t_hint",  "Compare the four gap mechanisms below. From tightest to loosest : nothing, Spacing, NewLine, Separator.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Two buttons with NOTHING between them -------------------------------
_ImGui_CreateText("a_hdr", "(A) No gap at all :")
_ImGui_CreateButton("a_b1", "Above")
_ImGui_CreateButton("a_b2", "Below (tight default spacing only)")
_ImGui_CreateSeparator("sep_a")

; --- (B) Two buttons with ONE Spacing between them ---------------------------
_ImGui_CreateText("b_hdr", "(B) One _ImGui_CreateSpacing between them :")
_ImGui_CreateButton("b_b1", "Above")
_ImGui_CreateSpacing("sp_b")
_ImGui_CreateButton("b_b2", "Below (one Spacing inserted)")
_ImGui_CreateSeparator("sep_b")

; --- (C) Two buttons with THREE Spacings between them ------------------------
_ImGui_CreateText("c_hdr", "(C) Three Spacings stacked (wider gap, still no rule) :")
_ImGui_CreateButton("c_b1", "Above")
_ImGui_CreateSpacing("sp_c1")
_ImGui_CreateSpacing("sp_c2")
_ImGui_CreateSpacing("sp_c3")
_ImGui_CreateButton("c_b2", "Below (three Spacings inserted)")
_ImGui_CreateSeparator("sep_c")

; --- (D) NewLine for comparison ----------------------------------------------
_ImGui_CreateText("d_hdr", "(D) One NewLine for comparison :")
_ImGui_CreateButton("d_b1", "Above")
_ImGui_CreateNewLine("nl_d")
_ImGui_CreateButton("d_b2", "Below (one NewLine inserted)")
_ImGui_CreateSeparator("sep_d")

; --- (E) Separator for comparison --------------------------------------------
_ImGui_CreateText("e_hdr", "(E) One Separator for comparison :")
_ImGui_CreateButton("e_b1", "Above")
_ImGui_CreateSeparator("sep_e_inline")
_ImGui_CreateButton("e_b2", "Below (one Separator inserted)")
_ImGui_CreateSeparator("sep_e")

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
