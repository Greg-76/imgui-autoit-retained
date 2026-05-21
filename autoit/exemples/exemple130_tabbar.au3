#cs
================================================================================
 Example 130 : _ImGui_CreateTabBar
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateTabBar   Create a TabBar container (host for TabItems)

 STRUCTURAL MARKER -- same family-wide rule as MenuBar (exemple126) :
 a TabBar has no standalone visual ; it opens an ImGui::BeginTabBar()
 scope and only draws something when at least one TabItem (or
 TabItemButton) child has been reparented into it. A TabItem
 reparented outside a TabBar is silently dropped at render time.

 The TabBar itself accepts flags that govern its global behavior :
 reorderable, auto-select-new-tabs, overline highlight, fitting
 policy, ... The flags are creation-time constants (cannot be flipped
 at runtime).

 This file shows THREE TabBars stacked vertically, each with a
 different flag combination so the user can compare side by side :

   bar_def     - default (no flags)               -- baseline
   bar_full    - Reorderable + AutoSelectNewTabs
                 + DrawSelectedOverline           -- "full-featured"
   bar_shrink  - FittingPolicyShrink              -- narrow bar shrinks
                                                     tabs instead of
                                                     scrolling

 Borrowed widgets : TabItem (exemple131), Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple130_tabbar.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple130_tabbar.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 130 : _ImGui_CreateTabBar", 720, 560) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateTabBar  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateTabBar($sId, $sLabel = "", $iFlags = 0)
;
;   Pure structural marker : opens an ImGui::BeginTabBar() scope.
;   No event flags of its own (clicks happen on TabItem / TabItemButton
;   children), no value, no getter / setter for the bar itself.
;
;   $sLabel    : kept for API uniformity ; current ImGui builds do not
;                draw a label for the bar.
;
;   $iFlags    : bitmask of $ImGuiTabBarFlags_*. Useful values :
;       0    = None                  -- baseline
;       1    = Reorderable           -- drag tabs to reorder
;       2    = AutoSelectNewTabs     -- selects newly-added tabs
;       4    = TabListPopupButton    -- chevron popup with all tabs
;       8    = NoCloseWithMiddleMouseButton
;       16   = NoTabListScrollingButtons
;       32   = NoTooltip
;       64   = DrawSelectedOverline  -- highlight under selected tab
;       128  = FittingPolicyMixed    -- DEFAULT (shrink then scroll)
;       256  = FittingPolicyShrink   -- shrink only (no scroll)
;       512  = FittingPolicyScroll   -- scroll only (no shrink)
;
;   Children : TabItem (exemple131) and TabItemButton (exemple132).
;              Reparent each one with _ImGui_SetParent($sChild, $sBar).
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded,
;            2=DllCall failed).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateTabBar demo  --  three bars with different flags")
_ImGui_CreateText("t_hint",  "Try dragging tabs in the second bar (Reorderable). Narrow the window to see the third bar shrink.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Bar 1  --  default flags (baseline)
; ==============================================================================
_ImGui_CreateText("t_def_hdr", "1) Default flags  --  tabs are clickable but not reorderable :")
_ImGui_CreateTabBar("bar_def", "", 0)
_ImGui_CreateTabItem("def_a", "Alpha")
_ImGui_CreateTabItem("def_b", "Beta")
_ImGui_CreateTabItem("def_c", "Gamma")
_ImGui_SetParent("def_a", "bar_def")
_ImGui_SetParent("def_b", "bar_def")
_ImGui_SetParent("def_c", "bar_def")
_ImGui_CreateText("def_a_body", "  Alpha tab body.")
_ImGui_CreateText("def_b_body", "  Beta  tab body.")
_ImGui_CreateText("def_c_body", "  Gamma tab body.")
_ImGui_SetParent("def_a_body", "def_a")
_ImGui_SetParent("def_b_body", "def_b")
_ImGui_SetParent("def_c_body", "def_c")

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Bar 2  --  Reorderable + AutoSelectNewTabs + DrawSelectedOverline
; ==============================================================================
_ImGui_CreateText("t_full_hdr", "2) Reorderable + AutoSelectNewTabs + DrawSelectedOverline  --  drag titles to reorder :")
Local $iFullFlags = BitOR( _
    $ImGuiTabBarFlags_Reorderable, _
    $ImGuiTabBarFlags_AutoSelectNewTabs, _
    $ImGuiTabBarFlags_DrawSelectedOverline)
_ImGui_CreateTabBar("bar_full", "", $iFullFlags)
_ImGui_CreateTabItem("full_a", "Reorder me")
_ImGui_CreateTabItem("full_b", "Drag titles")
_ImGui_CreateTabItem("full_c", "Note overline")
_ImGui_SetParent("full_a", "bar_full")
_ImGui_SetParent("full_b", "bar_full")
_ImGui_SetParent("full_c", "bar_full")
_ImGui_CreateText("full_a_body", "  Click-and-drag this tab's title onto another to swap order.")
_ImGui_CreateText("full_b_body", "  Same here -- the bar tracks the drag and reorders.")
_ImGui_CreateText("full_c_body", "  A thin overline highlights the currently selected tab.")
_ImGui_SetParent("full_a_body", "full_a")
_ImGui_SetParent("full_b_body", "full_b")
_ImGui_SetParent("full_c_body", "full_c")

_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Bar 3  --  FittingPolicyShrink (narrow the window to see)
; ==============================================================================
_ImGui_CreateText("t_shrink_hdr", "3) FittingPolicyShrink  --  resize the window to see tabs shrink rather than scroll :")
_ImGui_CreateTabBar("bar_shrink", "", $ImGuiTabBarFlags_FittingPolicyShrink)
_ImGui_CreateTabItem("shr_a", "First tab with a long title")
_ImGui_CreateTabItem("shr_b", "Second tab with a long title")
_ImGui_CreateTabItem("shr_c", "Third tab with a long title")
_ImGui_CreateTabItem("shr_d", "Fourth tab with a long title")
_ImGui_SetParent("shr_a", "bar_shrink")
_ImGui_SetParent("shr_b", "bar_shrink")
_ImGui_SetParent("shr_c", "bar_shrink")
_ImGui_SetParent("shr_d", "bar_shrink")
_ImGui_CreateText("shr_a_body", "  Narrow the host window -- watch all four titles shrink instead of overflowing.")
_ImGui_SetParent("shr_a_body", "shr_a")
_ImGui_CreateText("shr_b_body", "  Second body.")
_ImGui_SetParent("shr_b_body", "shr_b")
_ImGui_CreateText("shr_c_body", "  Third body.")
_ImGui_SetParent("shr_c_body", "shr_c")
_ImGui_CreateText("shr_d_body", "  Fourth body.")
_ImGui_SetParent("shr_d_body", "shr_d")

_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
