#cs
================================================================================
 Example 95 : _ImGui_IsDeactivated
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsDeactivated   Report whether a widget just transitioned OUT of Active state

 IsDeactivated is the mirror of IsActivated (exemple94). True only on
 the single frame the widget transitions from "active" back to
 "idle" -- typically when the user releases the mouse button after
 a click / drag, or moves keyboard focus away from an input field.

 Fires on EVERY deactivation, regardless of whether the value
 actually changed during the interaction. To fire only when the
 value did change, use _ImGui_IsDeactivatedAfterEdit (exemple96).

 Edge-frame pitfall : True for ONE frame only. See exemple92 for the
 polling-cadence discussion. Demo uses 16 ms tick.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple95_isdeactivated.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple95_isdeactivated.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 95 : _ImGui_IsDeactivated", 620, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsDeactivated  --  doc block
; ==============================================================================
; Signature : _ImGui_IsDeactivated($sId)
;
;   Returns True ONLY on the frame the widget transitions from active
;   to idle. False otherwise. Edge-frame, ~16 ms True window.
;
;   Fires unconditionally on every deactivation -- the value may or
;   may not have changed. Pair with IsActivated (exemple94) to detect
;   interaction boundaries (e.g. "snapshot undo state on Activated,
;   commit on Deactivated").
;
;   Not consumed by reading. Hidden / unknown widgets return False
;   silently.


; ==============================================================================
; Demo widgets  --  Slider + InputText, count BOTH activation and deactivation
;                  edges so the user can see them pair up.
; ==============================================================================
_ImGui_CreateText("t_title", "IsDeactivated demo  --  edge-frame deactivation paired with IsActivated")
_ImGui_CreateText("t_hint",  "Drag the slider, then release. Click in the input, then click outside. Watch the counters pair up.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateSliderFloat("tg_sl", "Target slider (drag and release)", 0.0, 1.0, 0.5, "%.3f")
_ImGui_CreateInputText("tg_in",   "Target input (focus, then defocus)", "type or just click", 64, 0)
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Counters (16 ms tick) :")
_ImGui_CreateText("t_sl_act",     "  Slider Activated   edges count : 0")
_ImGui_CreateText("t_sl_deact",   "  Slider Deactivated edges count : 0")
_ImGui_CreateText("t_in_act",     "  Input  Activated   edges count : 0")
_ImGui_CreateText("t_in_deact",   "  Input  Deactivated edges count : 0")
_ImGui_CreateText("t_pair_hint",  "  Pairing : Activated and Deactivated counts should stay equal (or off by 1 mid-interaction).")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iSlAct   = 0
Global $g_iSlDeact = 0
Global $g_iInAct   = 0
Global $g_iInDeact = 0


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
    If _ImGui_IsActivated("tg_sl") Then
        $g_iSlAct += 1
        _ImGui_SetText("t_sl_act", "  Slider Activated   edges count : " & $g_iSlAct)
    EndIf
    If _ImGui_IsDeactivated("tg_sl") Then
        $g_iSlDeact += 1
        _ImGui_SetText("t_sl_deact", "  Slider Deactivated edges count : " & $g_iSlDeact)
    EndIf
    If _ImGui_IsActivated("tg_in") Then
        $g_iInAct += 1
        _ImGui_SetText("t_in_act", "  Input  Activated   edges count : " & $g_iInAct)
    EndIf
    If _ImGui_IsDeactivated("tg_in") Then
        $g_iInDeact += 1
        _ImGui_SetText("t_in_deact", "  Input  Deactivated edges count : " & $g_iInDeact)
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
