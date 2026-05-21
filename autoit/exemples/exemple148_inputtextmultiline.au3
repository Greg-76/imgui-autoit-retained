#cs
================================================================================
 Example 148 : _ImGui_CreateInputTextMultiline
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateInputTextMultiline   Multi-line text editor

 Like _ImGui_CreateInputText (exemple147) but with an explicit $fW /
 $fH sized box and Enter producing a newline instead of committing.
 Re-uses the SAME read / write API : _ImGui_GetValueString and
 _ImGui_SetValueString (both work on any string-valued widget).

 Two notable flags specific to multi-line :
   * CtrlEnterForNewLine (256)  Enter validates, Ctrl+Enter inserts
                                newline. Combine with EnterReturnsTrue
                                to read "user pressed Enter (=commit)".
   * WordWrap (16777216)        wrap long lines at the box width
                                instead of horizontal scrolling.

 Read buffer sizing : $iMaxLength defaults to 1024 (vs 256 for the
 single-line variant). For large notes / scripts, bump $iMaxLength
 at creation AND $iBufSize at GetValueString time. The wrapper
 surfaces truncation via @extended = 4 (soft error -- partial string
 returned).

 Borrowed widgets : Button, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple148_inputtextmultiline.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple148_inputtextmultiline.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 148 : _ImGui_CreateInputTextMultiline", 760, 600) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateInputTextMultiline  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateInputTextMultiline($sId, $sLabel = "",
;                                              $sDefault = "",
;                                              $iMaxLength = 1024,
;                                              $iFlags = 0,
;                                              $fW = 0, $fH = 0)
;
;   $fW / $fH = 0 means ImGui auto-sizes (height ~ 8 lines, width =
;   available content region). Give explicit pixels for stable layout.
;
;   $iFlags : same $ImGuiInputTextFlags_* set as the single-line
;             variant (exemple147). Multi-line-specific :
;     256       = CtrlEnterForNewLine  Enter validates, Ctrl+Enter = \n
;     16777216  = WordWrap             wrap at box width
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateInputTextMultiline demo  --  three sized boxes with different flag combos")
_ImGui_CreateText("t_hint",  "Type freely. Enter is a newline ; use box C to see Enter-validates / Ctrl+Enter newline.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; A) Default multi-line (sized box, no special flags)
; ==============================================================================
_ImGui_CreateText("t_a_hdr", "A) Default  --  Enter inserts a newline, horizontal scroll on long lines :")
_ImGui_CreateInputTextMultiline("in_default", "##default", _
    "Line 1." & @CRLF & "Line 2." & @CRLF & "Press Enter to add a new line.", _
    512, 0, 700, 90)


; ==============================================================================
; B) WordWrap (no horizontal scroll, lines wrap visually)
; ==============================================================================
_ImGui_CreateText("t_b_hdr", "B) WordWrap  --  long lines wrap at the box width instead of overflowing :")
_ImGui_CreateInputTextMultiline("in_wrap", "##wrap", _
    "This is a fairly long single line of text that would normally overflow horizontally but with WordWrap it stays inside the box.", _
    1024, $ImGuiInputTextFlags_WordWrap, 700, 70)


; ==============================================================================
; C) CtrlEnterForNewLine + EnterReturnsTrue (commit on Enter idiom)
; ==============================================================================
_ImGui_CreateText("t_c_hdr", "C) CtrlEnterForNewLine + EnterReturnsTrue  --  Enter commits, Ctrl+Enter inserts a newline :")
_ImGui_CreateInputTextMultiline("in_commit", "##commit", _
    "Type some words then press Enter to bump the commit counter." & @CRLF & "Use Ctrl+Enter to add a line without committing.", _
    512, _
    BitOR($ImGuiInputTextFlags_CtrlEnterForNewLine, $ImGuiInputTextFlags_EnterReturnsTrue), _
    700, 90)


; ==============================================================================
; Programmatic controls
; ==============================================================================
_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_ctrl_hdr", "Programmatic (SetValueString never latches HasChanged) :")
_ImGui_CreateButton("btn_load_lorem", "Load Lorem ipsum into A")
_ImGui_CreateButton("btn_clear_all",  "Clear all three boxes")


; ==============================================================================
; Status footer
; ==============================================================================
_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_status_hdr", "Live state (length + edit counters polled at 100ms) :")
_ImGui_CreateText("t_status_a", "  A) default : 0 chars   user-edits: 0")
_ImGui_CreateText("t_status_b", "  B) wrap    : 0 chars   user-edits: 0")
_ImGui_CreateText("t_status_c", "  C) commit  : 0 chars   Enter-commits: 0")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters ---------------------------------------------------------------
Global $g_iEditsA   = 0
Global $g_iEditsB   = 0
Global $g_iCommitsC = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("in_default", "_OnEditA")
_ImGui_SetOnChange("in_wrap",    "_OnEditB")
_ImGui_SetOnChange("in_commit",  "_OnCommitC")
_ImGui_SetOnClick("btn_load_lorem", "_OnLoadLorem")
_ImGui_SetOnClick("btn_clear_all",  "_OnClearAll")
_ImGui_SetOnClick("btn_quit",       "_OnQuit")
_ImGui_SetOnTick("_OnPollStatus", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnEditA($sId)
    $g_iEditsA += 1
EndFunc

Func _OnEditB($sId)
    $g_iEditsB += 1
EndFunc

Func _OnCommitC($sId)
    ; EnterReturnsTrue : HasChanged latches ONLY on Enter -- not on every char.
    ; This counter increments once per Enter, not per keystroke.
    $g_iCommitsC += 1
EndFunc

Func _OnLoadLorem($sId)
    _ImGui_SetValueString("in_default", _
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit." & @CRLF & _
        "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua." & @CRLF & _
        "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.")
EndFunc

Func _OnClearAll($sId)
    _ImGui_SetValueString("in_default", "")
    _ImGui_SetValueString("in_wrap",    "")
    _ImGui_SetValueString("in_commit",  "")
EndFunc

Func _OnPollStatus()
    Local $sA = _ImGui_GetValueString("in_default")
    Local $sB = _ImGui_GetValueString("in_wrap")
    Local $sC = _ImGui_GetValueString("in_commit")
    _ImGui_SetText("t_status_a", "  A) default : " & StringLen($sA) & " chars   user-edits: " & $g_iEditsA)
    _ImGui_SetText("t_status_b", "  B) wrap    : " & StringLen($sB) & " chars   user-edits: " & $g_iEditsB)
    _ImGui_SetText("t_status_c", "  C) commit  : " & StringLen($sC) & " chars   Enter-commits: " & $g_iCommitsC)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
