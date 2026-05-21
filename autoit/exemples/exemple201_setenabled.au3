#cs
================================================================================
 Example 201 : _ImGui_SetEnabled
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetEnabled   Enable / disable any widget by id (greyed
                       appearance, rejects interaction)

 Programmatic counterpart to ImGui::BeginDisabled() / EndDisabled().
 Per-widget rather than scope-based : the wrapper stores a disabled
 flag on the Widget struct and ImGui::PushItemFlag(NoInteraction +
 disabled style) is applied during that widget's render. Cascading
 to children of a container (Window / Group / TabItem / Child) is
 NOT automatic -- you must call SetEnabled on each interactive
 leaf you want greyed.

 Disabled widgets :
   * render in a greyed-out style (alpha ~0.6 * normal).
   * reject mouse click / drag / focus -- their internal latches
     (clicked / changed / hovered-for-interaction) stay False.
   * accept programmatic _ImGui_Set* calls -- the script can still
     read or write their value ; only USER interaction is blocked.

 Use cases :
   * Gating dependent widgets : "Save" button greyed until form is
     valid ; "Connect" greyed while already connected.
   * Modal-style dimming without an actual modal popup.
   * Showing both states (enabled / disabled) of a widget for a
     screenshot or A/B comparison.

 Demo layout :
   * One Checkbox "MASTER : controls the rest" -- toggling it
     SetEnabled(False) on the entire cluster below.
   * A cluster of 6 widgets : 2 Buttons + 1 Slider + 1 Checkbox +
     1 InputText + 1 ColorEdit3. All driven by the master.
   * Counters : how many click / change events fired since launch.
     When the master is False, the counters STOP advancing (UI
     interaction rejected) -- but a script-side button can still
     mutate the slider's value programmatically (proves Set* works
     even when disabled).

 Borrowed widgets : Checkbox, Button, SliderInt, InputText,
 ColorEdit3, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple201_setenabled.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple201_setenabled.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 201 : SetEnabled", 760, 660) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetEnabled  --  doc block
; ==============================================================================
; Signature : _ImGui_SetEnabled($sId, $bEnabled)
;
;   $sId      : widget identifier.
;   $bEnabled : True to enable, False to disable (grey + reject input).
;
;   Return : True on success, False on failure (@error = 1, 2).
;
;   Per-widget, NOT recursive over a container's children. Cascade
;   manually by calling SetEnabled on each leaf inside a Group / Child
;   / Window if you want the whole region greyed.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "SetEnabled demo  --  programmatic enable/disable per widget")
_ImGui_CreateText("t_hint",  "Toggle the MASTER checkbox ; the cluster below greys out and stops accepting input.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Master toggle
; ==============================================================================
_ImGui_CreateCheckbox("cb_master", "MASTER  --  enable / disable everything below", True)
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Cluster  --  6 widgets gated by the master
; ==============================================================================
_ImGui_CreateText("t_cluster_hdr", "Cluster (enabled by default ; greyed when MASTER is off) :")
_ImGui_CreateButton("btn_a", "Button A")
_ImGui_CreateButton("btn_b", "Button B")
_ImGui_CreateSliderInt("sl_x", "Slider X", 0, 100, 25, "%d")
_ImGui_CreateCheckbox("cb_opt", "Optional setting", False)
_ImGui_CreateInputText("in_name", "Name", "edit me", 128)
_ImGui_CreateColorEdit3("ce_color", "Accent", 0.2, 0.6, 0.9, 0)
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Counters + programmatic test
; ==============================================================================
_ImGui_CreateText("t_counters", "Interaction counters (refreshed at 200 ms) :")
_ImGui_CreateText("t_c_lines",  "  buttons: 0   slider changes: 0   checkbox toggles: 0   text edits: 0   color edits: 0")
_ImGui_CreateText("t_prog_hdr", "Programmatic test (works EVEN when disabled) :")
_ImGui_CreateButton("btn_prog", "Add +5 to Slider X via SetValueInt  (bypass user interaction)")
_ImGui_CreateSeparator("sep3")


_ImGui_CreateText("t_status", "Status : everything enabled. Toggle MASTER to see the cluster grey out.")
_ImGui_CreateSeparator("sep4")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Globals -----------------------------------------------------------------
Global $g_iCBtn = 0, $g_iCSl = 0, $g_iCChk = 0, $g_iCIn = 0, $g_iCCol = 0
; The list of cluster ids -- iterate to cascade SetEnabled.
Global $g_aCluster[6] = ["btn_a", "btn_b", "sl_x", "cb_opt", "in_name", "ce_color"]


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("cb_master", "_OnMaster")
_ImGui_SetOnClick("btn_a",      "_OnBtn")
_ImGui_SetOnClick("btn_b",      "_OnBtn")
_ImGui_SetOnChange("sl_x",      "_OnSl")
_ImGui_SetOnChange("cb_opt",    "_OnChk")
_ImGui_SetOnChange("in_name",   "_OnIn")
_ImGui_SetOnChange("ce_color",  "_OnCol")
_ImGui_SetOnClick("btn_prog",   "_OnProg")
_ImGui_SetOnClick("btn_quit",   "_OnQuit")
_ImGui_SetOnTick("_OnRefresh", 200)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnMaster($sId)
    Local $bOn = _ImGui_GetValueBool("cb_master")
    For $i = 0 To UBound($g_aCluster) - 1
        _ImGui_SetEnabled($g_aCluster[$i], $bOn)
    Next
    If $bOn Then
        _ImGui_SetText("t_status", "Status : cluster ENABLED. Click / drag the widgets to fire events.")
    Else
        _ImGui_SetText("t_status", "Status : cluster DISABLED. Try interacting -- counters won't budge.")
    EndIf
EndFunc

Func _OnBtn($sId)
    $g_iCBtn += 1
EndFunc

Func _OnSl($sId)
    $g_iCSl += 1
EndFunc

Func _OnChk($sId)
    $g_iCChk += 1
EndFunc

Func _OnIn($sId)
    $g_iCIn += 1
EndFunc

Func _OnCol($sId)
    $g_iCCol += 1
EndFunc

Func _OnProg($sId)
    ; Demonstrate that programmatic SetValue* works regardless of enabled state.
    Local $iCur = _ImGui_GetValueInt("sl_x")
    Local $iNew = $iCur + 5
    If $iNew > 100 Then $iNew = 0
    _ImGui_SetValueInt("sl_x", $iNew)
    _ImGui_SetText("t_status", StringFormat( _
        "Status : SetValueInt('sl_x', %d) applied programmatically (works even when disabled).", $iNew))
EndFunc

Func _OnRefresh()
    _ImGui_SetText("t_c_lines", StringFormat( _
        "  buttons: %d   slider changes: %d   checkbox toggles: %d   text edits: %d   color edits: %d", _
        $g_iCBtn, $g_iCSl, $g_iCChk, $g_iCIn, $g_iCCol))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
