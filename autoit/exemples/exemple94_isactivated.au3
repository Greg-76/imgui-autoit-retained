#cs
================================================================================
 Example 94 : _ImGui_IsActivated
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsActivated   Report whether a widget just transitioned to Active state

 IsActivated is the EDGE counterpart of IsActive : True only on the
 single frame where the widget transitioned from "idle" to "active"
 (the user just pressed mouse-down on it, started dragging, started
 editing, ...).

 Pair with IsDeactivated (exemple95) to detect interaction boundaries
 (e.g. "begin recording undo state on Activated, commit on
 Deactivated").

 PITFALL : same as IsClicked / IsEdited -- edge-frame, True for ONE
 frame only. Polling at 50 ms may miss it ; demo uses 16 ms tick.

 RELIABLE ALTERNATIVE for click detection : _ImGui_SetOnClick (uses
 latched WasClicked under the hood -- persists across polls). But
 there is NO equivalent event helper specifically for "activation
 started" -- IsActivated is the only way to detect that edge from
 the script side.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple94_isactivated.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple94_isactivated.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 94 : _ImGui_IsActivated", 600, 460) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsActivated  --  doc block
; ==============================================================================
; Signature : _ImGui_IsActivated($sId)
;
;   Returns True ONLY on the frame the widget became active (mouse
;   down on it, drag started, edit started). False afterwards even
;   while the widget stays active (use IsActive for the persistent
;   state).
;
;   Not consumed. Refreshes every frame.


; ==============================================================================
; Demo widgets  --  Slider tracked both as IsActivated edge AND IsActive
;                  persistent state. Counters and live status side by side.
; ==============================================================================
_ImGui_CreateText("t_title", "IsActivated demo  --  edge frame (Activated) vs persistent state (IsActive)")
_ImGui_CreateText("t_hint",  "Drag the slider down and back up. IsActivated fires once at start ; IsActive stays True while dragging.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateSliderFloat("tg_sl", "Target slider", 0.0, 1.0, 0.5, "%.3f")
_ImGui_CreateInputText("tg_in",   "Target input (click to start editing)", "type here", 64, 0)
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Status :")
_ImGui_CreateText("t_sl_now",     "  Slider IsActive  : idle")
_ImGui_CreateText("t_sl_count",   "  Slider Activated edges count : 0")
_ImGui_CreateText("t_in_now",     "  Input  IsActive  : idle")
_ImGui_CreateText("t_in_count",   "  Input  Activated edges count : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iSlActivated = 0
Global $g_iInActivated = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollActivated", 16)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollActivated()
    Local $bSlActive = _ImGui_IsActive("tg_sl")
    Local $bInActive = _ImGui_IsActive("tg_in")
    _ImGui_SetText("t_sl_now", "  Slider IsActive  : " & ($bSlActive ? "ACTIVE (dragging)" : "idle"))
    _ImGui_SetText("t_in_now", "  Input  IsActive  : " & ($bInActive ? "ACTIVE (editing)"  : "idle"))

    If _ImGui_IsActivated("tg_sl") Then
        $g_iSlActivated += 1
        _ImGui_SetText("t_sl_count", "  Slider Activated edges count : " & $g_iSlActivated)
    EndIf
    If _ImGui_IsActivated("tg_in") Then
        $g_iInActivated += 1
        _ImGui_SetText("t_in_count", "  Input  Activated edges count : " & $g_iInActivated)
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
