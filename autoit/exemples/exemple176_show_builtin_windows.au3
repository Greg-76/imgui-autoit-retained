#cs
================================================================================
 Example 176 : Built-in debug windows (10-export cluster)
================================================================================
 Covers 10 exports of imgui_autoit.dll (inseparable cluster -- 5
 setters + 5 matching query getters) :

   _ImGui_ShowDemoWindow         / _ImGui_IsShowingDemoWindow
   _ImGui_ShowMetricsWindow      / _ImGui_IsShowingMetricsWindow
   _ImGui_ShowDebugLogWindow     / _ImGui_IsShowingDebugLogWindow
   _ImGui_ShowIDStackToolWindow  / _ImGui_IsShowingIDStackToolWindow
   _ImGui_ShowAboutWindow        / _ImGui_IsShowingAboutWindow

 Five built-in side-panels exposed by ImGui itself (not application
 widgets) :
   * Demo          exhaustive widget gallery -- the canonical
                   "what can ImGui do ?" reference
   * Metrics       per-frame stats, draw lists, perf counters,
                   storage inspector
   * Debug Log     ImGui's internal trace log (clipper / nav /
                   popups / IO events ...)
   * ID Stack Tool diagnose duplicate-ID warnings by inspecting the
                   hashed id stack at any point
   * About         version + build info + credits

 ROUND-TRIP semantics : the wrapper's `Show*` setter pushes a bool
 into ImGui ; the user can close the window via its OS-style [X]
 button, which writes False back. `IsShowing*` reflects ImGui's
 current internal state -- ALWAYS the source of truth.

 Canonical pattern : drive both directions in your UI :
   * On click of a checkbox / menu item  --  call ShowXxx($bWant).
   * Every tick                          --  poll IsShowingXxx and
                                              sync the checkbox to it
                                              (so a [X] close from the
                                              user updates the menu).

 Borrowed widgets : Checkbox, Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple176_show_builtin_windows.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple176_show_builtin_windows.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 176 : Built-in debug windows", 760, 580) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 10-export cluster
; ==============================================================================
; ShowDemoWindow($bShow = True)         --  toggle the built-in Demo
; ShowMetricsWindow($bShow = True)      --  ditto Metrics
; ShowDebugLogWindow($bShow = True)     --  ditto Debug Log
; ShowIDStackToolWindow($bShow = True)  --  ditto ID Stack Tool
; ShowAboutWindow($bShow = True)        --  ditto About
;
; IsShowing<Each>()                     --  bool query, reflects the
;                                            INTERNAL ImGui state
;                                            (including X-button-closes)


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "Built-in ImGui debug windows  --  5 Show*/IsShowing* pairs")
_ImGui_CreateText("t_hint",  "Toggle via the checkboxes. Closing a window via its X button updates the checkbox on the next tick.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; One row per window : checkbox + live IsShowing status
; ==============================================================================
_ImGui_CreateCheckbox("cb_demo",   "Demo window         (the canonical 'what can ImGui do ?' gallery)", False)
_ImGui_CreateText    ("t_demo",    "  IsShowingDemoWindow = False")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateCheckbox("cb_metrics","Metrics window      (per-frame stats, draw lists, perf counters)", False)
_ImGui_CreateText    ("t_metrics", "  IsShowingMetricsWindow = False")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateCheckbox("cb_dbglog", "Debug Log window    (ImGui internal trace : clipper / nav / popups)", False)
_ImGui_CreateText    ("t_dbglog",  "  IsShowingDebugLogWindow = False")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateCheckbox("cb_idstk",  "ID Stack Tool       (diagnose duplicate-ID warnings)", False)
_ImGui_CreateText    ("t_idstk",   "  IsShowingIDStackToolWindow = False")
_ImGui_CreateSeparator("sep4")

_ImGui_CreateCheckbox("cb_about",  "About window        (version + build info + credits)", False)
_ImGui_CreateText    ("t_about",   "  IsShowingAboutWindow = False")
_ImGui_CreateSeparator("sep5")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("cb_demo",    "_OnDemoToggled")
_ImGui_SetOnChange("cb_metrics", "_OnMetricsToggled")
_ImGui_SetOnChange("cb_dbglog",  "_OnDebugLogToggled")
_ImGui_SetOnChange("cb_idstk",   "_OnIdStackToggled")
_ImGui_SetOnChange("cb_about",   "_OnAboutToggled")
_ImGui_SetOnClick ("btn_quit",   "_OnQuit")
; Sync the checkboxes with ImGui's internal state every 200 ms -- catches
; [X] close button clicks on any of the five built-in windows.
_ImGui_SetOnTick("_OnPollState", 200)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnDemoToggled($sId)
    _ImGui_ShowDemoWindow(_ImGui_GetValueBool($sId))
EndFunc

Func _OnMetricsToggled($sId)
    _ImGui_ShowMetricsWindow(_ImGui_GetValueBool($sId))
EndFunc

Func _OnDebugLogToggled($sId)
    _ImGui_ShowDebugLogWindow(_ImGui_GetValueBool($sId))
EndFunc

Func _OnIdStackToggled($sId)
    _ImGui_ShowIDStackToolWindow(_ImGui_GetValueBool($sId))
EndFunc

Func _OnAboutToggled($sId)
    _ImGui_ShowAboutWindow(_ImGui_GetValueBool($sId))
EndFunc

Func _OnPollState()
    ; Read the canonical state from ImGui and reflect it both in the
    ; checkbox (so [X] closes update the toggle) and in the status text.
    _Sync("cb_demo",    "t_demo",    "IsShowingDemoWindow",         _ImGui_IsShowingDemoWindow())
    _Sync("cb_metrics", "t_metrics", "IsShowingMetricsWindow",      _ImGui_IsShowingMetricsWindow())
    _Sync("cb_dbglog",  "t_dbglog",  "IsShowingDebugLogWindow",     _ImGui_IsShowingDebugLogWindow())
    _Sync("cb_idstk",   "t_idstk",   "IsShowingIDStackToolWindow",  _ImGui_IsShowingIDStackToolWindow())
    _Sync("cb_about",   "t_about",   "IsShowingAboutWindow",        _ImGui_IsShowingAboutWindow())
EndFunc

Func _Sync($sCheckboxId, $sStatusId, $sLabel, $bIsShowing)
    ; Update status line every tick (cheap, reads internal state).
    _ImGui_SetText($sStatusId, "  " & $sLabel & " = " & ($bIsShowing ? "True" : "False"))
    ; Re-sync the checkbox if it disagrees with ImGui's truth.
    If _ImGui_GetValueBool($sCheckboxId) <> $bIsShowing Then
        _ImGui_SetValueBool($sCheckboxId, $bIsShowing)
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
