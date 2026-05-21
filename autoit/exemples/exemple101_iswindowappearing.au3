#cs
================================================================================
 Example 101 : _ImGui_IsWindowAppearing
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsWindowAppearing   True on the first frame after the window becomes visible

 IsWindowAppearing is an EDGE-FRAME query (same caveat as the Item
 queries IsClicked / IsActivated -- see exemple92). It is True only
 on the single frame the window transitions from hidden to shown.
 Use it to one-shot-initialize state when a dialog opens : reset
 fields, populate live data from a source, seed scroll position, ...

 Polling cadence pitfall : the True window lasts one render frame
 (~16 ms at 60 fps). The 50 ms default tick of _ImGui_SetOnTick
 will miss most appearances. Use a 16 ms tick OR design the demo
 to count appearances over many show/hide cycles so the chance of
 catching at least some is high.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple101_iswindowappearing.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple101_iswindowappearing.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 101 : _ImGui_IsWindowAppearing", 700, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsWindowAppearing  --  doc block
; ==============================================================================
; Signature : _ImGui_IsWindowAppearing($sId)
;
;   Returns True ONLY on the first frame the window is re-displayed
;   after being hidden. Refreshes every frame ; not consumed by
;   reading. Edge-frame ; ~16 ms True window.
;
;   Typical use case : initialize a dialog when it opens.
;     Func _OnTick()
;         If _ImGui_IsWindowAppearing("dlg_options") Then
;             _ImGui_SetValueString("opt_name", _LoadFromSettings())
;             _ImGui_SetScrollY("dlg_options", 0.0)
;         EndIf
;     EndFunc
;
;   Hidden / unknown ids return False silently.


; ==============================================================================
; Host area widgets
; ==============================================================================
_ImGui_CreateText("t_title", "IsWindowAppearing demo  --  edge-frame appearance counter")
_ImGui_CreateText("t_hint",  "Toggle the floating window with the checkbox. The Appearing counter increments each time it goes hidden -> visible.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateCheckbox("cb_show", "Show the floating window", True)
_ImGui_CreateButton("btn_pulse", "Pulse : hide-then-show in one click")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_count", "Appearing edges count : 0  (poll at 16 ms tick)")
_ImGui_CreateText("t_log",   "Last appearance time : -")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target floating window
; ==============================================================================
_ImGui_CreateWindow("dlg", "Target window (toggle me)", True, 0)
_ImGui_CreateText  ("dlg_t1", "I appear every time the checkbox flips off then on.")
_ImGui_CreateText  ("dlg_t2", "Use IsWindowAppearing to detect that and run init code.")
_ImGui_CreateButton("dlg_btn","Some button inside")
_ImGui_SetParent("dlg_t1",  "dlg")
_ImGui_SetParent("dlg_t2",  "dlg")
_ImGui_SetParent("dlg_btn", "dlg")
_ImGui_SetWindowPos ("dlg", 60,  40,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("dlg", 320, 160, $ImGuiCond_FirstUseEver)


; --- Script-side state -------------------------------------------------------
Global $g_iAppearCount = 0
Global $g_bPulseStage  = 0   ; 0 = idle, 1 = just hidden (next tick re-show)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("cb_show",   "_OnToggleShow")
_ImGui_SetOnClick ("btn_pulse", "_OnPulse")
_ImGui_SetOnClick ("btn_quit",  "_OnQuit")
_ImGui_SetOnTick  ("_OnPollAppearing", 16)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnToggleShow($sId)
    _ImGui_SetVisible("dlg", _ImGui_GetValueBool($sId))
EndFunc

Func _OnPulse($sId)
    ; Schedule a hide-now / show-next-tick sequence so the user can trigger an
    ; appearance edge with one click.
    _ImGui_SetVisible("dlg", False)
    _ImGui_SetValueBool("cb_show", False)
    $g_bPulseStage = 1
EndFunc

Func _OnPollAppearing()
    ; Stage 2 of the pulse : re-show on the tick following the hide.
    If $g_bPulseStage = 1 Then
        _ImGui_SetVisible("dlg", True)
        _ImGui_SetValueBool("cb_show", True)
        $g_bPulseStage = 0
    EndIf
    ; Edge-frame query.
    If _ImGui_IsWindowAppearing("dlg") Then
        $g_iAppearCount += 1
        _ImGui_SetText("t_count", "Appearing edges count : " & $g_iAppearCount & "  (poll at 16 ms tick)")
        _ImGui_SetText("t_log",   "Last appearance time : " & @HOUR & ":" & @MIN & ":" & @SEC & "." & @MSEC)
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
