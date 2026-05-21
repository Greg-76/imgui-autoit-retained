#cs
================================================================================
 Example 123 : _ImGui_SetScrollHereY
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetScrollHereY   Scroll vertically so a specific child widget is visible

 Vertical mirror of SetScrollHereX (exemple122). Brings the cursor's
 current Y position into view at the given vertical center ratio.

 CANONICAL USE -- "jump to selected item" in a long list :
   1. The user picks an entry in some external selector (combo,
      keystroke handler, search box, ...).
   2. The script computes the entry's id (stable widget identifier).
   3. The script calls a helper that calls _ImGui_SetScrollY with the
      entry's known local-Y offset, OR places a one-shot SetScrollHereY
      marker right after it (current wrapper exposes the marker only at
      script-init time -- see exemple122 for the runtime workaround).

 $fCenterRatio :
     0.0  = align at the TOP of the visible area
     0.5  = center vertically (default)
     1.0  = align at the BOTTOM

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple123_setscrollherey.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple123_setscrollherey.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 123 : _ImGui_SetScrollHereY", 740, 560) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetScrollHereY  --  doc block
; ==============================================================================
; Signature : _ImGui_SetScrollHereY($sId, $fCenterRatio = 0.5)
;
;   Same semantics as SetScrollHereX but for the Y axis.
;
;   Return : True on success, False on failure.


; ==============================================================================
; Host area widgets  --  buttons to jump to specific lines in a long list
; ==============================================================================
_ImGui_CreateText("t_title", "SetScrollHereY demo  --  jump-to-item in a long list (centered / top / bottom)")
_ImGui_CreateText("t_hint",  "Click a 'Jump to line N' button. The list scrolls so the chosen line lands at the requested vertical position.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_btn_hdr", "Jump targets (centered) :")
_ImGui_CreateButton("btn_line_1",  "Jump to line 1   (centered)")
_ImGui_CreateButton("btn_line_15", "Jump to line 15 (centered)")
_ImGui_CreateButton("btn_line_30", "Jump to line 30 (centered)")
_ImGui_CreateButton("btn_line_45", "Jump to line 45 (centered)")
_ImGui_CreateText("t_ratio_hdr", "Other centering on line 30 :")
_ImGui_CreateButton("btn_30_top",    "Align line 30 at TOP    (ratio = 0.0)")
_ImGui_CreateButton("btn_30_bottom", "Align line 30 at BOTTOM (ratio = 1.0)")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status",  "  ScrollY : 0 / 0")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window  --  60 items, more than fits in the visible area
; ==============================================================================
_ImGui_CreateWindow("tgt", "Long list target", True, 0)
_ImGui_CreateText("tgt_intro", "Use the host buttons to jump to a specific line.")
_ImGui_SetParent("tgt_intro", "tgt")

For $i = 1 To 60
    Local $sId = "tgt_line_" & $i
    _ImGui_CreateText($sId, StringFormat("  Line %02d : item content", $i))
    _ImGui_SetParent($sId, "tgt")
Next

_ImGui_SetWindowPos ("tgt", 280, 320, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 360, 200, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_line_1",     "_OnLine1")
_ImGui_SetOnClick("btn_line_15",    "_OnLine15")
_ImGui_SetOnClick("btn_line_30",    "_OnLine30")
_ImGui_SetOnClick("btn_line_45",    "_OnLine45")
_ImGui_SetOnClick("btn_30_top",    "_OnLine30Top")
_ImGui_SetOnClick("btn_30_bottom", "_OnLine30Bottom")
_ImGui_SetOnClick("btn_quit",      "_OnQuit")
_ImGui_SetOnTick ("_OnPollY", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

; Compute the line's local-Y offset, then SetScrollY to place it at the
; requested center ratio in the visible area. Equivalent to SetScrollHereY
; with the marker placed right after the line.
Func _JumpToLine($iN, $fCenterRatio)
    Local $sLineId = "tgt_line_" & $iN
    Local $aMin    = _ImGui_GetItemRectMin($sLineId)
    Local $aSz     = _ImGui_GetItemRectSize($sLineId)
    Local $aWPos   = _ImGui_GetWindowPos("tgt")
    Local $aWSz    = _ImGui_GetWindowSize("tgt")
    If Not IsArray($aMin) Or Not IsArray($aSz) Or Not IsArray($aWPos) Or Not IsArray($aWSz) Then Return
    Local $fScrollY = _ImGui_GetScrollY("tgt")
    Local $fLocalY  = $aMin[1] - $aWPos[1] + $fScrollY
    Local $fTarget  = $fLocalY - ($aWSz[1] * $fCenterRatio) + ($aSz[1] * $fCenterRatio)
    _ImGui_SetScrollY("tgt", $fTarget)
EndFunc

Func _OnLine1($sId)
    _JumpToLine(1, 0.5)
EndFunc

Func _OnLine15($sId)
    _JumpToLine(15, 0.5)
EndFunc

Func _OnLine30($sId)
    _JumpToLine(30, 0.5)
EndFunc

Func _OnLine45($sId)
    _JumpToLine(45, 0.5)
EndFunc

Func _OnLine30Top($sId)
    _JumpToLine(30, 0.0)
EndFunc

Func _OnLine30Bottom($sId)
    _JumpToLine(30, 1.0)
EndFunc

Func _OnPollY()
    _ImGui_SetText("t_status", StringFormat("  ScrollY : %.0f / %.0f", _
                                            _ImGui_GetScrollY("tgt"), _ImGui_GetScrollMaxY("tgt")))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
