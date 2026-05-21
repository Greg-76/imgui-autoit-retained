#cs
================================================================================
 Example 33 : _ImGui_CreateSliderInt3
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateSliderInt3   Three-component int slider (single widget row)
   _ImGui_GetValueIntN       Read the 3-component vector
   _ImGui_SetValueIntN       Set the 3-component vector

 SliderInt3 packs three int sliders into a single row, sharing the hard
 range [$iMin, $iMax]. Typical use : integer RGB (0..255), tile triple
 (col, row, layer), generic 3-channel counters.

 NOTE : for a proper color editor with HEX, picker, drag-and-drop, use
 the Color family (ColorEdit3 / ColorPicker3). SliderInt3 with 0..255
 just shows the three numeric channels -- no preview swatch.

 Strict semantics : see exemple17_sliderint.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple33_sliderint3.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple33_sliderint3.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 33 : _ImGui_CreateSliderInt3", 640, 400) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSliderInt3  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSliderInt3($sId, $sLabel = "",
;                                      $iMin = 0, $iMax = 100,
;                                      $iD0 = 0, $iD1 = 0, $iD2 = 0,
;                                      $sFormat = "%d")
;
;   Three integer slider handles on a single row, all clamped to
;   [$iMin, $iMax]. $iD0 / $iD1 / $iD2 are the initial values.
;
;   Read / write the triple as an AutoIt array of size 3 :
;     _ImGui_GetValueIntN($sId, 3)        -> [v0, v1, v2]
;     _ImGui_SetValueIntN($sId, $aVals)   -> 1D array of size 3 ; no OnChange
;
;   Bind user edits with _ImGui_SetOnChange (IntVec3ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  integer RGB triple (0..255), no color preview
; ==============================================================================
_ImGui_CreateText("t_title", "SliderInt3 demo  --  RGB-as-int (0..255), three channels")
_ImGui_CreateText("t_hint",  "Three independent int sliders. For a real color picker, see ColorEdit3 in the Color family.")
_ImGui_CreateSeparator("sep1")

; Range 0..255, defaults : neutral grey (128, 128, 128).
_ImGui_CreateSliderInt3("sl_rgb", "RGB (r, g, b)", 0, 255, 128, 128, 128, "%d")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : R=128, G=128, B=128  (hex=#808080, lum=128)")
_ImGui_CreateText("t_count", "User edits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueIntN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_black", "Black ( 0,  0,  0)")
_ImGui_CreateButton("btn_white", "White (255, 255, 255)")
_ImGui_CreateButton("btn_red",   "Red   (255,  0,  0)")
_ImGui_CreateButton("btn_grey",  "Grey  (128, 128, 128)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iEditCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("sl_rgb",    "_OnRgbChanged")
_ImGui_SetOnClick ("btn_black", "_OnBlack")
_ImGui_SetOnClick ("btn_white", "_OnWhite")
_ImGui_SetOnClick ("btn_red",   "_OnRed")
_ImGui_SetOnClick ("btn_grey",  "_OnGrey")
_ImGui_SetOnClick ("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnRgbChanged($sId)
    Local $aVal = _ImGui_GetValueIntN($sId, 3)
    If @error Or Not IsArray($aVal) Then Return
    $g_iEditCount += 1
    ; Rec. 601 luma approximation : 0.299 R + 0.587 G + 0.114 B
    Local $iLum = Round(0.299 * $aVal[0] + 0.587 * $aVal[1] + 0.114 * $aVal[2])
    _ImGui_SetText("t_read",  StringFormat("Read-back : R=%d, G=%d, B=%d  (hex=#%02X%02X%02X, lum=%d)", _
                                            $aVal[0], $aVal[1], $aVal[2], _
                                            $aVal[0], $aVal[1], $aVal[2], $iLum))
    _ImGui_SetText("t_count", "User edits : " & $g_iEditCount)
EndFunc

Func _OnBlack($sId)
    _ApplyPreset(0, 0, 0, "black")
EndFunc

Func _OnWhite($sId)
    _ApplyPreset(255, 255, 255, "white")
EndFunc

Func _OnRed($sId)
    _ApplyPreset(255, 0, 0, "red")
EndFunc

Func _OnGrey($sId)
    _ApplyPreset(128, 128, 128, "grey")
EndFunc

Func _ApplyPreset($iR, $iG, $iB, $sTag)
    Local $aNew[3] = [$iR, $iG, $iB]
    _ImGui_SetValueIntN("sl_rgb", $aNew)
    Local $iLum = Round(0.299 * $iR + 0.587 * $iG + 0.114 * $iB)
    _ImGui_SetText("t_read", StringFormat("Read-back : R=%d, G=%d, B=%d  (hex=#%02X%02X%02X, lum=%d, %s)", _
                                          $iR, $iG, $iB, $iR, $iG, $iB, $iLum, $sTag))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
