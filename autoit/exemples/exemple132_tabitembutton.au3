#cs
================================================================================
 Example 132 : _ImGui_CreateTabItemButton
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateTabItemButton   Inline clickable tab (no body, no sticky
                                selected state)

 Visually sits in the TabBar strip alongside regular TabItems, but :
   * No body  -- cannot be reparented as a container ; children go
                 nowhere.
   * No selected state -- clicking it raises a one-shot click event
                          without changing which tab is the "current"
                          one.

 ClickableWidget : latches Widget::clicked. Bind _ImGui_SetOnClick
 (NOT SetOnChange). Same gotcha class as ColorButton / RadioButton --
 visually a tab, semantically a button. See the "Widget event mapping"
 table in NOTES.md.

 Two pinning flags exercised here :
   $ImGuiTabItemFlags_Leading  (64)  -- pin to the bar's left  side
   $ImGuiTabItemFlags_Trailing (128) -- pin to the bar's right side

 Typical patterns :
   * Leading  -- inline menu button ("Menu", hamburger, ...)
   * Trailing -- "+ add new tab" button at the far right

 Borrowed widgets : TabBar (exemple130), TabItem (exemple131), Text +
 Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple132_tabitembutton.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple132_tabitembutton.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 132 : _ImGui_CreateTabItemButton", 720, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateTabItemButton  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateTabItemButton($sId, $sLabel = "", $iFlags = 0)
;
;   $sLabel    : the glyph or short text drawn in the tab strip
;                ("Menu", "+", ...). Kept short -- ImGui draws it as
;                a tab title slot.
;
;   $iFlags    : bitmask of $ImGuiTabItemFlags_*. Most useful for this
;                widget :
;       64   = Leading   -- pin to the bar's left
;       128  = Trailing  -- pin to the bar's right
;       16   = NoTooltip
;
;   Event model :
;     ClickableWidget under the hood -- latches Widget::clicked.
;     Bind _ImGui_SetOnClick($sId, ...). _ImGui_WasClicked also works.
;     SetOnChange is NOT meaningful here (no value, no Widget::changed).
;
;   NOT a container : reparenting children under a TabItemButton is a
;   silent no-op. The widget renders only its own title slot.
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded,
;            2=DllCall failed).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateTabItemButton demo  --  Leading 'Menu' and Trailing '+' inline buttons")
_ImGui_CreateText("t_hint",  "Click 'Menu' (pinned left) to toggle the menu state. Click '+' (pinned right) to bump the counter.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; TabBar  --  regular tabs + two TabItemButtons (Leading + Trailing)
; ==============================================================================
Local $iBarFlags = BitOR($ImGuiTabBarFlags_Reorderable, $ImGuiTabBarFlags_DrawSelectedOverline)
_ImGui_CreateTabBar("tabs", "", $iBarFlags)

; Regular TabItems  --  filler for the bar so the pinned buttons stand out.
_ImGui_CreateTabItem("tab_a", "Stats")
_ImGui_CreateTabItem("tab_b", "Logs")
_ImGui_CreateTabItem("tab_c", "About")
_ImGui_SetParent("tab_a", "tabs")
_ImGui_SetParent("tab_b", "tabs")
_ImGui_SetParent("tab_c", "tabs")
_ImGui_CreateText("ta_body", "  Stats tab body.")
_ImGui_CreateText("tb_body", "  Logs tab body.")
_ImGui_CreateText("tc_body", "  About tab body.")
_ImGui_SetParent("ta_body", "tab_a")
_ImGui_SetParent("tb_body", "tab_b")
_ImGui_SetParent("tc_body", "tab_c")

; Leading inline button  --  pinned to the bar's LEFT, ASCII label kept safe
; (no Unicode glyph) to avoid cp1252/UTF-8 round-trip surprises on Windows.
_ImGui_CreateTabItemButton("tib_menu", "Menu", $ImGuiTabItemFlags_Leading)
_ImGui_SetParent("tib_menu", "tabs")

; Trailing inline button  --  pinned to the bar's RIGHT, classic "+ add new"
_ImGui_CreateTabItemButton("tib_plus", "+", $ImGuiTabItemFlags_Trailing)
_ImGui_SetParent("tib_plus", "tabs")


; ==============================================================================
; Host footer  --  click counters + Quit
; ==============================================================================
_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_menu_state",  "Menu button state : closed")
_ImGui_CreateText("t_plus_count",  "'+' button clicks  : 0")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters (script-scope so handlers can mutate them) --------------------
Global $g_bMenuOpen   = False
Global $g_iPlusClicks = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("tib_menu", "_OnMenuClick")
_ImGui_SetOnClick("tib_plus", "_OnPlusClick")
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnMenuClick($sId)
    $g_bMenuOpen = Not $g_bMenuOpen
    _ImGui_SetText("t_menu_state", "Menu button state : " & ($g_bMenuOpen ? "OPEN" : "closed"))
EndFunc

Func _OnPlusClick($sId)
    $g_iPlusClicks += 1
    _ImGui_SetText("t_plus_count", "'+' button clicks  : " & $g_iPlusClicks)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
