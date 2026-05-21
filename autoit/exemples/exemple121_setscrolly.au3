#cs
================================================================================
 Example 121 : _ImGui_SetScrollY
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetScrollY   Queue an absolute vertical scroll for the next frame

 Vertical mirror of SetScrollX (exemple120). Sets the window's
 vertical scroll to an absolute pixel offset, applied AFTER the
 children are laid out.

 CANONICAL USE -- log-panel auto-scroll-to-bottom :
     Func _OnNewLogLine()
         AppendLineToTextWidget(...)
         If _bUserWasAtBottom Then           ; the "sticky-tail" check
             _ImGui_SetScrollY("log_panel", 99999.0)   ; clamps to MaxY
         EndIf
     EndFunc

 The "user was at bottom" gate is essential : without it, the panel
 auto-scrolls even when the user has scrolled up to read older
 entries. Compute it via _ImGui_GetScrollY / _ImGui_GetScrollMaxY
 (see exemple119).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple121_setscrolly.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple121_setscrolly.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 121 : _ImGui_SetScrollY", 720, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetScrollY  --  doc block
; ==============================================================================
; Signature : _ImGui_SetScrollY($sId, $fScroll)
;
;   $fScroll : vertical scroll target in pixels. 0 = top.
;              Values >= GetScrollMaxY clamp to the maximum.
;
;   One-shot ; applied AFTER children are rendered.
;
;   Return : True on success, False on failure.


; ==============================================================================
; Host area widgets  --  buttons + auto-scroll log demo
; ==============================================================================
_ImGui_CreateText("t_title", "SetScrollY demo  --  canonical auto-scroll-to-bottom for a log panel")
_ImGui_CreateText("t_hint",  "Click 'Append line' a few times. The log auto-scrolls only if you were already at the bottom.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_btn_hdr", "Snap vertical scroll :")
_ImGui_CreateButton("btn_top",    "Snap to 0    (top)")
_ImGui_CreateButton("btn_mid",    "Snap to 200  (mid)")
_ImGui_CreateButton("btn_bottom", "Snap to 99999 (clamp to MaxY = bottom)")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_log_hdr",    "Auto-scroll log demo (sticky-tail) :")
_ImGui_CreateButton("btn_append", "Append a new line to the log panel")
_ImGui_CreateText("t_status",     "  ScrollY : 0 / 0   was-at-bottom : (waiting)")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit",   "Quit")


; ==============================================================================
; The target sub-window  --  pre-populated with a few lines, more get appended
; ==============================================================================
_ImGui_CreateWindow("tgt", "Log panel (sticky tail)", True, 0)
_ImGui_CreateText("tgt_head", "[log start]")
_ImGui_SetParent("tgt_head", "tgt")

; Seed a baseline of lines so the scrollbar is visible from the first frame.
Global $g_iLineCount = 12
For $i = 1 To $g_iLineCount
    Local $sId = "tgt_line_" & $i
    _ImGui_CreateText($sId, StringFormat("  [%02d] line content", $i))
    _ImGui_SetParent($sId, "tgt")
Next

_ImGui_SetWindowPos ("tgt", 280, 280, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 360, 180, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_top",    "_OnTop")
_ImGui_SetOnClick("btn_mid",    "_OnMid")
_ImGui_SetOnClick("btn_bottom", "_OnBottom")
_ImGui_SetOnClick("btn_append", "_OnAppend")
_ImGui_SetOnClick("btn_quit",   "_OnQuit")
_ImGui_SetOnTick ("_OnPollY", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnTop($sId)
    _ImGui_SetScrollY("tgt", 0.0)
EndFunc

Func _OnMid($sId)
    _ImGui_SetScrollY("tgt", 200.0)
EndFunc

Func _OnBottom($sId)
    _ImGui_SetScrollY("tgt", 99999.0)
EndFunc

Func _OnAppend($sId)
    ; Capture the "was at bottom" gate BEFORE appending (the new line will
    ; grow ScrollMaxY, so checking after-the-fact would be inaccurate).
    Local $fY    = _ImGui_GetScrollY("tgt")
    Local $fMaxY = _ImGui_GetScrollMaxY("tgt")
    Local $bWasAtBottom = ($fMaxY > 0) And (($fMaxY - $fY) < 1.0)

    ; Append a new line. In retained mode the tree is built once at script
    ; init, so we can't add tree widgets after the main loop has started.
    ; To simulate the append, we mutate the LAST seed line's text -- the
    ; effect on layout / ScrollMaxY is similar enough for the demo.
    $g_iLineCount += 1
    _ImGui_SetText("tgt_line_12", StringFormat("  [12] line content (last appended -- count = %d)", $g_iLineCount))

    If $bWasAtBottom Then
        _ImGui_SetScrollY("tgt", 99999.0)
    EndIf
EndFunc

Func _OnPollY()
    Local $fY    = _ImGui_GetScrollY("tgt")
    Local $fMaxY = _ImGui_GetScrollMaxY("tgt")
    Local $bAtBottom = ($fMaxY > 0) And (($fMaxY - $fY) < 1.0)
    _ImGui_SetText("t_status", StringFormat("  ScrollY : %.0f / %.0f   was-at-bottom : %s", _
                                            $fY, $fMaxY, ($bAtBottom ? "YES" : "no")))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
