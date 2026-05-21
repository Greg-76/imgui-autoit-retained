#cs
================================================================================
 Example 105 : _ImGui_IsWindowHoveredEx + _ImGui_SetWindowHoveredFlags
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster -- the flag setter
 has no use without the latched reader) :

   _ImGui_SetWindowHoveredFlags   Configure the $ImGuiHoveredFlags_* mask for a window
   _ImGui_IsWindowHoveredEx       Read the flagged-hover state of that window

 IsWindowHovered (exemple104) always uses ImGui's default hover
 policy. To override it (include child windows, allow hover while
 blocked by a popup, ...), call SetWindowHoveredFlags ONCE at
 init-time to configure the mask, then poll IsWindowHoveredEx to
 read the result with that policy applied.

 The mask is per-window : different windows can have different
 hover policies in the same script.

 Useful flag values for windows (from $ImGuiHoveredFlags_*) :
     0     = None                            (= IsWindowHovered default)
     1     = ChildWindows                    (include child windows in the check)
     2     = RootWindow                      (test the root parent, not this exact id)
     4     = AnyWindow                       (True if ANY window is hovered)
     32    = AllowWhenBlockedByPopup
     128   = AllowWhenBlockedByActiveItem
     1024  = AllowWhenDisabled

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple105_iswindowhoveredex.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple105_iswindowhoveredex.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 105 : _ImGui_IsWindowHoveredEx", 740, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetWindowHoveredFlags + _ImGui_IsWindowHoveredEx  --  doc block
; ==============================================================================
; Setter : _ImGui_SetWindowHoveredFlags($sId, $iFlags)
;   Configures the $ImGuiHoveredFlags_* mask for the window. Pass 0
;   to reset to the default IsWindowHovered policy. Idempotent --
;   safe to call multiple times ; the latest value wins. Typically
;   called once at script init, before the main loop.
;
; Reader : _ImGui_IsWindowHoveredEx($sId)
;   Returns True iff the window is hovered under the configured
;   policy. Persistent state ; 50 ms polling is reliable.


; ==============================================================================
; Host area widgets
; ==============================================================================
_ImGui_CreateText("t_title", "IsWindowHoveredEx demo  --  per-window hover policy via SetWindowHoveredFlags")
_ImGui_CreateText("t_hint",  "Window B has the AllowWhenBlockedByActiveItem flag, so it stays HOVERED even while you drag a widget inside another window.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_status_hdr", "Hover status (Ex variant, polled at 20 Hz) :")
_ImGui_CreateText("t_a_state",    "  Window A (None)                          : not hovered")
_ImGui_CreateText("t_b_state",    "  Window B (AllowWhenBlockedByActiveItem)  : not hovered")
_ImGui_CreateText("t_c_state",    "  Window C (AnyWindow -- any hover counts) : not hovered")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Window A  --  default policy (flags = 0)
; ==============================================================================
_ImGui_CreateWindow("win_a", "Window A (default policy)", True, 0)
_ImGui_CreateText("a_t1", "Default hover policy (no flags).")
_ImGui_CreateSliderFloat("a_sl", "Drag me to see how A reacts", 0.0, 1.0, 0.5, "%.2f")
_ImGui_SetParent("a_t1", "win_a")
_ImGui_SetParent("a_sl", "win_a")
_ImGui_SetWindowPos ("win_a", 30,  60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_a", 220, 130, $ImGuiCond_FirstUseEver)


; ==============================================================================
; Window B  --  AllowWhenBlockedByActiveItem
; ==============================================================================
_ImGui_CreateWindow("win_b", "Window B (AllowWhenBlockedByActiveItem)", True, 0)
_ImGui_CreateText("b_t1", "While you drag the slider in window A above, hover me.")
_ImGui_CreateText("b_t2", "I report HOVERED thanks to the AllowWhenBlockedByActiveItem flag.")
_ImGui_SetParent("b_t1", "win_b")
_ImGui_SetParent("b_t2", "win_b")
_ImGui_SetWindowPos ("win_b", 270, 60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_b", 220, 130, $ImGuiCond_FirstUseEver)


; ==============================================================================
; Window C  --  AnyWindow (returns True if ANY window in the tree is hovered)
; ==============================================================================
_ImGui_CreateWindow("win_c", "Window C (AnyWindow)", True, 0)
_ImGui_CreateText("c_t1", "I report HOVERED if any window in the tree is.")
_ImGui_CreateText("c_t2", "Useful as a panel-wide gating flag.")
_ImGui_SetParent("c_t1", "win_c")
_ImGui_SetParent("c_t2", "win_c")
_ImGui_SetWindowPos ("win_c", 510, 60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_c", 220, 130, $ImGuiCond_FirstUseEver)


; ==============================================================================
; Configure the hovered-flags mask for each window (one-shot at init).
; ==============================================================================
_ImGui_SetWindowHoveredFlags("win_a", 0)
_ImGui_SetWindowHoveredFlags("win_b", $ImGuiHoveredFlags_AllowWhenBlockedByActiveItem)
_ImGui_SetWindowHoveredFlags("win_c", $ImGuiHoveredFlags_AnyWindow)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollHoverEx", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollHoverEx()
    Local $bA = _ImGui_IsWindowHoveredEx("win_a")
    Local $bB = _ImGui_IsWindowHoveredEx("win_b")
    Local $bC = _ImGui_IsWindowHoveredEx("win_c")
    _ImGui_SetText("t_a_state", "  Window A (None)                          : " & ($bA ? "HOVERED" : "not hovered"))
    _ImGui_SetText("t_b_state", "  Window B (AllowWhenBlockedByActiveItem)  : " & ($bB ? "HOVERED" : "not hovered"))
    _ImGui_SetText("t_c_state", "  Window C (AnyWindow -- any hover counts) : " & ($bC ? "HOVERED" : "not hovered"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
