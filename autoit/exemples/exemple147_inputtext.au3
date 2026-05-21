#cs
================================================================================
 Example 147 : _ImGui_CreateInputText
                (+ _ImGui_GetValueString + _ImGui_SetValueString)
================================================================================
 Covers 3 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_CreateInputText   Single-line text editor
   _ImGui_GetValueString    Read the current buffer contents
   _ImGui_SetValueString    Programmatically write the buffer

 ImGui owns a fixed-size text buffer in place while the user types ;
 the wrapper hands it a buffer at creation (capped by $iMaxLength,
 default 256) and never grows it.

 Five flag combinations are showcased side by side :
   A) Default          plain free text
   B) CharsDecimal     numeric-only (digits + . + - + + + * + /)
   C) Password         display as bullets, no copy to clipboard
   D) ReadOnly         viewable but not editable ; SetValueString
                       still works programmatically
   E) EnterReturnsTrue HasChanged fires only on Enter, not on every
                       character ; great for "commit on Enter" UX

 Event model :
   * Default        : HasChanged latches on EVERY character edit
   * EnterReturnsTrue : HasChanged latches only on Enter
   * Programmatic SetValueString never latches (strict semantics --
     [[imgui_retained_strict_changed]]).

 Read caveat :
   GetValueString defaults to a 4096-wchar receiving buffer. If the
   widget was created with a larger $iMaxLength AND the user filled
   it past 4095 chars, the wrapper returns the truncated value with
   @extended = 4. Pass a larger $iBufSize to silence the truncation.

 Borrowed widgets : Button, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple147_inputtext.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple147_inputtext.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 147 : _ImGui_CreateInputText", 760, 620) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateInputText  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateInputText($sId, $sLabel = "",
;                                     $sDefault = "",
;                                     $iMaxLength = 256, $iFlags = 0)
;
;   $iFlags : bitmask of $ImGuiInputTextFlags_*. Selected useful values :
;     0       = None
;     1       = CharsDecimal        digits + . + - + + + * + /
;     2       = CharsHexadecimal    0-9 a-f A-F
;     4       = CharsScientific     adds e / E
;     8       = CharsUppercase      auto-upper a..z
;     16      = CharsNoBlank        filter spaces / tabs
;     64      = EnterReturnsTrue    HasChanged only on Enter
;     128     = EscapeClearsAll     Esc clears the buffer if non-empty
;     512     = ReadOnly            view-only ; SetValueString still works
;     1024    = Password            bullets ; clipboard copy disabled
;     2048    = AlwaysOverwrite     insertion overwrites instead of inserting
;     4096    = AutoSelectAll       select all on focus
;     131072  = ElideLeft           single-line ; collapse left side of overflow
;
;   Return : True on success, False on failure (@error = 1, 2).

; ==============================================================================
; _ImGui_GetValueString / _ImGui_SetValueString  --  doc block
; ==============================================================================
; Get  : returns the buffer content. Optional $iBufSize (default 4096
;        wchars) sizes the receiving struct. On truncation, @extended
;        = 4 and the partial string is still returned (soft error).
;
; Set  : truncates server-side to ($iMaxLength - 1). Never latches
;        HasChanged.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateInputText demo  --  5 flag combos side by side + Get/Set readouts")
_ImGui_CreateText("t_hint",  "Type into each box. Status line below shows live GetValueString and edit counts.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; A) Default plain text
; ==============================================================================
_ImGui_CreateInputText("in_plain", "A) Default", "hello world", 64)


; ==============================================================================
; B) Decimal-only
; ==============================================================================
_ImGui_CreateInputText("in_dec", "B) CharsDecimal", "42", 16, $ImGuiInputTextFlags_CharsDecimal)


; ==============================================================================
; C) Password (bullets ; copy disabled)
; ==============================================================================
_ImGui_CreateInputText("in_pwd", "C) Password", "s3cret", 64, $ImGuiInputTextFlags_Password)


; ==============================================================================
; D) Read-only (typing ignored ; programmatic SetValueString still works)
; ==============================================================================
_ImGui_CreateInputText("in_ro", "D) ReadOnly", "cannot edit me", 64, $ImGuiInputTextFlags_ReadOnly)


; ==============================================================================
; E) EnterReturnsTrue (commit on Enter)
; ==============================================================================
_ImGui_CreateInputText("in_enter", "E) EnterReturnsTrue", "type then press Enter", 64, _
                        $ImGuiInputTextFlags_EnterReturnsTrue)


; ==============================================================================
; Programmatic controls
; ==============================================================================
_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_ctrl_hdr", "Programmatic SetValueString (never latches HasChanged) :")
_ImGui_CreateButton("btn_set_ro_now",   "Stamp ReadOnly with current time")
_ImGui_CreateButton("btn_set_pwd_clear","Clear Password buffer (empty string)")
_ImGui_CreateButton("btn_set_plain_x",  "Overwrite Default field with 'x' * 20")


; ==============================================================================
; Live status
; ==============================================================================
_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_status_hdr", "Live state (Get + user-change counters polled at 100ms) :")
_ImGui_CreateText("t_status_plain", "  A) <value> | edits: 0")
_ImGui_CreateText("t_status_dec",   "  B) <value> | edits: 0")
_ImGui_CreateText("t_status_pwd",   "  C) [hidden -- Password flag]  | edits: 0")
_ImGui_CreateText("t_status_ro",    "  D) <value> | edits: 0")
_ImGui_CreateText("t_status_enter", "  E) <value> | Enter commits: 0")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters ---------------------------------------------------------------
Global $g_iEditsPlain = 0
Global $g_iEditsDec   = 0
Global $g_iEditsPwd   = 0
Global $g_iEditsRo    = 0   ; should stay at 0 forever -- ReadOnly never latches user edits
Global $g_iEditsEnter = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("in_plain", "_OnEditPlain")
_ImGui_SetOnChange("in_dec",   "_OnEditDec")
_ImGui_SetOnChange("in_pwd",   "_OnEditPwd")
_ImGui_SetOnChange("in_ro",    "_OnEditRo")
_ImGui_SetOnChange("in_enter", "_OnEditEnter")
_ImGui_SetOnClick("btn_set_ro_now",    "_OnStampRo")
_ImGui_SetOnClick("btn_set_pwd_clear", "_OnClearPwd")
_ImGui_SetOnClick("btn_set_plain_x",   "_OnOverwritePlain")
_ImGui_SetOnClick("btn_quit",          "_OnQuit")
_ImGui_SetOnTick("_OnPollStatus", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnEditPlain($sId)
    $g_iEditsPlain += 1
EndFunc

Func _OnEditDec($sId)
    $g_iEditsDec += 1
EndFunc

Func _OnEditPwd($sId)
    $g_iEditsPwd += 1
EndFunc

Func _OnEditRo($sId)
    $g_iEditsRo += 1   ; never reached for user edits on a ReadOnly field
EndFunc

Func _OnEditEnter($sId)
    $g_iEditsEnter += 1
EndFunc

Func _OnStampRo($sId)
    ; SetValueString works on ReadOnly fields -- the read-only restriction is
    ; user-side only.
    _ImGui_SetValueString("in_ro", "stamped at " & @HOUR & ":" & @MIN & ":" & @SEC)
EndFunc

Func _OnClearPwd($sId)
    _ImGui_SetValueString("in_pwd", "")
EndFunc

Func _OnOverwritePlain($sId)
    Local $sX = ""
    For $i = 1 To 20
        $sX &= "x"
    Next
    _ImGui_SetValueString("in_plain", $sX)
EndFunc

Func _OnPollStatus()
    _ImGui_SetText("t_status_plain", "  A) " & _ImGui_GetValueString("in_plain") & " | edits: " & $g_iEditsPlain)
    _ImGui_SetText("t_status_dec",   "  B) " & _ImGui_GetValueString("in_dec")   & " | edits: " & $g_iEditsDec)
    _ImGui_SetText("t_status_pwd",   "  C) [hidden -- Password flag]  | edits: " & $g_iEditsPwd)
    _ImGui_SetText("t_status_ro",    "  D) " & _ImGui_GetValueString("in_ro")    & " | edits: " & $g_iEditsRo)
    _ImGui_SetText("t_status_enter", "  E) " & _ImGui_GetValueString("in_enter") & " | Enter commits: " & $g_iEditsEnter)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
