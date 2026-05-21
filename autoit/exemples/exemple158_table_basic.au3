#cs
================================================================================
 Example 158 : Tables  --  the basic 6-export cluster
================================================================================
 Covers 6 exports of imgui_autoit.dll (inseparable cluster -- a table
 without rows / cells is nothing) :

   _ImGui_CreateTable             Table scope (BeginTable)
   _ImGui_TableSetupColumn        Declare one column (label + flags + width)
   _ImGui_CreateTableHeadersRow   Auto-emit a header row from setup labels
   _ImGui_CreateTableHeader       Per-cell custom header (alt to HeadersRow)
   _ImGui_CreateTableNextRow      Advance to a new row (must precede cells)
   _ImGui_CreateTableNextColumn   Advance to next cell (must precede content)

 STRUCTURAL CANONICAL PATTERN (sibling-order at the TABLE level) :

   1. CreateTable (3 cols, Borders + Resizable + RowBg, ...)
   2. TableSetupColumn x N   (BEFORE any row -- order = display order)
   3. (optional TableSetupScrollFreeze -- exemple160)
   4. CreateTableHeadersRow + SetParent(headers, table)
   5. For each row :
        CreateTableNextRow + SetParent(row, table)
        For each cell :
            CreateTableNextColumn + SetParent(cell, table)
            CreateText / CreateButton / ... + SetParent(content, TABLE)
                                                            ^^^^^
   Read that last line again -- it's the trap.

 ============================================================================
   PITFALL : Cells are NOT containers.
 ============================================================================
   Unlike TabItem (exemple131) or Popup (exemple137) where children
   are SetParent'd to the TabItem / Popup, the Tables family is
   FLAT : every marker (NextRow, NextColumn, content widgets) is a
   SIBLING under the parent TABLE's children list.

   Tree order encodes the row/column structure :
     * NextRow marker MUST come before the cells of that row.
     * NextColumn marker MUST come before the content widgets of
       that cell (until the next NextColumn / NextRow).

   This is the same family of "previous-item" / "sibling-order"
   trap as ContextPopup kind=Item, OpenPopupOnItemClick, and
   ItemTooltip (Decisions log entry "Sibling-order-dependent
   markers"). The Tables variant is the most pervasive : EVERY
   cell in EVERY row participates.

 Standard headers vs custom : the t1 demo uses CreateTableHeadersRow
 (one call -- ImGui builds the row from the TableSetupColumn labels).
 The t2 demo overrides this with CreateTableHeader per cell, which
 lets you customize the header layout (e.g. icon + multi-line label).

 Borrowed widgets : Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple158_table_basic.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple158_table_basic.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 158 : Tables basic", 760, 620) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 6-export cluster
; ==============================================================================
; CreateTable($sId, $iColumns, $iFlags, $fOuterW, $fOuterH, $fInnerW)
;   $iFlags : bitmask of $ImGuiTableFlags_*. Common :
;     0x1     = Resizable           drag column edges
;     0x2     = Reorderable         drag column titles to reorder
;     0x4     = Hideable            context menu lets user hide a col
;     0x8     = Sortable            click headers to sort
;     0x40    = RowBg               alternating row backgrounds
;     0x780   = Borders             InnerH | OuterH | InnerV | OuterV
;     0x2000  = SizingFixedFit      columns sized to content
;
; TableSetupColumn($sTableId, $sLabel, $iFlags, $fWidthOrWeight)
;   MUST come AFTER CreateTable and BEFORE any row. $iFlags : useful :
;     0x8     = WidthStretch        weight-based size ($fW = weight)
;     0x10    = WidthFixed          pixel-based size ($fW = pixels)
;     0x4     = DefaultSort         this column is the initial sort
;
; CreateTableHeadersRow($sId)      -- standard header row.
; CreateTableHeader($sId, $sLabel) -- custom per-cell header (see t2).
;
; CreateTableNextRow($sId, $iRowFlags = 0, $fMinHeight = 0)
;   $iRowFlags : 0 = data, 1 = Headers (use with CreateTableHeader).
;
; CreateTableNextColumn($sId)      -- advance to next cell.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "Tables basic  --  standard headers (t1) vs custom per-cell headers (t2)")
_ImGui_CreateText("t_hint",  "Drag column edges to resize. The two tables show the same data with different header styles.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Table 1  --  standard pattern with CreateTableHeadersRow
; ==============================================================================
_ImGui_CreateText("t_t1_hdr", "1) Standard  --  CreateTableHeadersRow auto-emits headers from TableSetupColumn labels")

Local $iT1Flags = BitOR($ImGuiTableFlags_Borders, _
                         $ImGuiTableFlags_Resizable, _
                         $ImGuiTableFlags_RowBg)
_ImGui_CreateTable("t1", 3, $iT1Flags, 0, 0, 0)
_ImGui_TableSetupColumn("t1", "Name",  $ImGuiTableColumnFlags_WidthStretch, 2.0)
_ImGui_TableSetupColumn("t1", "Score", $ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_TableSetupColumn("t1", "Class", $ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_CreateTableHeadersRow("t1_hdr")
_ImGui_SetParent("t1_hdr", "t1")

; Data : 4 rows. NOTE the flat SetParent("t1") on every widget below --
; content widgets are SIBLINGS of the cell markers, NOT children.
Local $aT1[4][3] = [ _
    ["Alice",   42, "Mage"   ], _
    ["Bob",     17, "Warrior"], _
    ["Charlie", 88, "Rogue"  ], _
    ["Dana",    63, "Cleric" ]  ]

For $i = 0 To 3
    Local $sRowId = "t1_r" & $i
    _ImGui_CreateTableNextRow($sRowId)
    _ImGui_SetParent($sRowId, "t1")
    For $col = 0 To 2
        Local $sCellId = "t1_c" & $i & "_" & $col
        _ImGui_CreateTableNextColumn($sCellId)
        _ImGui_SetParent($sCellId, "t1")
        Local $sTxtId = "t1_t" & $i & "_" & $col
        _ImGui_CreateText($sTxtId, String($aT1[$i][$col]))
        _ImGui_SetParent($sTxtId, "t1")
    Next
Next

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Table 2  --  custom headers via CreateTableHeader (per-cell layout)
; ==============================================================================
_ImGui_CreateText("t_t2_hdr", "2) Custom headers  --  CreateTableHeader per cell ; pair with a Headers-flag row")

Local $iT2Flags = BitOR($ImGuiTableFlags_Borders, _
                         $ImGuiTableFlags_Resizable, _
                         $ImGuiTableFlags_RowBg)
_ImGui_CreateTable("t2", 3, $iT2Flags, 0, 0, 0)
; TableSetupColumn labels are still required (used by sort UI / context menu)
; but they won't be shown -- our custom Header below overrides the visual.
_ImGui_TableSetupColumn("t2", "n", $ImGuiTableColumnFlags_WidthStretch, 2.0)
_ImGui_TableSetupColumn("t2", "s", $ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_TableSetupColumn("t2", "c", $ImGuiTableColumnFlags_WidthStretch, 1.0)

; Custom header row -- NextRow with the Headers flag, then per-cell Header.
_ImGui_CreateTableNextRow("t2_hdr_row", $ImGuiTableRowFlags_Headers)
_ImGui_SetParent("t2_hdr_row", "t2")
_ImGui_CreateTableNextColumn("t2_hdr_c0")
_ImGui_SetParent("t2_hdr_c0", "t2")
_ImGui_CreateTableHeader("t2_h0", "PLAYER NAME")
_ImGui_SetParent("t2_h0", "t2")
_ImGui_CreateTableNextColumn("t2_hdr_c1")
_ImGui_SetParent("t2_hdr_c1", "t2")
_ImGui_CreateTableHeader("t2_h1", "SCORE PTS")
_ImGui_SetParent("t2_h1", "t2")
_ImGui_CreateTableNextColumn("t2_hdr_c2")
_ImGui_SetParent("t2_hdr_c2", "t2")
_ImGui_CreateTableHeader("t2_h2", "CLASS")
_ImGui_SetParent("t2_h2", "t2")

; Same data rows as t1.
For $i = 0 To 3
    Local $sRowId = "t2_r" & $i
    _ImGui_CreateTableNextRow($sRowId)
    _ImGui_SetParent($sRowId, "t2")
    For $col = 0 To 2
        Local $sCellId = "t2_c" & $i & "_" & $col
        _ImGui_CreateTableNextColumn($sCellId)
        _ImGui_SetParent($sCellId, "t2")
        Local $sTxtId = "t2_t" & $i & "_" & $col
        _ImGui_CreateText($sTxtId, String($aT1[$i][$col]))
        _ImGui_SetParent($sTxtId, "t2")
    Next
Next

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
