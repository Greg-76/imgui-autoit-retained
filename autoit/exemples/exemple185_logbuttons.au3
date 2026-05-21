#cs
================================================================================
 Example 185 : _ImGui_CreateLogButtons
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateLogButtons   Inline widget that renders ImGui's stock
                             "Log To TTY / File / Clipboard + Auto-open
                             depth" row

 This is the WIDGET-FLAVORED counterpart to the imperative LogTo* /
 LogFinish exports (exemple183). Different mental model :

   * exemple183 (LogTo*)         The SCRIPT triggers and terminates the
                                 session ; you choose the file path, the
                                 depth, the timing.
   * exemple185 (CreateLogButtons) ImGui draws the buttons in-tree ; the
                                 USER clicks them ; ImGui internally
                                 calls ImGui::LogToTTY / LogToFile /
                                 LogToClipboard at whatever depth the
                                 attached SliderInt shows. LogFinish is
                                 also handled by ImGui at end-of-frame.

 No event binding -- the embedded buttons are NOT addressable AutoIt
 widgets. Just place CreateLogButtons after the content you want
 captured ; rendering does the rest.

 Where does "Log To File" write ?
   To ImGui's default log filename, "imgui_log.txt", relative to the
   process CURRENT WORKING DIRECTORY. For an AutoIt script this is
   typically @WorkingDir, NOT @ScriptDir. The status panel below
   reports both so the user can locate the file.

 Quick A/B with exemple183 :
   * If you need scripted snapshots (timed dumps, automated diffs,
     annotated headers via LogText) -> exemple183 / exemple184.
   * If you want a ready-made UI for the user to dump the panel on
     demand                                 -> exemple185.

 Borrowed widgets : TreeNode (exemple134), CollapsingHeader
 (exemple135), SliderInt (exemple17), Text + Separator, Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple185_logbuttons.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple185_logbuttons.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 185 : _ImGui_CreateLogButtons", 780, 600) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateLogButtons  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateLogButtons($sId)
;
;   $sId : stable widget identifier (unique in the tree).
;
;   Return : True on success, False on failure (@error = 1, 2).
;
;   Pure marker -- the widget renders a row of stock ImGui buttons :
;     [ Log To TTY ] [ Log To File ] [ Log To Clipboard ]   default depth: N
;
;   Clicks are handled INSIDE ImGui. No SetOnClick binding is supported
;   (and would be ignored) -- the buttons are not separate AutoIt
;   widgets. The depth field next to them is an in-place SliderInt
;   wired straight to the ImGui::LogToXxx() arguments.
;
;   Like every other widget, it must live somewhere in the tree (a
;   Window, MainMenuBar, popup, ...). Place it adjacent to or below
;   the content you want captured ; ImGui's logging captures every
;   rendered window during the session, but placement-near-content
;   makes the UX clearer.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateLogButtons demo  --  in-tree stock buttons that drive LogTo* internally")
_ImGui_CreateText("t_hint",  "Click 'Log To File' below ; the dump appears at the path shown in the status box.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Capture target  --  rendered content the log will record
; ==============================================================================
_ImGui_CreateText("t_cap_hdr", "Capture target :")
_ImGui_CreateTreeNode("tn_root", "Section A  --  top-level node", 0)
_ImGui_CreateText("t_a1", "  A.1  --  plain text")
_ImGui_CreateText("t_a2", "  A.2  --  another line")
_ImGui_CreateCollapsingHeader("ch_nested", "Subsection (collapsible)", 0)
_ImGui_CreateText("t_n1", "    Nested 1")
_ImGui_CreateText("t_n2", "    Nested 2")
_ImGui_CreateSliderInt("sl_demo", "demo slider", 0, 100, 42, "%d")
_ImGui_CreateTreeNode("tn_b", "Section B  --  sibling top-level node", 0)
_ImGui_CreateText("t_b1", "  B.1  --  text inside B")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; The LogButtons widget itself  --  this is what example 185 is about
; ==============================================================================
_ImGui_CreateText("t_lb_hdr", "The widget  --  click any button to dump the current frame :")
_ImGui_CreateLogButtons("lb_dump")
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Status panel  --  reveal where the file ends up
; ==============================================================================
_ImGui_CreateText("t_paths_hdr", "Where files land :")
_ImGui_CreateText("t_wd",        "  @WorkingDir : " & @WorkingDir)
_ImGui_CreateText("t_sd",        "  @ScriptDir  : " & @ScriptDir)
_ImGui_CreateText("t_expected",  "  Expected log file : " & @WorkingDir & "\imgui_log.txt")
_ImGui_CreateText("t_size",      "  imgui_log.txt size : (not yet written)")
_ImGui_CreateSeparator("sep3")


_ImGui_CreateButton("btn_refresh", "Refresh file size readout")
_ImGui_CreateButton("btn_quit",    "Quit")


; --- Globals (none needed beyond the constant path) --------------------------
Global Const $g_sExpectedLog = @WorkingDir & "\imgui_log.txt"


; --- Bind --------------------------------------------------------------------
; NB : btn_quit + btn_refresh are addressable AutoIt buttons (we created them
; via _ImGui_CreateButton). The buttons INSIDE CreateLogButtons are NOT --
; trying _ImGui_SetOnClick("lb_dump", ...) would silently no-op (no clicked
; latch is raised by a layout marker).
_ImGui_SetOnClick("btn_refresh", "_OnRefresh")
_ImGui_SetOnClick("btn_quit",    "_OnQuit")
_ImGui_SetOnTick("_OnRefresh",   2000)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnRefresh($sId = "")
    Local $iSize = FileGetSize($g_sExpectedLog)
    If @error Or $iSize = "" Then
        _ImGui_SetText("t_size", "  imgui_log.txt size : (not yet written)")
    Else
        _ImGui_SetText("t_size", StringFormat( _
            "  imgui_log.txt size : %d bytes  (last refresh : %02d:%02d:%02d)", _
            $iSize, @HOUR, @MIN, @SEC))
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
