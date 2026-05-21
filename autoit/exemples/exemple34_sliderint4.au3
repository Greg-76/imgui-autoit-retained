#cs
================================================================================
 Example 34 : _ImGui_CreateSliderInt4
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateSliderInt4   Four-component int slider (single widget row)
   _ImGui_GetValueIntN       Read the 4-component vector
   _ImGui_SetValueIntN       Set the 4-component vector

 SliderInt4 packs four int sliders into a single row, all clamped to
 [$iMin, $iMax]. Typical use : integer RGBA (0..255), pixel rectangle
 (l, t, r, b), generic 4-channel counters.

 NOTE : for a proper RGBA editor with HEX, picker, alpha preview, use
 the Color family (ColorEdit4 / ColorPicker4). SliderInt4 with 0..255
 just shows the four numeric channels -- no preview swatch.

 Strict semantics : see exemple17_sliderint.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple34_sliderint4.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple34_sliderint4.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 34 : _ImGui_CreateSliderInt4", 660, 420) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSliderInt4  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSliderInt4($sId, $sLabel = "",
;                                      $iMin = 0, $iMax = 100,
;                                      $iD0 = 0, $iD1 = 0, $iD2 = 0, $iD3 = 0,
;                                      $sFormat = "%d")
;
;   Four integer slider handles on a single row, all clamped to
;   [$iMin, $iMax]. $iD0..3 are the initial values per component.
;
;   Read / write the quad as an AutoIt array of size 4 :
;     _ImGui_GetValueIntN($sId, 4)        -> [v0, v1, v2, v3]
;     _ImGui_SetValueIntN($sId, $aVals)   -> 1D array of size 4 ; no OnChange
;
;   Bind user edits with _ImGui_SetOnChange (IntVec4ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  integer RGBA quad (0..255), no color preview
; ==============================================================================
_ImGui_CreateText("t_title", "SliderInt4 demo  --  RGBA-as-int (0..255), four channels")
_ImGui_CreateText("t_hint",  "Four independent int sliders. For a real RGBA picker, see ColorEdit4 in the Color family.")
_ImGui_CreateSeparator("sep1")

; Range 0..255, defaults : opaque neutral grey (128, 128, 128, 255).
_ImGui_CreateSliderInt4("sl_rgba", "RGBA (r, g, b, a)", _
                        0, 255, _
                        128, 128, 128, 255, _
                        "%d")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : R=128, G=128, B=128, A=255  (hex=#808080FF)")
_ImGui_CreateText("t_count", "User edits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueIntN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_solid_white", "Solid white  (255, 255, 255, 255)")
_ImGui_CreateButton("btn_solid_black", "Solid black  ( 0,  0,  0, 255)")
_ImGui_CreateButton("btn_red_half",    "Red 50%% alpha (255,  0,  0, 128)")
_ImGui_CreateButton("btn_transparent", "Fully transparent (anything, ., ., 0)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",        "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iEditCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("sl_rgba",          "_OnRgbaChanged")
_ImGui_SetOnClick ("btn_solid_white",  "_OnSolidWhite")
_ImGui_SetOnClick ("btn_solid_black",  "_OnSolidBlack")
_ImGui_SetOnClick ("btn_red_half",     "_OnRedHalf")
_ImGui_SetOnClick ("btn_transparent",  "_OnTransparent")
_ImGui_SetOnClick ("btn_quit",         "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnRgbaChanged($sId)
    Local $aVal = _ImGui_GetValueIntN($sId, 4)
    If @error Or Not IsArray($aVal) Then Return
    $g_iEditCount += 1
    _ImGui_SetText("t_read",  StringFormat("Read-back : R=%d, G=%d, B=%d, A=%d  (hex=#%02X%02X%02X%02X)", _
                                            $aVal[0], $aVal[1], $aVal[2], $aVal[3], _
                                            $aVal[0], $aVal[1], $aVal[2], $aVal[3]))
    _ImGui_SetText("t_count", "User edits : " & $g_iEditCount)
EndFunc

Func _OnSolidWhite($sId)
    _ApplyPreset(255, 255, 255, 255, "solid white")
EndFunc

Func _OnSolidBlack($sId)
    _ApplyPreset(0, 0, 0, 255, "solid black")
EndFunc

Func _OnRedHalf($sId)
    _ApplyPreset(255, 0, 0, 128, "red 50% alpha")
EndFunc

Func _OnTransparent($sId)
    ; Keep current RGB, force A=0. Read current, then write back with A overridden.
    Local $aVal = _ImGui_GetValueIntN("sl_rgba", 4)
    If @error Or Not IsArray($aVal) Then Return
    _ApplyPreset($aVal[0], $aVal[1], $aVal[2], 0, "fully transparent")
EndFunc

Func _ApplyPreset($iR, $iG, $iB, $iA, $sTag)
    Local $aNew[4] = [$iR, $iG, $iB, $iA]
    _ImGui_SetValueIntN("sl_rgba", $aNew)
    _ImGui_SetText("t_read", StringFormat("Read-back : R=%d, G=%d, B=%d, A=%d  (hex=#%02X%02X%02X%02X, %s)", _
                                          $iR, $iG, $iB, $iA, $iR, $iG, $iB, $iA, $sTag))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
