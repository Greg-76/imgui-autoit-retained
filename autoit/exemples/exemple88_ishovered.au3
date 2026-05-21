#cs
================================================================================
 Example 88 : _ImGui_IsHovered
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsHovered   Report whether the mouse pointer is currently over a widget

 IsHovered is the first of the "item queries" family : pure read-only
 functions that report the interaction state of an existing widget by
 id. No "Create" prefix -- these are queries you call from a handler
 (typically an OnTick handler) every frame.

 Read-only semantics : the value is latched at the end of each frame by
 the render thread. Reading does NOT consume it. Unknown / hidden ids
 return False silently (no @error).

 Hover state is PERSISTENT : True for as long as the mouse stays over
 the widget. Polling at 50 ms is reliable.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple88_ishovered.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple88_ishovered.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 88 : _ImGui_IsHovered", 600, 420) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsHovered  --  doc block
; ==============================================================================
; Signature : _ImGui_IsHovered($sId)
;
;   $sId : identifier of an existing widget in the tree.
;
;   Returns True while the mouse pointer is over the widget's bounding
;   rect. False as soon as the pointer leaves. False for hidden /
;   clipped / unknown widgets (no @error -- the function never raises).
;
;   This is the PLAIN hover query. For flag-driven variants
;   (delays, tolerate-blocking-popup, ForTooltip, ...), see
;   _ImGui_CreateIsItemHoveredEx + _ImGui_GetItemHoveredEx in
;   exemple89.


; ==============================================================================
; Demo widgets  --  three targets + a live status panel polled every 50 ms
; ==============================================================================
_ImGui_CreateText("t_title", "IsHovered demo  --  live hover state polled via _ImGui_SetOnTick")
_ImGui_CreateText("t_hint",  "Move the mouse over the three targets below. The status panel updates ~20 Hz.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateButton("tg_btn",   "Target 1 : a regular Button")
_ImGui_CreateCheckbox("tg_cb",  "Target 2 : a Checkbox", False)
_ImGui_CreateText("tg_txt",     "Target 3 : a plain Text label  (yes, Text widgets are hoverable)")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Status panel :")
_ImGui_CreateText("t_btn_state",  "  Button   : not hovered")
_ImGui_CreateText("t_cb_state",   "  Checkbox : not hovered")
_ImGui_CreateText("t_txt_state",  "  Text     : not hovered")
_ImGui_CreateText("t_combined",   "  Any of the three : no")
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
    Local $bBtn = _ImGui_IsHovered("tg_btn")
    Local $bCb  = _ImGui_IsHovered("tg_cb")
    Local $bTxt = _ImGui_IsHovered("tg_txt")
    _ImGui_SetText("t_btn_state", "  Button   : " & ($bBtn ? "HOVERED" : "not hovered"))
    _ImGui_SetText("t_cb_state",  "  Checkbox : " & ($bCb  ? "HOVERED" : "not hovered"))
    _ImGui_SetText("t_txt_state", "  Text     : " & ($bTxt ? "HOVERED" : "not hovered"))
    _ImGui_SetText("t_combined",  "  Any of the three : " & (($bBtn Or $bCb Or $bTxt) ? "YES" : "no"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
