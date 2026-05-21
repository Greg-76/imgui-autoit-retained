#cs
================================================================================
 Example 112 : _ImGui_SetWindowCollapsed
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetWindowCollapsed   Queue a one-shot SetNextWindowCollapsed

 The setter pair of IsWindowCollapsed (exemple102). Forces the
 window to collapse / expand for the NEXT render. Same one-shot +
 $iCond model as SetWindowPos / SetWindowSize : if you want the
 collapse state pinned every frame regardless of the user clicking
 the caret, call it from a per-frame OnTick with $iCond_Always.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple112_setwindowcollapsed.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple112_setwindowcollapsed.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 112 : _ImGui_SetWindowCollapsed", 700, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetWindowCollapsed  --  doc block
; ==============================================================================
; Signature : _ImGui_SetWindowCollapsed($sId, $bCollapsed, $iCond = 0)
;
;   $bCollapsed : True = collapse to title bar, False = expand.
;   $iCond      : same $ImGuiCond_* options as the other Set* setters
;                 (Always / Once / FirstUseEver / Appearing).
;
;   One-shot per call. The user can still click the caret after this
;   to re-collapse / re-expand, unless you call it again every frame
;   with $iCond_Always to lock the state.
;
;   Return : True on success, False on failure (@error = 1, 2, or 3).


; ==============================================================================
; Host area widgets  --  buttons to drive the target window's collapsed state
; ==============================================================================
_ImGui_CreateText("t_title", "SetWindowCollapsed demo  --  scripted collapse / expand of a sub-window")
_ImGui_CreateText("t_hint",  "Use the buttons below. The status panel reads back the actual state via IsWindowCollapsed.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_btn_hdr", "Target window control :")
_ImGui_CreateButton("btn_collapse", "Collapse (Cond_Always, one-shot)")
_ImGui_CreateButton("btn_expand",   "Expand   (Cond_Always, one-shot)")
_ImGui_CreateButton("btn_toggle",   "Toggle   (read state, flip, set with Always)")
_ImGui_CreateCheckbox("cb_lock_collapsed", "Lock collapsed (re-call SetWindowCollapsed(True, Always) every tick)", False)
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Status (read via IsWindowCollapsed) :")
_ImGui_CreateText("t_state",      "  Target : expanded")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window
; ==============================================================================
_ImGui_CreateWindow("tgt", "Target window", True, 0)
_ImGui_CreateText("tgt_t1", "Use the host buttons to collapse / expand me.")
_ImGui_CreateText("tgt_t2", "You can also click my title-bar caret directly.")
_ImGui_CreateText("tgt_t3", "When 'Lock collapsed' is on, the script forces collapsed every tick.")
_ImGui_SetParent("tgt_t1", "tgt")
_ImGui_SetParent("tgt_t2", "tgt")
_ImGui_SetParent("tgt_t3", "tgt")
_ImGui_SetWindowPos ("tgt", 240, 220, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 320, 160, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_collapse", "_OnCollapse")
_ImGui_SetOnClick("btn_expand",   "_OnExpand")
_ImGui_SetOnClick("btn_toggle",   "_OnToggle")
_ImGui_SetOnClick("btn_quit",     "_OnQuit")
_ImGui_SetOnTick ("_OnTick", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnCollapse($sId)
    _ImGui_SetWindowCollapsed("tgt", True, $ImGuiCond_Always)
EndFunc

Func _OnExpand($sId)
    _ImGui_SetWindowCollapsed("tgt", False, $ImGuiCond_Always)
EndFunc

Func _OnToggle($sId)
    Local $bCur = _ImGui_IsWindowCollapsed("tgt")
    _ImGui_SetWindowCollapsed("tgt", Not $bCur, $ImGuiCond_Always)
EndFunc

Func _OnTick()
    ; Continuous-override path : re-apply each tick when the lock is on.
    If _ImGui_GetValueBool("cb_lock_collapsed") Then
        _ImGui_SetWindowCollapsed("tgt", True, $ImGuiCond_Always)
    EndIf
    ; Live readback.
    Local $bCol = _ImGui_IsWindowCollapsed("tgt")
    _ImGui_SetText("t_state", "  Target : " & ($bCol ? "COLLAPSED" : "expanded"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
