#cs
================================================================================
 Example 156 : _ImGui_IsKeyChordPressed
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsKeyChordPressed   True ONLY on the press edge of a key
                              chord (key + modifiers). No repeat.

 A chord is a $ImGuiKey_* OR'd with one or more $ImGuiMod_* modifier
 bits. Modifier constants live at high bits so the OR produces a
 single integer that uniquely identifies the chord :

   $ImGuiMod_Ctrl  = 0x1000
   $ImGuiMod_Shift = 0x2000
   $ImGuiMod_Alt   = 0x4000
   $ImGuiMod_Super = 0x8000   (Windows key on Win32)

 Three chords watched here side by side :
   * Ctrl + S         classical "Save" shortcut
   * Ctrl + Shift + Z classical "Redo" shortcut
   * F1               no modifier -- just the function key

 EDGE-FRAME (~16 ms True window) -- poll at 16 ms. Always fires on
 press only ; no $bRepeat parameter (unlike IsKeyPressed). Use
 IsKeyDown if you need "held" semantics.

 ImGui-side query : same focus / consumption rules as IsKeyDown
 (exemple155). For OS-wide hotkeys regardless of focus, use AutoIt's
 HotKeySet().

 Borrowed widgets : Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple156_keyboard_chord.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple156_keyboard_chord.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 156 : _ImGui_IsKeyChordPressed", 720, 460) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsKeyChordPressed  --  doc block
; ==============================================================================
; Signature : _ImGui_IsKeyChordPressed($iKeyChord)
;
;   $iKeyChord : an $ImGuiKey_* OR'd with zero or more $ImGuiMod_*
;                modifier bits.
;
;   Returns True only on the press EDGE -- no repeat. Edge-frame
;   (~16 ms True window) ; poll via SetOnTick at 16 ms.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "IsKeyChordPressed  --  watch three chords side by side, polled at 16 ms")
_ImGui_CreateText("t_hint",  "Give the window focus, then try Ctrl+S, Ctrl+Shift+Z, F1. Counters bump on each press edge.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Chord definitions
; ==============================================================================
; Pre-compute the chord ints so the doc block and the handler use the same
; values verbatim.
Global Const $g_iChordCtrlS    = BitOR($ImGuiMod_Ctrl, $ImGuiKey_S)
Global Const $g_iChordCtrlShZ  = BitOR(BitOR($ImGuiMod_Ctrl, $ImGuiMod_Shift), $ImGuiKey_Z)
Global Const $g_iChordF1       = $ImGuiKey_F1

_ImGui_CreateText("t_chord_ctrl_s",   StringFormat("  Ctrl + S           -> chord int = 0x%08X   |  count : 0", $g_iChordCtrlS))
_ImGui_CreateText("t_chord_ctrl_sh_z",StringFormat("  Ctrl + Shift + Z   -> chord int = 0x%08X   |  count : 0", $g_iChordCtrlShZ))
_ImGui_CreateText("t_chord_f1",       StringFormat("  F1                 -> chord int = 0x%08X   |  count : 0", $g_iChordF1))
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_flash", "(awaiting chord press...)")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters ---------------------------------------------------------------
Global $g_iHitCtrlS   = 0
Global $g_iHitCtrlShZ = 0
Global $g_iHitF1      = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPoll", 16)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPoll()
    Local $bCtrlS   = _ImGui_IsKeyChordPressed($g_iChordCtrlS)
    Local $bCtrlShZ = _ImGui_IsKeyChordPressed($g_iChordCtrlShZ)
    Local $bF1      = _ImGui_IsKeyChordPressed($g_iChordF1)
    If $bCtrlS   Then $g_iHitCtrlS   += 1
    If $bCtrlShZ Then $g_iHitCtrlShZ += 1
    If $bF1      Then $g_iHitF1      += 1

    _ImGui_SetText("t_chord_ctrl_s",    StringFormat("  Ctrl + S           -> chord int = 0x%08X   |  count : %d", $g_iChordCtrlS,   $g_iHitCtrlS))
    _ImGui_SetText("t_chord_ctrl_sh_z", StringFormat("  Ctrl + Shift + Z   -> chord int = 0x%08X   |  count : %d", $g_iChordCtrlShZ, $g_iHitCtrlShZ))
    _ImGui_SetText("t_chord_f1",        StringFormat("  F1                 -> chord int = 0x%08X   |  count : %d", $g_iChordF1,      $g_iHitF1))

    Local $bAny = ($bCtrlS Or $bCtrlShZ Or $bF1)
    _ImGui_SetText("t_flash", $bAny ? ">>> CHORD PRESSED THIS TICK <<<" : "(awaiting chord press...)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
