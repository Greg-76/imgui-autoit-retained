#cs
================================================================================
 Example 125 : _ImGui_SetScrollFromPosY
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetScrollFromPosY   Scroll vertically so a LOCAL pixel position lands at a ratio

 Vertical mirror of SetScrollFromPosX (exemple124). Useful when you
 know the exact local-Y of a target inside a tall virtual canvas
 (e.g. a custom drawing area, a fixed-row-height list where you
 compute Y = rowIndex * rowHeight, ...).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple125_setscrollfromposy.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple125_setscrollfromposy.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 125 : _ImGui_SetScrollFromPosY", 720, 560) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetScrollFromPosY  --  doc block
; ==============================================================================
; Signature : _ImGui_SetScrollFromPosY($sId, $fLocalPos, $fCenterRatio = 0.5)
;
;   $fLocalPos     : LOCAL Y coordinate in pixels (relative to the
;                    window's content origin).
;   $fCenterRatio  : 0 = top of visible area, 0.5 = centered, 1 = bottom.
;
;   One-shot ; applied after children render.
;
;   Return : True on success, False on failure.


; ==============================================================================
; Host area widgets
; ==============================================================================
_ImGui_CreateText("t_title", "SetScrollFromPosY demo  --  scroll vertically to a known local Y")
_ImGui_CreateText("t_hint",  "Click a preset to scroll to a specific local-Y in a tall virtual canvas.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_btn_hdr", "Scroll to local-Y (centered) :")
_ImGui_CreateButton("btn_pos_0",   "LocalY = 0      (the start)")
_ImGui_CreateButton("btn_pos_400", "LocalY = 400")
_ImGui_CreateButton("btn_pos_900", "LocalY = 900")
_ImGui_CreateButton("btn_pos_1400","LocalY = 1400 (near the bottom)")
_ImGui_CreateText("t_ratio_hdr", "Different ratios on LocalY = 700 :")
_ImGui_CreateButton("btn_700_top",    "LocalY = 700 at TOP    (ratio = 0)")
_ImGui_CreateButton("btn_700_bottom", "LocalY = 700 at BOTTOM (ratio = 1)")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status",  "  ScrollY : 0 / 0")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window  --  tall virtual canvas via SetWindowContentSize
; ==============================================================================
_ImGui_CreateWindow("tgt", "Tall virtual canvas", True, 0)
_ImGui_CreateText("tgt_intro", "I have a 1500-px tall content area (set every tick via SetWindowContentSize).")
_ImGui_SetParent("tgt_intro", "tgt")
_ImGui_CreateText("tgt_marks", "Reference markers in the source : Y=0 / Y=400 / Y=900 / Y=1400 / end")
_ImGui_SetParent("tgt_marks", "tgt")

_ImGui_SetWindowPos ("tgt", 280, 320, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 360, 200, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_pos_0",       "_OnPos0")
_ImGui_SetOnClick("btn_pos_400",     "_OnPos400")
_ImGui_SetOnClick("btn_pos_900",     "_OnPos900")
_ImGui_SetOnClick("btn_pos_1400",    "_OnPos1400")
_ImGui_SetOnClick("btn_700_top",     "_On700Top")
_ImGui_SetOnClick("btn_700_bottom",  "_On700Bottom")
_ImGui_SetOnClick("btn_quit",        "_OnQuit")
_ImGui_SetOnTick ("_OnTick", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPos0($sId)
    _ImGui_SetScrollFromPosY("tgt", 0.0, 0.5)
EndFunc

Func _OnPos400($sId)
    _ImGui_SetScrollFromPosY("tgt", 400.0, 0.5)
EndFunc

Func _OnPos900($sId)
    _ImGui_SetScrollFromPosY("tgt", 900.0, 0.5)
EndFunc

Func _OnPos1400($sId)
    _ImGui_SetScrollFromPosY("tgt", 1400.0, 0.5)
EndFunc

Func _On700Top($sId)
    _ImGui_SetScrollFromPosY("tgt", 700.0, 0.0)
EndFunc

Func _On700Bottom($sId)
    _ImGui_SetScrollFromPosY("tgt", 700.0, 1.0)
EndFunc

Func _OnTick()
    _ImGui_SetWindowContentSize("tgt", 0.0, 1500.0)
    _ImGui_SetText("t_status", StringFormat("  ScrollY : %.0f / %.0f", _
                                            _ImGui_GetScrollY("tgt"), _ImGui_GetScrollMaxY("tgt")))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
