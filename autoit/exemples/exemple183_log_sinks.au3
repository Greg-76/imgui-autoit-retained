#cs
================================================================================
 Example 183 : Log sinks  --  LogToTTY / LogToFile / LogToClipboard / LogFinish
================================================================================
 Covers 4 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_LogToTTY        Start capturing rendered text into stdout
   _ImGui_LogToFile       Start capturing rendered text into a file
   _ImGui_LogToClipboard  Start capturing rendered text into the OS clipboard
   _ImGui_LogFinish       Flush + close the active capture session

 All four are bundled because they describe the SAME stateful session :
 LogTo* opens it (one of three sinks) ; LogFinish always terminates it.
 Demonstrating any one alone leaves either an open session or an unused
 sink -- they only make sense together.

 What is "logging" in ImGui ?
   A capture mode that mirrors every rendered widget's TEXT into the
   chosen sink. Useful for textual screenshots, regression diffs, paste-
   to-issue snapshots. It does NOT capture pixels -- only the labels,
   values, and tree structure the widgets emit during render.

 $iAutoOpenDepth (all three LogTo* take it ; LogToFile requires it) :
   -1 = use ImGui's current default
    0 = do NOT auto-open any nested TreeNode / CollapsingHeader -- the
        log captures only what's already expanded.
   >0 = max depth to auto-open during capture. Lets a snapshot include
        nested content even when the live UI has it collapsed.

 Session pattern (the canonical idiom on a retained-mode binding) :
   1. Click "Log to ..." button.
   2. Handler calls _ImGui_LogToFile / TTY / Clipboard and arms a
      "pending finish" flag.
   3. A _ImGui_SetOnTick(50 ms) tick handler calls _ImGui_LogFinish
      AFTER the render thread has had a frame to capture.
   Calling LogTo* + LogFinish back-to-back in the same AutoIt tick
   captures NOTHING -- the render thread has not produced a frame yet
   between the two calls. New "Logging is a session, not a one-shot"
   pitfall (see NOTES.md Decisions log).

 The capture target is the TreeNode + nested widgets below ; tweak the
 depth slider to see auto-opening at work.

 Borrowed widgets : Button, SliderInt, TreeNode, CollapsingHeader, Text
 + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple183_log_sinks.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple183_log_sinks.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 183 : Log sinks  --  LogTo* + LogFinish", 780, 620) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 4-export cluster
; ==============================================================================
; _ImGui_LogToTTY      ([$iAutoOpenDepth = -1])               -> Bool
; _ImGui_LogToFile     ($iAutoOpenDepth, $sFilename)           -> Bool
; _ImGui_LogToClipboard([$iAutoOpenDepth = -1])               -> Bool
; _ImGui_LogFinish     ()                                      -> Bool
;
;   LogTo*       : opens a capture session writing rendered text to the
;                  matching sink. The session stays open across frames
;                  until LogFinish is called -- so each frame rendered
;                  in the meantime APPENDS its widget text to the sink.
;   LogFinish    : closes the active session, flushing buffers (TTY)
;                  or closing the file handle (File) or committing the
;                  clipboard write (Clipboard). No-op if no session is
;                  active.
;
;   All four return : True on success, False on failure
;                     (@error = 1 DLL not loaded, 2 DllCall failed)
;
;   Gotchas :
;     * Only ONE session can be active at a time. Calling LogTo* twice
;       in a row without LogFinish in between is undefined territory --
;       use the pending-finish pattern to be safe.
;     * The session is GLOBAL (not per-window) : every window rendered
;       between LogTo* and LogFinish contributes to the sink.
;     * LogToFile overwrites the target file ; no append mode.
;     * Clipboard sink commits in a system-native format ; paste into
;       a text editor to verify.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "Log sinks demo  --  TTY / File / Clipboard + LogFinish")
_ImGui_CreateText("t_hint",  "Pick a sink with the buttons below ; tweak $iAutoOpenDepth to expand nested capture.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Auto-open depth control  --  applied to ALL three LogTo* calls
; ==============================================================================
_ImGui_CreateText("t_depth_hdr", "$iAutoOpenDepth  --  -1 = default, 0 = none, >0 = max depth to auto-open during capture :")
_ImGui_CreateSliderInt("sl_depth", "##depth", -1, 5, -1, "depth = %d")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Sink buttons
; ==============================================================================
_ImGui_CreateText("t_sink_hdr", "Trigger a capture session :")
_ImGui_CreateButton("btn_tty",  "Log to TTY (stdout)")
_ImGui_CreateButton("btn_file", "Log to File (" & @ScriptDir & "\log_dump.txt)")
_ImGui_CreateButton("btn_clip", "Log to Clipboard (paste into a text editor)")
_ImGui_CreateText("t_status",  "Status : idle.")
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Capture target  --  this is the content the log will record
; ==============================================================================
_ImGui_CreateText("t_cap_hdr", "Capture target (collapse / expand to see depth effect) :")
_ImGui_CreateTreeNode("tn_root", "Section A  --  top-level node", 0)
_ImGui_CreateText("t_a1", "  A.1  --  plain text")
_ImGui_CreateText("t_a2", "  A.2  --  another line")
_ImGui_CreateCollapsingHeader("ch_nested", "Subsection (collapsible)", 0)
_ImGui_CreateText("t_n1", "    Nested 1")
_ImGui_CreateText("t_n2", "    Nested 2")
_ImGui_CreateSliderInt("sl_demo", "demo slider", 0, 100, 42, "%d")
_ImGui_CreateTreeNode("tn_b", "Section B  --  sibling top-level node", 0)
_ImGui_CreateText("t_b1", "  B.1  --  text inside B")
_ImGui_CreateSeparator("sep3")


_ImGui_CreateButton("btn_quit", "Quit")


; --- Globals (must precede first use under MustDeclareVars) ------------------
; The "pending finish" flag : one of "", "tty", "file", "clipboard". When non-
; empty, the next tick of _OnFlushTick will call LogFinish and update status.
Global $g_sPendingSink = ""
Global Const $g_sLogFile = @ScriptDir & "\log_dump.txt"
Global $g_iSessionCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_tty",  "_OnLogTTY")
_ImGui_SetOnClick("btn_file", "_OnLogFile")
_ImGui_SetOnClick("btn_clip", "_OnLogClipboard")
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnFlushTick", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnLogTTY($sId)
    If $g_sPendingSink <> "" Then Return  ; another session already arming
    Local $iDepth = _ImGui_GetValueInt("sl_depth")
    _ImGui_LogToTTY($iDepth)
    $g_sPendingSink = "tty"
    _ImGui_SetText("t_status", "Status : capturing to stdout (depth=" & $iDepth & ")...")
EndFunc

Func _OnLogFile($sId)
    If $g_sPendingSink <> "" Then Return
    Local $iDepth = _ImGui_GetValueInt("sl_depth")
    _ImGui_LogToFile($iDepth, $g_sLogFile)
    $g_sPendingSink = "file"
    _ImGui_SetText("t_status", "Status : capturing to file (depth=" & $iDepth & ")...")
EndFunc

Func _OnLogClipboard($sId)
    If $g_sPendingSink <> "" Then Return
    Local $iDepth = _ImGui_GetValueInt("sl_depth")
    _ImGui_LogToClipboard($iDepth)
    $g_sPendingSink = "clipboard"
    _ImGui_SetText("t_status", "Status : capturing to clipboard (depth=" & $iDepth & ")...")
EndFunc

Func _OnFlushTick()
    If $g_sPendingSink = "" Then Return
    _ImGui_LogFinish()
    $g_iSessionCount += 1
    Local $sSink = $g_sPendingSink
    $g_sPendingSink = ""
    Switch $sSink
        Case "tty"
            _ImGui_SetText("t_status", StringFormat( _
                "Status : LogToTTY -> stdout flushed. Sessions: %d.", $g_iSessionCount))
        Case "file"
            Local $iSize = FileGetSize($g_sLogFile)
            If $iSize = "" Then $iSize = -1
            _ImGui_SetText("t_status", StringFormat( _
                "Status : LogToFile -> %s (%d bytes). Sessions: %d.", _
                $g_sLogFile, $iSize, $g_iSessionCount))
        Case "clipboard"
            _ImGui_SetText("t_status", StringFormat( _
                "Status : LogToClipboard -> ready to paste (Ctrl+V). Sessions: %d.", _
                $g_iSessionCount))
    EndSwitch
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
