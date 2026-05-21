#cs
================================================================================
 Example 124 : _ImGui_SetScrollFromPosX
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetScrollFromPosX   Scroll horizontally so a LOCAL pixel position lands at a ratio

 SetScrollFromPosX is the explicit-coordinate sibling of
 SetScrollHereX. Instead of using the cursor's current position, you
 pass a specific LOCAL X (relative to the window's content area).
 The window scrolls so that local position lands at the requested
 horizontal center ratio of the visible area.

 Useful when you want to scroll to a position that is NOT the cursor's
 -- e.g. "scroll to the start of the third row" computed from a known
 layout, or "scroll to a 500-pixel marker" in a virtual canvas larger
 than the visible window.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple124_setscrollfromposx.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple124_setscrollfromposx.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 124 : _ImGui_SetScrollFromPosX", 740, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetScrollFromPosX  --  doc block
; ==============================================================================
; Signature : _ImGui_SetScrollFromPosX($sId, $fLocalPos, $fCenterRatio = 0.5)
;
;   $fLocalPos     : LOCAL X coordinate in pixels (relative to the
;                    window's content origin -- i.e. independent of the
;                    current scroll offset).
;   $fCenterRatio  : where $fLocalPos lands in the visible area
;                    (0 = left, 0.5 = center, 1 = right).
;
;   One-shot ; applied after children render.
;
;   Return : True on success, False on failure.


; ==============================================================================
; Host area widgets
; ==============================================================================
_ImGui_CreateText("t_title", "SetScrollFromPosX demo  --  scroll horizontally to a known local X")
_ImGui_CreateText("t_hint",  "Click a preset to scroll to a specific local-X coordinate in the target window.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_btn_hdr", "Scroll to local-X (centered) :")
_ImGui_CreateButton("btn_pos_0",    "LocalX = 0       (the start)")
_ImGui_CreateButton("btn_pos_300",  "LocalX = 300")
_ImGui_CreateButton("btn_pos_700",  "LocalX = 700")
_ImGui_CreateButton("btn_pos_1100", "LocalX = 1100")
_ImGui_CreateText("t_ratio_hdr", "Different ratios on LocalX = 500 :")
_ImGui_CreateButton("btn_500_left",  "LocalX = 500 at LEFT (ratio = 0)")
_ImGui_CreateButton("btn_500_right", "LocalX = 500 at RIGHT (ratio = 1)")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status",  "  ScrollX : 0 / 0")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window  --  wide virtual canvas via SetWindowContentSize
; ==============================================================================
_ImGui_CreateWindow("tgt", "Wide virtual canvas", True, $ImGuiWindowFlags_HorizontalScrollbar)
_ImGui_CreateText("tgt_intro", "I have a 1500-px wide content area (set every tick via SetWindowContentSize).")
_ImGui_SetParent("tgt_intro", "tgt")
_ImGui_CreateText("tgt_marks", "Markers (visual reference) : 0 -- 300 -- 600 -- 900 -- 1200 -- end")
_ImGui_SetParent("tgt_marks", "tgt")

_ImGui_SetWindowPos ("tgt", 280, 320, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 380, 180, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_pos_0",     "_OnPos0")
_ImGui_SetOnClick("btn_pos_300",   "_OnPos300")
_ImGui_SetOnClick("btn_pos_700",   "_OnPos700")
_ImGui_SetOnClick("btn_pos_1100",  "_OnPos1100")
_ImGui_SetOnClick("btn_500_left",  "_On500Left")
_ImGui_SetOnClick("btn_500_right", "_On500Right")
_ImGui_SetOnClick("btn_quit",      "_OnQuit")
; ContentSize is not sticky -- re-call each tick. Also poll the scroll readout.
_ImGui_SetOnTick ("_OnTick", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPos0($sId)
    _ImGui_SetScrollFromPosX("tgt", 0.0, 0.5)
EndFunc

Func _OnPos300($sId)
    _ImGui_SetScrollFromPosX("tgt", 300.0, 0.5)
EndFunc

Func _OnPos700($sId)
    _ImGui_SetScrollFromPosX("tgt", 700.0, 0.5)
EndFunc

Func _OnPos1100($sId)
    _ImGui_SetScrollFromPosX("tgt", 1100.0, 0.5)
EndFunc

Func _On500Left($sId)
    _ImGui_SetScrollFromPosX("tgt", 500.0, 0.0)
EndFunc

Func _On500Right($sId)
    _ImGui_SetScrollFromPosX("tgt", 500.0, 1.0)
EndFunc

Func _OnTick()
    ; Keep the virtual canvas size = 1500 px wide (SetWindowContentSize is
    ; not sticky -- see exemple111).
    _ImGui_SetWindowContentSize("tgt", 1500.0, 0.0)
    _ImGui_SetText("t_status", StringFormat("  ScrollX : %.0f / %.0f", _
                                            _ImGui_GetScrollX("tgt"), _ImGui_GetScrollMaxX("tgt")))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
