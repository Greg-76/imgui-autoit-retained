#cs
================================================================================
 Example 102 : _ImGui_IsWindowCollapsed
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsWindowCollapsed   True while the window is collapsed to its title bar

 IsWindowCollapsed is a PERSISTENT-state query : True for as long as
 the user has collapsed the window via the [v] caret on the title
 bar. Polling at 50 ms is reliable.

 Distinct from the Item-query IsHovered/IsFocused/IsActive : those
 ask "is this WIDGET (the last-rendered item) in some state ?". The
 IsWindow* family asks "is this WINDOW (including its children) in
 some state ?". Same vocabulary, different scope.

 Typical use case : skip per-frame computation for a collapsed
 panel (no children render, so any expensive readout is wasted).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple102_iswindowcollapsed.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple102_iswindowcollapsed.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 102 : _ImGui_IsWindowCollapsed", 720, 460) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsWindowCollapsed  --  doc block
; ==============================================================================
; Signature : _ImGui_IsWindowCollapsed($sId)
;
;   Returns True while the window is collapsed (only the title bar
;   visible, no client area). False when expanded.
;
;   The collapsed state is owned by ImGui ; the user toggles it by
;   clicking the [v] caret on the title bar. To force one or the
;   other from the script, use _ImGui_SetWindowCollapsed (exemple112).
;
;   Persistent state ; 50 ms polling is reliable. Hidden / unknown ids
;   return False silently.


; ==============================================================================
; Host area widgets
; ==============================================================================
_ImGui_CreateText("t_title", "IsWindowCollapsed demo  --  poll the collapsed/expanded state of two windows")
_ImGui_CreateText("t_hint",  "Click the [v] caret on each window's title bar to collapse / expand. The status panel updates ~20 Hz.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_status_hdr", "Status :")
_ImGui_CreateText("t_a_state",    "  Window A : expanded")
_ImGui_CreateText("t_b_state",    "  Window B : expanded")
_ImGui_CreateText("t_combined",   "  Any collapsed : no  --  any visible client area, no skip")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Two target windows side by side
; ==============================================================================
_ImGui_CreateWindow("win_a", "Window A (collapsible)", True, 0)
_ImGui_CreateText("a_t",   "I am window A. Click my [v] caret to collapse me.")
_ImGui_CreateText("a_t2",  "When collapsed, my client area disappears but my title bar stays.")
_ImGui_SetParent("a_t",  "win_a")
_ImGui_SetParent("a_t2", "win_a")
_ImGui_SetWindowPos ("win_a", 40,  60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_a", 280, 120, $ImGuiCond_FirstUseEver)

_ImGui_CreateWindow("win_b", "Window B (collapsible)", True, 0)
_ImGui_CreateText("b_t",   "I am window B. Same caret behavior.")
_ImGui_CreateText("b_t2",  "Try having both collapsed simultaneously -- the combined status flips to YES.")
_ImGui_SetParent("b_t",  "win_b")
_ImGui_SetParent("b_t2", "win_b")
_ImGui_SetWindowPos ("win_b", 340, 60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_b", 280, 120, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollCollapsed", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollCollapsed()
    Local $bA = _ImGui_IsWindowCollapsed("win_a")
    Local $bB = _ImGui_IsWindowCollapsed("win_b")
    _ImGui_SetText("t_a_state", "  Window A : " & ($bA ? "COLLAPSED" : "expanded"))
    _ImGui_SetText("t_b_state", "  Window B : " & ($bB ? "COLLAPSED" : "expanded"))
    _ImGui_SetText("t_combined", "  Any collapsed : " & (($bA Or $bB) ? "YES -- skip per-frame work for the collapsed one(s)" _
                                                                       : "no  --  any visible client area, no skip"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
