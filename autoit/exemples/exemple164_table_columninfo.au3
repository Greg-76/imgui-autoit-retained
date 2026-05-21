#cs
================================================================================
 Example 164 : Table column info (5-export cluster)
================================================================================
 Covers 5 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_TableGetColumnCount         frame-constant column count of a table
   _ImGui_CreateTableGetColumnInfo    marker that latches per-column info
                                      (index, flags, name)
   _ImGui_GetTableColumnIndex         readback : the latched col index (>=0)
   _ImGui_GetTableColumnFlags         readback : the latched ImGuiTableColumnFlags_ mask
   _ImGui_GetTableColumnName          readback : the latched column name

 Two complementary read paths :
   * COUNT : TableGetColumnCount is a direct getter on the table id --
             no marker needed, no row scope needed. Returns the
             latched count.
   * PER-COLUMN INFO : CreateTableGetColumnInfo is a MARKER placed
                       inside the table (after the relevant
                       TableNextColumn / TableSetColumnIndex marker).
                       It latches the current column's metadata at
                       render time ; readback via the three Get*
                       calls keyed on the marker id.

 $iColumnN on CreateTableGetColumnInfo :
   * -1   = use the current cursor column.
   * >= 0 = query that explicit column index, regardless of where the
            cursor is in the row.

 Demo : one column-info marker per column, all reading at "fixed
 explicit index" so the readout is stable. The UI displays the count
 plus a (index, flags hex, name) row for each.

 Borrowed widgets : Tables basic pattern (exemple158), Text +
 Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple164_table_columninfo.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple164_table_columninfo.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 164 : Table column info", 780, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 5-export cluster
; ==============================================================================
; TableGetColumnCount($sTableId)  -> int >= 0 (frame-constant)
;
; CreateTableGetColumnInfo($sId, $iColumnN = -1)
;   Marker. Place inside the table ; reads back via Get*.
;
; GetTableColumnIndex($sMarkerId)  -> int >= 0 (or -1 outside scope)
; GetTableColumnFlags($sMarkerId)  -> bitmask of $ImGuiTableColumnFlags_*
; GetTableColumnName($sMarkerId, $iBufSize = 64)  -> string


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "Tables column info  --  GetColumnCount + per-column metadata via markers")
_ImGui_CreateText("t_hint",  "All readouts polled at 100ms. The table has 4 columns with distinct flag combos.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; The table  --  4 columns with diverse flags so the readout varies
; ==============================================================================
Local $iTblFlags = BitOR($ImGuiTableFlags_Borders, _
                          $ImGuiTableFlags_Resizable, _
                          $ImGuiTableFlags_RowBg, _
                          $ImGuiTableFlags_Hideable, _
                          $ImGuiTableFlags_Sortable)
_ImGui_CreateTable("t", 4, $iTblFlags, 0, 0, 0)
_ImGui_TableSetupColumn("t", "Id",     $ImGuiTableColumnFlags_WidthFixed, 60.0)
_ImGui_TableSetupColumn("t", "Name",   BitOR($ImGuiTableColumnFlags_WidthStretch, $ImGuiTableColumnFlags_NoHide), 2.0)
_ImGui_TableSetupColumn("t", "Score",  BitOR($ImGuiTableColumnFlags_WidthStretch, $ImGuiTableColumnFlags_DefaultSort), 1.0)
_ImGui_TableSetupColumn("t", "Notes",  $ImGuiTableColumnFlags_WidthStretch, 2.0)
_ImGui_CreateTableHeadersRow("t_hdr")
_ImGui_SetParent("t_hdr", "t")

; A few data rows so the table is not empty
Local $aData[3][4] = [ _
    [1, "Alice",   42, "fire"  ], _
    [2, "Bob",     17, "axe"   ], _
    [3, "Charlie", 88, "stealth"]]

For $i = 0 To 2
    Local $sRow = "r" & $i
    _ImGui_CreateTableNextRow($sRow)
    _ImGui_SetParent($sRow, "t")
    For $col = 0 To 3
        Local $sCell = "c" & $i & "_" & $col
        _ImGui_CreateTableNextColumn($sCell)
        _ImGui_SetParent($sCell, "t")
        Local $sTxt = "x" & $i & "_" & $col
        _ImGui_CreateText($sTxt, String($aData[$i][$col]))
        _ImGui_SetParent($sTxt, "t")
    Next

    ; Once per row : place the column-info markers AFTER the data cells.
    ; Each marker uses an EXPLICIT column index ($iColumnN >= 0) so it
    ; latches a stable column regardless of cursor position. We only
    ; need them on row 0 ; placing them on every row would be wasteful
    ; but harmless.
    If $i = 0 Then
        For $col = 0 To 3
            Local $sInfo = "info_" & $col
            _ImGui_CreateTableGetColumnInfo($sInfo, $col)
            _ImGui_SetParent($sInfo, "t")
        Next
    EndIf
Next

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Live readouts
; ==============================================================================
_ImGui_CreateText("t_count", "TableGetColumnCount('t') = 0")
_ImGui_CreateText("t_c0",    "  col 0 : index=?  flags=0x?  name='?'")
_ImGui_CreateText("t_c1",    "  col 1 : index=?  flags=0x?  name='?'")
_ImGui_CreateText("t_c2",    "  col 2 : index=?  flags=0x?  name='?'")
_ImGui_CreateText("t_c3",    "  col 3 : index=?  flags=0x?  name='?'")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPollInfo", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollInfo()
    _ImGui_SetText("t_count", "TableGetColumnCount('t') = " & _ImGui_TableGetColumnCount("t"))
    For $col = 0 To 3
        Local $sMarker = "info_" & $col
        Local $iIdx   = _ImGui_GetTableColumnIndex($sMarker)
        Local $iFlags = _ImGui_GetTableColumnFlags($sMarker)
        Local $sName  = _ImGui_GetTableColumnName($sMarker)
        _ImGui_SetText("t_c" & $col, StringFormat("  col %d : index=%d  flags=0x%05X  name='%s'", _
            $col, $iIdx, $iFlags, $sName))
    Next
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
