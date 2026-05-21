#cs
================================================================================
 Example 194 : _ImGui_SetNavCursorVisible
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetNavCursorVisible   Show / hide the keyboard navigation
                                focus ring (one-shot intent)

 The "nav cursor" is the outlined rectangle ImGui draws around the
 currently keyboard-focused widget. By default it appears the moment
 the user presses any keyboard navigation key (Tab, arrows, Enter
 on a focusable widget). Some apps prefer to hide it until the user
 explicitly opts into keyboard nav -- this export is the lever.

 Semantics : one-shot INTENT, NOT a persistent state. The ring
 automatically REAPPEARS on the next keyboard input even after a
 SetNavCursorVisible(False) call. This is intentional : ImGui assumes
 that a key press is a signal the user wants keyboard navigation, so
 it un-hides the ring without asking.

 If you want the ring permanently hidden (mouse-only UI), the script
 must re-call SetNavCursorVisible(False) on every keyboard event --
 typically via a 16 ms SetOnTick that re-asserts the intent. Same
 per-frame setter idiom as SetMouseCursor (exemple153) and
 SetNextFrameWantCapture* (exemple157).

 Demo layout :
   * Three Buttons + an InputText  --  the focusable test bed.
   * Two buttons : "Hide nav ring (one-shot)" / "Show nav ring (one-shot)"
   * Checkbox "Persistent hide via 16 ms tick"  --  the always-off pattern.
   * Status text showing the last action + a key counter.

 Borrowed widgets : Button, InputText, Checkbox, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple194_setnavcursorvisible.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple194_setnavcursorvisible.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 194 : SetNavCursorVisible", 780, 580) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetNavCursorVisible  --  doc block
; ==============================================================================
; Signature : _ImGui_SetNavCursorVisible($bVisible)
;
;   $bVisible : True  -> show the focus ring on the next frame.
;               False -> hide the focus ring on the next frame.
;
;   Return : True on success, False on failure (@error = 1, 2).
;
;   ONE-SHOT INTENT : ImGui re-shows the ring automatically on the
;   next keyboard navigation input. For permanent-hide behavior,
;   re-call every frame via SetOnTick(16ms).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "SetNavCursorVisible demo  --  one-shot show/hide of the keyboard focus ring")
_ImGui_CreateText("t_hint",  "Use Tab / arrows to move focus through the widgets below ; click the toggles to show/hide.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Focusable test bed
; ==============================================================================
_ImGui_CreateText("t_bed_hdr", "Focus test bed (Tab through these) :")
_ImGui_CreateButton("btn_a", "Button A")
_ImGui_CreateButton("btn_b", "Button B")
_ImGui_CreateButton("btn_c", "Button C")
_ImGui_CreateInputText("in_focus", "InputText (Tab into me)", "type here", 256)
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; One-shot controls
; ==============================================================================
_ImGui_CreateText("t_one_hdr", "One-shot intent :")
_ImGui_CreateButton("btn_hide", "Hide nav ring (one-shot)")
_ImGui_CreateButton("btn_show", "Show nav ring (one-shot)")
_ImGui_CreateText("t_one_note", "  Note : the ring reappears on the next keyboard nav input ; that's intentional.")
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Persistent mode  --  re-apply False every 16 ms
; ==============================================================================
_ImGui_CreateText("t_persist_hdr", "Persistent mode (mouse-only UI) :")
_ImGui_CreateCheckbox("cb_persist", "Re-assert HIDDEN every 16 ms (overrides ImGui's auto-show)", False)
_ImGui_CreateSeparator("sep3")


; ==============================================================================
; Status / counters
; ==============================================================================
_ImGui_CreateText("t_status",  "Status : default (ring shows on first key press).")
_ImGui_CreateText("t_counters","One-shot calls  --  hide: 0   show: 0   persist re-asserts: 0")
_ImGui_CreateSeparator("sep4")


_ImGui_CreateButton("btn_quit", "Quit")


; --- Globals -----------------------------------------------------------------
Global $g_iHide = 0, $g_iShow = 0, $g_iPersist = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_hide", "_OnHide")
_ImGui_SetOnClick("btn_show", "_OnShow")
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPersistTick", 16)
_ImGui_SetOnTick("_OnRefreshTick", 200)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnHide($sId)
    _ImGui_SetNavCursorVisible(False)
    $g_iHide += 1
    _ImGui_SetText("t_status", "Status : ring hidden (one-shot). Press Tab to verify it reappears.")
EndFunc

Func _OnShow($sId)
    _ImGui_SetNavCursorVisible(True)
    $g_iShow += 1
    _ImGui_SetText("t_status", "Status : ring shown (one-shot).")
EndFunc

Func _OnPersistTick()
    If _ImGui_GetValueBool("cb_persist") Then
        _ImGui_SetNavCursorVisible(False)
        $g_iPersist += 1
    EndIf
EndFunc

Func _OnRefreshTick()
    _ImGui_SetText("t_counters", StringFormat( _
        "One-shot calls  --  hide: %d   show: %d   persist re-asserts: %d", _
        $g_iHide, $g_iShow, $g_iPersist))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
