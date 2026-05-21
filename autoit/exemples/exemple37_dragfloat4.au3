#cs
================================================================================
 Example 37 : _ImGui_CreateDragFloat4
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateDragFloat4   Four-component float "drag" widget
   _ImGui_GetValueFloatN     Read the 4-component vector
   _ImGui_SetValueFloatN     Set the 4-component vector

 DragFloat4 packs four click-and-drag float fields into one widget row.
 Typical use : axis-aligned bounding box (l, t, r, b), rectangle in
 pixel space, generic 4-channel unbounded parameters.

 Strict semantics : see exemple18_dragfloat.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple37_dragfloat4.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple37_dragfloat4.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 37 : _ImGui_CreateDragFloat4", 660, 420) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateDragFloat4  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateDragFloat4($sId, $sLabel = "",
;                                      $fSpeed = 1.0,
;                                      $fMin = 0.0, $fMax = 0.0,
;                                      $fD0 = 0.0, $fD1 = 0.0,
;                                      $fD2 = 0.0, $fD3 = 0.0,
;                                      $sFormat = "%.3f")
;
;   Four draggable float fields on a single row, sharing the same speed
;   and bounds. AABB rectangles work well here because all four
;   components live in the same coordinate space, so a single shared
;   bound makes sense.
;
;   Read / write the quad as an AutoIt array of size 4 :
;     _ImGui_GetValueFloatN($sId, 4)        -> [v0, v1, v2, v3]
;     _ImGui_SetValueFloatN($sId, $aVals)   -> 1D array of size 4 ; no OnChange
;
;   Bind user drags with _ImGui_SetOnChange (FloatVec4ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  AABB rectangle (left, top, right, bottom), speed 1.0
; ==============================================================================
_ImGui_CreateText("t_title", "DragFloat4 demo  --  AABB rectangle (l, t, r, b), speed 1.0 per pixel")
_ImGui_CreateText("t_hint",  "All four components share the same speed and bounds. Width / height are derived in the readout.")
_ImGui_CreateSeparator("sep1")

; Speed 1.0, unbounded, default rectangle 0..640 / 0..480.
_ImGui_CreateDragFloat4("dr_rect", "Rectangle (l, t, r, b)", _
                        1.0, _                       ; speed
                        0.0, 0.0, _                  ; unbounded
                        0.0, 0.0, 640.0, 480.0, _    ; default (0, 0, 640, 480)
                        "%.0f")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : l=0, t=0, r=640, b=480  (w=640, h=480)")
_ImGui_CreateText("t_count", "User edits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueFloatN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_zero", "Empty     (0, 0, 0, 0)")
_ImGui_CreateButton("btn_hd",   "HD canvas (0, 0, 1280, 720)")
_ImGui_CreateButton("btn_fhd",  "FHD canvas (0, 0, 1920, 1080)")
_ImGui_CreateButton("btn_grow", "Grow rect by 10 px on each side")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iEditCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("dr_rect",  "_OnRectChanged")
_ImGui_SetOnClick ("btn_zero", "_OnZero")
_ImGui_SetOnClick ("btn_hd",   "_OnHd")
_ImGui_SetOnClick ("btn_fhd",  "_OnFhd")
_ImGui_SetOnClick ("btn_grow", "_OnGrow")
_ImGui_SetOnClick ("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnRectChanged($sId)
    Local $aVal = _ImGui_GetValueFloatN($sId, 4)
    If @error Or Not IsArray($aVal) Then Return
    $g_iEditCount += 1
    Local $fW = $aVal[2] - $aVal[0]
    Local $fH = $aVal[3] - $aVal[1]
    _ImGui_SetText("t_read",  StringFormat("Read-back : l=%.0f, t=%.0f, r=%.0f, b=%.0f  (w=%.0f, h=%.0f)", _
                                            $aVal[0], $aVal[1], $aVal[2], $aVal[3], $fW, $fH))
    _ImGui_SetText("t_count", "User edits : " & $g_iEditCount)
EndFunc

Func _OnZero($sId)
    _ApplyPreset(0.0, 0.0, 0.0, 0.0, "empty")
EndFunc

Func _OnHd($sId)
    _ApplyPreset(0.0, 0.0, 1280.0, 720.0, "HD")
EndFunc

Func _OnFhd($sId)
    _ApplyPreset(0.0, 0.0, 1920.0, 1080.0, "FHD")
EndFunc

Func _OnGrow($sId)
    Local $aVal = _ImGui_GetValueFloatN("dr_rect", 4)
    If @error Or Not IsArray($aVal) Then Return
    _ApplyPreset($aVal[0] - 10, $aVal[1] - 10, $aVal[2] + 10, $aVal[3] + 10, "grown by 10")
EndFunc

Func _ApplyPreset($fL, $fT, $fR, $fB, $sTag)
    Local $aNew[4] = [$fL, $fT, $fR, $fB]
    _ImGui_SetValueFloatN("dr_rect", $aNew)
    Local $fW = $fR - $fL, $fH = $fB - $fT
    _ImGui_SetText("t_read", StringFormat("Read-back : l=%.0f, t=%.0f, r=%.0f, b=%.0f  (w=%.0f, h=%.0f, %s)", _
                                          $fL, $fT, $fR, $fB, $fW, $fH, $sTag))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
