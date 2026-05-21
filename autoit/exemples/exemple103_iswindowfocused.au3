#cs
================================================================================
 Example 103 : _ImGui_IsWindowFocused
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsWindowFocused   True while the window owns keyboard focus

 Window-level focus differs from item-level focus (exemple91) :
   - _ImGui_IsFocused($itemId)         : a SPECIFIC INPUT widget owns kbd focus
   - _ImGui_IsWindowFocused($winId)    : the window OR any of its children does
                                          (e.g. an InputText inside the window)

 Only ONE window can have focus at a time across the entire tree.
 Clicking on a window or any of its widgets brings it to focus and
 to front (default behavior, modifiable via the NoBringToFrontOnFocus
 / NoFocusOnAppearing flags).

 Persistent state ; 50 ms polling is reliable.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple103_iswindowfocused.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple103_iswindowfocused.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 103 : _ImGui_IsWindowFocused", 720, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsWindowFocused  --  doc block
; ==============================================================================
; Signature : _ImGui_IsWindowFocused($sId)
;
;   Returns True while the window owns keyboard focus -- either
;   directly, or through one of its child widgets having focus.
;
;   Mutual exclusion : at most ONE window returns True at any time.
;   The host area is also a window in ImGui terms but is not
;   addressable as a Created window in this wrapper.
;
;   Persistent state ; 50 ms polling is reliable.


; ==============================================================================
; Host area widgets
; ==============================================================================
_ImGui_CreateText("t_title", "IsWindowFocused demo  --  focus tracking across three sub-windows")
_ImGui_CreateText("t_hint",  "Click in each window or on a widget inside it. The status panel shows which window owns focus.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_status_hdr", "Focus status :")
_ImGui_CreateText("t_focus_now",  "  Currently focused window : (host -- no sub-window focused)")
_ImGui_CreateText("t_a_state",    "  Window A : no focus")
_ImGui_CreateText("t_b_state",    "  Window B : no focus")
_ImGui_CreateText("t_c_state",    "  Window C : no focus")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Three sub-windows
; ==============================================================================
_ImGui_CreateWindow("win_a", "Window A", True, 0)
_ImGui_CreateText  ("a_t",  "Click here or in the input below to focus me.")
_ImGui_CreateInputText("a_in", "##a_in", "input A", 64, 0)
_ImGui_SetParent("a_t",  "win_a")
_ImGui_SetParent("a_in", "win_a")
_ImGui_SetWindowPos ("win_a", 30,  40,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_a", 220, 140, $ImGuiCond_FirstUseEver)

_ImGui_CreateWindow("win_b", "Window B", True, 0)
_ImGui_CreateText  ("b_t",  "Click here or in the input below to focus me.")
_ImGui_CreateInputText("b_in", "##b_in", "input B", 64, 0)
_ImGui_SetParent("b_t",  "win_b")
_ImGui_SetParent("b_in", "win_b")
_ImGui_SetWindowPos ("win_b", 270, 40,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_b", 220, 140, $ImGuiCond_FirstUseEver)

_ImGui_CreateWindow("win_c", "Window C", True, 0)
_ImGui_CreateText  ("c_t",  "Click here or in the input below to focus me.")
_ImGui_CreateInputText("c_in", "##c_in", "input C", 64, 0)
_ImGui_SetParent("c_t",  "win_c")
_ImGui_SetParent("c_in", "win_c")
_ImGui_SetWindowPos ("win_c", 510, 40,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_c", 220, 140, $ImGuiCond_FirstUseEver)


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
    Local $bA = _ImGui_IsWindowFocused("win_a")
    Local $bB = _ImGui_IsWindowFocused("win_b")
    Local $bC = _ImGui_IsWindowFocused("win_c")
    Local $sFocused = "(host -- no sub-window focused)"
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
