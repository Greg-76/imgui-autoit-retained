#cs
================================================================================
 Example 62 : _ImGui_CreateSeparator
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateSeparator   Insert a horizontal divider line

 Separator is the simplest of all layout markers : it adds a thin
 horizontal rule across the available width at the current cursor
 position, then advances the cursor below it. No text, no parameters,
 no interaction.

 It is the "widget" you have been seeing in every other example as
 `_ImGui_CreateSeparator("sepN")` -- this file finally documents it.

 If you want a labelled divider (a section title embedded in the line),
 use _ImGui_CreateSeparatorText instead (exemple53).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple62_separator.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple62_separator.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 62 : _ImGui_CreateSeparator", 560, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSeparator  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSeparator($sId)
;
;   No visible content other than the line itself. The cursor is
;   advanced down by ImGui's default item spacing afterwards.
;
;   The $sId must still be unique in the tree -- separators are added
;   to the widget tree like any other widget. Conventionally named
;   `sepN` (sep1, sep2, ...) but any unique string works.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three sections side by side : no-separator / separator / mixed
; ==============================================================================
_ImGui_CreateText("t_title", "Separator demo  --  visual contrast of three layouts")
_ImGui_CreateText("t_hint",  "Compare how the same widgets feel with no separator, with separators between sections, and with separators inside groups.")
_ImGui_CreateSeparator("sep_intro")

; --- Layout A : NO separator between items -----------------------------------
_ImGui_CreateText("a_hdr",  "(A) Three buttons WITHOUT any separator between them :")
_ImGui_CreateButton("a_b1", "Cancel")
_ImGui_CreateButton("a_b2", "Apply")
_ImGui_CreateButton("a_b3", "OK")

; --- Layout B : separator between EACH item ----------------------------------
_ImGui_CreateText("b_hdr", "(B) Same three buttons WITH a separator between each :")
_ImGui_CreateButton("b_b1", "Cancel")
_ImGui_CreateSeparator("sep_b1")
_ImGui_CreateButton("b_b2", "Apply")
_ImGui_CreateSeparator("sep_b2")
_ImGui_CreateButton("b_b3", "OK")

_ImGui_CreateSeparator("sep_b_end")

; --- Layout C : real-world mixed layout --------------------------------------
_ImGui_CreateText("c_hdr", "(C) Mixed widgets, separators delimit groups :")

_ImGui_CreateText("c_user_lbl", "Username")
_ImGui_CreateInputText("c_user_in", "##user", "", 64, 0)
_ImGui_CreateText("c_pwd_lbl",  "Password")
_ImGui_CreateInputText("c_pwd_in",  "##pwd",  "", 64, 0)
_ImGui_CreateSeparator("sep_form")

_ImGui_CreateCheckbox("c_remember", "Remember me", False)
_ImGui_CreateCheckbox("c_send_stats","Send anonymous stats", False)
_ImGui_CreateSeparator("sep_opts")

_ImGui_CreateButton("c_login",  "Log in")
_ImGui_CreateButton("c_cancel", "Cancel")
_ImGui_CreateSeparator("sep_actions")

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
