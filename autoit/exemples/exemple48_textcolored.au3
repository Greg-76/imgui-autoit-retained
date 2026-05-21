#cs
================================================================================
 Example 48 : _ImGui_CreateTextColored
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateTextColored   Text label rendered with a fixed color

 TextColored is plain Text plus a hard-coded RGBA tint applied at draw
 time. The color is set at creation time and DOES NOT change after --
 there is no SetColor function on this widget. To change the color
 dynamically, destroy and re-create the widget (rare) or use a Style
 stack push around a plain Text (covered in the Style family).

 Update the content via _ImGui_SetText -- the color stays.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple48_textcolored.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple48_textcolored.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 48 : _ImGui_CreateTextColored", 620, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateTextColored  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateTextColored($sId, $sText,
;                                       $fR = 1.0, $fG = 1.0,
;                                       $fB = 1.0, $fA = 1.0)
;
;   Same as CreateText but with a hard-coded RGBA tint. Each channel is
;   a normalised float in [0.0, 1.0] -- ImGui clamps anything outside.
;   $fA = 1.0 is fully opaque ; $fA = 0.0 is fully transparent.
;
;   The color is locked at creation. Only the text content can change
;   afterwards (via _ImGui_SetText).
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  six TextColored side by side, one per typical role
;                  (success / warning / error / muted / brand / transparent)
; ==============================================================================
_ImGui_CreateText("t_title", "TextColored demo  --  six fixed-color labels (color is locked at creation)")
_ImGui_CreateText("t_hint",  "Buttons below update only the TEXT of the success label. The color stays whatever you set on Create.")
_ImGui_CreateSeparator("sep1")

; Common UI roles using conventional colors.
_ImGui_CreateTextColored("t_ok",      "OK -- success message (green)",   0.30, 0.85, 0.30, 1.0)
_ImGui_CreateTextColored("t_warn",    "Warning -- check this (yellow)",  1.00, 0.85, 0.20, 1.0)
_ImGui_CreateTextColored("t_err",     "Error -- something broke (red)",  0.95, 0.30, 0.30, 1.0)
_ImGui_CreateTextColored("t_muted",   "Muted -- low importance (grey)",  0.55, 0.55, 0.55, 1.0)
_ImGui_CreateTextColored("t_brand",   "Brand -- accent color (blue)",    0.30, 0.65, 1.00, 1.0)
_ImGui_CreateTextColored("t_alpha50", "Half-alpha -- partly transparent",1.00, 1.00, 1.00, 0.5)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_hint2", "Color is locked at creation -- only text can be mutated via SetText :")
_ImGui_CreateButton("btn_ok_text1", "Set OK label to ""All systems nominal""")
_ImGui_CreateButton("btn_ok_text2", "Set OK label to ""Backup completed (12.4 MB)""")
_ImGui_CreateButton("btn_ok_text3", "Set OK label to ""Login successful""")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit",     "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_ok_text1", "_OnOkText1")
_ImGui_SetOnClick("btn_ok_text2", "_OnOkText2")
_ImGui_SetOnClick("btn_ok_text3", "_OnOkText3")
_ImGui_SetOnClick("btn_quit",     "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnOkText1($sId)
    _ImGui_SetText("t_ok", "OK -- All systems nominal")
EndFunc

Func _OnOkText2($sId)
    _ImGui_SetText("t_ok", "OK -- Backup completed (12.4 MB)")
EndFunc

Func _OnOkText3($sId)
    _ImGui_SetText("t_ok", "OK -- Login successful")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
