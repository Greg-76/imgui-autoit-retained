#cs
================================================================================
 Example 106 : _ImGui_GetWindowPos
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_GetWindowPos   Read the current top-left position of a window

 GetWindowPos returns the window's top-left corner in screen-space
 pixels (same coordinate system as the rest of the geometry queries
 -- relative to the host window's client area).

 Persistent state ; 50 ms polling is reliable. Returns 0 with
 @error = 3 on unknown id or non-window id.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple106_getwindowpos.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple106_getwindowpos.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 106 : _ImGui_GetWindowPos", 700, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_GetWindowPos  --  doc block
; ==============================================================================
; Signature : _ImGui_GetWindowPos($sId)
;
;   Returns array[2] = [x, y] in screen-space pixels (top-left).
;   Returns 0 with @error set on failure :
;     1 = DLL not loaded
;     2 = DllCall failed
;     3 = unknown id or not a window
;
;   Persistent state ; 50 ms polling reliable.


; ==============================================================================
; Host area widgets
; ==============================================================================
_ImGui_CreateText("t_title", "GetWindowPos demo  --  live readout of two windows' positions")
_ImGui_CreateText("t_hint",  "Drag the sub-windows around. The host panel updates ~20 Hz.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_status_hdr", "Position panel :")
_ImGui_CreateText("t_a_pos", "  Window A pos : (0, 0)")
_ImGui_CreateText("t_b_pos", "  Window B pos : (0, 0)")
_ImGui_CreateText("t_delta", "  Delta (B - A) : (0, 0)")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Two draggable sub-windows
; ==============================================================================
_ImGui_CreateWindow("win_a", "Drag me (Window A)", True, 0)
_ImGui_CreateText("a_t1", "Drag my title bar to move me.")
_ImGui_CreateText("a_t2", "GetWindowPos returns my current top-left.")
_ImGui_SetParent("a_t1", "win_a")
_ImGui_SetParent("a_t2", "win_a")
_ImGui_SetWindowPos ("win_a", 30,  60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_a", 240, 120, $ImGuiCond_FirstUseEver)

_ImGui_CreateWindow("win_b", "Drag me (Window B)", True, 0)
_ImGui_CreateText("b_t1", "Same here -- drag me.")
_ImGui_CreateText("b_t2", "Delta between A and B is shown in the host panel.")
_ImGui_SetParent("b_t1", "win_b")
_ImGui_SetParent("b_t2", "win_b")
_ImGui_SetWindowPos ("win_b", 320, 60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_b", 240, 120, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollPos", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollPos()
    Local $aPosA = _ImGui_GetWindowPos("win_a")
    Local $aPosB = _ImGui_GetWindowPos("win_b")
    If Not IsArray($aPosA) Or Not IsArray($aPosB) Then Return
    _ImGui_SetText("t_a_pos", StringFormat("  Window A pos : (%.0f, %.0f) px", $aPosA[0], $aPosA[1]))
    _ImGui_SetText("t_b_pos", StringFormat("  Window B pos : (%.0f, %.0f) px", $aPosB[0], $aPosB[1]))
    _ImGui_SetText("t_delta", StringFormat("  Delta (B - A) : (%.0f, %.0f) px", _
                                            $aPosB[0] - $aPosA[0], $aPosB[1] - $aPosA[1]))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
