#cs
================================================================================
 Example 11 : _ImGui_CreateCheckbox
================================================================================
 Covers 4 exports of imgui_autoit.dll :

   _ImGui_CreateCheckbox    Standard on/off toggle
   _ImGui_GetValueBool      Read the current state
   _ImGui_SetValueBool      Set the state programmatically (no latch)
   _ImGui_HasChanged        Underlying primitive of OnChange ; see below

 OnChange is the wrapper-provided event helper that calls a handler on
 every user toggle ; it consumes the latched _ImGui_HasChanged flag for us.
 Scripts never need to call _ImGui_HasChanged directly.

 Strict semantics (very important here) :
   * Programmatic _ImGui_SetValueBool DOES NOT fire OnChange.
   * Only a user click in Render() latches the changed flag.
   * Consequence : the "Toggle programmatically" button below can flip the
     checkbox without retriggering its handler -- no infinite loop possible.
   * This is what makes script-side cascading (e.g. mutual exclusion in
     exemple13_radiobutton.au3) safe.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple11_checkbox.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple11_checkbox.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 11 : _ImGui_CreateCheckbox", 560, 360) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateCheckbox  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateCheckbox($sId, $sLabel = "", $bDefault = False)
;
;   Adds a clickable on/off toggle. The label appears to the RIGHT of the
;   checkbox square. $bDefault is the initial state ; the user can flip it
;   by clicking and the new state stays until changed again.
;
;   Bound APIs :
;     _ImGui_GetValueBool($sId)         -> True/False  (current state)
;     _ImGui_SetValueBool($sId, $bVal)  -> apply programmatically (no event)
;     _ImGui_SetOnChange($sId, "Func")  -> fire Func($sId) on each user click
;
;   Returns : True on success, False on failure (@error = 1 not initialised,
;   2 duplicate id, 3 DllCall failed).


; ==============================================================================
; Demo widgets
; ==============================================================================
_ImGui_CreateText("t_title", "Checkbox demo")
_ImGui_CreateText("t_hint",  "Toggle the checkbox by hand. Then use the buttons to flip it programmatically.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateCheckbox("cb_main", "I am the demo checkbox", False)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_state", "Current state : False")
_ImGui_CreateText("t_count", "User toggles  : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_progmat", "Programmatic actions (do NOT count as user toggles) :")
_ImGui_CreateButton("btn_on",    "Force ON   via SetValueBool(True)")
_ImGui_CreateButton("btn_off",   "Force OFF  via SetValueBool(False)")
_ImGui_CreateButton("btn_flip",  "Flip       via SetValueBool(Not GetValueBool)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iToggleCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("cb_main",  "_OnCheckboxToggled")
_ImGui_SetOnClick ("btn_on",   "_OnForceOn")
_ImGui_SetOnClick ("btn_off",  "_OnForceOff")
_ImGui_SetOnClick ("btn_flip", "_OnForceFlip")
_ImGui_SetOnClick ("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

; Fired only when the USER clicks the checkbox. NOT fired when the buttons
; below mutate the state via SetValueBool -- that is the strict-semantics
; rule that makes this safe.
Func _OnCheckboxToggled($sId)
    Local $bNew = _ImGui_GetValueBool($sId)
    $g_iToggleCount += 1
    _ImGui_SetText("t_state", "Current state : " & ($bNew ? "True" : "False"))
    _ImGui_SetText("t_count", "User toggles  : " & $g_iToggleCount)
EndFunc

Func _OnForceOn($sId)
    _ImGui_SetValueBool("cb_main", True)
    ; OnChange does NOT fire ; we update the readout ourselves.
    _ImGui_SetText("t_state", "Current state : True (set programmatically)")
EndFunc

Func _OnForceOff($sId)
    _ImGui_SetValueBool("cb_main", False)
    _ImGui_SetText("t_state", "Current state : False (set programmatically)")
EndFunc

Func _OnForceFlip($sId)
    Local $bNew = Not _ImGui_GetValueBool("cb_main")
    _ImGui_SetValueBool("cb_main", $bNew)
    _ImGui_SetText("t_state", "Current state : " & ($bNew ? "True" : "False") & " (set programmatically)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
