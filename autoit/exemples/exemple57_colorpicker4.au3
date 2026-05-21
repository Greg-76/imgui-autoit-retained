#cs
================================================================================
 Example 57 : _ImGui_CreateColorPicker4
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateColorPicker4   Full RGBA color picker
   _ImGui_GetValueFloatN       Read the 4-component RGBA value
   _ImGui_SetValueFloatN       Set the 4-component RGBA value programmatically

 ColorPicker4 = ColorPicker3 + alpha channel. The alpha gets its own
 horizontal slider near the bottom of the picker (when AlphaBar is
 set). Standard preview swatches show the result composited over a
 checkerboard so the alpha effect is visible.

 Flags : same $ImGuiColorEditFlags_* bitmask as the other Color
 widgets, with the alpha-relevant subset now meaningful :
     AlphaBar          -> dedicated horizontal alpha slider in picker
     AlphaPreviewHalf  -> preview shows half opaque, half alpha-blended
     AlphaNoBg         -> remove the alpha background (checkerboard)
     AlphaOpaque       -> preview ignores alpha
     NoAlpha           -> degenerate, alpha is hidden (rare here)

 Strict semantics : OnChange fires only on user picker drags.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple57_colorpicker4.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple57_colorpicker4.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 57 : _ImGui_CreateColorPicker4", 740, 760) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateColorPicker4  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateColorPicker4($sId, $sLabel = "",
;                                        $fR = 1.0, $fG = 1.0,
;                                        $fB = 1.0, $fA = 1.0,
;                                        $iFlags = 0)
;
;   Always-visible RGBA picker. Without AlphaBar the alpha channel is
;   still present in the value (and editable via the input fields) but
;   has no dedicated slider in the picker UI.
;
;   Read / write via _ImGui_GetValueFloatN / _ImGui_SetValueFloatN with
;   size 4. Bind OnChange.
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  HueBar + AlphaBar variant, HueWheel + AlphaBar variant,
;                   plus a main mutable picker.
; ==============================================================================
_ImGui_CreateText("t_title", "ColorPicker4 demo  --  HueBar + AlphaBar vs HueWheel + AlphaBar")
_ImGui_CreateText("t_hint",  "Drag the alpha bar to see the swatches go from opaque to transparent.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_a_hdr", "PickerHueBar + AlphaBar + AlphaPreviewHalf :")
_ImGui_CreateColorPicker4("cp_bar",   "Hue bar + alpha", 0.20, 0.65, 0.95, 0.60, _
                          BitOR(BitOR($ImGuiColorEditFlags_PickerHueBar, $ImGuiColorEditFlags_AlphaBar), _
                                $ImGuiColorEditFlags_AlphaPreviewHalf))
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_b_hdr", "PickerHueWheel + AlphaBar + NoSidePreview :")
_ImGui_CreateColorPicker4("cp_wheel", "Hue wheel + alpha", 0.20, 0.65, 0.95, 0.60, _
                          BitOR(BitOR($ImGuiColorEditFlags_PickerHueWheel, $ImGuiColorEditFlags_AlphaBar), _
                                $ImGuiColorEditFlags_NoSidePreview))
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_main_hdr", "Mutable picker (AlphaBar + AlphaPreviewHalf) with readout + presets :")
_ImGui_CreateColorPicker4("cp_main", "Main RGBA", 0.50, 0.50, 0.50, 1.00, _
                          BitOR($ImGuiColorEditFlags_AlphaBar, $ImGuiColorEditFlags_AlphaPreviewHalf))
_ImGui_CreateSeparator("sep4")

_ImGui_CreateText("t_read",  "Read-back : R=0.500, G=0.500, B=0.500, A=1.000  (hex=#808080FF)")
_ImGui_CreateText("t_count", "User edits : 0")
_ImGui_CreateSeparator("sep5")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueFloatN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_opaque",   "Opaque red   (1.0, 0.0, 0.0, 1.0)")
_ImGui_CreateButton("btn_half",     "Half-alpha   (1.0, 0.0, 0.0, 0.5)")
_ImGui_CreateButton("btn_clear",    "Transparent  (.,., 0.0)  (keep current RGB)")
_ImGui_CreateButton("btn_white",    "Opaque white (1.0, 1.0, 1.0, 1.0)")
_ImGui_CreateSeparator("sep6")
_ImGui_CreateButton("btn_quit",     "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iEditCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("cp_main",    "_OnColorChanged")
_ImGui_SetOnClick ("btn_opaque", "_OnOpaque")
_ImGui_SetOnClick ("btn_half",   "_OnHalf")
_ImGui_SetOnClick ("btn_clear",  "_OnClear")
_ImGui_SetOnClick ("btn_white",  "_OnWhite")
_ImGui_SetOnClick ("btn_quit",   "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnColorChanged($sId)
    Local $aVal = _ImGui_GetValueFloatN($sId, 4)
    If @error Or Not IsArray($aVal) Then Return
    $g_iEditCount += 1
    _UpdateReadout($aVal[0], $aVal[1], $aVal[2], $aVal[3], "")
    _ImGui_SetText("t_count", "User edits : " & $g_iEditCount)
EndFunc

Func _OnOpaque($sId)
    _ApplyPreset(1.0, 0.0, 0.0, 1.0, "opaque red")
EndFunc

Func _OnHalf($sId)
    _ApplyPreset(1.0, 0.0, 0.0, 0.5, "half-alpha red")
EndFunc

Func _OnClear($sId)
    ; Keep current RGB, force alpha=0 -- nice illustration of "modify just one
    ; channel" using the current value as starting point.
    Local $aVal = _ImGui_GetValueFloatN("cp_main", 4)
    If @error Or Not IsArray($aVal) Then Return
    _ApplyPreset($aVal[0], $aVal[1], $aVal[2], 0.0, "transparent (kept RGB)")
EndFunc

Func _OnWhite($sId)
    _ApplyPreset(1.0, 1.0, 1.0, 1.0, "opaque white")
EndFunc

Func _ApplyPreset($fR, $fG, $fB, $fA, $sTag)
    Local $aNew[4] = [$fR, $fG, $fB, $fA]
    _ImGui_SetValueFloatN("cp_main", $aNew)
    _UpdateReadout($fR, $fG, $fB, $fA, $sTag)
EndFunc

Func _UpdateReadout($fR, $fG, $fB, $fA, $sTag)
    Local $iR8 = Round($fR * 255.0), $iG8 = Round($fG * 255.0)
    Local $iB8 = Round($fB * 255.0), $iA8 = Round($fA * 255.0)
    Local $sSuffix = ($sTag = "") ? "" : (" (" & $sTag & ")")
    _ImGui_SetText("t_read", StringFormat("Read-back : R=%.3f, G=%.3f, B=%.3f, A=%.3f  (hex=#%02X%02X%02X%02X)%s", _
                                          $fR, $fG, $fB, $fA, $iR8, $iG8, $iB8, $iA8, $sSuffix))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
