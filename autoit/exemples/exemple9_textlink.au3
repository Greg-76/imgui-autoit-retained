#cs
================================================================================
 Example 9 : _ImGui_CreateTextLink
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateTextLink    Inline clickable text styled as a hyperlink

 TextLink looks like a hyperlink (underlined accent color, hand cursor on
 hover) but does NOT open anything by itself. The click is detected via
 OnClick exactly like a regular Button -- you decide what to do with it.

 For a TextLink that actually launches a URL via the OS, see
 exemple10_textlinkopenurl.au3.

 Click semantics (OnClick, ID uniqueness) : see exemple5_button.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple9_textlink.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple9_textlink.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 9 : _ImGui_CreateTextLink", 560, 320) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateTextLink  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateTextLink($sId, $sLabel = "")
;
;   Renders $sLabel as a clickable hyperlink-styled span : ImGui's text-link
;   accent color, optionally underlined when hovered, hand-cursor on hover.
;
;   The widget itself does nothing on click -- it only LATCHES the click,
;   which OnClick / WasClicked then surfaces. Use this when you want the
;   visual cue of a hyperlink (e.g. "What does this mean ?") but the action
;   is local -- show a modal, scroll to another section, etc.
;
;   Click semantics : see exemple5_button.au3.
;
;   Return : True on success, False on failure (@error = 1 not initialised,
;   2 duplicate id, 3 DllCall failed).


; ==============================================================================
; Demo widgets  --  three TextLinks that do different local actions
; ==============================================================================
_ImGui_CreateText("t_title", "TextLink demo")
_ImGui_CreateText("t_hint1", "Three hyperlink-styled spans. None of them opens a URL --")
_ImGui_CreateText("t_hint2", "the script reacts to each click and updates the message below.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateTextLink("lnk_help",  "(?) what is retained mode")
_ImGui_CreateTextLink("lnk_about", "About this example")
_ImGui_CreateTextLink("lnk_reset", "Reset the message")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_msg", "Click a link above.")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("lnk_help",  "_OnLinkClicked")
_ImGui_SetOnClick("lnk_about", "_OnLinkClicked")
_ImGui_SetOnClick("lnk_reset", "_OnLinkClicked")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------
Func _OnLinkClicked($sId)
    Switch $sId
        Case "lnk_help"
            _ImGui_SetText("t_msg", "Retained mode = widgets persist between frames. The script never re-creates them.")
        Case "lnk_about"
            _ImGui_SetText("t_msg", "This example showcases _ImGui_CreateTextLink. No URL is opened.")
        Case "lnk_reset"
            _ImGui_SetText("t_msg", "Click a link above.")
    EndSwitch
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
