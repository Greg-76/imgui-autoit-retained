#cs
================================================================================
 Example 53 : _ImGui_CreateSeparatorText
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateSeparatorText   Horizontal separator with embedded title

 SeparatorText draws a horizontal divider with a centered text inside
 the line, like a section header in a settings dialog. Compared to the
 plain Separator (no text, just a line), it conveys "the following
 widgets belong to <topic>". Compared to a regular Text, it visually
 groups the widgets BELOW it as one logical section.

 Update content via _ImGui_SetText -- the line stays, only the text
 changes.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple53_separatortext.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple53_separatortext.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 53 : _ImGui_CreateSeparatorText", 600, 420) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSeparatorText  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSeparatorText($sId, $sText)
;
;   Horizontal separator with the title $sText embedded at its center.
;   Empty string is legal but produces a plain Separator visually (no
;   text, just the line) -- if that's what you want, prefer the
;   dedicated _ImGui_CreateSeparator widget (no allocated text slot).
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  fake settings dialog laid out with SeparatorText sections
; ==============================================================================
_ImGui_CreateText("t_title", "SeparatorText demo  --  section headers in a settings-like layout")
_ImGui_CreateText("t_hint",  "Buttons at the bottom retitle the first section via SetText.")
_ImGui_CreateSeparator("sep_intro")

; --- Section 1 ---
_ImGui_CreateSeparatorText("sec_general", "General")
_ImGui_CreateCheckbox("g_autosave", "Auto-save every 5 minutes", True)
_ImGui_CreateCheckbox("g_telemetry","Send anonymous telemetry",  False)
_ImGui_CreateCheckbox("g_updates",  "Check for updates at launch", True)

; --- Section 2 ---
_ImGui_CreateSeparatorText("sec_appearance", "Appearance")
_ImGui_CreateCheckbox("a_dark",   "Dark theme", True)
_ImGui_CreateCheckbox("a_compact","Compact spacing", False)

; --- Section 3 ---
_ImGui_CreateSeparatorText("sec_advanced", "Advanced")
_ImGui_CreateCheckbox("x_log_verbose", "Verbose logging",          False)
_ImGui_CreateCheckbox("x_debug_alloc", "Debug memory allocations", False)

; --- Footer ---
_ImGui_CreateSeparatorText("sec_actions", "Actions")
_ImGui_CreateButton("btn_retitle1", "Rename ""General"" -> ""Behavior""")
_ImGui_CreateButton("btn_retitle2", "Rename ""General"" -> ""Settings (basic)""")
_ImGui_CreateButton("btn_retitle3", "Restore ""General""")
_ImGui_CreateButton("btn_quit",     "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_retitle1", "_OnTitle1")
_ImGui_SetOnClick("btn_retitle2", "_OnTitle2")
_ImGui_SetOnClick("btn_retitle3", "_OnTitle3")
_ImGui_SetOnClick("btn_quit",     "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnTitle1($sId)
    _ImGui_SetText("sec_general", "Behavior")
EndFunc

Func _OnTitle2($sId)
    _ImGui_SetText("sec_general", "Settings (basic)")
EndFunc

Func _OnTitle3($sId)
    _ImGui_SetText("sec_general", "General")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
