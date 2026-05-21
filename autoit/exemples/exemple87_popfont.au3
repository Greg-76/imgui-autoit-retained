#cs
================================================================================
 Example 87 : _ImGui_CreatePopFont
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePopFont   Pop ONE font frame off the font stack

 Mirror of PushFont (exemple86). Removes the topmost font from the
 font stack, restoring whatever font was active before the matching
 Push.

 PITFALL : same as PushClipRect / PopClipRect -- ImGui asserts at
 end-of-frame if Push/Pop counts do not match. The font stack is one
 of the strictest in this regard ; treat its pairing rule like a
 hard requirement.

 No $iCount on this Pop : one Pop per Push.

 This file focuses on Pop, especially the LIFO unwinding of a
 multi-font stack and the contrast with PopStyleColor / PopStyleVar
 which DO accept counted pops.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple87_popfont.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple87_popfont.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 87 : _ImGui_CreatePopFont", 640, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Load alternate fonts (MUST happen before any CreatePushFont call)
; ==============================================================================
Global Const $g_iFontConsola = _ImGui_LoadFont(@WindowsDir & "\Fonts\consola.ttf", 14.0)
Global Const $g_iFontArial   = _ImGui_LoadFont(@WindowsDir & "\Fonts\arial.ttf",   16.0)
Global Const $g_iFontImpact  = _ImGui_LoadFont(@WindowsDir & "\Fonts\impact.ttf",  20.0)


; ==============================================================================
; _ImGui_CreatePopFont  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePopFont($sId)
;
;   No $iCount : one Pop per Push. To unwind three pushes, call three
;   times.
;
;   Stack semantics : LIFO. Most recent Push is undone first.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three Pushes followed by three Pops, with a Text widget
;                  rendered between each Pop so the LIFO unwinding is visible.
; ==============================================================================
_ImGui_CreateText("t_title", "PopFont demo  --  LIFO unwinding of a 3-deep font stack")
_ImGui_CreateText("t_hint",  "Each Pop restores the font that was active before the most recent Push.")
_ImGui_CreateText("t_ids",   StringFormat("Loaded font_ids : Consolas=%d, Arial=%d, Impact=%d", _
                                          $g_iFontConsola, $g_iFontArial, $g_iFontImpact))
_ImGui_CreateSeparator("sep_intro")

; Default font (control) ------------------------------------------------------
_ImGui_CreateText("t_default", "[ default font here ] The quick brown fox jumps over the lazy dog.")
_ImGui_CreateSeparator("sep_default")

; Push 1 -- Consolas ----------------------------------------------------------
_ImGui_CreatePushFont("pf_1", $g_iFontConsola)
_ImGui_CreateText("t_in_1", "[ Consolas (mono) ] -- 1 frame on the stack")

; Push 2 -- Arial 16 ----------------------------------------------------------
_ImGui_CreatePushFont("pf_2", $g_iFontArial)
_ImGui_CreateText("t_in_2", "[ Arial 16 (proportional) ] -- 2 frames on the stack")

; Push 3 -- Impact 20 ---------------------------------------------------------
_ImGui_CreatePushFont("pf_3", $g_iFontImpact)
_ImGui_CreateText("t_in_3", "[ Impact 20 (bold display) ] -- 3 frames on the stack")
_ImGui_CreateSeparator("sep_pushed")

; Pop 1 -- back to Arial 16 ---------------------------------------------------
_ImGui_CreatePopFont("ppf_3")
_ImGui_CreateText("t_pop_3", "After 1st Pop -- back to Arial 16 (Impact frame removed)")

; Pop 2 -- back to Consolas ---------------------------------------------------
_ImGui_CreatePopFont("ppf_2")
_ImGui_CreateText("t_pop_2", "After 2nd Pop -- back to Consolas (Arial frame removed)")

; Pop 3 -- back to default ----------------------------------------------------
_ImGui_CreatePopFont("ppf_1")
_ImGui_CreateText("t_pop_1", "[ default font here ] After 3rd Pop -- font stack empty, defaults restored")
_ImGui_CreateSeparator("sep_popped")

_ImGui_CreateText("t_reminder", "Reminder : there is NO PopFont($iCount) overload. Three Pushes need three Pop calls.")
_ImGui_CreateSeparator("sep_reminder")

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
