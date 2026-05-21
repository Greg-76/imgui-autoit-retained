#cs
================================================================================
 Example 191 : _ImGui_SetStyleTheme
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetStyleTheme   Imperatively swap the global ImGui theme
                          ($iTheme : 0=Dark, 1=Light, 2=Classic)

 Imperative counterpart to _ImGui_CreateShowStyleSelector (exemple188).
 Same trap class as the LogTo* / LogButtons pair (exemples 183 vs 185)
 -- different mental model, same underlying action :

   * exemple188 (widget)        ImGui owns the Combo, USER picks the
                                theme from a dropdown.
   * exemple191 (imperative)    SCRIPT picks the theme, typically
                                driven by preferences, a CLI flag,
                                or a hotkey at startup. Three
                                explicit buttons here so the
                                difference is obvious.

 Idempotent : SetStyleTheme can be called as often as you want, with
 any of the three values, in any order. Each call re-applies the
 multi-viewport tweak (opaque WindowBg + zero WindowRounding) so
 dragged-out sub-windows stay clean.

 Constants : the wrapper exposes $ImGuiStyleTheme_Dark / _Light /
 _Classic (0 / 1 / 2). Pure convention -- not an ImGui enum.

 Borrowed widgets : SliderFloat, Button, Checkbox, ColorEdit4,
 CollapsingHeader, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple191_setstyletheme.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple191_setstyletheme.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 191 : SetStyleTheme", 760, 580) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetStyleTheme  --  doc block
; ==============================================================================
; Signature : _ImGui_SetStyleTheme($iTheme)
;
;   $iTheme : one of
;     0 = $ImGuiStyleTheme_Dark      (default, used by _ImGui_Init)
;     1 = $ImGuiStyleTheme_Light
;     2 = $ImGuiStyleTheme_Classic
;
;   Return : True on success, False on failure (@error = 1, 2).
;
;   Idempotent. Out-of-range $iTheme is silently ignored by the DLL
;   (returns success but no change).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "SetStyleTheme demo  --  imperative theme swap from the script")
_ImGui_CreateText("t_hint",  "Click a button below ; the whole UI re-renders in the chosen palette.")
_ImGui_CreateText("t_seealso", "See exemple188 for the in-tree Combo widget variant.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Three theme buttons
; ==============================================================================
_ImGui_CreateText("t_btn_hdr", "Switch theme :")
_ImGui_CreateButton("btn_dark",    "Dark  ($ImGuiStyleTheme_Dark = 0)")
_ImGui_CreateButton("btn_light",   "Light ($ImGuiStyleTheme_Light = 1)")
_ImGui_CreateButton("btn_classic", "Classic ($ImGuiStyleTheme_Classic = 2)")
_ImGui_CreateText("t_status",  "Status : default Dark theme is active.")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Sample widgets  --  show the theme effect visually
; ==============================================================================
_ImGui_CreateText("t_sample_hdr", "Sample widgets (re-rendered with the active theme) :")
_ImGui_CreateButton("btn_action",  "Sample button")
_ImGui_CreateCheckbox("cb_toggle", "Sample checkbox", True)
_ImGui_CreateSliderFloat("sl_demo", "Slider", 0.0, 1.0, 0.5, "%.2f")
_ImGui_CreateColorEdit4("ce_sample", "Color edit", 0.3, 0.7, 0.9, 1.0, 0)
_ImGui_CreateCollapsingHeader("ch_section", "Collapsing header (open me)", 0)
_ImGui_CreateText("t_nested", "  Nested text inside the collapsing header")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Globals -----------------------------------------------------------------
Global $g_iCallCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_dark",    "_OnDark")
_ImGui_SetOnClick("btn_light",   "_OnLight")
_ImGui_SetOnClick("btn_classic", "_OnClassic")
_ImGui_SetOnClick("btn_quit",    "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------
Func _OnDark($sId)
    _ImGui_SetStyleTheme($ImGuiStyleTheme_Dark)
    $g_iCallCount += 1
    _ImGui_SetText("t_status", "Status : Dark theme applied. Calls so far : " & $g_iCallCount)
EndFunc

Func _OnLight($sId)
    _ImGui_SetStyleTheme($ImGuiStyleTheme_Light)
    $g_iCallCount += 1
    _ImGui_SetText("t_status", "Status : Light theme applied. Calls so far : " & $g_iCallCount)
EndFunc

Func _OnClassic($sId)
    _ImGui_SetStyleTheme($ImGuiStyleTheme_Classic)
    $g_iCallCount += 1
    _ImGui_SetText("t_status", "Status : Classic theme applied. Calls so far : " & $g_iCallCount)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
