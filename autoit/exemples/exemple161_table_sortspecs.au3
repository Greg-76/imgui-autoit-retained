#cs
================================================================================
 Example 161 : Sort specs  --  Get + GetN (2-cluster)
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_TableGetSortSpecs    Read the active SINGLE-column sort spec
                               array[2] = (col_index, direction)
   _ImGui_TableGetSortSpecsN   Read the FULL multi-column sort spec
                               2D array[N][2] in priority order

 ImGui only provides the spec -- the script is responsible for
 actually sorting the data and refreshing the displayed cells (set
 widget texts each frame the sort changes). The canonical pattern is
 a "dirty bit" idiom : when the spec changes, re-sort the AutoIt-side
 array and push fresh text into the Text widgets.

 Single vs multi sort :
   * $ImGuiTableFlags_Sortable     allows ONE active sort column.
                                   Click header = swap sort, Shift+
                                   click does nothing extra. Read
                                   with TableGetSortSpecs.
   * $ImGuiTableFlags_SortMulti    allows Shift+click to add columns
                                   to the sort. Read with
                                   TableGetSortSpecsN for the
                                   ordered list.
   * $ImGuiTableFlags_SortTristate optional add-on : a third click
                                   removes the column from the sort.

 Direction values (same in both APIs) :
     0 = None       no sort active
     1 = Ascending
     2 = Descending

 t1 below uses Sortable + GetSortSpecs (single-column).
 t2 below uses SortMulti + GetSortSpecsN with Shift-click to chain.

 Borrowed widgets : Tables basic pattern (exemple158), Text +
 Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple161_table_sortspecs.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple161_table_sortspecs.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 161 : Table sort specs", 800, 720) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 2-export cluster
; ==============================================================================
; TableGetSortSpecs($sTableId)  -> array[2] = (col_index, direction)
;   col_index = -1 = no active sort
;   direction = 0 None / 1 Asc / 2 Desc
;
; TableGetSortSpecsN($sTableId, $iMaxSpecs = 4) -> array[N][2]
;   2D array, N >= 0 entries in priority order. Empty when no sort
;   active. Sets @error = 3 on table-side errors (@extended = code).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "TableGetSortSpecs (+N)  --  single-column sort vs multi-column sort")
_ImGui_CreateText("t_hint",  "Click headers in t1 to sort one column. Shift+click in t2 to chain multiple columns.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Table 1  --  Sortable, single-column sort
; ==============================================================================
_ImGui_CreateText("t_t1_hdr", "1) Sortable (single-column)  --  click a header :")
_ImGui_CreateText("t_t1_spec","   spec : col = -1, dir = 0 (no sort)")

Local $iT1Flags = BitOR($ImGuiTableFlags_Borders, _
                         $ImGuiTableFlags_Resizable, _
                         $ImGuiTableFlags_RowBg, _
                         $ImGuiTableFlags_Sortable)
_ImGui_CreateTable("t1", 3, $iT1Flags, 0, 0, 0)
_ImGui_TableSetupColumn("t1", "Name",  $ImGuiTableColumnFlags_WidthStretch, 2.0)
_ImGui_TableSetupColumn("t1", "Score", BitOR($ImGuiTableColumnFlags_WidthStretch, $ImGuiTableColumnFlags_DefaultSort), 1.0)
_ImGui_TableSetupColumn("t1", "Class", $ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_CreateTableHeadersRow("t1_hdr")
_ImGui_SetParent("t1_hdr", "t1")

; Data shared with t2 below.
Global $g_aScores[8][3] = [ _
    ["Alice",   42, "Mage"   ], _
    ["Bob",     17, "Warrior"], _
    ["Charlie", 88, "Rogue"  ], _
    ["Dana",    63, "Cleric" ], _
    ["Eve",     29, "Mage"   ], _
    ["Frank",   51, "Warrior"], _
    ["Grace",   74, "Rogue"  ], _
    ["Henry",   35, "Cleric" ]  ]

For $i = 0 To 7
    Local $sRow = "t1_r" & $i
    _ImGui_CreateTableNextRow($sRow)
    _ImGui_SetParent($sRow, "t1")
    For $col = 0 To 2
        Local $sCell = "t1_c" & $i & "_" & $col
        _ImGui_CreateTableNextColumn($sCell)
        _ImGui_SetParent($sCell, "t1")
        Local $sTxt = "t1_t" & $i & "_" & $col
        _ImGui_CreateText($sTxt, String($g_aScores[$i][$col]))
        _ImGui_SetParent($sTxt, "t1")
    Next
Next

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Table 2  --  SortMulti, multi-column sort with Shift-click
; ==============================================================================
_ImGui_CreateText("t_t2_hdr", "2) SortMulti (multi-column)  --  Shift+click headers to chain :")
_ImGui_CreateText("t_t2_spec","   (no sort)")

Local $iT2Flags = BitOR($ImGuiTableFlags_Borders, _
                         $ImGuiTableFlags_Resizable, _
                         $ImGuiTableFlags_RowBg, _
                         $ImGuiTableFlags_Sortable, _
                         $ImGuiTableFlags_SortMulti)
_ImGui_CreateTable("t2", 3, $iT2Flags, 0, 0, 0)
_ImGui_TableSetupColumn("t2", "Name",  $ImGuiTableColumnFlags_WidthStretch, 2.0)
_ImGui_TableSetupColumn("t2", "Score", $ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_TableSetupColumn("t2", "Class", $ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_CreateTableHeadersRow("t2_hdr")
_ImGui_SetParent("t2_hdr", "t2")

For $i = 0 To 7
    Local $sRow = "t2_r" & $i
    _ImGui_CreateTableNextRow($sRow)
    _ImGui_SetParent($sRow, "t2")
    For $col = 0 To 2
        Local $sCell = "t2_c" & $i & "_" & $col
        _ImGui_CreateTableNextColumn($sCell)
        _ImGui_SetParent($sCell, "t2")
        Local $sTxt = "t2_t" & $i & "_" & $col
        _ImGui_CreateText($sTxt, String($g_aScores[$i][$col]))
        _ImGui_SetParent($sTxt, "t2")
    Next
Next

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- State (dirty bits for the two sort modes) ------------------------------
Global $g_iLastSortColT1 = -2
Global $g_iLastSortDirT1 = -2
Global $g_sLastSpecsT2   = ""


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPollSorts", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollSorts()
    _CheckT1Sort()
    _CheckT2Sort()
EndFunc

Func _CheckT1Sort()
    Local $aSpec = _ImGui_TableGetSortSpecs("t1")
    If Not IsArray($aSpec) Then Return
    Local $iCol = $aSpec[0], $iDir = $aSpec[1]
    _ImGui_SetText("t_t1_spec", StringFormat("   spec : col = %d, dir = %d (%s)", $iCol, $iDir, _DirName($iDir)))
    If $iCol = $g_iLastSortColT1 And $iDir = $g_iLastSortDirT1 Then Return
    $g_iLastSortColT1 = $iCol
    $g_iLastSortDirT1 = $iDir
    If $iCol >= 0 And $iDir <> 0 Then _SortAndRefresh("t1", $iCol, $iDir)
EndFunc

Func _CheckT2Sort()
    Local $aSpecs = _ImGui_TableGetSortSpecsN("t2", 4)
    Local $iN = UBound($aSpecs)
    Local $sSummary = ""
    If $iN = 0 Then
        $sSummary = "   (no sort)"
    Else
        For $k = 0 To $iN - 1
            If $k > 0 Then $sSummary &= "  ,  "
            $sSummary &= "col " & $aSpecs[$k][0] & " " & _DirName($aSpecs[$k][1])
        Next
        $sSummary = "   " & $iN & " specs : " & $sSummary
    EndIf
    _ImGui_SetText("t_t2_spec", $sSummary)
    If $sSummary = $g_sLastSpecsT2 Then Return
    $g_sLastSpecsT2 = $sSummary
    ; Apply only the FIRST spec to keep this example small ; a real app would
    ; loop over all $iN entries and do a stable multi-key sort.
    If $iN > 0 Then _SortAndRefresh("t2", $aSpecs[0][0], $aSpecs[0][1])
EndFunc

Func _SortAndRefresh($sTablePrefix, $iCol, $iDir)
    ; Insertion sort -- 8 items is fine.
    For $i = 1 To UBound($g_aScores) - 1
        For $j = $i To 1 Step -1
            Local $vA = $g_aScores[$j - 1][$iCol]
            Local $vB = $g_aScores[$j][$iCol]
            Local $bGreater
            If $iCol = 1 Then
                $bGreater = (Number($vA) > Number($vB))
            Else
                $bGreater = (StringCompare(String($vA), String($vB)) > 0)
            EndIf
            Local $bSwap = ($iDir = 1) ? $bGreater : Not $bGreater
            If $iDir = 2 And Not $bGreater And StringCompare(String($vA), String($vB)) = 0 Then ContinueLoop
            If $bSwap Then
                Local $s0 = $g_aScores[$j - 1][0], $s1 = $g_aScores[$j - 1][1], $s2 = $g_aScores[$j - 1][2]
                $g_aScores[$j - 1][0] = $g_aScores[$j][0]
                $g_aScores[$j - 1][1] = $g_aScores[$j][1]
                $g_aScores[$j - 1][2] = $g_aScores[$j][2]
                $g_aScores[$j][0] = $s0
                $g_aScores[$j][1] = $s1
                $g_aScores[$j][2] = $s2
            Else
                ExitLoop
            EndIf
        Next
    Next
    ; Push the sorted data back into the displayed cells. Both tables share
    ; the same $g_aScores so we refresh both on every sort.
    For $i = 0 To 7
        For $col = 0 To 2
            _ImGui_SetText("t1_t" & $i & "_" & $col, String($g_aScores[$i][$col]))
            _ImGui_SetText("t2_t" & $i & "_" & $col, String($g_aScores[$i][$col]))
        Next
    Next
EndFunc

Func _DirName($iDir)
    If $iDir = 1 Then Return "Asc"
    If $iDir = 2 Then Return "Desc"
    Return "None"
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
