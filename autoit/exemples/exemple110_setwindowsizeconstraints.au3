#cs
================================================================================
 Example 110 : _ImGui_SetWindowSizeConstraints
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetWindowSizeConstraints   Lock user resize within a min / max bounding box

 SetWindowSizeConstraints fixes the user-resize range of a window.
 The user CAN'T drag the edges past the (min, max) bounds. Either or
 both bounds can be open : pass 0 (or any non-positive value) for
 max_w / max_h to mean "no upper limit on this axis" (mapped to
 FLT_MAX by the DLL).

 Constraints apply on every subsequent Render. Unlike SetWindowPos /
 SetWindowSize, this one is NOT one-shot ; it sticks until you call
 it again with different bounds.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple110_setwindowsizeconstraints.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple110_setwindowsizeconstraints.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 110 : _ImGui_SetWindowSizeConstraints", 720, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetWindowSizeConstraints  --  doc block
; ==============================================================================
; Signature : _ImGui_SetWindowSizeConstraints($sId,
;                                              $fMinW, $fMinH,
;                                              $fMaxW = 0, $fMaxH = 0)
;
;   $fMinW / $fMinH : lower bounds in pixels.
;   $fMaxW / $fMaxH : upper bounds in pixels (0 = no limit, mapped to
;                     FLT_MAX by the DLL).
;
;   Persistent override -- stays in effect until called again with
;   different bounds. Re-calling with (0, 0, 0, 0) is NOT a "remove"
;   -- it sets a 0x0 minimum which is a no-op.
;
;   Return : True on success, False on failure (@error = 1, 2, or 3).


; ==============================================================================
; Host area widgets  --  buttons to apply different constraint sets
; ==============================================================================
_ImGui_CreateText("t_title", "SetWindowSizeConstraints demo  --  bounded user resize")
_ImGui_CreateText("t_hint",  "Try resizing the target window with each constraint set applied. The bounds are enforced live.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_btn_hdr", "Apply a constraint set to the target :")
_ImGui_CreateButton("btn_tight",   "(A) Min 200x100,  Max 300x200    (tight bounds)")
_ImGui_CreateButton("btn_loose",   "(B) Min 150x80,   no max         (only floor)")
_ImGui_CreateButton("btn_wonly",   "(C) Min 100x100,  Max 600x0      (only width capped)")
_ImGui_CreateButton("btn_huge",    "(D) Min 100x100,  Max 1000x800   (loose envelope)")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Live size :")
_ImGui_CreateText("t_size",       "  Target size : 0 x 0")
_ImGui_CreateText("t_constraint", "  Active constraint : initial (Min 100x80, no max)")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window
; ==============================================================================
_ImGui_CreateWindow("tgt", "Target window (constrained resize)", True, 0)
_ImGui_CreateText("tgt_t1", "Drag my edges to resize.")
_ImGui_CreateText("tgt_t2", "Constraints enforced by SetWindowSizeConstraints from the host.")
_ImGui_CreateText("tgt_t3", "Try each preset button.")
_ImGui_SetParent("tgt_t1", "tgt")
_ImGui_SetParent("tgt_t2", "tgt")
_ImGui_SetParent("tgt_t3", "tgt")
_ImGui_SetWindowPos ("tgt", 250, 220, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 280, 180, $ImGuiCond_FirstUseEver)

; Seed initial constraints so the user has SOMETHING to play with at startup.
_ImGui_SetWindowSizeConstraints("tgt", 100.0, 80.0, 0.0, 0.0)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_tight", "_OnTight")
_ImGui_SetOnClick("btn_loose", "_OnLoose")
_ImGui_SetOnClick("btn_wonly", "_OnWidthOnly")
_ImGui_SetOnClick("btn_huge",  "_OnHuge")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")
_ImGui_SetOnTick ("_OnPollSize", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnTight($sId)
    _ImGui_SetWindowSizeConstraints("tgt", 200.0, 100.0, 300.0, 200.0)
    _ImGui_SetText("t_constraint", "  Active constraint : Min 200x100, Max 300x200 (tight)")
EndFunc

Func _OnLoose($sId)
    _ImGui_SetWindowSizeConstraints("tgt", 150.0, 80.0, 0.0, 0.0)
    _ImGui_SetText("t_constraint", "  Active constraint : Min 150x80, no max (only floor)")
EndFunc

Func _OnWidthOnly($sId)
    _ImGui_SetWindowSizeConstraints("tgt", 100.0, 100.0, 600.0, 0.0)
    _ImGui_SetText("t_constraint", "  Active constraint : Min 100x100, Max 600x(no limit) (width capped)")
EndFunc

Func _OnHuge($sId)
    _ImGui_SetWindowSizeConstraints("tgt", 100.0, 100.0, 1000.0, 800.0)
    _ImGui_SetText("t_constraint", "  Active constraint : Min 100x100, Max 1000x800 (loose envelope)")
EndFunc

Func _OnPollSize()
    Local $aSz = _ImGui_GetWindowSize("tgt")
    If IsArray($aSz) Then
        _ImGui_SetText("t_size", StringFormat("  Target size : %d x %d", $aSz[0], $aSz[1]))
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
