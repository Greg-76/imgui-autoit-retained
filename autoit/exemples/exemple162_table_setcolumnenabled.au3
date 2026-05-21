#cs
================================================================================
 Example 162 : _ImGui_TableSetColumnEnabled
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_TableSetColumnEnabled   Toggle a column's visibility at runtime

 Tied to the $ImGuiTableFlags_Hideable flag : when set, ImGui adds a
 context menu (right-click any header) that lets the USER hide /
 show columns. TableSetColumnEnabled gives the SCRIPT the same
 control programmatically.

 Behavior :
   * The toggle is QUEUED -- applied at the next BeginTable() scope.
   * Successive toggles on the same column coalesce (only the latest
     value matters when the table re-enters).
   * Hidden columns still receive NextColumn / content widgets in the
     tree -- ImGui simply skips rendering them.

 Combine with $ImGuiTableColumnFlags_NoHide on specific columns if
 you want to prevent the user-side context menu from hiding them
 (e.g. a primary key column that must always stay visible).

 Borrowed widgets : Tables basic pattern (exemple158), Checkbox,
 Button, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple162_table_setcolumnenabled.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple162_table_setcolumnenabled.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 162 : _ImGui_TableSetColumnEnabled", 740, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_TableSetColumnEnabled  --  doc block
; ==============================================================================
; Signature : _ImGui_TableSetColumnEnabled($sTableId, $iColumn, $bEnabled)
;
;   $iColumn  : 0-based column index. Out-of-range returns @error = 3
;               (@extended = 3 from the DLL).
;
;   $bEnabled : True  = show the column
;               False = hide the column (skipped at render time)
;
;   Requires the table to carry $ImGuiTableFlags_Hideable for the
;   user-side context menu to be drawn. The PROGRAMMATIC call works
;   regardless of the flag -- the flag only controls the right-click
;   menu the user sees.
;
;   Return : True on success, False on failure (@error = 1, 2, 3).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "TableSetColumnEnabled  --  Hideable table + per-column checkboxes")
_ImGui_CreateText("t_hint",  "Uncheck a column to hide it ; right-click any header for the user-side menu.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; The Hideable table  --  5 columns
; ==============================================================================
Local $iFlags = BitOR($ImGuiTableFlags_Borders, _
                      $ImGuiTableFlags_Resizable, _
                      $ImGuiTableFlags_RowBg, _
                      $ImGuiTableFlags_Hideable)
_ImGui_CreateTable("t", 5, $iFlags, 0, 0, 0)
; First column gets NoHide -- user CANNOT dismiss it via the context menu
; (but the script still can, via SetColumnEnabled below).
_ImGui_TableSetupColumn("t", "Name (NoHide)", BitOR($ImGuiTableColumnFlags_WidthStretch, $ImGuiTableColumnFlags_NoHide), 2.0)
_ImGui_TableSetupColumn("t", "Score",  $ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_TableSetupColumn("t", "Class",  $ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_TableSetupColumn("t", "Level",  $ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_TableSetupColumn("t", "Notes",  $ImGuiTableColumnFlags_WidthStretch, 1.5)
_ImGui_CreateTableHeadersRow("t_hdr")
_ImGui_SetParent("t_hdr", "t")

Local $aData[5][5] = [ _
    ["Alice",   42, "Mage",    12, "fire spells"   ], _
    ["Bob",     17, "Warrior",  3, "two-handed axe"], _
    ["Charlie", 88, "Rogue",   25, "stealth +20"   ], _
    ["Dana",    63, "Cleric",  18, "heals 5d6 hp"  ], _
    ["Eve",     29, "Mage",    11, "frost +12 dmg" ]  ]

For $i = 0 To 4
    Local $sRowId = "t_r" & $i
    _ImGui_CreateTableNextRow($sRowId)
    _ImGui_SetParent($sRowId, "t")
    For $col = 0 To 4
        Local $sCellId = "t_c" & $i & "_" & $col
        _ImGui_CreateTableNextColumn($sCellId)
        _ImGui_SetParent($sCellId, "t")
        Local $sTxtId = "t_t" & $i & "_" & $col
        _ImGui_CreateText($sTxtId, String($aData[$i][$col]))
        _ImGui_SetParent($sTxtId, "t")
    Next
Next

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Per-column checkboxes (programmatic toggle)
; ==============================================================================
_ImGui_CreateText("t_ctrl_hdr", "Script-side toggles (also work on NoHide column 0) :")
_ImGui_CreateCheckbox("cb_c0", "Show column 0  --  Name (user-side menu hides it = no, scripts = yes)", True)
_ImGui_CreateCheckbox("cb_c1", "Show column 1  --  Score", True)
_ImGui_CreateCheckbox("cb_c2", "Show column 2  --  Class", True)
_ImGui_CreateCheckbox("cb_c3", "Show column 3  --  Level", True)
_ImGui_CreateCheckbox("cb_c4", "Show column 4  --  Notes", True)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("cb_c0", "_OnToggleC0")
_ImGui_SetOnChange("cb_c1", "_OnToggleC1")
_ImGui_SetOnChange("cb_c2", "_OnToggleC2")
_ImGui_SetOnChange("cb_c3", "_OnToggleC3")
_ImGui_SetOnChange("cb_c4", "_OnToggleC4")
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnToggleC0($sId)
    _ImGui_TableSetColumnEnabled("t", 0, _ImGui_GetValueBool($sId))
EndFunc

Func _OnToggleC1($sId)
    _ImGui_TableSetColumnEnabled("t", 1, _ImGui_GetValueBool($sId))
EndFunc

Func _OnToggleC2($sId)
    _ImGui_TableSetColumnEnabled("t", 2, _ImGui_GetValueBool($sId))
EndFunc

Func _OnToggleC3($sId)
    _ImGui_TableSetColumnEnabled("t", 3, _ImGui_GetValueBool($sId))
EndFunc

Func _OnToggleC4($sId)
    _ImGui_TableSetColumnEnabled("t", 4, _ImGui_GetValueBool($sId))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
