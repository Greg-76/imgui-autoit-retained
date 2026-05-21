#cs
================================================================================
 Example 49 : _ImGui_CreateTextDisabled
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateTextDisabled   Text label rendered with the disabled-style color

 TextDisabled is a Text widget that picks its color from the current
 ImGui style's $ImGuiCol_TextDisabled slot -- typically a desaturated
 grey. Useful for : grey-out hints, secondary captions, "(optional)"
 labels, breadcrumbs of inactive steps.

 Unlike TextColored, the color is NOT hard-coded by the script -- it
 tracks the current style. If the user changes the style at runtime
 (light vs dark theme), TextDisabled labels follow automatically.

 Update content via _ImGui_SetText.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple49_textdisabled.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple49_textdisabled.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 49 : _ImGui_CreateTextDisabled", 620, 360) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateTextDisabled  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateTextDisabled($sId, $sText)
;
;   Plain Text widget that uses the current style's $ImGuiCol_TextDisabled
;   color slot. No RGBA arguments -- the color is decided by ImGui style,
;   not by the script. Theme-aware by construction.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  contrast pair (normal vs disabled) + a runtime-updated one
; ==============================================================================
_ImGui_CreateText("t_title", "TextDisabled demo  --  greyed-out hint text driven by the current style")
_ImGui_CreateText("t_hint",  "Compare the rendering of plain Text vs TextDisabled below.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_normal", "Plain Text -- full opacity, default color")
_ImGui_CreateTextDisabled("t_dim", "TextDisabled -- greyed out, secondary importance")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_hdr_caption", "Typical use : optional / secondary captions")
_ImGui_CreateText("t_email_lbl",  "Email address")
_ImGui_CreateTextDisabled("t_email_hint", "(optional -- leave blank to skip notifications)")
_ImGui_CreateText("t_phone_lbl",  "Phone number")
_ImGui_CreateTextDisabled("t_phone_hint", "(format : +CC followed by digits, e.g. +33 1 23 45 67 89)")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_h1", "Set the hint to ""(required field)""")
_ImGui_CreateButton("btn_h2", "Set the hint to ""(coming soon)""")
_ImGui_CreateButton("btn_h3", "Restore default hint")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit","Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_h1",  "_OnHint1")
_ImGui_SetOnClick("btn_h2",  "_OnHint2")
_ImGui_SetOnClick("btn_h3",  "_OnHint3")
_ImGui_SetOnClick("btn_quit","_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnHint1($sId)
    _ImGui_SetText("t_email_hint", "(required field)")
EndFunc

Func _OnHint2($sId)
    _ImGui_SetText("t_email_hint", "(coming soon)")
EndFunc

Func _OnHint3($sId)
    _ImGui_SetText("t_email_hint", "(optional -- leave blank to skip notifications)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
