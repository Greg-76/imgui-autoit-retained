#cs
================================================================================
 Example 38 : _ImGui_CreateDragInt2
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateDragInt2   Two-component int "drag" widget
   _ImGui_GetValueIntN     Read the 2-component vector
   _ImGui_SetValueIntN     Set the 2-component vector

 DragInt2 packs two click-and-drag int fields into one widget row.
 Typical use : grid coordinates, tile (col, row), pair of counters that
 can grow without an obvious upper bound.

 Strict semantics : see exemple19_dragint.au3. Programmatic
 _ImGui_SetValueIntN never fires OnChange.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple38_dragint2.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple38_dragint2.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 38 : _ImGui_CreateDragInt2", 620, 400) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateDragInt2  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateDragInt2($sId, $sLabel = "",
;                                    $fSpeed = 1.0,
;                                    $iMin = 0, $iMax = 0,
;                                    $iD0 = 0, $iD1 = 0,
;                                    $sFormat = "%d")
;
;   Two draggable int fields on a single row, sharing the same speed
;   and bounds. $fSpeed is a float (sub-1 speeds are supported -- the
;   widget accumulates fractional progress between integer steps).
;   $iMin == $iMax (both 0) -> unbounded.
;
;   Read / write the pair as an AutoIt array of size 2 :
;     _ImGui_GetValueIntN($sId, 2)        -> [v0, v1]
;     _ImGui_SetValueIntN($sId, $aVals)   -> 1D array of size 2 ; no OnChange
;
;   Bind user drags with _ImGui_SetOnChange (IntVec2ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  grid coords (col, row), unbounded, speed 0.2
; ==============================================================================
_ImGui_CreateText("t_title", "DragInt2 demo  --  unbounded grid coords (col, row), speed 0.2 per pixel")
_ImGui_CreateText("t_hint",  "Sub-1 speed means several pixels of drag for one integer step. Negative values are allowed (off-grid).")
_ImGui_CreateSeparator("sep1")

; Speed 0.2, unbounded, defaults (0, 0).
_ImGui_CreateDragInt2("dr_cell", "Grid cell (col, row)", _
                      0.2, _              ; sub-1 speed
                      0, 0, _             ; unbounded
                      0, 0, _             ; default
                      "%d")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : col=0, row=0, linear-index(width=16)=0")
_ImGui_CreateText("t_count", "User edits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueIntN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_origin",  "Origin     (0, 0)")
_ImGui_CreateButton("btn_offgrid", "Off-grid   (-3, -2)")
_ImGui_CreateButton("btn_corner",  "Far corner (255, 255)")
_ImGui_CreateButton("btn_step",    "Step right (+1, 0)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",    "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iEditCount = 0
Const  $g_iGridWidth = 16          ; for linear-index computation in the readout


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("dr_cell",     "_OnCellChanged")
_ImGui_SetOnClick ("btn_origin",  "_OnOrigin")
_ImGui_SetOnClick ("btn_offgrid", "_OnOffgrid")
_ImGui_SetOnClick ("btn_corner",  "_OnCorner")
_ImGui_SetOnClick ("btn_step",    "_OnStepRight")
_ImGui_SetOnClick ("btn_quit",    "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnCellChanged($sId)
    Local $aVal = _ImGui_GetValueIntN($sId, 2)
    If @error Or Not IsArray($aVal) Then Return
    $g_iEditCount += 1
    Local $iLinear = $aVal[1] * $g_iGridWidth + $aVal[0]
    _ImGui_SetText("t_read",  StringFormat("Read-back : col=%d, row=%d, linear-index(width=%d)=%d", _
                                            $aVal[0], $aVal[1], $g_iGridWidth, $iLinear))
    _ImGui_SetText("t_count", "User edits : " & $g_iEditCount)
EndFunc

Func _OnOrigin($sId)
    _ApplyPreset(0, 0, "origin")
EndFunc

Func _OnOffgrid($sId)
    _ApplyPreset(-3, -2, "off-grid")
EndFunc

Func _OnCorner($sId)
    _ApplyPreset(255, 255, "far corner")
EndFunc

Func _OnStepRight($sId)
    Local $aVal = _ImGui_GetValueIntN("dr_cell", 2)
    If @error Or Not IsArray($aVal) Then Return
    _ApplyPreset($aVal[0] + 1, $aVal[1], "step right")
EndFunc

Func _ApplyPreset($iC, $iR, $sTag)
    Local $aNew[2] = [$iC, $iR]
    _ImGui_SetValueIntN("dr_cell", $aNew)
    Local $iLinear = $iR * $g_iGridWidth + $iC
    _ImGui_SetText("t_read", StringFormat("Read-back : col=%d, row=%d, linear-index(width=%d)=%d (%s)", _
                                          $iC, $iR, $g_iGridWidth, $iLinear, $sTag))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
