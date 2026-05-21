#cs
================================================================================
 Example 159 : _ImGui_CreateTableSetColumnIndex
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateTableSetColumnIndex   Jump to a specific column

 Alternative to CreateTableNextColumn (exemple158) when you want
 sparse / out-of-order cell writes. ImGui auto-fills the skipped
 cells with empty content, so a row that touches only columns 0 and
 3 in a 5-column table will leave columns 1, 2, 4 visually empty.

 Same SIBLING-ORDER rule as TableNextColumn : the SetColumnIndex
 marker must come AFTER the relevant TableNextRow, and BEFORE the
 content widgets for that cell (see Decisions log entry
 "Cells are NOT containers (Tables)").

 Use cases :
   * Sparse data : score table where only some columns are filled
     per row.
   * Custom row layouts : place a wide button in column 1 by jumping
     past column 0.
   * Re-visit a cell : you can SetColumnIndex back to a previous
     column within the same row and append more content.

 Borrowed widgets : Tables basic pattern (exemple158), Button, Text +
 Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple159_table_setcolumnindex.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple159_table_setcolumnindex.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 159 : _ImGui_CreateTableSetColumnIndex", 760, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateTableSetColumnIndex  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateTableSetColumnIndex($sId, $iColumnIndex)
;
;   $iColumnIndex : 0-based ; skipped cells are auto-filled empty.
;
;   Marker placement : sibling of TableNextRow / TableNextColumn at
;   the parent TABLE's children level, BEFORE the content widget(s)
;   it targets. Same as TableNextColumn but jumps to an explicit
;   index instead of advancing by 1.
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "TableSetColumnIndex  --  sparse / out-of-order cell writes in a 5-column table")
_ImGui_CreateText("t_hint",  "Row labels in column 0, score in column 3, no other cells. Skipped cells stay empty.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; 5-column table  --  only columns 0 and 3 are touched
; ==============================================================================
Local $iFlags = BitOR($ImGuiTableFlags_Borders, $ImGuiTableFlags_RowBg)
_ImGui_CreateTable("t", 5, $iFlags, 0, 0, 0)
_ImGui_TableSetupColumn("t", "Name",   $ImGuiTableColumnFlags_WidthStretch, 2.0)
_ImGui_TableSetupColumn("t", "(empty)",$ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_TableSetupColumn("t", "(empty)",$ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_TableSetupColumn("t", "Score",  $ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_TableSetupColumn("t", "(empty)",$ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_CreateTableHeadersRow("t_hdr")
_ImGui_SetParent("t_hdr", "t")

; Data : 4 rows, only columns 0 and 3 written. Columns 1, 2, 4 stay empty.
Local $aData[4][2] = [ _
    ["Alice",   42], _
    ["Bob",     17], _
    ["Charlie", 88], _
    ["Dana",    63]  ]

For $i = 0 To 3
    Local $sRowId = "r" & $i
    _ImGui_CreateTableNextRow($sRowId)
    _ImGui_SetParent($sRowId, "t")

    ; Column 0 -- regular NextColumn (start of row)
    Local $sCol0 = "c" & $i & "_0"
    _ImGui_CreateTableNextColumn($sCol0)
    _ImGui_SetParent($sCol0, "t")
    Local $sTxt0 = "t" & $i & "_0"
    _ImGui_CreateText($sTxt0, $aData[$i][0])
    _ImGui_SetParent($sTxt0, "t")

    ; SKIP columns 1 and 2 -- jump straight to column 3 via SetColumnIndex.
    Local $sCol3 = "c" & $i & "_3"
    _ImGui_CreateTableSetColumnIndex($sCol3, 3)
    _ImGui_SetParent($sCol3, "t")
    Local $sTxt3 = "t" & $i & "_3"
    _ImGui_CreateText($sTxt3, String($aData[$i][1]))
    _ImGui_SetParent($sTxt3, "t")
Next

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Bonus row  --  fill columns OUT OF ORDER (3 then 0 then 4 then 1)
; ==============================================================================
_ImGui_CreateText("t_oo_hdr", "Bonus row  --  same row, columns filled OUT OF ORDER via SetColumnIndex :")

_ImGui_CreateTableNextRow("oo_row")
_ImGui_SetParent("oo_row", "t")

_ImGui_CreateTableSetColumnIndex("oo_c3", 3)
_ImGui_SetParent("oo_c3", "t")
_ImGui_CreateText("oo_t3", "wrote col 3 first")
_ImGui_SetParent("oo_t3", "t")

_ImGui_CreateTableSetColumnIndex("oo_c0", 0)
_ImGui_SetParent("oo_c0", "t")
_ImGui_CreateText("oo_t0", "then col 0")
_ImGui_SetParent("oo_t0", "t")

_ImGui_CreateTableSetColumnIndex("oo_c4", 4)
_ImGui_SetParent("oo_c4", "t")
_ImGui_CreateText("oo_t4", "then col 4")
_ImGui_SetParent("oo_t4", "t")

_ImGui_CreateTableSetColumnIndex("oo_c1", 1)
_ImGui_SetParent("oo_c1", "t")
_ImGui_CreateText("oo_t1", "finally col 1")
_ImGui_SetParent("oo_t1", "t")

_ImGui_CreateSeparator("sep2")
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
