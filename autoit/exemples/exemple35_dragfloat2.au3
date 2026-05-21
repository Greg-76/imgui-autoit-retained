#cs
================================================================================
 Example 35 : _ImGui_CreateDragFloat2
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateDragFloat2   Two-component float "drag" widget
   _ImGui_GetValueFloatN     Read the 2-component vector
   _ImGui_SetValueFloatN     Set the 2-component vector

 DragFloat2 packs two click-and-drag float fields into one widget row.
 Unlike SliderFloat2, the default range is UNBOUNDED -- if $fMin == $fMax
 (both 0), values can grow arbitrarily large in either direction.
 Use Drag widgets for "tweak around a value" (offsets, deltas, world
 coordinates) and Slider widgets for "pick a value in a bounded range".

 Strict semantics : see exemple18_dragfloat.au3. Programmatic
 _ImGui_SetValueFloatN never fires OnChange.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple35_dragfloat2.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple35_dragfloat2.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 35 : _ImGui_CreateDragFloat2", 620, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateDragFloat2  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateDragFloat2($sId, $sLabel = "",
;                                      $fSpeed = 1.0,
;                                      $fMin = 0.0, $fMax = 0.0,
;                                      $fD0 = 0.0, $fD1 = 0.0,
;                                      $sFormat = "%.3f")
;
;   $fSpeed : how fast the value changes per drag pixel. Use small values
;             (0.01, 0.1) for precise tweaks, larger ones (1, 10) for
;             coarse movement.
;
;   $fMin = $fMax (both 0) -> UNBOUNDED. Otherwise the value clamps to
;   [$fMin, $fMax] like Slider does, but the widget keeps its drag
;   interaction model (no track / handle, just a draggable label).
;
;   Read / write the pair as an AutoIt array of size 2 :
;     _ImGui_GetValueFloatN($sId, 2)        -> [v0, v1]
;     _ImGui_SetValueFloatN($sId, $aVals)   -> 1D array of size 2 ; no OnChange
;
;   Bind user drags with _ImGui_SetOnChange (FloatVec2ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  camera offset (dx, dy), unbounded, speed 0.1
; ==============================================================================
_ImGui_CreateText("t_title", "DragFloat2 demo  --  unbounded 2D offset, speed 0.1 per pixel")
_ImGui_CreateText("t_hint",  "Click-drag the value horizontally. Hold Ctrl + click to type a value directly.")
_ImGui_CreateSeparator("sep1")

; Speed 0.1, min=max=0 -> unbounded ; defaults (0.0, 0.0).
_ImGui_CreateDragFloat2("dr_offset", "Camera offset (dx, dy)", _
                        0.1, _              ; speed
                        0.0, 0.0, _         ; unbounded
                        0.0, 0.0, _         ; default
                        "%.2f")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : dx=0.00, dy=0.00, distance=0.00")
_ImGui_CreateText("t_count", "User edits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueFloatN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_recenter", "Recenter to (0.0, 0.0)")
_ImGui_CreateButton("btn_far",      "Jump far to (100.0, -100.0)")
_ImGui_CreateButton("btn_double",   "Double current offset (cumulative)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",     "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iEditCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("dr_offset",    "_OnOffsetChanged")
_ImGui_SetOnClick ("btn_recenter", "_OnRecenter")
_ImGui_SetOnClick ("btn_far",      "_OnFar")
_ImGui_SetOnClick ("btn_double",   "_OnDouble")
_ImGui_SetOnClick ("btn_quit",     "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnOffsetChanged($sId)
    Local $aVal = _ImGui_GetValueFloatN($sId, 2)
    If @error Or Not IsArray($aVal) Then Return
    $g_iEditCount += 1
    Local $fDist = Sqrt($aVal[0]*$aVal[0] + $aVal[1]*$aVal[1])
    _ImGui_SetText("t_read",  StringFormat("Read-back : dx=%.2f, dy=%.2f, distance=%.2f", _
                                            $aVal[0], $aVal[1], $fDist))
    _ImGui_SetText("t_count", "User edits : " & $g_iEditCount)
EndFunc

Func _OnRecenter($sId)
    _ApplyPreset(0.0, 0.0, "recentered")
EndFunc

Func _OnFar($sId)
    _ApplyPreset(100.0, -100.0, "far jump")
EndFunc

Func _OnDouble($sId)
    Local $aVal = _ImGui_GetValueFloatN("dr_offset", 2)
    If @error Or Not IsArray($aVal) Then Return
    _ApplyPreset($aVal[0] * 2.0, $aVal[1] * 2.0, "doubled")
EndFunc

Func _ApplyPreset($f0, $f1, $sTag)
    Local $aNew[2] = [$f0, $f1]
    _ImGui_SetValueFloatN("dr_offset", $aNew)
    Local $fDist = Sqrt($f0*$f0 + $f1*$f1)
    _ImGui_SetText("t_read", StringFormat("Read-back : dx=%.2f, dy=%.2f, distance=%.2f (%s)", _
                                          $f0, $f1, $fDist, $sTag))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
