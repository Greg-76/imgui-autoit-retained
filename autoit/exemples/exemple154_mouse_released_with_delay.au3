#cs
================================================================================
 Example 154 : _ImGui_IsMouseReleasedWithDelay
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsMouseReleasedWithDelay   Edge-frame query : True only on
                                     release events that occur AT
                                     LEAST $fDelay seconds after the
                                     corresponding press

 Canonical use case : the Windows Explorer "single-click rename"
 idiom -- the user clicks a file, waits half a second still hovering,
 then releases ; the field switches to edit mode. A naive
 IsMouseReleased fires every time which collides with the double-
 click idiom (file open). With a delay >= io.MouseDoubleClickTime
 (~0.3 s), double-clicks are filtered out automatically.

 Other use cases :
   * Deferred-action confirmation : "hold the button for at least
     N seconds to confirm" -- release fires the action.
   * Drag-vs-click disambiguation when MouseDragThreshold is too
     small for what you want.

 EDGE-FRAME query (~16 ms True window) -- poll via SetOnTick at 16 ms.
 50 ms polling will miss most events.

 Borrowed widgets : SliderFloat (exemple16), Button, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple154_mouse_released_with_delay.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple154_mouse_released_with_delay.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 154 : _ImGui_IsMouseReleasedWithDelay", 720, 500) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsMouseReleasedWithDelay  --  doc block
; ==============================================================================
; Signature : _ImGui_IsMouseReleasedWithDelay($iButton = 0, $fDelay = 0.5)
;
;   $iButton : 0 = Left (default), 1 = Right, 2 = Middle.
;   $fDelay  : minimum hold time in seconds before the release fires.
;
;   Canonical pairing : $fDelay >= io.MouseDoubleClickTime (~0.3 s).
;   Smaller delays may collide with the double-click idiom -- the
;   second click of a double-click can also satisfy the "held >=
;   $fDelay" condition and fire twice.
;
;   Edge-frame -- True for ONE frame on a qualifying release. Poll at
;   16 ms to catch every event ; 50 ms misses ~70% of them.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "IsMouseReleasedWithDelay  --  fire on release ONLY if the click was held long enough")
_ImGui_CreateText("t_hint",  "Click and hold inside this window, then release. Adjust the delay slider below.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Controls  --  the delay slider + button choice
; ==============================================================================
_ImGui_CreateSliderFloat("sl_delay", "Delay (seconds)", 0.05, 2.00, 0.50, "%.2f s")
_ImGui_CreateText("t_delay_hint", "  Below 0.30 s -- collides with double-click. Above 0.30 s -- safe.")

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Live status
; ==============================================================================
_ImGui_CreateText("t_status_hdr", "Live state (polled at 16 ms) :")
_ImGui_CreateText("t_status_left",   "  LEFT   button : 0 qualifying releases")
_ImGui_CreateText("t_status_right",  "  RIGHT  button : 0 qualifying releases")
_ImGui_CreateText("t_status_middle", "  MIDDLE button : 0 qualifying releases")
_ImGui_CreateText("t_flash",         "(awaiting release...)")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters (edge-frame events) -------------------------------------------
Global $g_iRelL = 0
Global $g_iRelR = 0
Global $g_iRelM = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPoll", 16)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPoll()
    Local $fDelay = _ImGui_GetValueFloat("sl_delay")
    Local $bL = _ImGui_IsMouseReleasedWithDelay(0, $fDelay)
    Local $bR = _ImGui_IsMouseReleasedWithDelay(1, $fDelay)
    Local $bM = _ImGui_IsMouseReleasedWithDelay(2, $fDelay)
    If $bL Then $g_iRelL += 1
    If $bR Then $g_iRelR += 1
    If $bM Then $g_iRelM += 1

    _ImGui_SetText("t_status_left",   "  LEFT   button : " & $g_iRelL & " qualifying releases")
    _ImGui_SetText("t_status_right",  "  RIGHT  button : " & $g_iRelR & " qualifying releases")
    _ImGui_SetText("t_status_middle", "  MIDDLE button : " & $g_iRelM & " qualifying releases")

    Local $bAny = ($bL Or $bR Or $bM)
    _ImGui_SetText("t_flash", $bAny ? ">>> QUALIFYING RELEASE THIS TICK <<<" : "(awaiting release...)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
