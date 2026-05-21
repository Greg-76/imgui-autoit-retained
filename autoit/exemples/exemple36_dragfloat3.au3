#cs
================================================================================
 Example 36 : _ImGui_CreateDragFloat3
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateDragFloat3   Three-component float "drag" widget
   _ImGui_GetValueFloatN     Read the 3-component vector
   _ImGui_SetValueFloatN     Set the 3-component vector

 DragFloat3 packs three click-and-drag float fields into one widget row.
 Typical use : world-space position (x, y, z), Euler angles, generic
 unbounded 3-channel parameters.

 Strict semantics : see exemple18_dragfloat.au3. Programmatic
 _ImGui_SetValueFloatN never fires OnChange.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple36_dragfloat3.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple36_dragfloat3.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 36 : _ImGui_CreateDragFloat3", 640, 400) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateDragFloat3  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateDragFloat3($sId, $sLabel = "",
;                                      $fSpeed = 1.0,
;                                      $fMin = 0.0, $fMax = 0.0,
;                                      $fD0 = 0.0, $fD1 = 0.0, $fD2 = 0.0,
;                                      $sFormat = "%.3f")
;
;   Three draggable float fields on a single row, sharing the same speed
;   and bounds. $fMin == $fMax (both 0) -> unbounded.
;
;   Read / write the triple as an AutoIt array of size 3 :
;     _ImGui_GetValueFloatN($sId, 3)        -> [v0, v1, v2]
;     _ImGui_SetValueFloatN($sId, $aVals)   -> 1D array of size 3 ; no OnChange
;
;   Bind user drags with _ImGui_SetOnChange (FloatVec3ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  world position (x, y, z), unbounded, speed 0.5
; ==============================================================================
_ImGui_CreateText("t_title", "DragFloat3 demo  --  unbounded 3D position, speed 0.5 per pixel")
_ImGui_CreateText("t_hint",  "Click-drag each component. Ctrl + click to type a value directly.")
_ImGui_CreateSeparator("sep1")

; Speed 0.5, unbounded, defaults (0, 0, 0).
_ImGui_CreateDragFloat3("dr_pos", "World position (x, y, z)", _
                        0.5, _              ; speed
                        0.0, 0.0, _         ; unbounded
                        0.0, 0.0, 0.0, _    ; default
                        "%.2f")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : x=0.00, y=0.00, z=0.00  (|p|=0.00)")
_ImGui_CreateText("t_count", "User edits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueFloatN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_origin",  "Origin       ( 0.0,  0.0,  0.0)")
_ImGui_CreateButton("btn_far",     "Far point    (1000.0,  500.0, -250.0)")
_ImGui_CreateButton("btn_invert",  "Invert sign  (-x, -y, -z)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",    "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iEditCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("dr_pos",     "_OnPosChanged")
_ImGui_SetOnClick ("btn_origin", "_OnOrigin")
_ImGui_SetOnClick ("btn_far",    "_OnFar")
_ImGui_SetOnClick ("btn_invert", "_OnInvert")
_ImGui_SetOnClick ("btn_quit",   "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPosChanged($sId)
    Local $aVal = _ImGui_GetValueFloatN($sId, 3)
    If @error Or Not IsArray($aVal) Then Return
    $g_iEditCount += 1
    Local $fNorm = Sqrt($aVal[0]*$aVal[0] + $aVal[1]*$aVal[1] + $aVal[2]*$aVal[2])
    _ImGui_SetText("t_read",  StringFormat("Read-back : x=%.2f, y=%.2f, z=%.2f  (|p|=%.2f)", _
                                            $aVal[0], $aVal[1], $aVal[2], $fNorm))
    _ImGui_SetText("t_count", "User edits : " & $g_iEditCount)
EndFunc

Func _OnOrigin($sId)
    _ApplyPreset(0.0, 0.0, 0.0, "origin")
EndFunc

Func _OnFar($sId)
    _ApplyPreset(1000.0, 500.0, -250.0, "far point")
EndFunc

Func _OnInvert($sId)
    Local $aVal = _ImGui_GetValueFloatN("dr_pos", 3)
    If @error Or Not IsArray($aVal) Then Return
    _ApplyPreset(-$aVal[0], -$aVal[1], -$aVal[2], "inverted")
EndFunc

Func _ApplyPreset($f0, $f1, $f2, $sTag)
    Local $aNew[3] = [$f0, $f1, $f2]
    _ImGui_SetValueFloatN("dr_pos", $aNew)
    Local $fNorm = Sqrt($f0*$f0 + $f1*$f1 + $f2*$f2)
    _ImGui_SetText("t_read", StringFormat("Read-back : x=%.2f, y=%.2f, z=%.2f  (|p|=%.2f, %s)", _
                                          $f0, $f1, $f2, $fNorm, $sTag))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
