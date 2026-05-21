#cs
================================================================================
 Example 141 : _ImGui_CreatePopupOpenMousePos
                (+ _ImGui_GetPopupOpenMousePos)
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_CreatePopupOpenMousePos   Invisible marker that latches the
                                     mouse position at the moment the
                                     enclosing popup was opened
   _ImGui_GetPopupOpenMousePos      Read the latched [x, y] coordinates
                                     (screen pixels)

 The marker is a CHILD of a Popup / PopupModal / ContextPopup
 (reparented via _ImGui_SetParent). It renders inside the popup body
 ; on each render it calls ImGui::GetMousePosOnOpeningCurrentPopup()
 and freezes the result in its widget state. _ImGui_GetPopupOpenMousePos
 reads that frozen value from any thread, at any time.

 Why a marker rather than a free function : ImGui's free function
 reads g.BeginPopupStack, which is empty BETWEEN frames. Called from
 the AutoIt thread (always between frames under our frame mutex), it
 falls back to the current mouse pos -- defeating the purpose. The
 marker runs DURING the popup's Render() on the render thread where
 the stack is non-empty.

 Use cases :
   * Position a sub-widget at the click location ("place new node at
     mouse").
   * Display "you right-clicked at (x, y)".
   * Build a coordinate-driven action menu (Delete-near-here, etc.).

 Initial value before first render : [0.0, 0.0]. The latched value
 persists AFTER the popup closes -- it stays at the last open
 position until the next open replaces it.

 Borrowed widgets : ContextPopup (exemple139), MenuItem (exemple128),
 Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple141_popupopenmousepos.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple141_popupopenmousepos.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 141 : _ImGui_CreatePopupOpenMousePos", 760, 580) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePopupOpenMousePos  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePopupOpenMousePos($sId)
;
;   Invisible marker. Place as a CHILD of a Popup / PopupModal /
;   ContextPopup via _ImGui_SetParent($sMarker, $sPopup) -- outside
;   a popup scope the marker never renders and the latch never
;   updates.
;
;   Return : True on success, False on failure (@error = 1, 2).

; ==============================================================================
; _ImGui_GetPopupOpenMousePos  --  doc block
; ==============================================================================
; Signature : _ImGui_GetPopupOpenMousePos($sMarkerId)
;
;   Returns array[2] = [x, y] in screen pixels. (0.0, 0.0) until the
;   marker has rendered inside a popup body at least once. Latched --
;   stays at the value last captured when the popup was open.
;
;   @error = 1 (DLL not loaded), 2 (DllCall failed),
;            3 (unknown id or wrong widget kind ; @extended = DLL status).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreatePopupOpenMousePos demo  --  freeze the click position at popup open time")
_ImGui_CreateText("t_hint",  "Right-click the target at DIFFERENT positions. The latched [x, y] updates only when the popup opens.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; A wide target  --  right-click anywhere on it to open the context menu
; ==============================================================================
_ImGui_CreateText("t_target_hdr", "Target  --  right-click anywhere inside the area below :")
_ImGui_CreateButton("btn_target", "                  Right-click me at different X/Y                  ")

; ContextPopup kind=Item attached to btn_target. PLACEMENT : must be the next
; child after btn_target in the same parent (root here).
_ImGui_CreateContextPopup("ctx_pos", "", 0, $ImGuiPopupFlags_MouseButtonRight)
_ImGui_CreateText("ctx_pos_t",  "Mouse pos when this popup opened :")
_ImGui_CreateText("ctx_pos_xy", "  (waiting for first open...)")
; The marker (invisible) latches the value during this popup's render.
_ImGui_CreatePopupOpenMousePos("mark_pos")
_ImGui_CreateSeparator("ctx_pos_sep")
_ImGui_CreateMenuItem("ctx_pos_act", "Imaginary action at this position")
_ImGui_SetParent("ctx_pos_t",   "ctx_pos")
_ImGui_SetParent("ctx_pos_xy",  "ctx_pos")
_ImGui_SetParent("mark_pos",    "ctx_pos")
_ImGui_SetParent("ctx_pos_sep", "ctx_pos")
_ImGui_SetParent("ctx_pos_act", "ctx_pos")


; ==============================================================================
; Host footer  --  latched value also displayed here (proves it persists)
; ==============================================================================
_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_host_hdr", "Live readout of GetPopupOpenMousePos (persists even after the popup closes) :")
_ImGui_CreateText("t_host_xy",  "  latched (x, y) = (0.0, 0.0)   --  open the popup at least once")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("ctx_pos_act", "_OnActionClicked")
_ImGui_SetOnClick("btn_quit",    "_OnQuit")
_ImGui_SetOnTick("_OnPollMousePos", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollMousePos()
    Local $aXY = _ImGui_GetPopupOpenMousePos("mark_pos")
    If @error Then Return
    Local $sLine = StringFormat("  (x, y) = (%.1f, %.1f)", $aXY[0], $aXY[1])
    ; Update both views : inside the popup body (visible only while open) AND
    ; in the persistent host footer.
    _ImGui_SetText("ctx_pos_xy", $sLine)
    _ImGui_SetText("t_host_xy",  "  latched " & $sLine)
EndFunc

Func _OnActionClicked($sId)
    ; Re-read the latched value at click time and reflect it in the host area
    ; as a sticky "last action at ..." line.
    Local $aXY = _ImGui_GetPopupOpenMousePos("mark_pos")
    Local $sLine = StringFormat("  action FIRED at latched (%.1f, %.1f)", $aXY[0], $aXY[1])
    _ImGui_SetText("t_host_xy", $sLine)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
