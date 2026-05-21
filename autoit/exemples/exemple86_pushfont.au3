#cs
================================================================================
 Example 86 : _ImGui_CreatePushFont
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePushFont   Push an alternate font onto ImGui's font stack

 PushFont changes the font used by every Text-family widget added
 next, until a matching PopFont (exemple87) restores the previous
 font. Useful for : code/monospace blocks, headings in a larger
 face, accent text, language-specific fallback fonts.

 Workflow :
   1. Call _ImGui_LoadFont (or _ImGui_LoadFontEx) BEFORE creating any
      widget. The function returns a font_id (>= 1).
   2. Use that font_id in _ImGui_CreatePushFont.
   3. Add the widgets that should use the alternate font.
   4. Call _ImGui_CreatePopFont to restore the previous font.

 If LoadFont fails (file missing, etc.), the returned font_id is -1
 and PushFont with -1 silently falls back to font 0 (default). This
 demo handles that gracefully.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple86_pushfont.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple86_pushfont.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 86 : _ImGui_CreatePushFont", 620, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Load alternate fonts (MUST happen before any CreatePushFont call)
; ==============================================================================
; Pick three sizes / faces so the demo has visible contrast. Each LoadFont
; returns a non-zero font_id ; a -1 means the file could not be opened.
Global Const $g_iFontConsola14 = _ImGui_LoadFont(@WindowsDir & "\Fonts\consola.ttf", 14.0)
Global Const $g_iFontConsola24 = _ImGui_LoadFont(@WindowsDir & "\Fonts\consola.ttf", 24.0)
Global Const $g_iFontArialBig  = _ImGui_LoadFont(@WindowsDir & "\Fonts\arial.ttf",   22.0)


; ==============================================================================
; _ImGui_CreatePushFont  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePushFont($sId, $iFontId)
;
;   $iFontId : value returned by _ImGui_LoadFont / _ImGui_LoadFontEx.
;              Font 0 is always the default ImGui font ; never pass 0
;              unless you actually want the default.
;
;   PushFont MUST be matched by a PopFont in the same parent's children
;   list. Mismatched stack -> ImGui assertion at end-of-frame (same
;   strict pairing as PushClipRect).
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  default, consola 14, consola 24, arial 22, nested combos
; ==============================================================================
_ImGui_CreateText("t_title", "PushFont demo  --  three loaded fonts pushed around blocks of text")
_ImGui_CreateText("t_hint",  "If your system is missing Consolas or Arial, those sections fall back to the default font silently.")
_ImGui_CreateText("t_ids",   StringFormat("Loaded font_ids : Consolas-14=%d, Consolas-24=%d, Arial-22=%d", _
                                          $g_iFontConsola14, $g_iFontConsola24, $g_iFontArialBig))
_ImGui_CreateSeparator("sep_intro")

; --- (A) Default font (no Push) ---------------------------------------------
_ImGui_CreateText("a_hdr", "(A) Default font (no Push) :")
_ImGui_CreateText("a_t1",  "The quick brown fox jumps over the lazy dog 0123456789.")
_ImGui_CreateSeparator("sep_a")

; --- (B) Consolas 14 (monospace, same size as default) ----------------------
_ImGui_CreateText("b_hdr", "(B) PushFont(Consolas 14 px) -- visible monospace ; same size as default :")
_ImGui_CreatePushFont("pf_b", $g_iFontConsola14)
_ImGui_CreateText("b_t1",  "The quick brown fox jumps over the lazy dog 0123456789.")
_ImGui_CreateText("b_t2",  "Each character occupies the same horizontal slot in this font.")
_ImGui_CreatePopFont("ppf_b")
_ImGui_CreateText("b_after","Default font is back after PopFont")
_ImGui_CreateSeparator("sep_b")

; --- (C) Consolas 24 (monospace, large) -------------------------------------
_ImGui_CreateText("c_hdr", "(C) PushFont(Consolas 24 px) -- bigger monospace block :")
_ImGui_CreatePushFont("pf_c", $g_iFontConsola24)
_ImGui_CreateText("c_t",   "WidePixelLine = 24px")
_ImGui_CreatePopFont("ppf_c")
_ImGui_CreateText("c_after","Default font is back")
_ImGui_CreateSeparator("sep_c")

; --- (D) Arial Big (proportional, large) ------------------------------------
_ImGui_CreateText("d_hdr", "(D) PushFont(Arial 22 px) -- large proportional font for headings :")
_ImGui_CreatePushFont("pf_d", $g_iFontArialBig)
_ImGui_CreateText("d_t",   "Big Heading In Arial")
_ImGui_CreatePopFont("ppf_d")
_ImGui_CreateText("d_after","Default font is back")
_ImGui_CreateSeparator("sep_d")

; --- (E) Nested : Arial Big around a Consolas-14 inner block ----------------
_ImGui_CreateText("e_hdr", "(E) Nested : Arial 22 outer, Consolas 14 inner, then unwind :")
_ImGui_CreatePushFont("pf_e1", $g_iFontArialBig)
_ImGui_CreateText("e_t_outer", "Heading-style outer text")
_ImGui_CreatePushFont("pf_e2", $g_iFontConsola14)
_ImGui_CreateText("e_t_inner", "  Inline mono inside the heading scope")
_ImGui_CreatePopFont("ppf_e2")
_ImGui_CreateText("e_t_outer2","Back to heading-style outer")
_ImGui_CreatePopFont("ppf_e1")
_ImGui_CreateText("e_t_after", "Default font fully restored")
_ImGui_CreateSeparator("sep_e")

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
