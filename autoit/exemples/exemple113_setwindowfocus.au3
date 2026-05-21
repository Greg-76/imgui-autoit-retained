#cs
================================================================================
 Example 113 : _ImGui_SetWindowFocus
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetWindowFocus   Bring the window to the front and give it keyboard focus

 One-shot equivalent of clicking the window's title bar. The window
 is raised above all other ImGui windows and gains keyboard focus.

 No $iCond parameter -- this setter is unconditional ; it always
 applies at the next Render. To "always-on-top" a window across the
 session, re-call from OnTick (use sparingly, it steals focus from
 the user).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple113_setwindowfocus.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple113_setwindowfocus.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 113 : _ImGui_SetWindowFocus", 720, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetWindowFocus  --  doc block
; ==============================================================================
; Signature : _ImGui_SetWindowFocus($sId)
;
;   Brings the window to the front AND gives it keyboard focus. The
;   one-shot is consumed at the next Render -- afterwards the user
;   can click another window to refocus it.
;
;   Mutual exclusion : only one window can be focused at a time
;   across the whole tree.
;
;   Return : True on success, False on failure (@error = 1, 2, or 3).


; ==============================================================================
; Host area widgets  --  one button per target window
; ==============================================================================
_ImGui_CreateText("t_title", "SetWindowFocus demo  --  scripted focus across three sub-windows")
_ImGui_CreateText("t_hint",  "The buttons below raise the target window to the front and focus it. The status panel reads back the focus state.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_btn_hdr", "Focus a window from the script :")
_ImGui_CreateButton("btn_focus_a", "Focus window A")
_ImGui_CreateButton("btn_focus_b", "Focus window B")
_ImGui_CreateButton("btn_focus_c", "Focus window C")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Focus state (read live via IsWindowFocused) :")
_ImGui_CreateText("t_focus_now",  "  Currently focused window : (none)")
_ImGui_CreateText("t_a_state",    "  Window A : no focus")
_ImGui_CreateText("t_b_state",    "  Window B : no focus")
_ImGui_CreateText("t_c_state",    "  Window C : no focus")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Three sub-windows that overlap intentionally to demonstrate raising
; ==============================================================================
_ImGui_CreateWindow("win_a", "Window A", True, 0)
_ImGui_CreateText("a_t1", "Click the host's 'Focus A' to raise me + focus me.")
_ImGui_CreateInputText("a_in", "##a_in", "type here (proves I have focus)", 64, 0)
_ImGui_SetParent("a_t1", "win_a")
_ImGui_SetParent("a_in", "win_a")
_ImGui_SetWindowPos ("win_a", 80,  80,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_a", 280, 140, $ImGuiCond_FirstUseEver)

_ImGui_CreateWindow("win_b", "Window B", True, 0)
_ImGui_CreateText("b_t1", "Click 'Focus B' to bring me up.")
_ImGui_CreateInputText("b_in", "##b_in", "type here", 64, 0)
_ImGui_SetParent("b_t1", "win_b")
_ImGui_SetParent("b_in", "win_b")
_ImGui_SetWindowPos ("win_b", 160, 140, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_b", 280, 140, $ImGuiCond_FirstUseEver)

_ImGui_CreateWindow("win_c", "Window C", True, 0)
_ImGui_CreateText("c_t1", "Click 'Focus C' to bring me up.")
_ImGui_CreateInputText("c_in", "##c_in", "type here", 64, 0)
_ImGui_SetParent("c_t1", "win_c")
_ImGui_SetParent("c_in", "win_c")
_ImGui_SetWindowPos ("win_c", 240, 200, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_c", 280, 140, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_focus_a", "_OnFocusA")
_ImGui_SetOnClick("btn_focus_b", "_OnFocusB")
_ImGui_SetOnClick("btn_focus_c", "_OnFocusC")
_ImGui_SetOnClick("btn_quit",    "_OnQuit")
_ImGui_SetOnTick ("_OnPollFocus", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnFocusA($sId)
    _ImGui_SetWindowFocus("win_a")
EndFunc

Func _OnFocusB($sId)
    _ImGui_SetWindowFocus("win_b")
EndFunc

Func _OnFocusC($sId)
    _ImGui_SetWindowFocus("win_c")
EndFunc

Func _OnPollFocus()
    Local $bA = _ImGui_IsWindowFocused("win_a")
    Local $bB = _ImGui_IsWindowFocused("win_b")
    Local $bC = _ImGui_IsWindowFocused("win_c")
    Local $sFocused = "(none)"
    If $bA Then $sFocused = "Window A"
    If $bB Then $sFocused = "Window B"
    If $bC Then $sFocused = "Window C"
    _ImGui_SetText("t_focus_now", "  Currently focused window : " & $sFocused)
    _ImGui_SetText("t_a_state",   "  Window A : " & ($bA ? "FOCUSED" : "no focus"))
    _ImGui_SetText("t_b_state",   "  Window B : " & ($bB ? "FOCUSED" : "no focus"))
    _ImGui_SetText("t_c_state",   "  Window C : " & ($bC ? "FOCUSED" : "no focus"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
