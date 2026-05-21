#cs
================================================================================
 Example 50 : _ImGui_CreateTextWrapped
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateTextWrapped   Text label that wraps at the available width

 TextWrapped lets ImGui break the text into multiple visual lines so it
 fits the current available width (window minus left margin minus right
 padding). When the window is resized, the layout reflows automatically
 on the next frame.

 Plain Text by contrast renders on a single line and lets the text run
 outside the window (clipped). Use TextWrapped whenever you display a
 paragraph, a description, or any user-supplied string that might be
 long.

 Update content via _ImGui_SetText. The new content wraps automatically.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple50_textwrapped.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple50_textwrapped.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 50 : _ImGui_CreateTextWrapped", 560, 420) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateTextWrapped  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateTextWrapped($sId, $sText)
;
;   Word-wrapped text. The visual layout adapts to the current available
;   width on each frame -- resize the window and the paragraph reflows.
;
;   Wrap respects whitespace (spaces, tabs, newlines). Embedded '\n' in
;   the source string produces a hard line break.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  one fixed long paragraph + one runtime-mutable paragraph
; ==============================================================================
_ImGui_CreateText("t_title", "TextWrapped demo  --  paragraphs that reflow on resize")
_ImGui_CreateText("t_hint",  "Resize the window horizontally to see the paragraph re-wrap on every frame.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_a_hdr", "Plain Text below (single line, clips on the right) :")
_ImGui_CreateText("t_a",      "Plain Text always renders on a single line even when there is more text than the available width. This sentence is long enough to demonstrate that.")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_b_hdr", "TextWrapped below (re-flows on the same content) :")
_ImGui_CreateTextWrapped("t_b", _
    "TextWrapped breaks at word boundaries so the same long paragraph stays " & _
    "fully visible inside the window. Try resizing the window horizontally -- " & _
    "the layout updates on every frame. Embedded newlines like" & @CRLF & _
    "this one start a fresh visual line.")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_c_hdr", "Mutable TextWrapped (driven by buttons via SetText) :")
_ImGui_CreateTextWrapped("t_c", "Click a button below to replace this paragraph.")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_lorem",  "Set to lorem-ipsum (~3 sentences)")
_ImGui_CreateButton("btn_oneword","Set to one very long unbreakable token")
_ImGui_CreateButton("btn_short",  "Set to a short one-line sentence")
_ImGui_CreateButton("btn_quit",   "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_lorem",   "_OnLorem")
_ImGui_SetOnClick("btn_oneword", "_OnOneWord")
_ImGui_SetOnClick("btn_short",   "_OnShort")
_ImGui_SetOnClick("btn_quit",    "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnLorem($sId)
    _ImGui_SetText("t_c", _
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do " & _
        "eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut " & _
        "enim ad minim veniam, quis nostrud exercitation ullamco laboris.")
EndFunc

Func _OnOneWord($sId)
    ; One very long alphanumeric run with no whitespace -- the wrap algo has
    ; no break points, so this typically overflows the available width.
    _ImGui_SetText("t_c", "ThisIsAVeryLongUnbreakableTokenThatHasNoWhitespaceAnywhereInsideOfItAndWillProbablyOverflowTheAvailableWidth")
EndFunc

Func _OnShort($sId)
    _ImGui_SetText("t_c", "A short one-line sentence -- no wrap needed.")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
