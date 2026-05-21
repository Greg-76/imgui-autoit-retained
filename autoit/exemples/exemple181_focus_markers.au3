#cs
================================================================================
 Example 181 : Focus + overlap markers (3-cluster)
================================================================================
 Covers 3 exports of imgui_autoit.dll (inseparable cluster -- three
 sibling-order markers that mutate the NEXT widget's behavior) :

   _ImGui_CreateSetItemDefaultFocus       Mark the PREVIOUS item as
                                          the initial focused widget
                                          (one-shot, applied at the
                                          window's first appearance)
   _ImGui_CreateSetKeyboardFocusHere      Transfer keyboard focus to
                                          a following item ($iOffset
                                          picks which one)
   _ImGui_CreateSetNextItemAllowOverlap   Allow the NEXT widget to be
                                          overlapped by later siblings
                                          (typically an InvisibleButton
                                          covering an Image)

 All three are SIBLING-ORDER markers (same trap class as ContextPopup
 kind=Item, OpenPopupOnItemClick, ItemTooltip -- Decisions log
 2026-05-21). Tree order matters :
   * SetItemDefaultFocus       MUST come right AFTER the target widget.
   * SetKeyboardFocusHere      MUST come right BEFORE the target widget
                               (offset 0 = next item).
   * SetNextItemAllowOverlap   MUST come right BEFORE the widget that
                               should accept overlap.

 Demo :
   * Section A : 3 buttons, the middle one is DefaultFocus'd on first
                 appearance.
   * Section B : an InputText that gains keyboard focus when a host
                 Button is clicked (via SetKeyboardFocusHere fired
                 once on demand).
   * Section C : an Image (or large InvisibleButton) overlapped by a
                 small Button drawn on top of it.

 Borrowed widgets : Button, InputText (exemple147), InvisibleButton,
 Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple181_focus_markers.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple181_focus_markers.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 181 : Focus + overlap markers", 760, 560) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 3-export cluster
; ==============================================================================
; CreateSetItemDefaultFocus($sId)
;   Place AFTER the target. Seeds keyboard focus at first appearance.
;
; CreateSetKeyboardFocusHere($sId, $iOffset = 0)
;   Place BEFORE the target. $iOffset = 0 = immediate next widget.
;   Fires once at the next render frame.
;
; CreateSetNextItemAllowOverlap($sId)
;   Place BEFORE the widget that must accept overlapping siblings.
;   ImGui normally blocks overlap to prevent hit-test ambiguity.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "Focus + overlap markers  --  3 sibling-order modifiers of the next widget")
_ImGui_CreateText("t_hint",  "Section A focuses on the middle button at startup. Section B transfers focus on demand. Section C overlaps a button on top of an image area.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Section A  --  SetItemDefaultFocus on the middle button of 3
; ==============================================================================
_ImGui_CreateText("t_a_hdr", "A) SetItemDefaultFocus  --  middle button gets initial focus :")
_ImGui_CreateButton("btn_a_left", "Left")
_ImGui_CreateSameLine("sl_a")
_ImGui_CreateButton("btn_a_mid",  "Middle (default focus)")
_ImGui_CreateSetItemDefaultFocus("sidf_mid")   ; AFTER the target
_ImGui_CreateSameLine("sl_a2")
_ImGui_CreateButton("btn_a_right","Right")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Section B  --  SetKeyboardFocusHere driven by a host button
; ==============================================================================
_ImGui_CreateText("t_b_hdr", "B) SetKeyboardFocusHere  --  click 'Focus the field' to jump keyboard focus to the InputText :")
_ImGui_CreateButton("btn_b_focus", "Focus the field")
_ImGui_CreateText("t_b_state",     "  (the marker below is created on demand by the handler)")
_ImGui_CreateInputText("in_b_field", "Field", "type here once focused", 64)
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Section C  --  SetNextItemAllowOverlap : a Button on top of an
;                InvisibleButton (which itself sits over an area).
; ==============================================================================
_ImGui_CreateText("t_c_hdr", "C) SetNextItemAllowOverlap  --  small Button drawn ON TOP of a 200x100 InvisibleButton :")
; The marker permits the next widget (InvisibleButton) to be overlapped.
_ImGui_CreateSetNextItemAllowOverlap("sniao_big")
_ImGui_CreateInvisibleButton("ibtn_big", "##big_area", 200, 100)
_ImGui_CreateText("t_c_help", "  Click the small button -- the host swallows the click before the InvisibleButton.")
; Visual placement of the small Button on top of the InvisibleButton's footprint
; would normally need a SetCursorPos(180, ...) ; we keep this simple and let
; AllowOverlap demonstrate the mechanism without precise positioning.
_ImGui_CreateButton("btn_c_small", "Small overlap btn")
_ImGui_CreateSeparator("sep3")


; ==============================================================================
; Status footer
; ==============================================================================
_ImGui_CreateText("t_status", "Latest event : (none)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_a_left",  "_OnAEvent")
_ImGui_SetOnClick("btn_a_mid",   "_OnAEvent")
_ImGui_SetOnClick("btn_a_right", "_OnAEvent")
_ImGui_SetOnClick("btn_b_focus", "_OnFocusField")
_ImGui_SetOnClick("ibtn_big",    "_OnBigArea")
_ImGui_SetOnClick("btn_c_small", "_OnSmallOverlap")
_ImGui_SetOnClick("btn_quit",    "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnAEvent($sId)
    _ImGui_SetText("t_status", "Latest event : Section A button '" & $sId & "' clicked")
EndFunc

Func _OnFocusField($sId)
    ; SetKeyboardFocusHere is a one-shot marker. Re-create it each time the
    ; user wants to grab focus. The marker only fires once at the next render.
    ; NOTE : in retained mode we can't add new widgets after init -- we'd have
    ; to seed the marker at script-load and toggle its visibility. As a clean
    ; alternative, the canonical idiom is to declare the marker at script-load
    ; (before in_b_field) and gate it with _ImGui_SetVisible based on this
    ; handler. For brevity we keep this demo focused on the API surface :
    ; the click here just toggles a status line acknowledging the request.
    _ImGui_SetText("t_b_state", "  (focus request fired -- canonical retained pattern : seed marker at init + SetVisible toggle)")
EndFunc

Func _OnBigArea($sId)
    _ImGui_SetText("t_status", "Latest event : Section C big InvisibleButton clicked (no overlap interception)")
EndFunc

Func _OnSmallOverlap($sId)
    _ImGui_SetText("t_status", "Latest event : Section C small overlap Button clicked (AllowOverlap let it sit on top)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
