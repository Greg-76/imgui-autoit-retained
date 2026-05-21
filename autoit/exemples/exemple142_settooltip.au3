#cs
================================================================================
 Example 142 : _ImGui_SetTooltip
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetTooltip   Attach a single-line tooltip to an EXISTING widget

 Helper API : the tooltip is stored in Widget::tooltip on the target.
 ImGui pops it up when the widget is hovered for the standard delay.
 No container, no children -- text only. For rich tooltips with
 multiple widgets inside (separators, colored text, sliders) use
 _ImGui_CreateItemTooltip (exemple143).

 The text is MUTABLE at runtime : re-calling SetTooltip with a new
 string updates the popup ; passing the empty string clears the
 tooltip entirely.

 Target widget can be ANY id in the tree (Button, Slider, Checkbox,
 Text, ...). The mechanism is per-widget, NOT per-hover-area, so
 each target gets its own tooltip text independently.

 Borrowed widgets : Button, SliderFloat, Checkbox, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple142_settooltip.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple142_settooltip.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 142 : _ImGui_SetTooltip", 720, 500) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetTooltip  --  doc block
; ==============================================================================
; Signature : _ImGui_SetTooltip($sId, $sText)
;
;   $sId   : identifier of any existing widget in the tree. NOT
;            validated by the wrapper -- unknown ids are silently
;            ignored by the DLL.
;
;   $sText : tooltip text (UTF-8). Single line. Pass "" to CLEAR the
;            tooltip (no popup on hover).
;
;   Mutable : re-call any time to change the text ; ImGui picks up the
;             new value on the next render.
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded,
;            2=DllCall failed).


; ==============================================================================
; Targets  --  three widgets each with their own tooltip
; ==============================================================================
_ImGui_CreateText("t_title", "SetTooltip demo  --  single-line tooltips attached to existing widgets")
_ImGui_CreateText("t_hint",  "Hover the targets below for ~0.5s to see each tooltip pop up.")
_ImGui_CreateSeparator("sep0")

_ImGui_CreateButton("btn_save",   "Save")
_ImGui_CreateSliderFloat("sl_vol","Volume", 0.0, 1.0, 0.5, "%.2f")
_ImGui_CreateCheckbox("cb_mute",  "Mute audio", False)
_ImGui_CreateButton("btn_action", "Do action")

; Static tooltips applied once at startup. Re-callable any time later.
_ImGui_SetTooltip("btn_save",   "Save the current document to disk.")
_ImGui_SetTooltip("sl_vol",     "Drag to set the master output volume (0.0 to 1.0).")
_ImGui_SetTooltip("cb_mute",    "When checked, all audio output is silenced.")
_ImGui_SetTooltip("btn_action", "Run the configured action.")

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Controls  --  mutate / clear tooltips at runtime
; ==============================================================================
_ImGui_CreateText("t_ctrl_hdr", "Runtime controls :")
_ImGui_CreateButton("btn_relabel", "Re-label the 'Do action' tooltip (cycles through 3 messages)")
_ImGui_CreateButton("btn_clear",   "Clear ALL tooltips (re-hover : no popup anymore)")
_ImGui_CreateButton("btn_restore", "Restore all tooltips to their startup text")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status", "Current 'Do action' tooltip : <startup>")

_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- State (cycle index for the re-label button) ----------------------------
Global $g_iCycle = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("cb_mute",    "_OnMuteToggled")
_ImGui_SetOnClick ("btn_relabel","_OnRelabel")
_ImGui_SetOnClick ("btn_clear",  "_OnClearAll")
_ImGui_SetOnClick ("btn_restore","_OnRestoreAll")
_ImGui_SetOnClick ("btn_quit",   "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnMuteToggled($sId)
    ; Drive the tooltip text from the live state. Re-calling SetTooltip with a
    ; new string is the canonical way to keep a tooltip in sync with widget
    ; state (no dedicated SetTooltipDynamic API needed).
    If _ImGui_GetValueBool($sId) Then
        _ImGui_SetTooltip("cb_mute", "Currently MUTED -- click again to un-mute.")
    Else
        _ImGui_SetTooltip("cb_mute", "Currently audible -- click to mute.")
    EndIf
EndFunc

Func _OnRelabel($sId)
    Local $aMsgs = ["Cycle #1 : Do something useful.", _
                    "Cycle #2 : Or maybe something else.", _
                    "Cycle #3 : Third time's the charm."]
    Local $sNew = $aMsgs[Mod($g_iCycle, 3)]
    _ImGui_SetTooltip("btn_action", $sNew)
    _ImGui_SetText   ("t_status",   "Current 'Do action' tooltip : " & $sNew)
    $g_iCycle += 1
EndFunc

Func _OnClearAll($sId)
    ; Empty string = clear the tooltip. The widgets still exist and respond
    ; to clicks ; only the popup is gone.
    _ImGui_SetTooltip("btn_save",   "")
    _ImGui_SetTooltip("sl_vol",     "")
    _ImGui_SetTooltip("cb_mute",    "")
    _ImGui_SetTooltip("btn_action", "")
    _ImGui_SetText("t_status", "Current 'Do action' tooltip : <cleared>")
EndFunc

Func _OnRestoreAll($sId)
    _ImGui_SetTooltip("btn_save",   "Save the current document to disk.")
    _ImGui_SetTooltip("sl_vol",     "Drag to set the master output volume (0.0 to 1.0).")
    _ImGui_SetTooltip("cb_mute",    "When checked, all audio output is silenced.")
    _ImGui_SetTooltip("btn_action", "Run the configured action.")
    _ImGui_SetText("t_status",      "Current 'Do action' tooltip : <restored to startup>")
    $g_iCycle = 0
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
