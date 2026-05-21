#cs
================================================================================
 Example 13 : _ImGui_CreateRadioButton
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateRadioButton    Standalone radio button (no automatic group)
   _ImGui_GetValueBool         Read individual state
   _ImGui_SetValueBool         Apply exclusivity from the OnClick handler

 IMPORTANT -- two non-obvious points about RadioButton :

   1) It is a CLICKABLE widget, not a Bool-valued widget. It latches a
      click (_ImGui_WasClicked), NOT a change (_ImGui_HasChanged). Bind
      _ImGui_SetOnClick, never _ImGui_SetOnChange -- the latter will never
      fire on a RadioButton.

   2) It does NOT change its own visual state on click. The widget exposes
      Get/SetValueBool to read/write the active state, but a click only
      raises the click flag -- the SCRIPT must explicitly SetValueBool to
      update the visual.

 That second point means a script-side exclusion is FORCED for low-level
 RadioButton. The handler below does it explicitly. The strict-semantics
 rule (programmatic _ImGui_SetValueBool does NOT raise the click flag)
 means we can SetValueBool on all three radios without any cascade.

 For automatic exclusion (one int per group, no script-side cascade),
 use _ImGui_CreateRadioButtonGroup -- see exemple14_radiobuttongroup.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple13_radiobutton.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple13_radiobutton.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 13 : _ImGui_CreateRadioButton", 560, 320) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateRadioButton  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateRadioButton($sId, $sLabel = "", $bActive = False)
;
;   Renders a round radio-style toggle. Internally it inherits from
;   ClickableWidget : clicks latch a `clicked` flag, NOT a `changed` flag.
;   It also overrides Get/SetValueBool so scripts can read/write the
;   visual `active` state by hand.
;
;   $bActive is the INITIAL visual state. The DLL never updates `active`
;   on click ; the script must do it via _ImGui_SetValueBool.
;
;   Bound APIs :
;     _ImGui_GetValueBool($sId)         -> True/False  (visual active state)
;     _ImGui_SetValueBool($sId, $bVal)  -> set visual state (no latch)
;     _ImGui_SetOnClick($sId, "Func")   -> fire Func($sId) on each user click
;     _ImGui_SetOnChange                -> NEVER FIRES for RadioButton
;
;   Return : True on success, False on failure (@error = 1 not initialised,
;   2 duplicate id, 3 DllCall failed).


; ==============================================================================
; Demo widgets  --  3 standalone radios, script-side exclusion
; ==============================================================================
_ImGui_CreateText("t_title", "RadioButton demo  --  script-side mutual exclusion")
_ImGui_CreateText("t_hint",  "Click any radio. The OnClick handler updates all three visuals.")
_ImGui_CreateSeparator("sep1")

; Only the first one is active initially. The user can switch by clicking.
_ImGui_CreateRadioButton("rb_a", "Option A", True)
_ImGui_CreateRadioButton("rb_b", "Option B", False)
_ImGui_CreateRadioButton("rb_c", "Option C", False)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_choice", "Selection  : Option A")
_ImGui_CreateText("t_count",  "User picks : 0")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iPickCount = 0


; --- Bind  --  same handler shared by the three radios ----------------------
; OnClick (not OnChange) because RadioButton latches `clicked`, not `changed`.
_ImGui_SetOnClick("rb_a",     "_OnRadioPicked")
_ImGui_SetOnClick("rb_b",     "_OnRadioPicked")
_ImGui_SetOnClick("rb_c",     "_OnRadioPicked")
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

; Called when ANY of the three radios was just clicked by the user.
; Because RadioButton does NOT update its own `active` state on click,
; the handler must set the visual on all three radios -- True on the one
; that was clicked, False on the others. The SetValueBool calls don't
; re-latch the click flag (strict semantics) so no cascade is possible.
Func _OnRadioPicked($sId)
    _ImGui_SetValueBool("rb_a", $sId = "rb_a")
    _ImGui_SetValueBool("rb_b", $sId = "rb_b")
    _ImGui_SetValueBool("rb_c", $sId = "rb_c")

    Local $sLabel = ""
    Switch $sId
        Case "rb_a"
            $sLabel = "Option A"
        Case "rb_b"
            $sLabel = "Option B"
        Case "rb_c"
            $sLabel = "Option C"
    EndSwitch

    $g_iPickCount += 1
    _ImGui_SetText("t_choice", "Selection  : " & $sLabel)
    _ImGui_SetText("t_count",  "User picks : " & $g_iPickCount)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
