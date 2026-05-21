#cs
================================================================================
 Example 165 : _ImGui_CreateTableAngledHeadersRow
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateTableAngledHeadersRow   Render diagonal (45 deg) text
                                        headers for narrow columns

 Useful when you have many narrow columns that need long labels --
 diagonal text saves horizontal real estate. The angle is controlled
 by ImGui style ($ImGuiStyleVar_TableAngledHeadersAngle, exposed in
 exemple73-74) ; the default is 45 deg.

 SETUP REQUIREMENTS :
   1. At least ONE column must carry $ImGuiTableColumnFlags_AngledHeader
      to opt in (the others render normally side-by-side).
   2. The angled-headers row marker is placed BEFORE the standard
      CreateTableHeadersRow ; both can coexist (angled row on top,
      then a normal labelled row below).

 Combine with $ImGuiTableColumnFlags_WidthFixed + narrow widths so the
 diagonal labels actually save space.

 Borrowed widgets : Tables basic pattern (exemple158), Text +
 Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple165_table_angledheaders.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple165_table_angledheaders.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 165 : _ImGui_CreateTableAngledHeadersRow", 820, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateTableAngledHeadersRow  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateTableAngledHeadersRow($sId)
;
;   Marker (no $iFlags). Place as a child of the table BEFORE any
;   row marker -- typically right before CreateTableHeadersRow if
;   you want both angled + horizontal rows.
;
;   Requires at least one column with $ImGuiTableColumnFlags_AngledHeader.
;   The DLL falls back to a normal header if no column is opted in.
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "TableAngledHeadersRow  --  diagonal labels for narrow columns")
_ImGui_CreateText("t_hint",  "Compare the wide-label angled headers to the regular row beneath them.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; The table  --  1 wide column + 5 narrow columns with AngledHeader flag
; ==============================================================================
Local $iFlags = BitOR($ImGuiTableFlags_Borders, _
                      $ImGuiTableFlags_RowBg, _
                      $ImGuiTableFlags_SizingFixedFit)
_ImGui_CreateTable("t", 6, $iFlags, 0, 0, 0)
_ImGui_TableSetupColumn("t", "Subject",       $ImGuiTableColumnFlags_WidthFixed, 140.0)
_ImGui_TableSetupColumn("t", "Math",          BitOR($ImGuiTableColumnFlags_WidthFixed, $ImGuiTableColumnFlags_AngledHeader), 60.0)
_ImGui_TableSetupColumn("t", "Physics",       BitOR($ImGuiTableColumnFlags_WidthFixed, $ImGuiTableColumnFlags_AngledHeader), 60.0)
_ImGui_TableSetupColumn("t", "Chemistry",     BitOR($ImGuiTableColumnFlags_WidthFixed, $ImGuiTableColumnFlags_AngledHeader), 60.0)
_ImGui_TableSetupColumn("t", "Biology",       BitOR($ImGuiTableColumnFlags_WidthFixed, $ImGuiTableColumnFlags_AngledHeader), 60.0)
_ImGui_TableSetupColumn("t", "Literature",    BitOR($ImGuiTableColumnFlags_WidthFixed, $ImGuiTableColumnFlags_AngledHeader), 60.0)

; Angled row first ...
_ImGui_CreateTableAngledHeadersRow("t_angled")
_ImGui_SetParent("t_angled", "t")
; ... then a regular header row underneath (mostly empty since the angled row
; already drew the column labels ; useful for the first non-angled column).
_ImGui_CreateTableHeadersRow("t_hdr")
_ImGui_SetParent("t_hdr", "t")


; ==============================================================================
; Data rows  --  6 cells each (1 subject label + 5 grades)
; ==============================================================================
Local $aData[5][6] = [ _
    ["Alice",   15, 12, 18, 14, 11], _
    ["Bob",     11, 16, 12, 13, 17], _
    ["Charlie", 18, 14, 10, 15, 19], _
    ["Dana",    13, 17, 16, 12, 14], _
    ["Eve",     16, 11, 14, 18, 12]  ]

For $i = 0 To 4
    Local $sRow = "r" & $i
    _ImGui_CreateTableNextRow($sRow)
    _ImGui_SetParent($sRow, "t")
    For $col = 0 To 5
        Local $sCell = "c" & $i & "_" & $col
        _ImGui_CreateTableNextColumn($sCell)
        _ImGui_SetParent($sCell, "t")
        Local $sTxt = "x" & $i & "_" & $col
        _ImGui_CreateText($sTxt, String($aData[$i][$col]))
        _ImGui_SetParent($sTxt, "t")
    Next
Next

_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_note", "Notes : angled headers + WidthFixed = compact gradebook style. Style var '$ImGuiStyleVar_TableAngledHeadersAngle' tunes the angle.")
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
