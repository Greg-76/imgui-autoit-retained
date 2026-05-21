#cs
================================================================================
 Example 160 : _ImGui_TableSetupScrollFreeze
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_TableSetupScrollFreeze   Lock leading columns + rows during
                                   ScrollX / ScrollY

 Sets the count of LEADING columns and LEADING rows that stay
 visible while the user scrolls a tall / wide table. Set ONCE after
 CreateTable -- sticky for the lifetime of the table.

 Requires the table to carry $ImGuiTableFlags_ScrollY (for vertical
 row freezing) and/or $ImGuiTableFlags_ScrollX (for horizontal
 column freezing). Without these flags the table doesn't scroll and
 ScrollFreeze is a no-op.

 The frozen rows + columns get a distinct visual style (typically a
 darker background) so the user can see what is locked.

 Two demos side by side :
   * t1 : ScrollY + freeze 1 row (the header)  --  classic
   * t2 : ScrollX + ScrollY + freeze 1 row + 1 col  --  spreadsheet-
                                                       style frozen
                                                       header + name
                                                       column

 Borrowed widgets : Tables basic pattern (exemple158).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple160_table_scrollfreeze.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple160_table_scrollfreeze.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 160 : _ImGui_TableSetupScrollFreeze", 820, 720) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_TableSetupScrollFreeze  --  doc block
; ==============================================================================
; Signature : _ImGui_TableSetupScrollFreeze($sTableId, $iCols, $iRows)
;
;   $iCols : count of LEADING columns to lock during ScrollX (>=0).
;   $iRows : count of LEADING rows to lock during ScrollY (>=0).
;
;   Call ONCE after CreateTable, BEFORE any row marker. Sticky.
;
;   Requires :
;     * $iCols > 0  -> table needs $ImGuiTableFlags_ScrollX
;     * $iRows > 0  -> table needs $ImGuiTableFlags_ScrollY
;   Without the matching flag the freeze is silently ignored.
;
;   Return : True on success, False on failure (@error = 1, 2, 3).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "TableSetupScrollFreeze  --  freeze leading rows / cols across ScrollX / ScrollY")
_ImGui_CreateText("t_hint",  "Scroll inside each table : frozen sections stay anchored. Outer height is fixed via CreateTable's $fOuterH.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Table 1  --  ScrollY + freeze the 1 header row
; ==============================================================================
_ImGui_CreateText("t_t1_hdr", "1) ScrollY + freeze 1 row  --  header stays visible while data scrolls")

Local $iT1Flags = BitOR($ImGuiTableFlags_Borders, _
                         $ImGuiTableFlags_Resizable, _
                         $ImGuiTableFlags_RowBg, _
                         $ImGuiTableFlags_ScrollY)
_ImGui_CreateTable("t1", 3, $iT1Flags, 0, 220, 0)   ; $fOuterH = 220 px (fixed)
_ImGui_TableSetupColumn("t1", "Idx",    $ImGuiTableColumnFlags_WidthFixed, 60.0)
_ImGui_TableSetupColumn("t1", "Hex",    $ImGuiTableColumnFlags_WidthFixed, 80.0)
_ImGui_TableSetupColumn("t1", "Square", $ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_TableSetupScrollFreeze("t1", 0, 1)   ; freeze 0 cols, 1 row
_ImGui_CreateTableHeadersRow("t1_hdr")
_ImGui_SetParent("t1_hdr", "t1")

For $i = 0 To 39
    Local $sRow = "t1_r" & $i
    _ImGui_CreateTableNextRow($sRow)
    _ImGui_SetParent($sRow, "t1")
    Local $sC0 = "t1_c" & $i & "_0", $sC1 = "t1_c" & $i & "_1", $sC2 = "t1_c" & $i & "_2"
    _ImGui_CreateTableNextColumn($sC0)
    _ImGui_SetParent($sC0, "t1")
    _ImGui_CreateText("t1_t" & $i & "_0", $i)
    _ImGui_SetParent("t1_t" & $i & "_0", "t1")
    _ImGui_CreateTableNextColumn($sC1)
    _ImGui_SetParent($sC1, "t1")
    _ImGui_CreateText("t1_t" & $i & "_1", "0x" & Hex($i, 2))
    _ImGui_SetParent("t1_t" & $i & "_1", "t1")
    _ImGui_CreateTableNextColumn($sC2)
    _ImGui_SetParent($sC2, "t1")
    _ImGui_CreateText("t1_t" & $i & "_2", $i * $i)
    _ImGui_SetParent("t1_t" & $i & "_2", "t1")
Next

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Table 2  --  ScrollX + ScrollY + freeze 1 row + 1 col  (spreadsheet style)
; ==============================================================================
_ImGui_CreateText("t_t2_hdr", "2) ScrollX + ScrollY + freeze 1 row + 1 col  --  spreadsheet style")

Local $iT2Flags = BitOR($ImGuiTableFlags_Borders, _
                         $ImGuiTableFlags_Resizable, _
                         $ImGuiTableFlags_RowBg, _
                         $ImGuiTableFlags_ScrollX, _
                         $ImGuiTableFlags_ScrollY)
_ImGui_CreateTable("t2", 6, $iT2Flags, 0, 220, 0)
; First column = "Name" (frozen). Others = "Q1" .. "Q5".
_ImGui_TableSetupColumn("t2", "Name", $ImGuiTableColumnFlags_WidthFixed, 100.0)
_ImGui_TableSetupColumn("t2", "Q1",   $ImGuiTableColumnFlags_WidthFixed, 100.0)
_ImGui_TableSetupColumn("t2", "Q2",   $ImGuiTableColumnFlags_WidthFixed, 100.0)
_ImGui_TableSetupColumn("t2", "Q3",   $ImGuiTableColumnFlags_WidthFixed, 100.0)
_ImGui_TableSetupColumn("t2", "Q4",   $ImGuiTableColumnFlags_WidthFixed, 100.0)
_ImGui_TableSetupColumn("t2", "Q5",   $ImGuiTableColumnFlags_WidthFixed, 100.0)
_ImGui_TableSetupScrollFreeze("t2", 1, 1)   ; freeze 1 col, 1 row
_ImGui_CreateTableHeadersRow("t2_hdr")
_ImGui_SetParent("t2_hdr", "t2")

Local $aNames[20]
For $i = 0 To 19
    $aNames[$i] = "Employee #" & ($i + 1)
Next

For $i = 0 To 19
    Local $sRow = "t2_r" & $i
    _ImGui_CreateTableNextRow($sRow)
    _ImGui_SetParent($sRow, "t2")
    For $col = 0 To 5
        Local $sCell = "t2_c" & $i & "_" & $col
        _ImGui_CreateTableNextColumn($sCell)
        _ImGui_SetParent($sCell, "t2")
        Local $sTxt = "t2_t" & $i & "_" & $col
        If $col = 0 Then
            _ImGui_CreateText($sTxt, $aNames[$i])
        Else
            _ImGui_CreateText($sTxt, ($i + 1) * $col * 137)
        EndIf
        _ImGui_SetParent($sTxt, "t2")
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
