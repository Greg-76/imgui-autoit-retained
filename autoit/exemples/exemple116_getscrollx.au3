#cs
================================================================================
 Example 116 : _ImGui_GetScrollX
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_GetScrollX   Read the current horizontal scroll offset of a window

 Returns a float in pixels : how far to the right the window's
 client area is scrolled. 0 means no horizontal scroll (left-most).
 The maximum is GetScrollMaxX (exemple118).

 Persistent state ; 50 ms polling reliable. Returns 0 on unknown
 / non-scrollable window (no @error -- defensive, like the Item Is*
 queries).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple116_getscrollx.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple116_getscrollx.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 116 : _ImGui_GetScrollX", 720, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_GetScrollX  --  doc block
; ==============================================================================
; Signature : _ImGui_GetScrollX($sId)
;
;   Returns the horizontal scroll offset in pixels. 0 = left-most.
;
;   Requires the window to have a horizontal scrollbar (either the
;   $ImGuiWindowFlags_HorizontalScrollbar flag is set, or
;   $ImGuiWindowFlags_AlwaysHorizontalScrollbar). Otherwise the
;   window doesn't scroll horizontally and the value stays at 0.
;
;   Persistent state ; 50 ms polling reliable. Returns 0 on unknown
;   widget (no @error).


; ==============================================================================
; Host area widgets
; ==============================================================================
_ImGui_CreateText("t_title", "GetScrollX demo  --  live horizontal scroll offset")
_ImGui_CreateText("t_hint",  "Scroll the target window left / right using the bottom bar. The readout updates ~20 Hz.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_status_hdr", "Scroll panel :")
_ImGui_CreateText("t_x",   "  ScrollX     : 0 px")
_ImGui_CreateText("t_max", "  ScrollMaxX  : 0 px")
_ImGui_CreateText("t_pct", "  Horizontal progress : 0 %")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window  --  HorizontalScrollbar + content wider than the window.
; ==============================================================================
_ImGui_CreateWindow("tgt", "Scroll me horizontally", True, $ImGuiWindowFlags_HorizontalScrollbar)
_ImGui_CreateText("tgt_t1", "Drag the horizontal bar at the bottom of this window. The host readout updates live.")
_ImGui_SetParent("tgt_t1", "tgt")

; Long single-line label = wide content = forces a horizontal scrollbar.
_ImGui_CreateText("tgt_long", "(very long single-line) -- aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
_ImGui_SetParent("tgt_long", "tgt")

_ImGui_SetWindowPos ("tgt", 280, 220, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 380, 180, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollScrollX", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollScrollX()
    Local $fX    = _ImGui_GetScrollX("tgt")
    Local $fMaxX = _ImGui_GetScrollMaxX("tgt")
    Local $fPct  = ($fMaxX = 0) ? 0.0 : ($fX / $fMaxX) * 100.0
    _ImGui_SetText("t_x",   StringFormat("  ScrollX     : %.0f px", $fX))
    _ImGui_SetText("t_max", StringFormat("  ScrollMaxX  : %.0f px", $fMaxX))
    _ImGui_SetText("t_pct", StringFormat("  Horizontal progress : %.1f %%", $fPct))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
