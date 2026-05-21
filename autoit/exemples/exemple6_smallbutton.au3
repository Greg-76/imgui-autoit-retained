#cs
================================================================================
 Example 6 : _ImGui_CreateSmallButton
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateSmallButton    Compact button with no vertical padding

 SmallButton is identical to Button (see exemple5_button.au3 for the click
 semantics) but skips the vertical FramePadding. It is meant to be used
 inline inside a sentence -- the height matches a regular Text widget so
 the layout flows naturally.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple6_smallbutton.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple6_smallbutton.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init  --  see exemple1_init_shutdown.au3 -----------------------------
If Not _ImGui_Init("Example 6 : _ImGui_CreateSmallButton", 560, 280) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSmallButton  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSmallButton($sId, $sLabel = "")
;
;   Same as _ImGui_CreateButton but with zero vertical FramePadding ; the
;   button height matches the current font line height instead of being
;   inflated by the regular button padding.
;
;   Typical use : a clickable word inside a paragraph of text, an inline
;   "[X] close" affordance, action chips, etc.
;
;   Click semantics (OnClick, ID uniqueness, no programmatic click API) :
;   see exemple5_button.au3 for the detailed reference doc block.
;
;   Return : True on success, False on failure (@error = 1 not initialised,
;   2 duplicate id, 3 DllCall failed).


; ==============================================================================
; Demo widgets
; ==============================================================================
_ImGui_CreateText("t_title", "SmallButton demo")
_ImGui_CreateText("t_hint1", "Notice how the buttons below sit flush with the surrounding text")
_ImGui_CreateText("t_hint2", "instead of pushing their lines taller, the way a regular Button would.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateSmallButton("btn_a", "[A]")
_ImGui_CreateSmallButton("btn_b", "[B]")
_ImGui_CreateSmallButton("btn_c", "[C]")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_last", "Last clicked : (none yet)")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_a",    "_OnDemoClicked")
_ImGui_SetOnClick("btn_b",    "_OnDemoClicked")
_ImGui_SetOnClick("btn_c",    "_OnDemoClicked")
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------
Func _OnDemoClicked($sId)
    _ImGui_SetText("t_last", "Last clicked : " & $sId)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
