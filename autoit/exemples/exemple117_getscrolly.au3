#cs
================================================================================
 Example 117 : _ImGui_GetScrollY
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_GetScrollY   Read the current vertical scroll offset of a window

 Returns a float in pixels : how far down the window's client area
 is scrolled. 0 means no vertical scroll (top-most). The maximum is
 GetScrollMaxY (exemple119).

 Vertical scroll is always available in regular ImGui windows
 (unless $ImGuiWindowFlags_NoScrollbar is set), so this readout
 works out of the box for any tall window.

 Persistent state ; 50 ms polling reliable. Returns 0 on unknown
 / non-scrollable window (no @error).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple117_getscrolly.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple117_getscrolly.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 117 : _ImGui_GetScrollY", 720, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_GetScrollY  --  doc block
; ==============================================================================
; Signature : _ImGui_GetScrollY($sId)
;
;   Returns the vertical scroll offset in pixels. 0 = top.
;
;   Persistent state ; 50 ms polling reliable. Returns 0 on unknown
;   widget (no @error).


; ==============================================================================
; Host area widgets
; ==============================================================================
_ImGui_CreateText("t_title", "GetScrollY demo  --  live vertical scroll offset")
_ImGui_CreateText("t_hint",  "Scroll the target window up / down with the side bar or mouse wheel. Readout updates ~20 Hz.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_status_hdr", "Scroll panel :")
_ImGui_CreateText("t_y",   "  ScrollY     : 0 px")
_ImGui_CreateText("t_max", "  ScrollMaxY  : 0 px")
_ImGui_CreateText("t_pct", "  Vertical progress : 0 %")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window  --  many items to force vertical scrolling
; ==============================================================================
_ImGui_CreateWindow("tgt", "Scroll me vertically", True, 0)
_ImGui_CreateText("tgt_head", "Top of the list -- scroll down with the side bar or mouse wheel.")
_ImGui_SetParent("tgt_head", "tgt")

For $i = 1 To 40
    Local $sId = "tgt_item_" & $i
    _ImGui_CreateText($sId, "  Item #" & $i & " in the long scrollable list.")
    _ImGui_SetParent($sId, "tgt")
Next

_ImGui_CreateText("tgt_tail", "Bottom of the list.")
_ImGui_SetParent("tgt_tail", "tgt")

_ImGui_SetWindowPos ("tgt", 280, 240, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 360, 220, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollScrollY", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollScrollY()
    Local $fY    = _ImGui_GetScrollY("tgt")
    Local $fMaxY = _ImGui_GetScrollMaxY("tgt")
    Local $fPct  = ($fMaxY = 0) ? 0.0 : ($fY / $fMaxY) * 100.0
    _ImGui_SetText("t_y",   StringFormat("  ScrollY     : %.0f px", $fY))
    _ImGui_SetText("t_max", StringFormat("  ScrollMaxY  : %.0f px", $fMaxY))
    _ImGui_SetText("t_pct", StringFormat("  Vertical progress : %.1f %%", $fPct))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
