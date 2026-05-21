#cs
================================================================================
 Example 184 : _ImGui_LogText
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_LogText   Append literal text into the active log sink

 LogText is the COMPLEMENT to LogTo* / LogFinish (exemple183) : while
 LogTo* captures rendered widget text into a sink, LogText lets the
 script INJECT arbitrary text into the same stream. Use it to :
   * annotate snapshots ("=== before action ===", timestamps, ...)
   * mark sections ("[panel A]" / "[panel B]" headers)
   * embed external data (file contents, settings dump, error reasons)

 Key rules :
   * LogText is a NO-OP outside an active session (no error, no warn).
     Always pair it with a prior LogToFile / LogToTTY / LogToClipboard.
   * Embedded "%" characters are SAFE -- the wrapper passes the string
     through "%s" format. No format-string injection risk.
   * From the AutoIt thread, LogText injects between the surrounding
     render-thread captures : the exact ordering relative to widget
     text depends on when frames render between your calls. For
     reliable headers/footers, call LogText IMMEDIATELY after LogTo*
     and IMMEDIATELY before LogFinish.

 This example exposes the session lifecycle as three explicit steps :
   1. "Open log" button       -> LogToFile  + LogText("=== Header ===")
   2. "Append text" buttons   -> LogText(user-edited line)
   3. "Close log" button      -> LogText("=== Footer ===") + LogFinish
 The user can verify : clicking "Append text" before "Open log" does
 nothing (silent no-op), and the file written includes the injected
 lines bracketing the captured UI snapshot.

 Borrowed widgets : Button, InputText (exemple147), Checkbox, Text +
 Separator. Re-uses the pending-finish pattern from exemple183.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple184_logtext.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple184_logtext.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 184 : _ImGui_LogText", 780, 600) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_LogText  --  doc block
; ==============================================================================
; Signature : _ImGui_LogText($sText)
;
;   $sText : literal text to append to the active log sink (UTF-8).
;            Embedded "%" characters are sent through "%s" -- safe.
;
;   Return : True on success, False on failure (@error = 1 DLL not
;            loaded, 2 DllCall failed).
;
;   Important : NO-OP if no log session is active (no error raised).
;               The caller is responsible for pairing with LogTo* /
;               LogFinish (see exemple183).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "LogText demo  --  inject literal text into the active log sink")
_ImGui_CreateText("t_hint",  "Open the log, append a few lines, close it -- then check log_text_dump.txt.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Step 1  --  Open the log
; ==============================================================================
_ImGui_CreateText("t_step1", "Step 1  --  Open a file-backed log session :")
_ImGui_CreateButton("btn_open", "Open log (LogToFile + LogText header)")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Step 2  --  Append user-edited text
; ==============================================================================
_ImGui_CreateText("t_step2", "Step 2  --  Append literal text (works only while a session is active) :")
_ImGui_CreateInputText("in_line", "##line", "annotation : 100% complete", 256)
_ImGui_CreateButton("btn_append", "Append this line to the log")
_ImGui_CreateText("t_safe_hint", "  Tip : embedded '%' characters are passed safely through '%s' -- no format-string issue.")
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Step 3  --  Close the log
; ==============================================================================
_ImGui_CreateText("t_step3", "Step 3  --  Close the session (LogText footer + LogFinish) :")
_ImGui_CreateButton("btn_close", "Close log")
_ImGui_CreateSeparator("sep3")


; ==============================================================================
; Status + counters
; ==============================================================================
_ImGui_CreateText("t_session",  "Session : closed.")
_ImGui_CreateText("t_appends",  "Appends so far this session : 0  (lifetime : 0)")
_ImGui_CreateText("t_last_act", "Last action : none.")
_ImGui_CreateSeparator("sep4")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Globals -----------------------------------------------------------------
Global Const $g_sLogFile = @ScriptDir & "\log_text_dump.txt"
Global $g_bSessionOpen      = False
Global $g_iAppendsSession   = 0
Global $g_iAppendsLifetime  = 0
Global $g_bPendingClose     = False    ; armed by btn_close ; flushed at next tick


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_open",   "_OnOpen")
_ImGui_SetOnClick("btn_append", "_OnAppend")
_ImGui_SetOnClick("btn_close",  "_OnClose")
_ImGui_SetOnClick("btn_quit",   "_OnQuit")
_ImGui_SetOnTick("_OnFlushTick", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnOpen($sId)
    If $g_bSessionOpen Then
        _ImGui_SetText("t_last_act", "Last action : Open ignored -- a session is already active.")
        Return
    EndIf
    ; Use depth = 0 so the file mostly reflects the explicit LogText injections
    ; (no nested auto-open noise).
    _ImGui_LogToFile(0, $g_sLogFile)
    _ImGui_LogText("=== Snapshot opened " & _DateTimeNowIso() & " ===" & @CRLF)
    $g_bSessionOpen      = True
    $g_iAppendsSession   = 0
    _ImGui_SetText("t_session",  "Session : OPEN  --  " & $g_sLogFile)
    _ImGui_SetText("t_last_act", "Last action : LogToFile + LogText(header).")
EndFunc

Func _OnAppend($sId)
    Local $sLine = _ImGui_GetValueString("in_line")
    If Not $g_bSessionOpen Then
        ; Demonstrate the no-op semantics : LogText returns success but no
        ; output is produced. Surface this in the UI so the user notices.
        _ImGui_LogText($sLine & @CRLF)  ; intentional no-op
        _ImGui_SetText("t_last_act", "Last action : LogText called WITHOUT an open session -- silent no-op.")
        Return
    EndIf
    _ImGui_LogText($sLine & @CRLF)
    $g_iAppendsSession  += 1
    $g_iAppendsLifetime += 1
    _ImGui_SetText("t_appends", StringFormat( _
        "Appends so far this session : %d  (lifetime : %d)", _
        $g_iAppendsSession, $g_iAppendsLifetime))
    _ImGui_SetText("t_last_act", "Last action : LogText appended " & StringLen($sLine) & " chars.")
EndFunc

Func _OnClose($sId)
    If Not $g_bSessionOpen Then
        _ImGui_SetText("t_last_act", "Last action : Close ignored -- no session is open.")
        Return
    EndIf
    _ImGui_LogText("=== Snapshot closed " & _DateTimeNowIso() & " ===" & @CRLF)
    $g_bPendingClose = True
    _ImGui_SetText("t_last_act", "Last action : LogText(footer) -- flushing on next tick.")
EndFunc

Func _OnFlushTick()
    If Not $g_bPendingClose Then Return
    _ImGui_LogFinish()
    $g_bPendingClose = False
    $g_bSessionOpen  = False
    Local $iSize = FileGetSize($g_sLogFile)
    If $iSize = "" Then $iSize = -1
    _ImGui_SetText("t_session",  "Session : closed.")
    _ImGui_SetText("t_last_act", StringFormat( _
        "Last action : LogFinish -- %s (%d bytes, %d appends in session).", _
        $g_sLogFile, $iSize, $g_iAppendsSession))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc


; Helper : ISO-ish timestamp for log markers.
Func _DateTimeNowIso()
    Return StringFormat("%04d-%02d-%02d %02d:%02d:%02d", _
        @YEAR, @MON, @MDAY, @HOUR, @MIN, @SEC)
EndFunc
