#cs
================================================================================
 Example 14 : _ImGui_CreateRadioButtonGroup
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateRadioButtonGroup    Auto-exclusive radio bound to an int
   _ImGui_GetRadioGroupValue        Read the currently-selected int
   _ImGui_SetRadioGroupValue        Set the selection programmatically

 RadioButtonGroup is the HIGH-LEVEL radio. Multiple widgets sharing the
 same $sGroupId hold a single int value internally ; clicking one updates
 the shared int and the OTHER widgets in the group automatically untick.
 No script-side cascade needed.

 Compare with exemple13_radiobutton.au3 -- same UX, more API.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple14_radiobuttongroup.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple14_radiobuttongroup.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 14 : _ImGui_CreateRadioButtonGroup", 560, 360) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateRadioButtonGroup  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateRadioButtonGroup($sId, $sLabel, $sGroupId, $iMyValue, $bDefaultActive = False)
;
;   Renders a radio that belongs to the group named $sGroupId. The group
;   stores ONE int. This widget is checked iff group.value == $iMyValue.
;
;   Parameters :
;     $sId            Unique widget id (one per radio).
;     $sLabel         Displayed label.
;     $sGroupId       Group name. All radios sharing this string are mutually
;                     exclusive ; the wrapper enforces exclusion in the DLL,
;                     no script-side cascade required.
;     $iMyValue       The integer value this radio represents within the group.
;     $bDefaultActive If True at creation time, the group's value becomes
;                     $iMyValue. Only mark ONE radio per group as default.
;
;   Group APIs :
;     _ImGui_GetRadioGroupValue($sGroupId)         -> int (selected value, -1 if unset)
;     _ImGui_SetRadioGroupValue($sGroupId, $iVal)  -> apply programmatically (no OnClick)
;
;   IMPORTANT : RadioButtonGroupWidget inherits from ClickableWidget, NOT
;   BoolValueWidget. It latches `clicked`, not `changed`. Use
;   _ImGui_SetOnClick to react to user picks ; _ImGui_SetOnChange would
;   never fire on this widget.
;
;   The visual still switches automatically though, because the shared
;   group state is updated inside the DLL on click and every member
;   renders "selected iff its my_value == group state". The OnClick
;   handler is only needed to react in the script (update readouts,
;   trigger side effects, etc.).


; ==============================================================================
; Demo widgets  --  three radios in one group + a Reset button
; ==============================================================================
_ImGui_CreateText("t_title", "RadioButtonGroup demo  --  auto-exclusive")
_ImGui_CreateText("t_hint",  "Click any radio. Mutual exclusion is handled by the wrapper itself.")
_ImGui_CreateSeparator("sep1")

; All three radios share group "prio". Option Normal is the default.
_ImGui_CreateRadioButtonGroup("rb_low",    "Low priority",    "prio", 1, False)
_ImGui_CreateRadioButtonGroup("rb_normal", "Normal priority", "prio", 2, True)
_ImGui_CreateRadioButtonGroup("rb_high",   "High priority",   "prio", 3, False)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_value", "Group value : 2 (Normal)")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_progmat", "Programmatic actions (do NOT fire OnChange) :")
_ImGui_CreateButton("btn_set_low",  "SetRadioGroupValue(1)  -- Low")
_ImGui_CreateButton("btn_set_high", "SetRadioGroupValue(3)  -- High")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
; OnClick (not OnChange) because RadioButtonGroup latches `clicked`, not `changed`.
_ImGui_SetOnClick("rb_low",       "_OnRadioPicked")
_ImGui_SetOnClick("rb_normal",    "_OnRadioPicked")
_ImGui_SetOnClick("rb_high",      "_OnRadioPicked")
_ImGui_SetOnClick("btn_set_low",  "_OnSetLow")
_ImGui_SetOnClick("btn_set_high", "_OnSetHigh")
_ImGui_SetOnClick("btn_quit",     "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

; Fired whenever the user clicks ANY radio in the group. The widget id
; tells us which one was clicked, but the group value is what we care
; about -- read it back via GetRadioGroupValue.
Func _OnRadioPicked($sId)
    Local $iVal = _ImGui_GetRadioGroupValue("prio")
    Local $sLabel = ""
    Switch $iVal
        Case 1
            $sLabel = "Low"
        Case 2
            $sLabel = "Normal"
        Case 3
            $sLabel = "High"
        Case Else
            $sLabel = "(unknown)"
    EndSwitch
    _ImGui_SetText("t_value", StringFormat("Group value : %d (%s)", $iVal, $sLabel))
EndFunc

; Programmatic Set : does NOT fire OnChange. We update the readout
; ourselves to reflect the new state.
Func _OnSetLow($sId)
    _ImGui_SetRadioGroupValue("prio", 1)
    _ImGui_SetText("t_value", "Group value : 1 (Low, set programmatically)")
EndFunc

Func _OnSetHigh($sId)
    _ImGui_SetRadioGroupValue("prio", 3)
    _ImGui_SetText("t_value", "Group value : 3 (High, set programmatically)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
