#cs
================================================================================
 Example 61 : _ImGui_ColorRGBtoHSV + _ImGui_ColorHSVtoRGB
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster -- the natural
 demo of either one is a round-trip via the other) :

   _ImGui_ColorRGBtoHSV   Convert RGB -> HSV, all components in [0..1]
   _ImGui_ColorHSVtoRGB   Convert HSV -> RGB, all components in [0..1]

 Both directions are pure math wrappers around ImGui's own helpers.
 Useful for : palette generation, hue rotation, programmatic tinting,
 saturation/value adjustments on existing colors.

 HSV convention here :
     H (hue)        in [0..1] (0.0 = 0 deg red, 0.33 = 120 deg green,
                    0.67 = 240 deg blue, 1.0 wraps back to red)
     S (saturation) in [0..1] (0 = grey, 1 = pure color)
     V (value)      in [0..1] (0 = black, 1 = max brightness)

 Round-trip note : RGBtoHSV(HSVtoRGB(...)) is the identity for non-grey
 inputs. Pure grey (S = 0) collapses to a single point in HSV -- the
 hue becomes undefined and may not be preserved exactly.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple61_colorconvert_rgb_hsv.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple61_colorconvert_rgb_hsv.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 61 : _ImGui_ColorRGBtoHSV + _ImGui_ColorHSVtoRGB", 680, 560) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_ColorRGBtoHSV  --  doc block
; ==============================================================================
; Signature : _ImGui_ColorRGBtoHSV($fR, $fG, $fB)
;
;   All components in [0..1]. Returns array[3] = [H, S, V].
;   Return 0 + @error on failure (1 = DLL not loaded, 2 = DllCall failed,
;   3 = DLL status non-zero).
;
; ==============================================================================
; _ImGui_ColorHSVtoRGB  --  doc block
; ==============================================================================
; Signature : _ImGui_ColorHSVtoRGB($fH, $fS, $fV)
;
;   All components in [0..1]. Returns array[3] = [R, G, B].
;   Same error model.


; ==============================================================================
; Demo widgets  --  edit RGB, see HSV ; edit HSV (sliders), see RGB ;
;                  hue-rotation demo at the bottom showing both directions.
; ==============================================================================
_ImGui_CreateText("t_title", "RGB <-> HSV demo  --  round-trip + hue rotation")
_ImGui_CreateText("t_hint",  "Edit the source ColorEdit3. The HSV readout below is recomputed via RGBtoHSV.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_src_hdr", "Source color (RGB) :")
_ImGui_CreateColorEdit3("ce_src", "Source RGB", 0.20, 0.70, 0.95, 0)
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_hsv_hdr", "Decoded HSV (RGBtoHSV) :")
_ImGui_CreateText("t_hsv",     "H=0.000, S=0.000, V=0.000  (H_deg=0.0)")
_ImGui_CreateText("t_back_hdr","Round-trip back to RGB (HSVtoRGB) :")
_ImGui_CreateText("t_back",    "R=0.000, G=0.000, B=0.000  (|diff vs source| = 0.000)")
_ImGui_CreateColorButton("cb_rt", "Round-trip swatch", 0.0, 0.0, 0.0, 1.0, 0, 200, 32)
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_rot_hdr", "Hue rotation example (RGBtoHSV -> rotate H -> HSVtoRGB) :")
_ImGui_CreateSliderInt("sl_rot", "Rotation (deg)", -180, 180, 0, "%d deg")
_ImGui_CreateText("t_rot_out", "Rotated RGB : R=0.000, G=0.000, B=0.000  (H_rotated_deg=0.0)")
_ImGui_CreateColorButton("cb_rot", "Rotated swatch", 0.0, 0.0, 0.0, 1.0, 0, 200, 32)
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("ce_src", "_OnSrcChanged")
_ImGui_SetOnChange("sl_rot", "_OnRotChanged")
_ImGui_SetOnClick ("btn_quit","_OnQuit")

; Seed all readouts from the initial values.
_RefreshAll()


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers + helpers -------------------------------------------------------

Func _OnSrcChanged($sId)
    _RefreshAll()
EndFunc

Func _OnRotChanged($sId)
    _RefreshAll()
EndFunc

Func _RefreshAll()
    ; --- Read the source RGB ---
    Local $aRgb = _ImGui_GetValueFloatN("ce_src", 3)
    If @error Or Not IsArray($aRgb) Then Return
    Local $fR = $aRgb[0], $fG = $aRgb[1], $fB = $aRgb[2]

    ; --- RGB -> HSV ---
    Local $aHsv = _ImGui_ColorRGBtoHSV($fR, $fG, $fB)
    If @error Or Not IsArray($aHsv) Then Return
    Local $fH = $aHsv[0], $fS = $aHsv[1], $fV = $aHsv[2]
    _ImGui_SetText("t_hsv", StringFormat("H=%.3f, S=%.3f, V=%.3f  (H_deg=%.1f)", _
                                          $fH, $fS, $fV, $fH * 360.0))

    ; --- HSV -> RGB (round-trip back) ---
    Local $aBack = _ImGui_ColorHSVtoRGB($fH, $fS, $fV)
    If @error Or Not IsArray($aBack) Then Return
    Local $fDiff = Sqrt( ($aBack[0]-$fR)^2 + ($aBack[1]-$fG)^2 + ($aBack[2]-$fB)^2 )
    _ImGui_SetText("t_back", StringFormat("R=%.3f, G=%.3f, B=%.3f  (|diff vs source| = %.4f)", _
                                           $aBack[0], $aBack[1], $aBack[2], $fDiff))
    Local $aRtSwatch[4] = [$aBack[0], $aBack[1], $aBack[2], 1.0]
    _ImGui_SetValueFloatN("cb_rt", $aRtSwatch)

    ; --- Hue rotation : rotate H by the slider value, convert back, display ---
    Local $iRotDeg = _ImGui_GetValueInt("sl_rot")
    Local $fHrot = $fH + ($iRotDeg / 360.0)
    ; Wrap to [0..1).
    While $fHrot >= 1.0
        $fHrot -= 1.0
    WEnd
    While $fHrot < 0.0
        $fHrot += 1.0
    WEnd
    Local $aRot = _ImGui_ColorHSVtoRGB($fHrot, $fS, $fV)
    If @error Or Not IsArray($aRot) Then Return
    _ImGui_SetText("t_rot_out", StringFormat("Rotated RGB : R=%.3f, G=%.3f, B=%.3f  (H_rotated_deg=%.1f)", _
                                              $aRot[0], $aRot[1], $aRot[2], $fHrot * 360.0))
    Local $aRotSwatch[4] = [$aRot[0], $aRot[1], $aRot[2], 1.0]
    _ImGui_SetValueFloatN("cb_rot", $aRotSwatch)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
