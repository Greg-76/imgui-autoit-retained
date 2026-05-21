#cs
================================================================================
 Example 15 : _ImGui_CreateSelectable
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateSelectable    Persistent on/off row, like a list item
   _ImGui_GetValueBool        Read its selected state
   _ImGui_SetValueBool        Set its selected state programmatically

 Selectable is a clickable full-width row that latches its selected state.
 Unlike a Button (one-shot click) or Checkbox (left-side toggle square),
 a Selectable highlights the ENTIRE row when active.

 With the AllowDoubleClick flag, the wrapper also exposes a third event
 latch (_ImGui_WasDoubleClicked / _ImGui_SetOnDoubleClick) that fires only
 on detected double-clicks. Detection happens on the render thread at the
 exact frame of the press, so it is reliable regardless of polling speed.

 Click semantics (OnClick, ID uniqueness) : see exemple5_button.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple15_selectable.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple15_selectable.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 15 : _ImGui_CreateSelectable", 640, 440) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSelectable  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSelectable($sId, $sLabel = "", $bDefault = False,
;                                      $iFlags = 0, $fW = 0, $fH = 0)
;
;   Renders a clickable line that fills the available width (or $fW/$fH if
;   given). Toggling preserves its boolean state across frames -- read it
;   via _ImGui_GetValueBool.
;
;   $iFlags is a bit-OR of $ImGuiSelectableFlags_* constants. Useful values :
;
;     $ImGuiSelectableFlags_None              = 0    default
;     $ImGuiSelectableFlags_AllowDoubleClick  = 4    ALSO fires on double-click
;     $ImGuiSelectableFlags_Disabled          = 8    grayed, no click
;     $ImGuiSelectableFlags_Highlight         = 32   always rendered as hovered
;     $ImGuiSelectableFlags_NoAutoClosePopups = 1    keeps parent popup open
;     $ImGuiSelectableFlags_SpanAllColumns    = 2    span every column in a Table
;     $ImGuiSelectableFlags_AllowOverlap      = 16   tolerate overlapping widgets
;     $ImGuiSelectableFlags_SelectOnNav       = 64   keyboard nav also selects
;
;   AllowDoubleClick is misleadingly named in ImGui itself : the flag makes
;   the widget fire on a single click (default) AND ADDITIONALLY on a
;   detected double-click. Each ImGui-level click toggles the bool.
;
;   The wrapper provides a clean way to react ONLY to double-clicks :
;   bind _ImGui_SetOnDoubleClick to the widget. The double-click flag is
;   latched on the render thread the exact frame ImGui sees the second
;   click, so the AutoIt-side polling cadence cannot miss it.
;
;   Triple event latching :
;     * OnClick       fires when the row is clicked (any click).
;     * OnChange      fires when the selected state flips.
;     * OnDoubleClick fires only when the second click of a double-click
;                     burst is detected (requires AllowDoubleClick flag).


; ==============================================================================
; Demo widgets  --  one Selectable per flag variant (None / AllowDoubleClick /
;                   Disabled / Highlight)
; ==============================================================================
_ImGui_CreateText("t_title", "Selectable demo  --  one widget per flag variant")
_ImGui_CreateText("t_hint",  "Click rows to toggle selection. The DoubleClick row reacts ONLY to double-clicks.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateSelectable("sel_plain", "Plain Selectable (no flags)",                                  False, $ImGuiSelectableFlags_None)
_ImGui_CreateSelectable("sel_dbl",   "AllowDoubleClick (4)  -- DoubleClick handler updates counter", False, $ImGuiSelectableFlags_AllowDoubleClick)
_ImGui_CreateSelectable("sel_dis",   "Disabled (8)  -- grayed and unclickable",                      False, $ImGuiSelectableFlags_Disabled)
_ImGui_CreateSelectable("sel_hl",    "Highlight (32)  -- permanently rendered as hover",             False, $ImGuiSelectableFlags_Highlight)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_state_plain", "Plain        : False")
_ImGui_CreateText("t_state_dbl",   "DoubleClick  : 0 detected double-clicks")
_ImGui_CreateText("t_state_hl",    "Highlight    : False")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iDblCount = 0


; --- Bind --------------------------------------------------------------------
; Plain + Highlight : OnChange for normal selection tracking.
_ImGui_SetOnChange("sel_plain", "_OnPlainToggled")
_ImGui_SetOnChange("sel_hl",    "_OnHighlightToggled")

; sel_dbl : OnDoubleClick fires ONLY on detected double-clicks ; the
; underlying state still toggles on every click (ImGui native behaviour
; with AllowDoubleClick), we just don't observe it here.
_ImGui_SetOnDoubleClick("sel_dbl", "_OnDoubleClicked")

_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPlainToggled($sId)
    Local $bNew = _ImGui_GetValueBool($sId)
    _ImGui_SetText("t_state_plain", "Plain        : " & ($bNew ? "True " : "False"))
EndFunc

; Fired only when ImGui detected a double-click on this widget. Reliable
; because the render thread latched the flag at the press frame.
Func _OnDoubleClicked($sId)
    $g_iDblCount += 1
    _ImGui_SetText("t_state_dbl", "DoubleClick  : " & $g_iDblCount & " detected double-click" & ($g_iDblCount = 1 ? "" : "s"))
EndFunc

Func _OnHighlightToggled($sId)
    Local $bNew = _ImGui_GetValueBool($sId)
    _ImGui_SetText("t_state_hl",    "Highlight    : " & ($bNew ? "True " : "False"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
