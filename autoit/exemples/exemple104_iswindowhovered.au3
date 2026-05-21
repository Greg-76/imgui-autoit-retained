#cs
================================================================================
 Example 104 : _ImGui_IsWindowHovered
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsWindowHovered   True while the mouse is over the window

 Window-level hover (the mouse is anywhere over the window's title
 bar or client area) vs item-level hover (_ImGui_IsHovered, the
 mouse is over a SPECIFIC widget). Both can be True simultaneously
 when the mouse is over a widget INSIDE the window.

 The default behavior of IsWindowHovered EXCLUDES child windows and
 popups -- if you need to include them, use IsWindowHoveredEx with
 the right flags ($ImGuiHoveredFlags_ChildWindows, AnyWindow,
 RootWindow, ...). See exemple105.

 Persistent state ; 50 ms polling is reliable.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple104_iswindowhovered.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple104_iswindowhovered.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 104 : _ImGui_IsWindowHovered", 720, 460) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsWindowHovered  --  doc block
; ==============================================================================
; Signature : _ImGui_IsWindowHovered($sId)
;
;   Returns True while the mouse pointer is inside the window's
;   bounding rect (title bar + client area). The default-hover
;   policy : no child windows, no popups counted.
;
;   For flagged variants (include child windows, allow when blocked
;   by popup, etc.), use _ImGui_IsWindowHoveredEx + _ImGui_SetWindowHoveredFlags
;   (exemple105).
;
;   Persistent state ; 50 ms polling is reliable. Hidden / unknown
;   ids return False silently.


; ==============================================================================
; Host area widgets
; ==============================================================================
_ImGui_CreateText("t_title", "IsWindowHovered demo  --  per-window hover tracking, default policy")
_ImGui_CreateText("t_hint",  "Move the mouse over each sub-window. The status panel shows which one (if any) is hovered.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_status_hdr", "Hover status :")
_ImGui_CreateText("t_hov_now",    "  Currently hovered window : (none)")
_ImGui_CreateText("t_a_state",    "  Window A : not hovered")
_ImGui_CreateText("t_b_state",    "  Window B : not hovered")
_ImGui_CreateText("t_c_state",    "  Window C : not hovered")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Three sub-windows
; ==============================================================================
_ImGui_CreateWindow("win_a", "Window A", True, 0)
_ImGui_CreateText  ("a_t1", "Hover me to see window-level hover.")
_ImGui_CreateText  ("a_t2", "Mouse over title bar OR client area both count.")
_ImGui_SetParent("a_t1", "win_a")
_ImGui_SetParent("a_t2", "win_a")
_ImGui_SetWindowPos ("win_a", 30,  60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_a", 220, 120, $ImGuiCond_FirstUseEver)

_ImGui_CreateWindow("win_b", "Window B", True, 0)
_ImGui_CreateText  ("b_t1", "Same here. Notice : at most one returns True at a time.")
_ImGui_SetParent("b_t1", "win_b")
_ImGui_SetWindowPos ("win_b", 270, 60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_b", 220, 120, $ImGuiCond_FirstUseEver)

_ImGui_CreateWindow("win_c", "Window C", True, 0)
_ImGui_CreateText  ("c_t1", "Default policy : child windows / popups are NOT counted.")
_ImGui_CreateText  ("c_t2", "See exemple105 for the flagged variant.")
_ImGui_SetParent("c_t1", "win_c")
_ImGui_SetParent("c_t2", "win_c")
_ImGui_SetWindowPos ("win_c", 510, 60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_c", 220, 120, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollHover", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollHover()
    Local $bA = _ImGui_IsWindowHovered("win_a")
    Local $bB = _ImGui_IsWindowHovered("win_b")
    Local $bC = _ImGui_IsWindowHovered("win_c")
    Local $sHov = "(none)"
    If $bA Then $sHov = "Window A"
    If $bB Then $sHov = "Window B"
    If $bC Then $sHov = "Window C"
    _ImGui_SetText("t_hov_now",  "  Currently hovered window : " & $sHov)
    _ImGui_SetText("t_a_state",  "  Window A : " & ($bA ? "HOVERED" : "not hovered"))
    _ImGui_SetText("t_b_state",  "  Window B : " & ($bB ? "HOVERED" : "not hovered"))
    _ImGui_SetText("t_c_state",  "  Window C : " & ($bC ? "HOVERED" : "not hovered"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
