#cs
================================================================================
 Example 189 : _ImGui_CreateShowFontSelector
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateShowFontSelector   Combo widget that picks the active
                                   font from the loaded font registry

 In-tree alternative to the manual PushFont (exemple86) / PopFont
 (exemple87) workflow : ImGui owns the Combo, and selection triggers
 a PushFont for the next render frame (covering the whole UI, not
 just nested widgets).

 Dependency : the registry must contain MORE THAN ONE font for the
 selector to be useful. Font id 0 = the default Calibri loaded by
 _ImGui_Init ; every _ImGui_LoadFont call adds one more (id >= 1).
 This example loads 3 fonts from the bundled imgui-docking misc/fonts/
 directory before creating the selector.

 If LoadFont fails (missing file, wrong arch, etc.) the example still
 starts -- the selector will simply have fewer entries. Status text
 reports the resolved font count.

 Borrowed widgets : LoadFont (exemple170), Text + Separator, Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple189_showfont_selector.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple189_showfont_selector.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 189 : ShowFontSelector", 760, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateShowFontSelector  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateShowFontSelector($sId, $sLabel = "Font")
;
;   $sId    : stable widget identifier.
;   $sLabel : displayed combo label (default "Font").
;
;   Return : True on success, False on failure (@error = 1, 2).
;
;   Behavior : renders a Combo populated with the names of every
;   font in the registry (default + each LoadFont*). Selecting an
;   entry triggers a PushFont for the next render frame, which
;   means the WHOLE UI (the surrounding widgets too) renders in
;   that font until the next selection.


; ==============================================================================
; Load extra fonts BEFORE creating the selector
; ==============================================================================
Global Const $g_sFontsDir = @ScriptDir & "\..\..\dll\imgui-docking\misc\fonts"

Global $g_iLoadedFonts = 0
If _ImGui_LoadFont($g_sFontsDir & "\DroidSans.ttf", 16.0) Then $g_iLoadedFonts += 1
If _ImGui_LoadFont($g_sFontsDir & "\Roboto-Medium.ttf", 16.0) Then $g_iLoadedFonts += 1
If _ImGui_LoadFont($g_sFontsDir & "\Karla-Regular.ttf", 16.0) Then $g_iLoadedFonts += 1


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "ShowFontSelector demo  --  in-tree Combo that PushFonts the whole UI")
_ImGui_CreateText("t_hint",  "Pick a font below ; every text on this screen re-renders in the new face.")
_ImGui_CreateText("t_loaded", "Loaded extra fonts : " & $g_iLoadedFonts & " (registry total : default + loaded)")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; The widget itself
; ==============================================================================
_ImGui_CreateShowFontSelector("fs_picker", "Active font")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Sample text  --  shows the font effect
; ==============================================================================
_ImGui_CreateText("t_sample_hdr", "Sample text in the active font :")
_ImGui_CreateText("t_alpha", "The quick brown fox jumps over the lazy dog.")
_ImGui_CreateText("t_digits", "0123456789  +-*/=  !@#$%^&*()  {}[]<>")
_ImGui_CreateText("t_lorem",  "Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
_ImGui_CreateText("t_widgetlabels", "Widgets, labels, MenuItems  --  all driven by the active font.")
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
