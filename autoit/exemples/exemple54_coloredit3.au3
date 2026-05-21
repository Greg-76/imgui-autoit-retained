#cs
================================================================================
 Example 54 : _ImGui_CreateColorEdit3
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateColorEdit3   Compact RGB color edit field (input + swatch)
   _ImGui_GetValueFloatN     Read the 3-component RGB value
   _ImGui_SetValueFloatN     Set the 3-component RGB value programmatically

 ColorEdit3 is the "small" RGB editor : a row of three input fields
 ($r, $g, $b) plus a preview swatch. Clicking the swatch opens a full
 ColorPicker3 (unless NoPicker is set). The right-click context menu
 lets the user switch display modes at runtime.

 Flags ($ImGuiColorEditFlags_*) are a bitmask shared by ALL four Color
 widgets (ColorEdit3/4, ColorPicker3/4) -- learn them once, reuse
 everywhere. This file showcases the three Display* values side by
 side : DisplayRGB / DisplayHSV / DisplayHex.

 Strict semantics : OnChange fires only on user edits. Programmatic
 SetValueFloatN never re-fires it.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple54_coloredit3.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple54_coloredit3.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 54 : _ImGui_CreateColorEdit3", 640, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateColorEdit3  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateColorEdit3($sId, $sLabel = "",
;                                      $fR = 1.0, $fG = 1.0, $fB = 1.0,
;                                      $iFlags = 0)
;
;   Compact RGB editor. Components are normalised floats in [0.0, 1.0].
;
;   $iFlags : bitmask of $ImGuiColorEditFlags_*. Useful values for an
;   RGB editor :
;     0   = $ImGuiColorEditFlags_None             (default, RGB display)
;     2   = $ImGuiColorEditFlags_NoAlpha          (no effect on ColorEdit3)
;     4   = $ImGuiColorEditFlags_NoPicker         (clicking the swatch
;                                                  does NOT open a picker)
;     32  = $ImGuiColorEditFlags_NoInputs         (swatch only)
;     128 = $ImGuiColorEditFlags_NoLabel
;     262144  = $ImGuiColorEditFlags_AlphaBar     (n/a on RGB-only widget)
;     1048576 = $ImGuiColorEditFlags_DisplayRGB
;     2097152 = $ImGuiColorEditFlags_DisplayHSV
;     4194304 = $ImGuiColorEditFlags_DisplayHex
;     8388608 = $ImGuiColorEditFlags_Uint8        (display 0..255 instead of 0.0..1.0)
;
;   Read / write via _ImGui_GetValueFloatN / _ImGui_SetValueFloatN with
;   size 3. Bind OnChange to react to user edits.
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  three side-by-side editors with different Display* flags,
;                   plus a main mutable editor with OnChange + presets.
; ==============================================================================
_ImGui_CreateText("t_title", "ColorEdit3 demo  --  display modes RGB / HSV / Hex + presets")
_ImGui_CreateText("t_hint",  "Right-click any widget to see all the options ImGui exposes natively. Edit the bottom one and watch the readout.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_modes_hdr", "Same default (0.30, 0.65, 0.95) shown in three different display modes :")
_ImGui_CreateColorEdit3("ce_rgb", "DisplayRGB", 0.30, 0.65, 0.95, $ImGuiColorEditFlags_DisplayRGB)
_ImGui_CreateColorEdit3("ce_hsv", "DisplayHSV", 0.30, 0.65, 0.95, $ImGuiColorEditFlags_DisplayHSV)
_ImGui_CreateColorEdit3("ce_hex", "DisplayHex", 0.30, 0.65, 0.95, $ImGuiColorEditFlags_DisplayHex)
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_main_hdr", "Mutable ColorEdit3 (default flags = 0) with live readout + presets :")
_ImGui_CreateColorEdit3("ce_main", "Main color", 0.5, 0.5, 0.5, 0)
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_read",  "Read-back : R=0.500, G=0.500, B=0.500  (hex=#808080, lum=0.500)")
_ImGui_CreateText("t_count", "User edits : 0")
_ImGui_CreateSeparator("sep4")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueFloatN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_red",   "Pure red   (1.0, 0.0, 0.0)")
_ImGui_CreateButton("btn_green", "Pure green (0.0, 1.0, 0.0)")
_ImGui_CreateButton("btn_blue",  "Pure blue  (0.0, 0.0, 1.0)")
_ImGui_CreateButton("btn_grey",  "Grey       (0.5, 0.5, 0.5)")
_ImGui_CreateSeparator("sep5")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iEditCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("ce_main",  "_OnColorChanged")
_ImGui_SetOnClick ("btn_red",   "_OnRed")
_ImGui_SetOnClick ("btn_green", "_OnGreen")
_ImGui_SetOnClick ("btn_blue",  "_OnBlue")
_ImGui_SetOnClick ("btn_grey",  "_OnGrey")
_ImGui_SetOnClick ("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnColorChanged($sId)
    Local $aVal = _ImGui_GetValueFloatN($sId, 3)
    If @error Or Not IsArray($aVal) Then Return
    $g_iEditCount += 1
    _UpdateReadout($aVal[0], $aVal[1], $aVal[2], "")
    _ImGui_SetText("t_count", "User edits : " & $g_iEditCount)
EndFunc

Func _OnRed($sId)
    _ApplyPreset(1.0, 0.0, 0.0, "pure red")
EndFunc

Func _OnGreen($sId)
    _ApplyPreset(0.0, 1.0, 0.0, "pure green")
EndFunc

Func _OnBlue($sId)
    _ApplyPreset(0.0, 0.0, 1.0, "pure blue")
EndFunc

Func _OnGrey($sId)
    _ApplyPreset(0.5, 0.5, 0.5, "grey")
EndFunc

Func _ApplyPreset($fR, $fG, $fB, $sTag)
    Local $aNew[3] = [$fR, $fG, $fB]
    _ImGui_SetValueFloatN("ce_main", $aNew)
    _UpdateReadout($fR, $fG, $fB, $sTag)
EndFunc

Func _UpdateReadout($fR, $fG, $fB, $sTag)
    Local $iR8 = Round($fR * 255.0), $iG8 = Round($fG * 255.0), $iB8 = Round($fB * 255.0)
    ; Rec. 601 luma approximation in normalized [0, 1] :
    Local $fLum = 0.299 * $fR + 0.587 * $fG + 0.114 * $fB
    Local $sSuffix = ($sTag = "") ? "" : (" (" & $sTag & ")")
    _ImGui_SetText("t_read", StringFormat("Read-back : R=%.3f, G=%.3f, B=%.3f  (hex=#%02X%02X%02X, lum=%.3f)%s", _
                                          $fR, $fG, $fB, $iR8, $iG8, $iB8, $fLum, $sSuffix))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
