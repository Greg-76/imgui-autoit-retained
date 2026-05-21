#cs
================================================================================
 Example 47 : _ImGui_CreateText + _ImGui_SetText
================================================================================
 Covers 2 exports of imgui_autoit.dll :

   _ImGui_CreateText    Create a plain text label
   _ImGui_SetText       Replace the text content at runtime

 These two are the workhorses behind every readout, status line, and
 dynamic label in every other example. They've been used everywhere up
 to now without a dedicated file -- this is that dedicated file.

 _ImGui_SetText is GENERIC : the SAME function updates plain Text,
 TextColored, TextDisabled, TextWrapped, BulletText, SeparatorText, and
 the value half of LabelText. One setter for all six text variants.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple47_createtext.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple47_createtext.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 47 : _ImGui_CreateText + _ImGui_SetText", 600, 360) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateText  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateText($sId, $sText = "")
;
;   Adds a plain, non-interactive text label. UTF-8 is supported. An
;   empty $sText is legal -- the widget renders nothing but stays in the
;   tree, ready to be filled by _ImGui_SetText.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; _ImGui_SetText  --  doc block
; ==============================================================================
; Signature : _ImGui_SetText($sId, $sText)
;
;   Replaces the text content of an existing text-family widget. The
;   widget keeps its id, position, and style ; only the displayed
;   string changes. UTF-8 supported, empty string clears the label.
;
;   Generic : works on plain Text (created with _ImGui_CreateText),
;   TextColored, TextDisabled, TextWrapped, BulletText, SeparatorText,
;   and the value part of LabelText.
;
;   Return : True on success, False on failure (@error same as above).


; ==============================================================================
; Demo widgets  --  static labels + one mutable label driven by buttons
; ==============================================================================
_ImGui_CreateText("t_title", "Text demo  --  create + set, UTF-8, runtime updates")
_ImGui_CreateText("t_hint",  "Buttons below mutate the label between the separators by calling SetText.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_static", "Static label (never changes after CreateText) -- I stay the same.")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_dyn",   "Dynamic label  --  click a button to replace me.")
_ImGui_CreateText("t_meta",  "Length : 41 chars   Update count : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_short",   "Set to a short string")
_ImGui_CreateButton("btn_long",    "Set to a long-ish ASCII string")
_ImGui_CreateButton("btn_utf8",    "Set to UTF-8 : naive cafe vs cafe")
_ImGui_CreateButton("btn_clear",   "Clear (empty string -- widget stays, label is gone)")
_ImGui_CreateButton("btn_restore", "Restore default")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",    "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iUpdateCount = 0
Const  $g_sDefault = "Dynamic label  --  click a button to replace me."


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_short",   "_OnShort")
_ImGui_SetOnClick("btn_long",    "_OnLong")
_ImGui_SetOnClick("btn_utf8",    "_OnUtf8")
_ImGui_SetOnClick("btn_clear",   "_OnClear")
_ImGui_SetOnClick("btn_restore", "_OnRestore")
_ImGui_SetOnClick("btn_quit",    "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnShort($sId)
    _Apply("Hi.")
EndFunc

Func _OnLong($sId)
    _Apply("The quick brown fox jumps over the lazy dog 1234567890.")
EndFunc

Func _OnUtf8($sId)
    ; Two strings that look similar but with one having UTF-8 accents.
    ; Decoded at the DLL boundary from the wstr argument.
    _Apply(Chr(99) & Chr(97) & Chr(102) & Chr(233) & " (UTF-8 with accent)  vs  cafe (plain ASCII)")
EndFunc

Func _OnClear($sId)
    _Apply("")
EndFunc

Func _OnRestore($sId)
    _Apply($g_sDefault)
EndFunc

Func _Apply($sNew)
    _ImGui_SetText("t_dyn", $sNew)
    $g_iUpdateCount += 1
    _ImGui_SetText("t_meta", StringFormat("Length : %d chars   Update count : %d", _
                                          StringLen($sNew), $g_iUpdateCount))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
