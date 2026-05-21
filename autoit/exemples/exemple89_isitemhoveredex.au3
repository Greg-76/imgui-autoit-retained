#cs
================================================================================
 Example 89 : _ImGui_CreateIsItemHoveredEx
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster : the marker is
 useless without its reader) :

   _ImGui_CreateIsItemHoveredEx   Marker widget that latches a flagged hover query
   _ImGui_GetItemHoveredEx        Read the latched value

 The "Ex" variant of IsHovered : same idea, but driven by an
 $ImGuiHoveredFlags_* bitmask. Useful when you need :

   - Delayed hover (DelayShort / DelayNormal) for tooltips
   - "AllowWhenBlockedByActiveItem" so the hover persists during a
     drag on another widget
   - "Stationary" so the hover only counts when the mouse stops
   - "ForTooltip" which combines the common tooltip-trigger options

 IMPORTANT PLACEMENT RULE : the marker MUST be the IMMEDIATE next
 sibling of the target widget in the same parent's children list.
 If you put another widget between them, the marker reads the OTHER
 widget's hover state, not the one you wanted. Same constraint as
 the existing ItemTooltip pattern (H.2).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple89_isitemhoveredex.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple89_isitemhoveredex.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 89 : _ImGui_CreateIsItemHoveredEx", 660, 500) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateIsItemHoveredEx + _ImGui_GetItemHoveredEx  --  doc blocks
; ==============================================================================
; Create-marker signature : _ImGui_CreateIsItemHoveredEx($sId, $iFlags)
;   Reader signature       : _ImGui_GetItemHoveredEx($sId)
;
;   $iFlags : bitmask of $ImGuiHoveredFlags_* values. Useful subset :
;     0     = $ImGuiHoveredFlags_None
;     32    = AllowWhenBlockedByPopup
;     128   = AllowWhenBlockedByActiveItem
;     1024  = AllowWhenDisabled
;     4096  = ForTooltip      (DelayShort + Stationary + AllowWhenDisabled,
;                              the common "show a tooltip after a brief pause" combo)
;     8192  = Stationary      (mouse must be still over the widget)
;     16384 = DelayNone
;     32768 = DelayShort      (~150 ms default)
;     65536 = DelayNormal     (~500 ms default)
;
;   Pair Create + Get by sharing the same marker $sId.


; ==============================================================================
; Demo widgets  --  four buttons, each followed immediately by a HoveredEx
;                  marker with different flags. A status panel polls all four
;                  markers via OnTick.
; ==============================================================================
_ImGui_CreateText("t_title", "IsItemHoveredEx demo  --  four flag variants on identical buttons")
_ImGui_CreateText("t_hint",  "Hover each button. Notice the delay before DelayShort / DelayNormal turn True, and how Stationary reacts only when the mouse stops.")
_ImGui_CreateSeparator("sep1")

; --- (A) Default flags = 0 (same behavior as plain IsHovered) ---------------
_ImGui_CreateButton("tg_a", "(A) Target with flags = 0 (= plain IsHovered)")
_ImGui_CreateIsItemHoveredEx("ihex_a", 0)

; --- (B) DelayShort -- ~150 ms delay before True -----------------------------
_ImGui_CreateButton("tg_b", "(B) Target with $ImGuiHoveredFlags_DelayShort (~150 ms)")
_ImGui_CreateIsItemHoveredEx("ihex_b", $ImGuiHoveredFlags_DelayShort)

; --- (C) DelayNormal -- ~500 ms delay before True ----------------------------
_ImGui_CreateButton("tg_c", "(C) Target with $ImGuiHoveredFlags_DelayNormal (~500 ms)")
_ImGui_CreateIsItemHoveredEx("ihex_c", $ImGuiHoveredFlags_DelayNormal)

; --- (D) Stationary -- True only when the mouse stops moving over the target -
_ImGui_CreateButton("tg_d", "(D) Target with $ImGuiHoveredFlags_Stationary")
_ImGui_CreateIsItemHoveredEx("ihex_d", $ImGuiHoveredFlags_Stationary)

_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr","Status panel (~20 Hz poll) :")
_ImGui_CreateText("t_a_state",   "  (A) None       : no")
_ImGui_CreateText("t_b_state",   "  (B) DelayShort : no")
_ImGui_CreateText("t_c_state",   "  (C) DelayNormal: no")
_ImGui_CreateText("t_d_state",   "  (D) Stationary : no")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_quit", "Quit")


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
    Local $bA = _ImGui_GetItemHoveredEx("ihex_a")
    Local $bB = _ImGui_GetItemHoveredEx("ihex_b")
    Local $bC = _ImGui_GetItemHoveredEx("ihex_c")
    Local $bD = _ImGui_GetItemHoveredEx("ihex_d")
    _ImGui_SetText("t_a_state", "  (A) None       : " & ($bA ? "YES" : "no"))
    _ImGui_SetText("t_b_state", "  (B) DelayShort : " & ($bB ? "YES (after ~150 ms)" : "no"))
    _ImGui_SetText("t_c_state", "  (C) DelayNormal: " & ($bC ? "YES (after ~500 ms)" : "no"))
    _ImGui_SetText("t_d_state", "  (D) Stationary : " & ($bD ? "YES (mouse is still)" : "no"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
