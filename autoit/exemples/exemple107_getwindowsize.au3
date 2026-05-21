#cs
================================================================================
 Example 107 : _ImGui_GetWindowSize
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_GetWindowSize   Read the current size of a window

 Mirror of GetWindowPos (exemple106) for the size. Returns
 array[2] = [width, height] in pixels (full window incl. title bar).

 Persistent state ; 50 ms polling reliable. Returns 0 with
 @error = 3 on unknown / non-window id.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple107_getwindowsize.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple107_getwindowsize.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 107 : _ImGui_GetWindowSize", 700, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_GetWindowSize  --  doc block
; ==============================================================================
; Signature : _ImGui_GetWindowSize($sId)
;
;   Returns array[2] = [width, height] in pixels (full window
;   including the title bar). For just the client area, subtract the
;   style's title-bar height -- there is no dedicated client-size
;   getter in this wrapper.
;
;   Returns 0 with @error set on failure (same codes as GetWindowPos).
;
;   Persistent state ; 50 ms polling reliable.


; ==============================================================================
; Host area widgets
; ==============================================================================
_ImGui_CreateText("t_title", "GetWindowSize demo  --  live readout of two windows' sizes")
_ImGui_CreateText("t_hint",  "Drag the sub-windows' edges to resize them. The host panel updates ~20 Hz.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_status_hdr", "Size panel :")
_ImGui_CreateText("t_a_size",  "  Window A : 0 x 0  (aspect 0.00)")
_ImGui_CreateText("t_b_size",  "  Window B : 0 x 0  (aspect 0.00)")
_ImGui_CreateText("t_total",   "  Combined area : 0 px^2")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Two resizable sub-windows
; ==============================================================================
_ImGui_CreateWindow("win_a", "Resize me (Window A)", True, 0)
_ImGui_CreateText("a_t1", "Drag my bottom-right corner or right/bottom edges to resize.")
_ImGui_CreateText("a_t2", "Width and height update in the host panel each tick.")
_ImGui_SetParent("a_t1", "win_a")
_ImGui_SetParent("a_t2", "win_a")
_ImGui_SetWindowPos ("win_a", 30,  60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_a", 220, 140, $ImGuiCond_FirstUseEver)

_ImGui_CreateWindow("win_b", "Resize me (Window B)", True, 0)
_ImGui_CreateText("b_t1", "Same here. Try making me wide and short, or tall and narrow.")
_ImGui_SetParent("b_t1", "win_b")
_ImGui_SetWindowPos ("win_b", 290, 60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_b", 260, 200, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollSize", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollSize()
    Local $aSzA = _ImGui_GetWindowSize("win_a")
    Local $aSzB = _ImGui_GetWindowSize("win_b")
    If Not IsArray($aSzA) Or Not IsArray($aSzB) Then Return
    Local $fAspectA = ($aSzA[1] = 0) ? 0.0 : ($aSzA[0] / $aSzA[1])
    Local $fAspectB = ($aSzB[1] = 0) ? 0.0 : ($aSzB[0] / $aSzB[1])
    _ImGui_SetText("t_a_size", StringFormat("  Window A : %d x %d  (aspect %.2f)", _
                                            $aSzA[0], $aSzA[1], $fAspectA))
    _ImGui_SetText("t_b_size", StringFormat("  Window B : %d x %d  (aspect %.2f)", _
                                            $aSzB[0], $aSzB[1], $fAspectB))
    _ImGui_SetText("t_total",  StringFormat("  Combined area : %d px^2", _
                                            $aSzA[0] * $aSzA[1] + $aSzB[0] * $aSzB[1]))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
