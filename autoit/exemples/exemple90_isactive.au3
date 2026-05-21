#cs
================================================================================
 Example 90 : _ImGui_IsActive
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsActive   Report whether a widget is currently held / dragged / edited

 IsActive is True while the user is actively interacting with the
 widget : holding the mouse button down on a Button, dragging a
 Slider's handle, editing an InputText. It transitions from False to
 True on mouse-down and back to False on mouse-up.

 PERSISTENT state across frames -- polling at 50 ms is reliable. To
 detect the transitions themselves (edge frames), see IsActivated /
 IsDeactivated (exemple94 / exemple95).

 Hidden / unknown widgets return False silently (no @error).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple90_isactive.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple90_isactive.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 90 : _ImGui_IsActive", 600, 460) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsActive  --  doc block
; ==============================================================================
; Signature : _ImGui_IsActive($sId)
;
;   Returns True while the user holds / drags / edits the widget.
;   Persistent across frames as long as the interaction continues.
;
;   "Active" definition by widget type :
;     - Button       : mouse button held down over the widget
;     - Slider/Drag  : handle currently grabbed
;     - InputText    : keyboard cursor active in the field
;     - Checkbox     : while the mouse button is pressed on the box
;     - Selectable   : while pressed
;
;   Hidden / unknown widgets return False silently (no @error).


; ==============================================================================
; Demo widgets  --  three targets that you can hold / drag / edit, plus a
;                  live status panel.
; ==============================================================================
_ImGui_CreateText("t_title", "IsActive demo  --  hold / drag / edit detection")
_ImGui_CreateText("t_hint",  "Hold the button down, drag the slider, click inside the input field. Watch the panel below.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateButton("tg_btn",     "Target 1 : hold the mouse button down on me")
_ImGui_CreateSliderFloat("tg_sl", "Target 2 : drag the slider", 0.0, 1.0, 0.5, "%.2f")
_ImGui_CreateInputText("tg_in",   "Target 3 : click and type inside this field", "type here", 64, 0)
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Status panel (~20 Hz poll) :")
_ImGui_CreateText("t_btn_state",  "  Button   : idle")
_ImGui_CreateText("t_sl_state",   "  Slider   : idle")
_ImGui_CreateText("t_in_state",   "  Input    : idle")
_ImGui_CreateText("t_any_state",  "  Any of the three : no")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollActive", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollActive()
    Local $bBtn = _ImGui_IsActive("tg_btn")
    Local $bSl  = _ImGui_IsActive("tg_sl")
    Local $bIn  = _ImGui_IsActive("tg_in")
    _ImGui_SetText("t_btn_state", "  Button   : " & ($bBtn ? "ACTIVE (held)"      : "idle"))
    _ImGui_SetText("t_sl_state",  "  Slider   : " & ($bSl  ? "ACTIVE (dragging)"  : "idle"))
    _ImGui_SetText("t_in_state",  "  Input    : " & ($bIn  ? "ACTIVE (editing)"   : "idle"))
    _ImGui_SetText("t_any_state", "  Any of the three : " & (($bBtn Or $bSl Or $bIn) ? "YES" : "no"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
