#cs
================================================================================
 Example 139 : _ImGui_CreateContextPopup
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateContextPopup   Inline context popup -- fuses
                               BeginPopupContext{Item,Window,Void} with
                               its body widgets

 Three kinds (= the three ImGui::BeginPopupContext* helpers) wired
 through a single $iKind parameter :
   0 = Item    Right-click attaches to the previous sibling widget
               (the one just before this marker in the same parent).
   1 = Window  Right-click anywhere inside the enclosing window
               (root host or a Child).
   2 = Void    Right-click in void area (no window hovered).

 PLACEMENT RULE :
   * kind=0 (Item) : MUST be the next child after the target item in
     the same parent. The trigger reads ImGui's "previous item"
     state, so the order of siblings matters. Inserting any widget
     between the target and the ContextPopup breaks the attachment.
   * kind=1 (Window) : placement inside the enclosing window's
     children works anywhere ; only the SCOPE matters.
   * kind=2 (Void)   : placement anywhere is fine.

 Open / close / IsOpen reuse the Popup verbs (exemple137) with the
 same uniform routing. The popup body holds Selectables / MenuItems
 (MenuItem auto-closes the parent popup on click unless the
 $ImGuiItemFlags_AutoClosePopups behavior is disabled).

 Borrowed widgets : MenuItem (exemple128), Child (exemple100 family),
 Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple139_contextpopup.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple139_contextpopup.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 139 : _ImGui_CreateContextPopup", 760, 640) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateContextPopup  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateContextPopup($sId, $sLabel = "",
;                                        $iKind = 0, $iFlags = 0)
;
;   $iKind : 0 = Item    (right-click attaches to previous sibling)
;            1 = Window  (right-click anywhere in the enclosing window)
;            2 = Void    (right-click in void area)
;
;   $iFlags : bitmask of $ImGuiPopupFlags_*. Default 0 = ImGui's
;             $ImGuiPopupFlags_MouseButtonRight (since 1.92.6). Override
;             with $ImGuiPopupFlags_MouseButtonLeft (4),
;             $ImGuiPopupFlags_MouseButtonMiddle (12), etc.
;
;   Children : MenuItem / Selectable / Text / any widget, reparented
;              via _ImGui_SetParent. They render inside the context
;              popup when it opens.
;
;   Routing : _ImGui_OpenPopup / _ImGui_ClosePopup / _ImGui_IsPopupOpen
;             all accept ContextPopup ids uniformly.
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateContextPopup demo  --  three kinds : Item / Window / Void")
_ImGui_CreateText("t_hint",  "Each section below is triggered by a right-click in a different scope. Watch the IsPopupOpen readouts.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; 1) kind = Item  --  right-click on the target Button
; ==============================================================================
_ImGui_CreateText("t_item_hdr", "1) kind = Item  --  right-click the button below to open its menu :")
_ImGui_CreateButton("btn_item_target", "Right-click me")
; PLACEMENT : must be the NEXT child after btn_item_target in the same parent.
_ImGui_CreateContextPopup("ctx_item", "", 0, $ImGuiPopupFlags_MouseButtonRight)
_ImGui_CreateMenuItem("ctx_item_copy",  "Copy",   "Ctrl+C")
_ImGui_CreateMenuItem("ctx_item_paste", "Paste",  "Ctrl+V")
_ImGui_CreateMenuItem("ctx_item_del",   "Delete", "Del")
_ImGui_SetParent("ctx_item_copy",  "ctx_item")
_ImGui_SetParent("ctx_item_paste", "ctx_item")
_ImGui_SetParent("ctx_item_del",   "ctx_item")

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; 2) kind = Window  --  right-click anywhere inside a Child window
; ==============================================================================
_ImGui_CreateText("t_win_hdr", "2) kind = Window  --  right-click ANYWHERE inside the bordered box below :")
_ImGui_CreateChild("ch_winctx", "", 720, 110, True)
_ImGui_CreateText("ch_winctx_t1", "Right-click here, in the margins, between items -- anywhere triggers the menu.")
_ImGui_CreateText("ch_winctx_t2", "Scope = the Child window itself. kind=Window, MouseButtonRight.")
_ImGui_SetParent("ch_winctx_t1", "ch_winctx")
_ImGui_SetParent("ch_winctx_t2", "ch_winctx")
; Placement inside the Child container ; kind=Window doesn't need sibling ordering.
_ImGui_CreateContextPopup("ctx_win", "", 1, $ImGuiPopupFlags_MouseButtonRight)
_ImGui_CreateMenuItem("ctx_win_save",   "Save",   "Ctrl+S")
_ImGui_CreateMenuItem("ctx_win_export", "Export", "")
_ImGui_CreateMenuItem("ctx_win_close",  "Close",  "Ctrl+W")
_ImGui_SetParent("ctx_win",        "ch_winctx")
_ImGui_SetParent("ctx_win_save",   "ctx_win")
_ImGui_SetParent("ctx_win_export", "ctx_win")
_ImGui_SetParent("ctx_win_close",  "ctx_win")

_ImGui_CreateSeparator("sep2")


; ==============================================================================
; 3) kind = Void  --  right-click on the void area of the host
; ==============================================================================
_ImGui_CreateText("t_void_hdr", "3) kind = Void  --  right-click on EMPTY area of the host (between widgets, in the margin) :")
_ImGui_CreateContextPopup("ctx_void", "", 2, $ImGuiPopupFlags_MouseButtonRight)
_ImGui_CreateMenuItem("ctx_void_new",   "New file",    "Ctrl+N")
_ImGui_CreateMenuItem("ctx_void_pref",  "Preferences", "")
_ImGui_CreateMenuItem("ctx_void_about", "About",       "")
_ImGui_SetParent("ctx_void_new",   "ctx_void")
_ImGui_SetParent("ctx_void_pref",  "ctx_void")
_ImGui_SetParent("ctx_void_about", "ctx_void")

_ImGui_CreateSeparator("sep3")


; ==============================================================================
; Status footer
; ==============================================================================
_ImGui_CreateText("t_status_hdr", "Live state + last MenuItem click :")
_ImGui_CreateText("t_status_item", "  ctx_item : closed   (last: -)")
_ImGui_CreateText("t_status_win",  "  ctx_win  : closed   (last: -)")
_ImGui_CreateText("t_status_void", "  ctx_void : closed   (last: -)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Last-clicked memos (script-scope) --------------------------------------
Global $g_sLastItem = "-"
Global $g_sLastWin  = "-"
Global $g_sLastVoid = "-"


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("ctx_item_copy",  "_OnItemMenu")
_ImGui_SetOnClick("ctx_item_paste", "_OnItemMenu")
_ImGui_SetOnClick("ctx_item_del",   "_OnItemMenu")

_ImGui_SetOnClick("ctx_win_save",   "_OnWinMenu")
_ImGui_SetOnClick("ctx_win_export", "_OnWinMenu")
_ImGui_SetOnClick("ctx_win_close",  "_OnWinMenu")

_ImGui_SetOnClick("ctx_void_new",   "_OnVoidMenu")
_ImGui_SetOnClick("ctx_void_pref",  "_OnVoidMenu")
_ImGui_SetOnClick("ctx_void_about", "_OnVoidMenu")

_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPollStatus", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnItemMenu($sId)
    $g_sLastItem = $sId
EndFunc

Func _OnWinMenu($sId)
    $g_sLastWin = $sId
EndFunc

Func _OnVoidMenu($sId)
    $g_sLastVoid = $sId
EndFunc

Func _OnPollStatus()
    _ImGui_SetText("t_status_item", "  ctx_item : " & (_ImGui_IsPopupOpen("ctx_item") ? "OPEN" : "closed") & "   (last: " & $g_sLastItem & ")")
    _ImGui_SetText("t_status_win",  "  ctx_win  : " & (_ImGui_IsPopupOpen("ctx_win")  ? "OPEN" : "closed") & "   (last: " & $g_sLastWin  & ")")
    _ImGui_SetText("t_status_void", "  ctx_void : " & (_ImGui_IsPopupOpen("ctx_void") ? "OPEN" : "closed") & "   (last: " & $g_sLastVoid & ")")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
