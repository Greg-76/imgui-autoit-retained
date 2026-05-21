#cs
================================================================================
 Example 91 : _ImGui_IsFocused
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsFocused   Report whether a widget owns the keyboard focus

 IsFocused is True when the widget is the keyboard-focused item --
 typically the InputText / InputFloat that the user is currently
 typing into. Tab navigation cycles focus through eligible widgets.

 ONLY ONE widget can be focused at a time across the entire tree.
 If your demo has multiple input fields, only one of them returns
 True at any moment.

 PERSISTENT state -- True for as long as the field keeps focus.
 Polling at 50 ms is reliable.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple91_isfocused.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple91_isfocused.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 91 : _ImGui_IsFocused", 620, 460) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsFocused  --  doc block
; ==============================================================================
; Signature : _ImGui_IsFocused($sId)
;
;   Returns True while the widget owns keyboard focus. False when
;   another widget owns it, or when nothing is focused (clicked
;   outside any input field).
;
;   Mutual exclusion : at most ONE widget in the tree returns True.
;   To detect "no focus at all", check that all input widgets you
;   care about return False.
;
;   Hidden / unknown widgets return False silently (no @error).


; ==============================================================================
; Demo widgets  --  three input fields ; the panel shows which one (if any)
;                  is currently focused. Tab cycles through them.
; ==============================================================================
_ImGui_CreateText("t_title", "IsFocused demo  --  keyboard focus tracking across three inputs")
_ImGui_CreateText("t_hint",  "Click inside a field, or press Tab to cycle focus. The status panel shows which field owns focus.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateInputText("tg_user",  "Username", "alice",  64, 0)
_ImGui_CreateInputText("tg_email", "Email",    "alice@example.org", 128, 0)
_ImGui_CreateInputText("tg_pwd",   "Password", "",       64, 0)
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Focus status (~20 Hz poll) :")
_ImGui_CreateText("t_focus_now",  "  Currently focused : (none)")
_ImGui_CreateText("t_user_state", "  Username field   : no focus")
_ImGui_CreateText("t_email_state","  Email field      : no focus")
_ImGui_CreateText("t_pwd_state",  "  Password field   : no focus")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollFocus", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollFocus()
    Local $bU = _ImGui_IsFocused("tg_user")
    Local $bE = _ImGui_IsFocused("tg_email")
    Local $bP = _ImGui_IsFocused("tg_pwd")
    Local $sFocused = "(none)"
    If $bU Then $sFocused = "Username"
    If $bE Then $sFocused = "Email"
    If $bP Then $sFocused = "Password"
    _ImGui_SetText("t_focus_now",   "  Currently focused : " & $sFocused)
    _ImGui_SetText("t_user_state",  "  Username field   : " & ($bU ? "FOCUSED" : "no focus"))
    _ImGui_SetText("t_email_state", "  Email field      : " & ($bE ? "FOCUSED" : "no focus"))
    _ImGui_SetText("t_pwd_state",   "  Password field   : " & ($bP ? "FOCUSED" : "no focus"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
