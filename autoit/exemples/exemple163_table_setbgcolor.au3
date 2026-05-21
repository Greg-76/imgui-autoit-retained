#cs
================================================================================
 Example 163 : _ImGui_CreateTableSetBgColor
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateTableSetBgColor   Emit a marker that sets the background
                                  color of a row or cell

 Marker widget (no visible content of its own). Placed as a SIBLING of
 TableNextRow / TableNextColumn at the parent TABLE's children level,
 AFTER the marker that targets the row or cell. Reads :
   * RowBg0 / RowBg1 target  --  set the row background.
   * CellBg target           --  set the current cell background.

 RowBg0 vs RowBg1 : ImGui stacks two row background layers. RowBg0 is
 the lower layer (drawn behind the alternating $ImGuiTableFlags_RowBg
 stripes) ; RowBg1 is the upper layer (drawn ON TOP of the stripes).
 For "highlight a row" use RowBg1 ; for "category color zone" use
 RowBg0.

 Color is a packed ImU32 (0xAABBGGRR). Build via _ImGui_ColorFloat4ToU32
 (exemple60) -- avoids manual byte order shuffles.

 $iColumnN parameter :
   * For RowBg0 / RowBg1 : ignored (rows span all columns).
   * For CellBg : -1 = current cell, >=0 = explicit column index.

 Borrowed widgets : Tables basic pattern (exemple158), ColorFloat4ToU32
 (exemple60), Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple163_table_setbgcolor.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple163_table_setbgcolor.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 163 : _ImGui_CreateTableSetBgColor", 760, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateTableSetBgColor  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateTableSetBgColor($sId, $iTarget, $iU32Color,
;                                           $iColumnN = -1)
;
;   $iTarget : $ImGuiTableBgTarget_RowBg0 (1) / RowBg1 (2) / CellBg (3).
;   $iU32Color : packed ImU32 ; use _ImGui_ColorFloat4ToU32 to build.
;   $iColumnN : -1 = current cell (CellBg) / current row (RowBg* -- ignored).
;
;   Tree placement : sibling of TableNextRow / TableNextColumn at the
;   parent TABLE's children level. AFTER the marker that targets the
;   row or cell you want to color.
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "TableSetBgColor  --  RowBg0 (under stripes), RowBg1 (over stripes), CellBg (single cell)")
_ImGui_CreateText("t_hint",  "Each row uses a different target so you can see the layering.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Pre-build a few ImU32 colors
; ==============================================================================
Global Const $g_iColRed    = _ImGui_ColorFloat4ToU32(0.55, 0.10, 0.10, 0.45)
Global Const $g_iColGreen  = _ImGui_ColorFloat4ToU32(0.10, 0.50, 0.10, 0.45)
Global Const $g_iColBlue   = _ImGui_ColorFloat4ToU32(0.10, 0.25, 0.70, 0.45)
Global Const $g_iColYellow = _ImGui_ColorFloat4ToU32(0.85, 0.75, 0.10, 0.55)


; ==============================================================================
; Table  --  Borders + RowBg so we can SEE the contrast between the layers
; ==============================================================================
Local $iFlags = BitOR($ImGuiTableFlags_Borders, $ImGuiTableFlags_RowBg)
_ImGui_CreateTable("t", 3, $iFlags, 0, 0, 0)
_ImGui_TableSetupColumn("t", "Row",      $ImGuiTableColumnFlags_WidthFixed, 60.0)
_ImGui_TableSetupColumn("t", "Treatment",$ImGuiTableColumnFlags_WidthStretch, 2.0)
_ImGui_TableSetupColumn("t", "Notes",    $ImGuiTableColumnFlags_WidthStretch, 2.0)
_ImGui_CreateTableHeadersRow("t_hdr")
_ImGui_SetParent("t_hdr", "t")


; Row 0  --  RowBg0 red (UNDER the alternating RowBg stripes)
_ImGui_CreateTableNextRow("r0")
_ImGui_SetParent("r0", "t")
_ImGui_CreateTableSetBgColor("r0_bg", $ImGuiTableBgTarget_RowBg0, $g_iColRed, -1)
_ImGui_SetParent("r0_bg", "t")
_AddCell("r0", 0, "0",     "RowBg0 red")
_AddCell("r0", 1, "lower", "Drawn UNDER the RowBg alternating stripes")
_AddCell("r0", 2, "lower", "Result : subdued red, stripes still visible")


; Row 1  --  RowBg1 green (OVER the alternating RowBg stripes)
_ImGui_CreateTableNextRow("r1")
_ImGui_SetParent("r1", "t")
_ImGui_CreateTableSetBgColor("r1_bg", $ImGuiTableBgTarget_RowBg1, $g_iColGreen, -1)
_ImGui_SetParent("r1_bg", "t")
_AddCell("r1", 0, "1",     "RowBg1 green")
_AddCell("r1", 1, "upper", "Drawn ON TOP of the RowBg alternating stripes")
_AddCell("r1", 2, "upper", "Result : flat green, stripes hidden")


; Row 2  --  no row color, instead a single CellBg blue on column 1
_ImGui_CreateTableNextRow("r2")
_ImGui_SetParent("r2", "t")
_AddCell("r2", 0, "2",     "CellBg on column 1 only")
_AddCell("r2", 1, "cell",  "CellBg blue (just this cell)")
; CellBg marker is placed AFTER the cell content for column 1. -1 = current cell.
_ImGui_CreateTableSetBgColor("r2_cb", $ImGuiTableBgTarget_CellBg, $g_iColBlue, -1)
_ImGui_SetParent("r2_cb", "t")
_AddCell("r2", 2, "cell",  "Other cells unchanged")


; Row 3  --  CellBg yellow on an explicit column (index 2)
_ImGui_CreateTableNextRow("r3")
_ImGui_SetParent("r3", "t")
_AddCell("r3", 0, "3",     "CellBg via explicit column index")
_AddCell("r3", 1, "cell",  "$iColumnN = 2 (explicit)")
_AddCell("r3", 2, "cell",  "CellBg yellow on this one")
_ImGui_CreateTableSetBgColor("r3_cb", $ImGuiTableBgTarget_CellBg, $g_iColYellow, 2)
_ImGui_SetParent("r3_cb", "t")


_ImGui_CreateSeparator("sep1")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Helpers + Handlers ------------------------------------------------------

Func _AddCell($sRowId, $iCol, $sCellTag, $sText)
    ; Tiny helper to keep the row code readable. Cell marker + content widget
    ; both at the TABLE's children level (see exemple158 pitfall).
    Local $sCellId = $sRowId & "_c" & $iCol
    _ImGui_CreateTableNextColumn($sCellId)
    _ImGui_SetParent($sCellId, "t")
    Local $sTxtId = $sRowId & "_t" & $iCol
    _ImGui_CreateText($sTxtId, $sText)
    _ImGui_SetParent($sTxtId, "t")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
