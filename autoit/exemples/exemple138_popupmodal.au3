#cs
================================================================================
 Example 138 : _ImGui_CreatePopupModal
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePopupModal   Top-level modal Popup (dim background +
                             optional title bar with X close button)

 Differs from a regular Popup (exemple137) in two ways :
   1) The host is DIMMED while the modal is open -- the user cannot
      interact with anything else until the modal is dismissed.
   2) A title bar is drawn (with $sLabel), optionally including an
      X close button via $bClosable = True.

 Open / close / IsOpen reuse the same verbs as Popup :
   _ImGui_OpenPopup($modalId)
   _ImGui_ClosePopup($modalId)
   _ImGui_IsPopupOpen($modalId)
 -- documented in exemple137.

 Closable variant : the X button writes Widget::visible = false
 (same mechanism as Window / TabItem / CollapsingHeader). Re-opening
 via _ImGui_OpenPopup auto-resets visible = true, so the cycle stays
 clean -- no manual SetVisible required.

 Borrowed widgets : Popup verbs (exemple137), SliderFloat, Checkbox,
 InputText, Text + Button + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple138_popupmodal.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple138_popupmodal.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 138 : _ImGui_CreatePopupModal", 740, 560) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePopupModal  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePopupModal($sId, $sLabel = "",
;                                      $bClosable = False, $iFlags = 0)
;
;   $sLabel    : displayed in the title bar.
;
;   $bClosable : True adds an X close button on the title bar. The X
;                writes Widget::visible = false. Re-opening via
;                _ImGui_OpenPopup auto-resets visible = true -- no
;                manual restore needed.
;
;   $iFlags    : bitmask of $ImGuiPopupFlags_* / $ImGuiWindowFlags_*.
;
;   Children : reparented via _ImGui_SetParent. Render in the modal
;              body.
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Host area  --  trigger buttons + status
; ==============================================================================
_ImGui_CreateText("t_title", "CreatePopupModal demo  --  modal without X  vs  modal with X")
_ImGui_CreateText("t_hint",  "While a modal is open the host area is DIMMED and ignores clicks.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateButton("btn_open_noX", "Open modal (no X  --  must use Apply / Cancel)")
_ImGui_CreateButton("btn_open_x",   "Open modal (with X  --  click X, Apply, or Cancel)")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Live IsPopupOpen state :")
_ImGui_CreateText("t_status_noX", "  p_noX  : closed")
_ImGui_CreateText("t_status_x",   "  p_X    : closed")
_ImGui_CreateText("t_counters",   "Apply hits  --  noX: 0   X: 0")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Modal 1  --  NOT closable (no X). Must be dismissed via inside buttons.
; ==============================================================================
_ImGui_CreatePopupModal("p_noX", "Modal without X", False, 0)
_ImGui_CreateText  ("p_noX_t1",  "I have no X close button.")
_ImGui_CreateText  ("p_noX_t2",  "Use Apply or Cancel below to dismiss me.")
_ImGui_CreateInputText("p_noX_in", "Note", "", 64)
_ImGui_CreateButton("p_noX_apply", "Apply")
_ImGui_CreateButton("p_noX_cancel","Cancel")
_ImGui_SetParent("p_noX_t1",    "p_noX")
_ImGui_SetParent("p_noX_t2",    "p_noX")
_ImGui_SetParent("p_noX_in",    "p_noX")
_ImGui_SetParent("p_noX_apply", "p_noX")
_ImGui_SetParent("p_noX_cancel","p_noX")


; ==============================================================================
; Modal 2  --  Closable (X on title bar). Re-opening auto-resets Widget::visible.
; ==============================================================================
_ImGui_CreatePopupModal("p_X", "Modal with X", True, 0)
_ImGui_CreateText  ("p_X_t1",      "Title bar has an X. Click it to dismiss.")
_ImGui_CreateText  ("p_X_t2",      "Apply also dismisses ; re-opening auto-resets visible=true.")
_ImGui_CreateSliderFloat("p_X_sl", "Sensitivity", 0.0, 1.0, 0.5, "%.2f")
_ImGui_CreateCheckbox("p_X_cb",    "Enable feature", True)
_ImGui_CreateButton("p_X_apply",   "Apply")
_ImGui_CreateButton("p_X_cancel",  "Cancel")
_ImGui_SetParent("p_X_t1",     "p_X")
_ImGui_SetParent("p_X_t2",     "p_X")
_ImGui_SetParent("p_X_sl",     "p_X")
_ImGui_SetParent("p_X_cb",     "p_X")
_ImGui_SetParent("p_X_apply",  "p_X")
_ImGui_SetParent("p_X_cancel", "p_X")


; --- Counters ---------------------------------------------------------------
Global $g_iNoXApply = 0
Global $g_iXApply   = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_open_noX", "_OnOpenNoX")
_ImGui_SetOnClick("btn_open_x",   "_OnOpenX")
_ImGui_SetOnClick("p_noX_apply",  "_OnNoXApply")
_ImGui_SetOnClick("p_noX_cancel", "_OnNoXCancel")
_ImGui_SetOnClick("p_X_apply",    "_OnXApply")
_ImGui_SetOnClick("p_X_cancel",   "_OnXCancel")
_ImGui_SetOnClick("btn_quit",     "_OnQuit")
_ImGui_SetOnTick("_OnPollStatus", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnOpenNoX($sId)
    _ImGui_OpenPopup("p_noX")
EndFunc

Func _OnOpenX($sId)
    _ImGui_OpenPopup("p_X")
EndFunc

Func _OnNoXApply($sId)
    $g_iNoXApply += 1
    _ImGui_ClosePopup("p_noX")
EndFunc

Func _OnNoXCancel($sId)
    _ImGui_ClosePopup("p_noX")
EndFunc

Func _OnXApply($sId)
    $g_iXApply += 1
    _ImGui_ClosePopup("p_X")
EndFunc

Func _OnXCancel($sId)
    _ImGui_ClosePopup("p_X")
EndFunc

Func _OnPollStatus()
    _ImGui_SetText("t_status_noX", "  p_noX  : " & (_ImGui_IsPopupOpen("p_noX") ? "OPEN" : "closed"))
    _ImGui_SetText("t_status_x",   "  p_X    : " & (_ImGui_IsPopupOpen("p_X")   ? "OPEN" : "closed"))
    _ImGui_SetText("t_counters",   "Apply hits  --  noX: " & $g_iNoXApply & "   X: " & $g_iXApply)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
