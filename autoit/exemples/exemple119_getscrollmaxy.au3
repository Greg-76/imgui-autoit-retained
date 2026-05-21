#cs
================================================================================
 Example 119 : _ImGui_GetScrollMaxY
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_GetScrollMaxY   Read the maximum vertical scroll offset of a window

 Vertical mirror of GetScrollMaxX (exemple118). Returns the largest
 valid GetScrollY value -- 0 if the content fits vertically without
 overflow.

 Use cases :
   - Detect "scrolled to bottom" with GetScrollY == GetScrollMaxY
     (canonical condition for log-panel auto-scroll : if the user
     was at the bottom and a new line appears, scroll to the new
     bottom ; if not, leave them where they are).
   - Compute a vertical scroll-progress percent.

 Persistent state ; 50 ms polling reliable. Returns 0 on unknown id.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple119_getscrollmaxy.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple119_getscrollmaxy.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 119 : _ImGui_GetScrollMaxY", 720, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_GetScrollMaxY  --  doc block
; ==============================================================================
; Signature : _ImGui_GetScrollMaxY($sId)
;
;   Returns the largest valid vertical scroll offset, in pixels.
;   0 means the content fits vertically.
;
;   Canonical use : pair with GetScrollY to detect "at the bottom"
;     If GetScrollY($sId) >= GetScrollMaxY($sId) Then
;         ; user is scrolled to the very bottom
;     EndIf
;
;   Persistent state ; refreshes each frame. Returns 0 on unknown id.


; ==============================================================================
; Host area widgets
; ==============================================================================
_ImGui_CreateText("t_title", "GetScrollMaxY demo  --  detect 'scrolled to bottom' + live progress")
_ImGui_CreateText("t_hint",  "Scroll the target window. The status panel shows the current Y, the max Y, and whether the user is at the bottom.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_status_hdr", "Scroll panel :")
_ImGui_CreateText("t_y",       "  ScrollY    : 0 px")
_ImGui_CreateText("t_max",     "  ScrollMaxY : 0 px")
_ImGui_CreateText("t_pct",     "  Progress   : 0 %")
_ImGui_CreateText("t_at_end",  "  At bottom  : (waiting)")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window  --  long scrollable list
; ==============================================================================
_ImGui_CreateWindow("tgt", "Scroll target", True, 0)
_ImGui_CreateText("tgt_head", "Top of the list. Scroll down to see all items.")
_ImGui_SetParent("tgt_head", "tgt")

For $i = 1 To 60
    Local $sId = "tgt_item_" & $i
    _ImGui_CreateText($sId, "  Item #" & $i & " of the long list.")
    _ImGui_SetParent($sId, "tgt")
Next

_ImGui_CreateText("tgt_tail", "Bottom of the list. ScrollY now equals ScrollMaxY.")
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
    ; Canonical "at bottom" check : 1-pixel tolerance for rounding.
    Local $bAtEnd = ($fMaxY > 0) And (($fMaxY - $fY) < 1.0)
    _ImGui_SetText("t_y",      StringFormat("  ScrollY    : %.0f px", $fY))
    _ImGui_SetText("t_max",    StringFormat("  ScrollMaxY : %.0f px", $fMaxY))
    _ImGui_SetText("t_pct",    StringFormat("  Progress   : %.1f %%", $fPct))
    _ImGui_SetText("t_at_end", "  At bottom  : " & ($bAtEnd ? "YES (auto-scroll on new content)" : "no  (preserve user scroll)"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
