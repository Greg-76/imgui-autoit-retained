#cs
================================================================================
 Example 137 : _ImGui_CreatePopup
                (+ _ImGui_OpenPopup + _ImGui_ClosePopup + _ImGui_IsPopupOpen)
================================================================================
 Covers 4 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_CreatePopup    Top-level Popup container (no title bar)
   _ImGui_OpenPopup      Queue a one-shot open at the next render
   _ImGui_ClosePopup     Queue a one-shot close at the next render
   _ImGui_IsPopupOpen    Live latched query : True while the popup body
                         is rendering

 The four are bundled in the same file because the Popup widget is
 not useful without its driver verbs (Open / Close / IsOpen) -- same
 bundling rule as exemple100 (CreateWindow + SetParent + SetVisible /
 GetVisible).

 Popup characteristics :
   * Rendered OUTSIDE the host Begin / End -- always TOP-LEVEL.
     Children are reparented under the popup id, NOT under any
     window.
   * No title bar -- the visual is just the body floating above the
     host. Dismissable by clicking outside or via _ImGui_ClosePopup.
   * Position : ImGui places it near the current cursor at open time
     by default. For caller-controlled placement see exemple141
     (PopupOpenMousePos).
   * Idempotent open : re-calling _ImGui_OpenPopup while the popup is
     already open is a no-op (unless $ImGuiPopupFlags_NoReopen is
     set on the Create call).

 Borrowed widgets : Text + Button + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple137_popup.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple137_popup.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 137 : _ImGui_CreatePopup", 720, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePopup  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePopup($sId, $sLabel = "", $iFlags = 0)
;
;   $sLabel : optional displayed title (most popups omit it -- popups
;             have no title bar anyway, the label is only used for the
;             internal ImGui id stack).
;
;   $iFlags : bitmask of $ImGuiPopupFlags_* / $ImGuiWindowFlags_*.
;             Useful values :
;     0    = default
;     32   = NoReopen      OpenPopup while-open is a no-op + leaves nav
;     128  = NoOpenOverExistingPopup
;     128  = NoBackground  ($ImGuiWindowFlags_NoBackground)
;
;   Children : any widget, reparented via _ImGui_SetParent. They render
;              in the popup body.
;
;   Return : True on success, False on failure (@error = 1, 2).

; ==============================================================================
; _ImGui_OpenPopup  --  doc block
; ==============================================================================
; Signature : _ImGui_OpenPopup($sId)
;
;   Queues an open at the next Render(). Idempotent : re-calling while
;   the popup is already open is a no-op (ImGui repositions + reinits
;   nav state unless $ImGuiPopupFlags_NoReopen was set on Create).
;
;   Return : True on success ; SetError(3) if $sId isn't a popup widget.

; ==============================================================================
; _ImGui_ClosePopup  --  doc block
; ==============================================================================
; Signature : _ImGui_ClosePopup($sId)
;
;   Queues a close at the next Render(). Honored only if the popup is
;   open at that moment -- silently dropped otherwise (safe to spam
;   from a button handler without checking IsPopupOpen first).
;
;   Return : True on success ; SetError(3) if $sId isn't a popup widget.

; ==============================================================================
; _ImGui_IsPopupOpen  --  doc block
; ==============================================================================
; Signature : _ImGui_IsPopupOpen($sId)
;
;   Returns True while the popup body is rendering. False for unknown
;   ids or non-popup widgets. Latched -- no edge-frame issue ; safe to
;   poll at any rate.


; ==============================================================================
; Host area  --  the trigger button + live status
; ==============================================================================
_ImGui_CreateText("t_title", "CreatePopup demo  --  top-level floating body, no title bar")
_ImGui_CreateText("t_hint",  "Click 'Open popup' to show it. Dismiss via Confirm, Cancel, or click outside.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateButton("btn_open", "Open popup")
_ImGui_CreateText  ("t_status", "IsPopupOpen('p_simple') : closed")
_ImGui_CreateText  ("t_counts", "OpenPopup() calls: 0   ClosePopup() calls: 0   Confirm: 0   Cancel: 0")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The Popup  --  declared at root, top-level
; ==============================================================================
_ImGui_CreatePopup("p_simple", "", 0)
_ImGui_CreateText  ("p_t1",     "Top-level popup.")
_ImGui_CreateText  ("p_t2",     "Pick Confirm or Cancel, or click outside to dismiss.")
_ImGui_CreateButton("p_confirm","Confirm")
_ImGui_CreateButton("p_cancel", "Cancel")
_ImGui_SetParent("p_t1",      "p_simple")
_ImGui_SetParent("p_t2",      "p_simple")
_ImGui_SetParent("p_confirm", "p_simple")
_ImGui_SetParent("p_cancel",  "p_simple")


; --- Counters ---------------------------------------------------------------
Global $g_iOpenCalls    = 0
Global $g_iCloseCalls   = 0
Global $g_iConfirmHits  = 0
Global $g_iCancelHits   = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_open",   "_OnOpen")
_ImGui_SetOnClick("p_confirm",  "_OnConfirm")
_ImGui_SetOnClick("p_cancel",   "_OnCancel")
_ImGui_SetOnClick("btn_quit",   "_OnQuit")
_ImGui_SetOnTick("_OnPollStatus", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnOpen($sId)
    _ImGui_OpenPopup("p_simple")
    $g_iOpenCalls += 1
EndFunc

Func _OnConfirm($sId)
    $g_iConfirmHits += 1
    _ImGui_ClosePopup("p_simple")
    $g_iCloseCalls += 1
EndFunc

Func _OnCancel($sId)
    $g_iCancelHits += 1
    _ImGui_ClosePopup("p_simple")
    $g_iCloseCalls += 1
EndFunc

Func _OnPollStatus()
    Local $bOpen = _ImGui_IsPopupOpen("p_simple")
    _ImGui_SetText("t_status", "IsPopupOpen('p_simple') : " & ($bOpen ? "OPEN" : "closed"))
    _ImGui_SetText("t_counts", StringFormat( _
        "OpenPopup() calls: %d   ClosePopup() calls: %d   Confirm: %d   Cancel: %d", _
        $g_iOpenCalls, $g_iCloseCalls, $g_iConfirmHits, $g_iCancelHits))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
