#cs
================================================================================
 Example 190 : _ImGui_CreateShowUserGuide
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateShowUserGuide   Static help block listing ImGui's
                                built-in keyboard / mouse shortcuts

 Zero-argument widget : no events, no value to update -- just a
 read-only block of text rendered by ImGui. Typical placement :
 inside an About / Help / Tutorial sub-window.

 What ImGui's user guide includes (verbatim from imgui.cpp ShowUserGuide) :
   * Double-click on title bar to collapse window.
   * Click and drag on lower corner to resize window.
   * Click and drag on any empty space to move window.
   * TAB / SHIFT+TAB to cycle through keyboard editable fields.
   * CTRL+Click on a slider or drag box to input value as text.
   * Hold SHIFT/ALT for faster/slower edit.
   * Double-click or CTRL+Click on a slider to input value as text.
   * While inputing text :
     - CTRL+Left/Right to word jump.
     - CTRL+A or double-click to select all.
     - CTRL+X/C/V to use clipboard cut/copy/paste.
     - CTRL+Z, CTRL+Y to undo/redo.
     - ESCAPE to revert.

 Combine with CreateShowStyleSelector / CreateShowFontSelector for
 a complete About panel. exemple190 packages the guide alongside a
 lightweight set of sample widgets that ARE responsive to those
 keyboard shortcuts, so the reader can try them live.

 Borrowed widgets : SliderFloat, InputText, Text + Separator, Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple190_showuserguide.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple190_showuserguide.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 190 : ShowUserGuide", 720, 620) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateShowUserGuide  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateShowUserGuide($sId)
;
;   $sId : stable widget identifier.
;
;   Return : True on success, False on failure (@error = 1, 2).
;
;   Zero-arg, zero-event. Pure rendered text block. Place it wherever
;   you want the help cheatsheet to appear (sub-window, MainMenuBar
;   dropdown body, popup, etc.).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "ShowUserGuide demo  --  ImGui's built-in keyboard / mouse cheatsheet")
_ImGui_CreateText("t_hint",  "The block below is rendered entirely by ImGui ; try the shortcuts on the widgets at the bottom.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; The widget itself
; ==============================================================================
_ImGui_CreateShowUserGuide("guide_block")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Live test bed  --  try the shortcuts on these
; ==============================================================================
_ImGui_CreateText("t_test_hdr", "Test the shortcuts below :")
_ImGui_CreateSliderFloat("sl_test", "Ctrl+Click me to type a value", 0.0, 100.0, 50.0, "%.2f")
_ImGui_CreateInputText("in_test", "Tab into me, try Ctrl+A/C/V/Z", "edit me", 256)
_ImGui_CreateInputText("in_test2", "Tab cycles fields", "and me too", 256)
_ImGui_CreateText("t_collapse_hint", "Double-click the title bar of this window to collapse it.")
_ImGui_CreateSeparator("sep2")

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
