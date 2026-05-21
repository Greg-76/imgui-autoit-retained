#cs
================================================================================
 Example 55 : _ImGui_CreateColorEdit4
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateColorEdit4   Compact RGBA color edit field (input + swatch)
   _ImGui_GetValueFloatN     Read the 4-component RGBA value
   _ImGui_SetValueFloatN     Set the 4-component RGBA value programmatically

 ColorEdit4 = ColorEdit3 + alpha channel. The swatch becomes
 half-opaque / half-checkerboard so the user can see the alpha effect.
 Alpha-specific flags are showcased here :
     AlphaBar         -> draws an extra vertical alpha slider in the picker
     AlphaPreviewHalf -> swatch shows half opaque, half alpha-blended
     AlphaNoBg        -> swatch has no background under the alpha
     AlphaOpaque      -> swatch always renders opaque, ignoring alpha
     NoAlpha          -> hide alpha entirely (degenerates into a ColorEdit3
                         visually, but the value vector is still 4 floats)

 Strict semantics : OnChange fires only on user edits.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple55_coloredit4.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple55_coloredit4.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 55 : _ImGui_CreateColorEdit4", 660, 580) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateColorEdit4  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateColorEdit4($sId, $sLabel = "",
;                                      $fR = 1.0, $fG = 1.0,
;                                      $fB = 1.0, $fA = 1.0,
;                                      $iFlags = 0)
;
;   Same as ColorEdit3 plus the alpha channel. Read / write via
;   _ImGui_GetValueFloatN / _ImGui_SetValueFloatN with size 4. Alpha
;   flags from $ImGuiColorEditFlags_* :
;     2     = NoAlpha
;     4096  = AlphaOpaque
;     8192  = AlphaNoBg
;     16384 = AlphaPreviewHalf
;     262144= AlphaBar (picker-only ; visible after clicking the swatch)
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  alpha presentation flags side by side + a mutable main edit
; ==============================================================================
_ImGui_CreateText("t_title", "ColorEdit4 demo  --  alpha presentation flags side by side")
_ImGui_CreateText("t_hint",  "Click any swatch to open the full picker (with AlphaBar visible where flagged).")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_flags_hdr", "Same default RGBA (0.20, 0.40, 0.80, 0.50) shown with different alpha flags :")
_ImGui_CreateColorEdit4("ce_def",     "Default flags",      0.20, 0.40, 0.80, 0.50, 0)
_ImGui_CreateColorEdit4("ce_bar",     "+ AlphaBar",          0.20, 0.40, 0.80, 0.50, $ImGuiColorEditFlags_AlphaBar)
_ImGui_CreateColorEdit4("ce_phalf",   "+ AlphaPreviewHalf",  0.20, 0.40, 0.80, 0.50, $ImGuiColorEditFlags_AlphaPreviewHalf)
_ImGui_CreateColorEdit4("ce_nobg",    "+ AlphaNoBg",         0.20, 0.40, 0.80, 0.50, $ImGuiColorEditFlags_AlphaNoBg)
_ImGui_CreateColorEdit4("ce_opaque",  "+ AlphaOpaque",       0.20, 0.40, 0.80, 0.50, $ImGuiColorEditFlags_AlphaOpaque)
_ImGui_CreateColorEdit4("ce_noalpha", "+ NoAlpha (alpha hidden)", 0.20, 0.40, 0.80, 0.50, $ImGuiColorEditFlags_NoAlpha)
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_main_hdr", "Mutable ColorEdit4 (AlphaBar + AlphaPreviewHalf) with readout + presets :")
_ImGui_CreateColorEdit4("ce_main", "Main color", 0.5, 0.5, 0.5, 1.0, _
                        BitOR($ImGuiColorEditFlags_AlphaBar, $ImGuiColorEditFlags_AlphaPreviewHalf))
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_read",  "Read-back : R=0.500, G=0.500, B=0.500, A=1.000  (hex=#808080FF)")
_ImGui_CreateText("t_count", "User edits : 0")
_ImGui_CreateSeparator("sep4")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueFloatN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_opaque",  "Opaque red   (1.0, 0.0, 0.0, 1.0)")
_ImGui_CreateButton("btn_half",    "Half-alpha   (1.0, 0.0, 0.0, 0.5)")
_ImGui_CreateButton("btn_clear",   "Transparent  (1.0, 0.0, 0.0, 0.0)")
_ImGui_CreateButton("btn_white",   "Opaque white (1.0, 1.0, 1.0, 1.0)")
_ImGui_CreateSeparator("sep5")
_ImGui_CreateButton("btn_quit",    "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iEditCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("ce_main",    "_OnColorChanged")
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
    _ApplyPreset(1.0, 0.0, 0.0, 0.0, "transparent red")
EndFunc

Func _OnWhite($sId)
    _ApplyPreset(1.0, 1.0, 1.0, 1.0, "opaque white")
EndFunc

Func _ApplyPreset($fR, $fG, $fB, $fA, $sTag)
    Local $aNew[4] = [$fR, $fG, $fB, $fA]
    _ImGui_SetValueFloatN("ce_main", $aNew)
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
