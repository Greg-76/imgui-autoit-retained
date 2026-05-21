#cs
================================================================================
 Example 157 : SetNextFrameWantCapture* (mouse + keyboard, 2-cluster)
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_SetNextFrameWantCaptureMouse      hint : ImGui takes / releases
                                            the mouse for the NEXT frame
   _ImGui_SetNextFrameWantCaptureKeyboard   same idea, for keyboard input

 ONE-SHOT INTENT : the hint applies to the NEXT frame only. If you
 want the capture to persist, re-call every frame (SetOnTick at 16 ms).

 What "capture" means : ImGui's io.WantCaptureMouse / io.WantCapture-
 Keyboard flags tell the HOST application "should I forward this
 event to ImGui or to my game / underlying app ?" Setting them via
 these APIs is a HINT to your input routing layer -- it does NOT
 swallow events INSIDE ImGui itself. In a standalone demo (no game
 underneath) the visible effect is limited to the io.WantCapture*
 readouts ; the educational point is the API contract.

 Typical use cases :
   * "Swallow the next click" : a custom widget detects a click that
     ImGui hasn't claimed, calls SetNextFrameWantCaptureMouse(True)
     for the click frame, then releases on the next.
   * "Release input for one frame" : on a state transition where the
     game underneath needs that exact frame.

 The demo provides four buttons (mouse / keyboard x True / False) and
 a counter showing how many times each was called. The state is also
 latched into two Globals so an optional SetOnTick "persistent mode"
 can re-apply each frame (toggled by a checkbox).

 Borrowed widgets : Button, Checkbox, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple157_capture_intent.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple157_capture_intent.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 157 : SetNextFrameWantCapture*", 760, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 2-export cluster
; ==============================================================================
; _ImGui_SetNextFrameWantCaptureMouse($bWant)
; _ImGui_SetNextFrameWantCaptureKeyboard($bWant)
;
;   $bWant : True  = next frame, ImGui takes the input from the host
;                    application (even if no widget is hovered).
;            False = next frame, ImGui releases the input.
;
;   One-shot. To make the override persistent, re-call every frame
;   via _ImGui_SetOnTick(16ms).
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "SetNextFrameWantCapture*  --  mouse + keyboard, one-shot or persistent")
_ImGui_CreateText("t_hint",  "Buttons below = one-shot calls. The checkbox enables persistent re-apply at 16 ms.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; One-shot controls
; ==============================================================================
_ImGui_CreateText("t_one_hdr", "One-shot calls (apply to the NEXT frame only) :")
_ImGui_CreateButton("btn_m_true",  "Capture MOUSE next frame  (True)")
_ImGui_CreateButton("btn_m_false", "Release MOUSE next frame  (False)")
_ImGui_CreateButton("btn_k_true",  "Capture KEYBOARD next frame  (True)")
_ImGui_CreateButton("btn_k_false", "Release KEYBOARD next frame  (False)")

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Persistent mode  --  re-apply latched intent every 16 ms
; ==============================================================================
_ImGui_CreateText("t_persist_hdr", "Persistent mode :")
_ImGui_CreateCheckbox("cb_persist", "Re-apply last-set intent every 16 ms (mouse + keyboard)", False)
_ImGui_CreateText("t_persist_state", "  Latched intent  --  mouse: True  keyboard: True")

_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Counters
; ==============================================================================
_ImGui_CreateText("t_counters", "Call counters  --  M-True: 0   M-False: 0   K-True: 0   K-False: 0")
_ImGui_CreateText("t_persist_counter", "Persistent re-applies (this run) : 0")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters + latched intent ---------------------------------------------
Global $g_iCallMT = 0, $g_iCallMF = 0
Global $g_iCallKT = 0, $g_iCallKF = 0
Global $g_iPersistApplies = 0
; Latched intent for the persistent mode -- mirrors the last button click.
Global $g_bWantMouse    = True
Global $g_bWantKeyboard = True


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_m_true",  "_OnMouseTrue")
_ImGui_SetOnClick("btn_m_false", "_OnMouseFalse")
_ImGui_SetOnClick("btn_k_true",  "_OnKeyboardTrue")
_ImGui_SetOnClick("btn_k_false", "_OnKeyboardFalse")
_ImGui_SetOnClick("btn_quit",    "_OnQuit")
_ImGui_SetOnTick("_OnPersistTick", 16)
_ImGui_SetOnTick("_OnStatusTick",  100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnMouseTrue($sId)
    _ImGui_SetNextFrameWantCaptureMouse(True)
    $g_bWantMouse = True
    $g_iCallMT += 1
EndFunc

Func _OnMouseFalse($sId)
    _ImGui_SetNextFrameWantCaptureMouse(False)
    $g_bWantMouse = False
    $g_iCallMF += 1
EndFunc

Func _OnKeyboardTrue($sId)
    _ImGui_SetNextFrameWantCaptureKeyboard(True)
    $g_bWantKeyboard = True
    $g_iCallKT += 1
EndFunc

Func _OnKeyboardFalse($sId)
    _ImGui_SetNextFrameWantCaptureKeyboard(False)
    $g_bWantKeyboard = False
    $g_iCallKF += 1
EndFunc

Func _OnPersistTick()
    ; Only fires while the user opted into persistent mode.
    If _ImGui_GetValueBool("cb_persist") Then
        _ImGui_SetNextFrameWantCaptureMouse($g_bWantMouse)
        _ImGui_SetNextFrameWantCaptureKeyboard($g_bWantKeyboard)
        $g_iPersistApplies += 1
    EndIf
EndFunc

Func _OnStatusTick()
    _ImGui_SetText("t_persist_state", _
        "  Latched intent  --  mouse: " & ($g_bWantMouse ? "True " : "False") & _
        "  keyboard: " & ($g_bWantKeyboard ? "True " : "False"))
    _ImGui_SetText("t_counters", StringFormat( _
        "Call counters  --  M-True: %d   M-False: %d   K-True: %d   K-False: %d", _
        $g_iCallMT, $g_iCallMF, $g_iCallKT, $g_iCallKF))
    _ImGui_SetText("t_persist_counter", "Persistent re-applies (this run) : " & $g_iPersistApplies)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
