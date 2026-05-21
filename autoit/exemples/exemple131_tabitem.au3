#cs
================================================================================
 Example 131 : _ImGui_CreateTabItem
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateTabItem   Create a selectable tab with a body inside a TabBar

 A TabItem is a CONTAINER : its children render inside the tab body
 when the tab is the selected one. Reparent body widgets with
 _ImGui_SetParent($sChild, $sTabItem) -- same pattern as Window
 (exemple100).

 Two optional features showcased here :
   * $bClosable = True  -- adds an X button on the tab title. Clicking
     X writes Widget::visible = false (same mechanism as Window /
     CollapsingHeader). _ImGui_SetVisible($sTabId, True) brings the
     tab back.
   * $ImGuiTabItemFlags_UnsavedDocument -- adds a small dot next to the
     title (typical "modified file" indicator). Cosmetic only ; the
     flag is creation-time.

 TabItem is NOT a clickable widget : SetOnClick on the title is a
 no-op (selection happens via ImGui's internal nav state, not via the
 Widget::clicked flag). To react when the user SWITCHES to a tab,
 poll the body's children with _ImGui_IsVisible or just place
 visible-only widgets inside.

 STRUCTURAL MARKER rule (see Decisions log 2026-05-21) : TabItem
 reparented outside a TabBar is silently dropped.

 Borrowed widgets : TabBar (exemple130), SliderFloat, Text + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple131_tabitem.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple131_tabitem.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 131 : _ImGui_CreateTabItem", 720, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateTabItem  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateTabItem($sId, $sLabel = "",
;                                   $bClosable = False, $iFlags = 0)
;
;   $bClosable : True draws an X button on the tab title. The X writes
;                Widget::visible = false ; reading state with
;                _ImGui_GetVisible($sTabId). Bring the tab back via
;                _ImGui_SetVisible($sTabId, True) -- or close more
;                cleanly via _ImGui_SetTabItemClosed (exemple133).
;
;   $iFlags    : bitmask of $ImGuiTabItemFlags_*. Useful values :
;       0    = None                              -- baseline
;       1    = UnsavedDocument                   -- dot next to title
;       2    = SetSelected                       -- force selected once
;       4    = NoCloseWithMiddleMouseButton
;       16   = NoTooltip
;       32   = NoReorder
;       64   = Leading                           -- pin to bar's left
;       128  = Trailing                          -- pin to bar's right
;     (Leading / Trailing matter only on a Reorderable bar -- see
;      exemple132 for the TabItemButton variant that exercises them.)
;
;   Children : any widget. They render INSIDE the tab body, visible
;              only while the tab is the selected one.
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded,
;            2=DllCall failed).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateTabItem demo  --  four tabs : plain / rich / closable / unsaved")
_ImGui_CreateText("t_hint",  "Click a tab title to switch ; bodies render only for the selected tab.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; The TabBar
; ==============================================================================
_ImGui_CreateTabBar("tabs", "", $ImGuiTabBarFlags_Reorderable)

; --- Tab 1 : plain ----------------------------------------------------------
_ImGui_CreateTabItem("tab_plain", "Plain")
_ImGui_SetParent("tab_plain", "tabs")
_ImGui_CreateText("tp_t1", "  This is a plain tab with two Text children.")
_ImGui_CreateText("tp_t2", "  Bodies render only when the tab is the selected one.")
_ImGui_SetParent("tp_t1", "tab_plain")
_ImGui_SetParent("tp_t2", "tab_plain")

; --- Tab 2 : rich content (slider + live readout) ---------------------------
_ImGui_CreateTabItem("tab_rich", "Rich")
_ImGui_SetParent("tab_rich", "tabs")
_ImGui_CreateText("tr_t1", "  This tab's body holds interactive widgets, reparented via SetParent.")
_ImGui_CreateSliderFloat("tr_sl", "Sensitivity", 0.0, 1.0, 0.5, "%.2f")
_ImGui_CreateText("tr_readout", "  Sensitivity = 0.50")
_ImGui_SetParent("tr_t1",      "tab_rich")
_ImGui_SetParent("tr_sl",      "tab_rich")
_ImGui_SetParent("tr_readout", "tab_rich")

; --- Tab 3 : closable (X button via Widget::visible) ------------------------
_ImGui_CreateTabItem("tab_close", "Closable", True)
_ImGui_SetParent("tab_close", "tabs")
_ImGui_CreateText("tc_t1", "  Click the X on this tab's title to dismiss me.")
_ImGui_CreateText("tc_t2", "  Use 'Restore Closable' in the host area below to bring me back.")
_ImGui_SetParent("tc_t1", "tab_close")
_ImGui_SetParent("tc_t2", "tab_close")

; --- Tab 4 : UnsavedDocument flag (dot on the title) -------------------------
_ImGui_CreateTabItem("tab_dot", "Unsaved", False, $ImGuiTabItemFlags_UnsavedDocument)
_ImGui_SetParent("tab_dot", "tabs")
_ImGui_CreateText("td_t1", "  Look at this tab's title : a small dot signals an unsaved document.")
_ImGui_CreateText("td_t2", "  The flag is creation-time only ; the dot cannot be toggled at runtime.")
_ImGui_SetParent("td_t1", "tab_dot")
_ImGui_SetParent("td_t2", "tab_dot")


; ==============================================================================
; Host footer  --  controls + status feedback
; ==============================================================================
_ImGui_CreateSeparator("sep1")
_ImGui_CreateButton("btn_restore_close", "Restore Closable (after X)")
_ImGui_CreateText  ("t_close_state",     "tab_close visible : True")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("tr_sl",            "_OnSliderChanged")
_ImGui_SetOnClick ("btn_restore_close","_OnRestoreClose")
_ImGui_SetOnClick ("btn_quit",         "_OnQuit")
; Poll the closable tab's visibility every 100ms to keep the status line live.
_ImGui_SetOnTick("_OnPollVisibility", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnSliderChanged($sId)
    _ImGui_SetText("tr_readout", StringFormat("  Sensitivity = %.2f", _ImGui_GetValueFloat($sId)))
EndFunc

Func _OnRestoreClose($sId)
    _ImGui_SetVisible("tab_close", True)
EndFunc

Func _OnPollVisibility()
    Local $bVis = _ImGui_GetVisible("tab_close")
    _ImGui_SetText("t_close_state", "tab_close visible : " & ($bVis ? "True" : "False  (click Restore Closable to bring it back)"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
