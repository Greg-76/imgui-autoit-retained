#cs
================================================================================
 Example 63 : _ImGui_CreateNewLine
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateNewLine   Force a vertical line break

 NewLine inserts a blank vertical advance equivalent to one line
 height, then resets the cursor to the left edge of the current
 layout. Useful after a chain of SameLine() calls to start a fresh
 row, or to add a deliberate blank line between groups without using
 a Separator (no rule drawn).

 Compared to Spacing (small gap) and Separator (gap + line),
 NewLine sits in the middle : medium vertical gap, no visual line.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple63_newline.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple63_newline.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 63 : _ImGui_CreateNewLine", 560, 420) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateNewLine  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateNewLine($sId)
;
;   Cursor jumps down by one line of vertical space and resets to the
;   left edge. No drawn content.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three rows of inline buttons separated by NewLine
;                  + one comparison block (no NewLine, all SameLine-chained)
; ==============================================================================
_ImGui_CreateText("t_title", "NewLine demo  --  rows separated by an explicit vertical break")
_ImGui_CreateText("t_hint",  "Below : the SameLine chain is broken into three rows by NewLine markers.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_a_hdr", "(A) Three rows with NewLine between each :")
_ImGui_CreateButton("a_r1c1", "Row1.Col1")
_ImGui_CreateSameLine("sl_a_r1_2")
_ImGui_CreateButton("a_r1c2", "Row1.Col2")
_ImGui_CreateSameLine("sl_a_r1_3")
_ImGui_CreateButton("a_r1c3", "Row1.Col3")

_ImGui_CreateNewLine("nl_a_1")

_ImGui_CreateButton("a_r2c1", "Row2.Col1")
_ImGui_CreateSameLine("sl_a_r2_2")
_ImGui_CreateButton("a_r2c2", "Row2.Col2")
_ImGui_CreateSameLine("sl_a_r2_3")
_ImGui_CreateButton("a_r2c3", "Row2.Col3")

_ImGui_CreateNewLine("nl_a_2")

_ImGui_CreateButton("a_r3c1", "Row3.Col1")
_ImGui_CreateSameLine("sl_a_r3_2")
_ImGui_CreateButton("a_r3c2", "Row3.Col2")
_ImGui_CreateSameLine("sl_a_r3_3")
_ImGui_CreateButton("a_r3c3", "Row3.Col3")

_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_b_hdr", "(B) Same widget count WITHOUT NewLine (everything on one logical line, wraps if needed) :")
_ImGui_CreateButton("b_b1", "B1")
_ImGui_CreateSameLine("sl_b_2")
_ImGui_CreateButton("b_b2", "B2")
_ImGui_CreateSameLine("sl_b_3")
_ImGui_CreateButton("b_b3", "B3")
_ImGui_CreateSameLine("sl_b_4")
_ImGui_CreateButton("b_b4", "B4")
_ImGui_CreateSameLine("sl_b_5")
_ImGui_CreateButton("b_b5", "B5")
_ImGui_CreateSameLine("sl_b_6")
_ImGui_CreateButton("b_b6", "B6")
_ImGui_CreateSameLine("sl_b_7")
_ImGui_CreateButton("b_b7", "B7")
_ImGui_CreateSameLine("sl_b_8")
_ImGui_CreateButton("b_b8", "B8")
_ImGui_CreateSameLine("sl_b_9")
_ImGui_CreateButton("b_b9", "B9")

_ImGui_CreateSeparator("sep3")
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
