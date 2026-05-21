#cs
================================================================================
 Example 69 : _ImGui_CreateAlignTextToFramePadding
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateAlignTextToFramePadding   Vertically align next Text to a framed widget

 ImGui framed widgets (Buttons, InputText, Combo, Slider, ...) carry
 a small vertical FramePadding around their baseline. A plain Text
 placed next to a Button via SameLine therefore sits a couple of
 pixels HIGHER than the Button's label, which looks visually misaligned.

 AlignTextToFramePadding fixes this : added BEFORE the Text widget,
 it nudges the cursor down by the current style's FramePadding.y so
 the Text baseline matches the framed widget baseline on the same row.

 Useful for : labels in front of input fields, status text next to
 action buttons, key:value rows mixing Text + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple69_aligntexttoframepadding.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple69_aligntexttoframepadding.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 69 : _ImGui_CreateAlignTextToFramePadding", 620, 460) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateAlignTextToFramePadding  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateAlignTextToFramePadding($sId)
;
;   No parameters. Adds a "next-text-vertical-align" marker to the
;   tree. The NEXT Text-class widget rendered on this row is shifted
;   down by FramePadding.y so its baseline matches framed widgets
;   (Button, InputText, ...) on the same line.
;
;   Effect is one-shot : applies to the next item only, not to later
;   widgets on the same row.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three rows of "Text + Button" : default (misaligned),
;                  aligned (clean), and a longer column-aligned row using
;                  SameLine(.,$fOffsetX) for both axes.
; ==============================================================================
_ImGui_CreateText("t_title", "AlignTextToFramePadding demo  --  fix the Text-next-to-Button vertical offset")
_ImGui_CreateText("t_hint",  "Look carefully at the vertical alignment between Text labels and Button captions on each row.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Default : Text sits 2-3 px above the Button label -------------------
_ImGui_CreateText("a_hdr", "(A) WITHOUT AlignTextToFramePadding (default -- Text appears slightly elevated) :")
_ImGui_CreateText("a_lbl",   "Volume :")
_ImGui_CreateSameLine("sl_a_2")
_ImGui_CreateButton("a_btn", "Set to 50 %%")
_ImGui_CreateSeparator("sep_a")

; --- (B) Fixed : AlignTextToFramePadding before the Text ---------------------
_ImGui_CreateText("b_hdr", "(B) WITH AlignTextToFramePadding before the Text (baseline matches Button caption) :")
_ImGui_CreateAlignTextToFramePadding("a_b_align")
_ImGui_CreateText("b_lbl",   "Volume :")
_ImGui_CreateSameLine("sl_b_2")
_ImGui_CreateButton("b_btn", "Set to 50 %%")
_ImGui_CreateSeparator("sep_b")

; --- (C) Three column-aligned rows with the fix applied ----------------------
_ImGui_CreateText("c_hdr", "(C) Aligned form rows -- AlignTextToFramePadding + SameLine($fOffsetX=140) per row :")

_ImGui_CreateAlignTextToFramePadding("a_c1")
_ImGui_CreateText("c_l1", "Username :")
_ImGui_CreateSameLine("sl_c1", 140.0)
_ImGui_CreateInputText("c_in1", "##user", "alice", 64, 0)

_ImGui_CreateAlignTextToFramePadding("a_c2")
_ImGui_CreateText("c_l2", "Email :")
_ImGui_CreateSameLine("sl_c2", 140.0)
_ImGui_CreateInputText("c_in2", "##email", "alice@example.org", 128, 0)

_ImGui_CreateAlignTextToFramePadding("a_c3")
_ImGui_CreateText("c_l3", "Role :")
_ImGui_CreateSameLine("sl_c3", 140.0)
_ImGui_CreateButton("c_btn3", "Change role...")

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
