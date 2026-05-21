#cs
================================================================================
 Example 29 : _ImGui_CreateSliderFloat2
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateSliderFloat2   Two-component float slider (single widget row)
   _ImGui_GetValueFloatN       Read the 2-component vector
   _ImGui_SetValueFloatN       Set the 2-component vector

 SliderFloat2 packs two independent float sliders into a single widget row.
 Each component is clamped to [$fMin, $fMax]. There is no per-component
 range -- both share the same bounds.

 Strict semantics : see exemple16_sliderfloat.au3. Programmatic
 _ImGui_SetValueFloatN never fires OnChange ; only user drags do.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple29_sliderfloat2.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple29_sliderfloat2.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 29 : _ImGui_CreateSliderFloat2", 600, 360) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSliderFloat2  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSliderFloat2($sId, $sLabel = "",
;                                        $fMin = 0.0, $fMax = 1.0,
;                                        $fD0 = 0.0, $fD1 = 0.0,
;                                        $sFormat = "%.3f")
;
;   Two horizontal slider handles laid out side by side on a single row.
;   Both components share the hard range [$fMin, $fMax] (ImGui clamps).
;   $fD0 / $fD1 are the initial values for component 0 / 1.
;
;   Read / write the pair as an AutoIt array of size 2 :
;     _ImGui_GetValueFloatN($sId, 2)        -> [v0, v1]
;     _ImGui_SetValueFloatN($sId, $aVals)   -> 1D array of size 2 ; no OnChange
;
;   Bind user edits with _ImGui_SetOnChange (it's a FloatVec2ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  2D position (x, y) editor
; ==============================================================================
_ImGui_CreateText("t_title", "SliderFloat2 demo  --  edit a 2D position in [0, 1]")
_ImGui_CreateText("t_hint",  "Drag either handle. Presets update the value programmatically (no OnChange).")
_ImGui_CreateSeparator("sep1")

; Range 0..1, defaults (0.5, 0.5).
_ImGui_CreateSliderFloat2("sl_pos", "Position (x, y)", 0.0, 1.0, 0.5, 0.5, "%.3f")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : x=0.500, y=0.500")
_ImGui_CreateText("t_count", "User edits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueFloatN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_origin", "Origin (0.0, 0.0)")
_ImGui_CreateButton("btn_center", "Center (0.5, 0.5)")
_ImGui_CreateButton("btn_corner", "Corner (1.0, 1.0)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",   "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iEditCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("sl_pos",     "_OnPosChanged")
_ImGui_SetOnClick ("btn_origin", "_OnOrigin")
_ImGui_SetOnClick ("btn_center", "_OnCenter")
_ImGui_SetOnClick ("btn_corner", "_OnCorner")
_ImGui_SetOnClick ("btn_quit",   "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPosChanged($sId)
    Local $aVal = _ImGui_GetValueFloatN($sId, 2)
    If @error Or Not IsArray($aVal) Then Return
    $g_iEditCount += 1
    _ImGui_SetText("t_read",  StringFormat("Read-back : x=%.3f, y=%.3f", $aVal[0], $aVal[1]))
    _ImGui_SetText("t_count", "User edits : " & $g_iEditCount)
EndFunc

Func _OnOrigin($sId)
    _ApplyPreset(0.0, 0.0, "origin")
EndFunc

Func _OnCenter($sId)
    _ApplyPreset(0.5, 0.5, "center")
EndFunc

Func _OnCorner($sId)
    _ApplyPreset(1.0, 1.0, "corner")
EndFunc

Func _ApplyPreset($f0, $f1, $sTag)
    Local $aNew[2] = [$f0, $f1]
    _ImGui_SetValueFloatN("sl_pos", $aNew)
    ; OnChange does NOT fire ; update the readout ourselves.
    _ImGui_SetText("t_read", StringFormat("Read-back : x=%.3f, y=%.3f (set to %s)", $f0, $f1, $sTag))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
