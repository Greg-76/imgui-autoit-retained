#cs
================================================================================
 Example 133 : _ImGui_SetTabItemClosed
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetTabItemClosed   Cleanly close a TabItem (anti-flicker)

 Two ways to programmatically dismiss a tab :

   A) _ImGui_SetVisible($sTabId, False)
      Direct flip of Widget::visible. Works, but on a Reorderable
      TabBar the next frame can render the tab for a fraction of a
      frame before ImGui notices it was hidden -- visible flicker on
      drag-in-progress / animation frames.

   B) _ImGui_SetTabItemClosed($sTabId)   <-- this exemple
      Atomically sets Widget::visible = false AND flips
      pending_closed = true. On the next render the DLL calls
      ImGui::SetTabItemClosed($sTabId), which is the official ImGui
      API for "this tab is going away" -- the bar updates its layout
      before drawing, so no flicker.

 Both are restored the same way : _ImGui_SetVisible($sTabId, True).

 This file shows two equivalent tabs (Log + Chat). Each tab body
 contains TWO close buttons : "clean" (SetTabItemClosed) and "raw"
 (SetVisible(False)) so the user can compare both paths visually
 while dragging another tab.

 NOTE : SetTabItemClosed expects a TabItem id ; calling it on any
 other widget returns @error = 3.

 Borrowed widgets : TabBar (exemple130) + Reorderable, TabItem
 (exemple131), Text + Button + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple133_settabitemclosed.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple133_settabitemclosed.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 133 : _ImGui_SetTabItemClosed", 740, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetTabItemClosed  --  doc block
; ==============================================================================
; Signature : _ImGui_SetTabItemClosed($sTabItemId)
;
;   Marks a TabItem for clean closure on the next render :
;     * Widget::visible       <- false
;     * pending_closed        <- true   (DLL will call
;                                        ImGui::SetTabItemClosed on
;                                        the next frame)
;   Both writes happen under the tree mutex -- atomic relative to the
;   render thread, no torn state.
;
;   Restore the tab the same way as for a click-X close :
;     _ImGui_SetVisible($sTabItemId, True)
;
;   $sTabItemId : MUST identify a TabItem widget. Other widget types
;                 return @error = 3 with @extended carrying the DLL
;                 status (2 = unknown id, 3 = not a TabItem).
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded,
;            2=DllCall failed, 3=unknown id or not a TabItem).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "SetTabItemClosed demo  --  clean close vs raw SetVisible(False)")
_ImGui_CreateText("t_hint",  "Each tab body has TWO close buttons : 'clean' (SetTabItemClosed) and 'raw' (SetVisible).")
_ImGui_CreateText("t_hint2", "Both restore the tab via SetVisible(True). On Reorderable bars the 'clean' path avoids flicker.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; TabBar with two equivalent closable tabs
; ==============================================================================
Local $iBarFlags = BitOR($ImGuiTabBarFlags_Reorderable, $ImGuiTabBarFlags_DrawSelectedOverline)
_ImGui_CreateTabBar("tabs", "", $iBarFlags)

; --- Tab : Log ---------------------------------------------------------------
_ImGui_CreateTabItem("tab_log", "Log", True)
_ImGui_SetParent("tab_log", "tabs")
_ImGui_CreateText  ("log_t1",      "  Log tab body.")
_ImGui_CreateButton("log_btn_clean","  Close Log (clean : SetTabItemClosed)")
_ImGui_CreateButton("log_btn_raw",  "  Close Log (raw : SetVisible(False))")
_ImGui_SetParent("log_t1",       "tab_log")
_ImGui_SetParent("log_btn_clean","tab_log")
_ImGui_SetParent("log_btn_raw",  "tab_log")

; --- Tab : Chat --------------------------------------------------------------
_ImGui_CreateTabItem("tab_chat", "Chat", True)
_ImGui_SetParent("tab_chat", "tabs")
_ImGui_CreateText  ("chat_t1",       "  Chat tab body.")
_ImGui_CreateButton("chat_btn_clean","  Close Chat (clean : SetTabItemClosed)")
_ImGui_CreateButton("chat_btn_raw",  "  Close Chat (raw : SetVisible(False))")
_ImGui_SetParent("chat_t1",       "tab_chat")
_ImGui_SetParent("chat_btn_clean","tab_chat")
_ImGui_SetParent("chat_btn_raw",  "tab_chat")


; ==============================================================================
; Host footer  --  restore buttons + live visibility readout
; ==============================================================================
_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_restore_hdr", "Restore (works for either close path) :")
_ImGui_CreateButton("btn_restore_log",  "Restore Log")
_ImGui_CreateButton("btn_restore_chat", "Restore Chat")
_ImGui_CreateButton("btn_restore_both", "Restore both")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_vis_hdr", "Current visibility :")
_ImGui_CreateText("t_vis",     "  Log = True   Chat = True")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("log_btn_clean",   "_OnCloseLogClean")
_ImGui_SetOnClick("log_btn_raw",     "_OnCloseLogRaw")
_ImGui_SetOnClick("chat_btn_clean",  "_OnCloseChatClean")
_ImGui_SetOnClick("chat_btn_raw",    "_OnCloseChatRaw")
_ImGui_SetOnClick("btn_restore_log", "_OnRestoreLog")
_ImGui_SetOnClick("btn_restore_chat","_OnRestoreChat")
_ImGui_SetOnClick("btn_restore_both","_OnRestoreBoth")
_ImGui_SetOnClick("btn_quit",        "_OnQuit")
; Poll the visibility every 100ms to keep the readout live (close paths can
; come from the [X] button on the title too).
_ImGui_SetOnTick("_OnPollVisibility", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnCloseLogClean($sId)
    _ImGui_SetTabItemClosed("tab_log")
EndFunc

Func _OnCloseLogRaw($sId)
    _ImGui_SetVisible("tab_log", False)
EndFunc

Func _OnCloseChatClean($sId)
    _ImGui_SetTabItemClosed("tab_chat")
EndFunc

Func _OnCloseChatRaw($sId)
    _ImGui_SetVisible("tab_chat", False)
EndFunc

Func _OnRestoreLog($sId)
    _ImGui_SetVisible("tab_log", True)
EndFunc

Func _OnRestoreChat($sId)
    _ImGui_SetVisible("tab_chat", True)
EndFunc

Func _OnRestoreBoth($sId)
    _ImGui_SetVisible("tab_log",  True)
    _ImGui_SetVisible("tab_chat", True)
EndFunc

Func _OnPollVisibility()
    Local $sLog  = _ImGui_GetVisible("tab_log")  ? "True " : "False"
    Local $sChat = _ImGui_GetVisible("tab_chat") ? "True " : "False"
    _ImGui_SetText("t_vis", "  Log = " & $sLog & "  Chat = " & $sChat)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
