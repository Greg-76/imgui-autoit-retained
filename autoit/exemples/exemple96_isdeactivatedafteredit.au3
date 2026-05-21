#cs
================================================================================
 Example 96 : _ImGui_IsDeactivatedAfterEdit
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsDeactivatedAfterEdit   Edge-frame deactivation, FILTERED by "value changed"

 The most useful edge-frame query for form validation : True on the
 deactivation frame ONLY IF the user actually changed the value
 during the interaction. Click-into-an-input-then-click-outside (no
 typing) does NOT fire it ; click-into-then-type-then-click-outside
 does.

 Canonical "commit on blur" pattern : bind a handler that polls
 IsDeactivatedAfterEdit per-frame and writes the final value to your
 persistence layer (file, DB, settings). This avoids writing on every
 keystroke while still catching every meaningful change.

 Edge-frame pitfall : True for ONE frame only. Demo uses 16 ms tick.

 Compare with IsDeactivated (exemple95) which fires unconditionally.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple96_isdeactivatedafteredit.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple96_isdeactivatedafteredit.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 96 : _ImGui_IsDeactivatedAfterEdit", 620, 500) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsDeactivatedAfterEdit  --  doc block
; ==============================================================================
; Signature : _ImGui_IsDeactivatedAfterEdit($sId)
;
;   Returns True ONLY on the deactivation frame if and only if the
;   user changed the widget's value during the active interval. False
;   otherwise.
;
;   Differs from IsDeactivated (exemple95) by the value-change filter.
;   Use IsDeactivated when you need every deactivation (e.g.
;   "snapshot undo state" or focus tracking). Use this one when you
;   only care about the value actually changing (commit-on-blur,
;   "save" triggers, dirty-flag updates).
;
;   Not consumed by reading. Hidden / unknown widgets return False.


; ==============================================================================
; Demo widgets  --  Slider + InputText. Track BOTH IsDeactivated and
;                  IsDeactivatedAfterEdit so the difference is visible.
; ==============================================================================
_ImGui_CreateText("t_title", "IsDeactivatedAfterEdit demo  --  commit-on-blur semantics")
_ImGui_CreateText("t_hint",  "Activate then deactivate WITHOUT changing the value (click in / click out) -- only the plain Deactivated counter advances.")
_ImGui_CreateText("t_hint2", "Then deactivate AFTER changing the value -- both counters advance together.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateSliderFloat("tg_sl", "Target slider", 0.0, 1.0, 0.5, "%.3f")
_ImGui_CreateInputText("tg_in",   "Target input",  "preset", 64, 0)
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Counters (16 ms tick) :")
_ImGui_CreateText("t_sl_deact",   "  Slider Deactivated           : 0")
_ImGui_CreateText("t_sl_dae",     "  Slider DeactivatedAfterEdit  : 0  (commit-on-blur)")
_ImGui_CreateText("t_in_deact",   "  Input  Deactivated           : 0")
_ImGui_CreateText("t_in_dae",     "  Input  DeactivatedAfterEdit  : 0  (commit-on-blur)")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_log_hdr",    "Last commit event :")
_ImGui_CreateText("t_log",        "  (waiting for the first DeactivatedAfterEdit ...)")
_ImGui_CreateSeparator("sep4")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iSlDeact = 0
Global $g_iSlDae   = 0
Global $g_iInDeact = 0
Global $g_iInDae   = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollEdges", 16)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollEdges()
    If _ImGui_IsDeactivated("tg_sl") Then
        $g_iSlDeact += 1
        _ImGui_SetText("t_sl_deact", "  Slider Deactivated           : " & $g_iSlDeact)
    EndIf
    If _ImGui_IsDeactivatedAfterEdit("tg_sl") Then
        $g_iSlDae += 1
        _ImGui_SetText("t_sl_dae", "  Slider DeactivatedAfterEdit  : " & $g_iSlDae & "  (commit-on-blur)")
        _ImGui_SetText("t_log",    "  Slider committed value : " & StringFormat("%.3f", _ImGui_GetValueFloat("tg_sl")))
    EndIf
    If _ImGui_IsDeactivated("tg_in") Then
        $g_iInDeact += 1
        _ImGui_SetText("t_in_deact", "  Input  Deactivated           : " & $g_iInDeact)
    EndIf
    If _ImGui_IsDeactivatedAfterEdit("tg_in") Then
        $g_iInDae += 1
        _ImGui_SetText("t_in_dae", "  Input  DeactivatedAfterEdit  : " & $g_iInDae & "  (commit-on-blur)")
        _ImGui_SetText("t_log",    "  Input committed value : """ & _ImGui_GetValueString("tg_in") & """")
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
