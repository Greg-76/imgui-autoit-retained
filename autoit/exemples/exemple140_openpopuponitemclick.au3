#cs
================================================================================
 Example 140 : _ImGui_CreateOpenPopupOnItemClick
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateOpenPopupOnItemClick   Invisible trigger marker that
                                       opens a target Popup when the
                                       previous sibling is clicked

 The marker has no body, no visible widget -- it just attaches an
 ImGui::OpenPopupOnItemClick(target, flags) call to the "previous
 item" on every frame. On qualifying click (button encoded in
 $iFlags), it sets pending_open_dirty on the target popup widget
 (Popup / PopupModal / ContextPopup) via a tree lookup. The popup
 then opens on the next render.

 KEY DIFFERENCE vs ContextPopup kind=Item (exemple139) :
   * ContextPopup kind=Item fuses the trigger AND the popup body in
     ONE widget : the popup MUST be the next sibling after the
     target.
   * OpenPopupOnItemClick is just the TRIGGER ; the target popup
     can live ANYWHERE in the tree (typical : a top-level Popup at
     root, while the marker lives deep inside a Child / Window).
     The marker bypasses ImGui's cross-pass id hashing via a direct
     tree lookup.

 PLACEMENT RULE (sibling-order, like ContextPopup kind=Item) :
   The marker MUST be the next child AFTER the target widget in the
   SAME parent. Inserting anything between them breaks the trigger.

 $sTargetPopupId is NOT validated at create time : typos silently
 no-op (clicking the button does nothing).

 Default trigger button = $ImGuiPopupFlags_MouseButtonRight (since
 1.92.6). Override to LEFT for the "Settings cog opens dialog" idiom.

 Borrowed widgets : Popup (exemple137), Text + Button + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple140_openpopuponitemclick.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple140_openpopuponitemclick.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 140 : _ImGui_CreateOpenPopupOnItemClick", 760, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateOpenPopupOnItemClick  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateOpenPopupOnItemClick($sId, $sTargetPopupId,
;                                                $iFlags = 0)
;
;   $sId             : stable identifier for the marker. Must be unique
;                      in the tree even though the marker has no body.
;
;   $sTargetPopupId  : identifier of the target Popup / PopupModal /
;                      ContextPopup. NOT validated at create time --
;                      typos silently no-op (clicking does nothing).
;
;   $iFlags          : bitmask of $ImGuiPopupFlags_*. Useful values :
;     0    = default = ImGui's $ImGuiPopupFlags_MouseButtonRight (1.92.6+)
;     4    = MouseButtonLeft
;     8    = MouseButtonRight
;     12   = MouseButtonMiddle
;     32   = NoReopen
;
;   PLACEMENT : MUST be the next child after the target widget in the
;   SAME parent. The marker reads ImGui's "previous item" state at
;   render time -- inserting any widget between the target and the
;   marker breaks the attachment.
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateOpenPopupOnItemClick demo  --  invisible trigger marker chains a button to a top-level Popup")
_ImGui_CreateText("t_hint",  "Two demos : LEFT-click chains and RIGHT-click chains. The popup body lives elsewhere in the tree.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Demo A  --  LEFT-click chain (button -> marker -> top-level popup)
; ==============================================================================
_ImGui_CreateText("t_left_hdr", "1) LEFT-click  --  marker uses $ImGuiPopupFlags_MouseButtonLeft :")
_ImGui_CreateButton("btn_left_target", "Left-click me")
; PLACEMENT : marker MUST be the next child after btn_left_target at root.
_ImGui_CreateOpenPopupOnItemClick("trig_left", "p_left", $ImGuiPopupFlags_MouseButtonLeft)

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Demo B  --  RIGHT-click chain (default flag)
; ==============================================================================
_ImGui_CreateText("t_right_hdr", "2) RIGHT-click  --  marker uses default $ImGuiPopupFlags_MouseButtonRight :")
_ImGui_CreateButton("btn_right_target", "Right-click me")
_ImGui_CreateOpenPopupOnItemClick("trig_right", "p_right", $ImGuiPopupFlags_MouseButtonRight)

_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Status footer
; ==============================================================================
_ImGui_CreateText("t_status_hdr", "Live popup state (proves the chain works) :")
_ImGui_CreateText("t_status_left",  "  p_left  : closed   (opens: 0)")
_ImGui_CreateText("t_status_right", "  p_right : closed   (opens: 0)")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Top-level Popups  --  live at root, ANYWHERE relative to their triggers
; ==============================================================================
_ImGui_CreatePopup("p_left", "", 0)
_ImGui_CreateText  ("p_left_t",     "Opened via OpenPopupOnItemClick (LEFT trigger).")
_ImGui_CreateButton("p_left_close", "Dismiss")
_ImGui_SetParent("p_left_t",     "p_left")
_ImGui_SetParent("p_left_close", "p_left")

_ImGui_CreatePopup("p_right", "", 0)
_ImGui_CreateText  ("p_right_t",     "Opened via OpenPopupOnItemClick (RIGHT trigger).")
_ImGui_CreateButton("p_right_close", "Dismiss")
_ImGui_SetParent("p_right_t",     "p_right")
_ImGui_SetParent("p_right_close", "p_right")


; --- Counters (latch open-edges so 'opens' increments only once per open) ---
Global $g_iLeftOpens   = 0
Global $g_iRightOpens  = 0
Global $g_bWasLeftOpen  = False
Global $g_bWasRightOpen = False


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("p_left_close",  "_OnCloseLeft")
_ImGui_SetOnClick("p_right_close", "_OnCloseRight")
_ImGui_SetOnClick("btn_quit",      "_OnQuit")
_ImGui_SetOnTick("_OnPollStatus", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnCloseLeft($sId)
    _ImGui_ClosePopup("p_left")
EndFunc

Func _OnCloseRight($sId)
    _ImGui_ClosePopup("p_right")
EndFunc

Func _OnPollStatus()
    ; Rising-edge detection for the 'opens' counter.
    Local $bLeftOpen  = _ImGui_IsPopupOpen("p_left")
    Local $bRightOpen = _ImGui_IsPopupOpen("p_right")
    If $bLeftOpen  And Not $g_bWasLeftOpen  Then $g_iLeftOpens  += 1
    If $bRightOpen And Not $g_bWasRightOpen Then $g_iRightOpens += 1
    $g_bWasLeftOpen  = $bLeftOpen
    $g_bWasRightOpen = $bRightOpen

    _ImGui_SetText("t_status_left",  "  p_left  : " & ($bLeftOpen  ? "OPEN" : "closed") & "   (opens: " & $g_iLeftOpens  & ")")
    _ImGui_SetText("t_status_right", "  p_right : " & ($bRightOpen ? "OPEN" : "closed") & "   (opens: " & $g_iRightOpens & ")")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
