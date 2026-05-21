#cs
================================================================================
 Example 170 : _ImGui_LoadFont (+ _ImGui_LoadFontEx)
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_LoadFont      Load a TTF / OTF font from disk at a given
                        pixel size  --  Default glyph range (Latin)
   _ImGui_LoadFontEx    Same, with a $ImGuiFontGlyphRange_* parameter
                        for non-Latin scripts (Cyrillic, CJK, Thai, ...)

 Both return a font_id (>= 1) on success, -1 on failure. font_id 0 is
 always reserved for the default font loaded at _ImGui_Init time
 (Calibri 15.5pt). Loaded fonts persist until _ImGui_Shutdown -- no
 free / unload API in the MVP.

 Use a font via _ImGui_CreatePushFont(font_id) (exemple86) +
 matching PopFont (exemple87). Wrong / unknown id silently falls
 back to font 0 -- no crash, no stack imbalance.

 Glyph range constants (LoadFontEx) :
     0 = Default                  Latin baseline (same as LoadFont)
     1 = Vietnamese
     2 = Cyrillic
     3 = Greek
     4 = ChineseFull
     5 = ChineseSimplifiedCommon
     6 = Japanese
     7 = Korean
     8 = Thai

 Bigger ranges = larger texture atlas + slower init. Pick the
 smallest range that covers your needs.

 Demo : load three fonts from this repo's misc/fonts/ folder (always
 present), then render the same line of text with each via
 PushFont / PopFont. Hot-load a fourth font from @WindowsDir on
 button click to demonstrate runtime addition.

 Borrowed widgets : PushFont + PopFont (exemple86 / 87), Button,
 Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple170_font_load.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple170_font_load.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 170 : LoadFont + LoadFontEx", 720, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 2-export cluster
; ==============================================================================
; LoadFont($sPath, $fSize) -> font_id (>= 1) or -1
; LoadFontEx($sPath, $fSize, $iGlyphRange = 0) -> same
;
;   @extended on -1 carries the DLL status :
;     1 = bad args
;     2 = AddFontFromFileTTF failed (file missing / not a valid TTF)
;     6 = shutting down
;
;   Best practice : load all fonts BEFORE creating widgets that
;   reference them. PushFont with an unknown id falls back to font 0
;   silently.


; ==============================================================================
; Load fonts (from the repo's bundled fonts folder + a Cyrillic range)
; ==============================================================================
Global Const $g_sFontsDir = @ScriptDir & "\..\..\dll\imgui-docking\misc\fonts"
Global $g_iDroid  = _ImGui_LoadFont(  $g_sFontsDir & "\DroidSans.ttf",     22.0)
Global $g_iRoboto = _ImGui_LoadFont(  $g_sFontsDir & "\Roboto-Medium.ttf", 18.0)
; LoadFontEx with Cyrillic range -- demonstrates non-default glyphs.
Global $g_iKarla  = _ImGui_LoadFontEx($g_sFontsDir & "\Karla-Regular.ttf", 18.0, $ImGuiFontGlyphRange_Cyrillic)


; ==============================================================================
; Status header
; ==============================================================================
_ImGui_CreateText("t_title", "LoadFont / LoadFontEx  --  3 fonts from bundled folder + hot-load button")
_ImGui_CreateText("t_status", StringFormat("font_ids :  DroidSans = %d   Roboto = %d   Karla (Cyrillic ext) = %d   (-1 = file missing)", _
    $g_iDroid, $g_iRoboto, $g_iKarla))
_ImGui_CreateText("t_count",  "Total fonts in atlas : (waiting)")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Render the same line in each font
; ==============================================================================
_ImGui_CreateText("t_def_hdr", "Default (font_id = 0, Calibri 15.5pt loaded at init) :")
_ImGui_CreateText("t_def",     "  The quick brown fox jumps over the lazy dog.")
_ImGui_CreateSeparator("sep1")

If $g_iDroid >= 0 Then
    _ImGui_CreateText("t_droid_hdr", "DroidSans 22pt (LoadFont, Default range) :")
    _ImGui_CreatePushFont("pf_droid", $g_iDroid)
    _ImGui_CreateText("t_droid", "  The quick brown fox jumps over the lazy dog.")
    _ImGui_CreatePopFont("pop_droid")
    _ImGui_CreateSeparator("sep2")
EndIf

If $g_iRoboto >= 0 Then
    _ImGui_CreateText("t_robo_hdr", "Roboto-Medium 18pt (LoadFont, Default range) :")
    _ImGui_CreatePushFont("pf_robo", $g_iRoboto)
    _ImGui_CreateText("t_robo", "  The quick brown fox jumps over the lazy dog.")
    _ImGui_CreatePopFont("pop_robo")
    _ImGui_CreateSeparator("sep3")
EndIf

If $g_iKarla >= 0 Then
    _ImGui_CreateText("t_karla_hdr", "Karla 18pt + Cyrillic range (LoadFontEx) :")
    _ImGui_CreatePushFont("pf_karla", $g_iKarla)
    _ImGui_CreateText("t_karla_lat", "  Latin : The quick brown fox.")
    _ImGui_CreateText("t_karla_cyr", "  Cyrillic : " & ChrW(0x0410) & ChrW(0x0411) & ChrW(0x0412) & " " & ChrW(0x041F) & ChrW(0x0440) & ChrW(0x0438) & ChrW(0x0432) & ChrW(0x0435) & ChrW(0x0442))
    _ImGui_CreatePopFont("pop_karla")
    _ImGui_CreateSeparator("sep4")
EndIf


; ==============================================================================
; Hot-load button : adds Tahoma from @WindowsDir\Fonts at runtime
; ==============================================================================
_ImGui_CreateText("t_hot_hdr", "Hot-load : add Tahoma 16pt from Windows fonts at runtime")
_ImGui_CreateButton("btn_hot", "Load Tahoma")
_ImGui_CreateText  ("t_hot_result", "  (not loaded yet)")
_ImGui_CreateSeparator("sep5")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_hot",  "_OnHotLoad")
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPollCount", 300)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnHotLoad($sId)
    Local $iTahoma = _ImGui_LoadFont(@WindowsDir & "\Fonts\tahoma.ttf", 16.0)
    _ImGui_SetText("t_hot_result", "  Tahoma font_id = " & $iTahoma & "  --  atlas updated at next frame")
EndFunc

Func _OnPollCount()
    _ImGui_SetText("t_count", "Total fonts in atlas : " & _ImGui_GetFontCount())
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
