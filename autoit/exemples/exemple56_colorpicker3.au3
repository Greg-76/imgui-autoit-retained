#cs
================================================================================
 Example 56 : _ImGui_CreateColorPicker3
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateColorPicker3   Full RGB color picker (square + hue selector)
   _ImGui_GetValueFloatN       Read the 3-component RGB value
   _ImGui_SetValueFloatN       Set the 3-component RGB value programmatically

 ColorPicker3 is the BIG color editor : a saturation/value square plus
 a hue selector (bar or wheel). It always shows the picker UI ; if you
 want the compact swatch+inputs editor, use ColorEdit3 instead.

 Key flags ($ImGuiColorEditFlags_*) :
     PickerHueBar     -> the default thin vertical hue bar
     PickerHueWheel   -> circular hue wheel (more visual, fewer pixels)
     NoSidePreview    -> hide the side swatch (small + saved colors)
     NoSmallPreview   -> hide the small live preview next to the label
     NoLabel          -> hide the label entirely
     DisplayRGB / DisplayHSV / DisplayHex -- same as ColorEdit3

 Strict semantics : OnChange fires only on user interaction with the
 picker. Programmatic SetValueFloatN never re-fires it.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple56_colorpicker3.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple56_colorpicker3.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 56 : _ImGui_CreateColorPicker3", 720, 720) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateColorPicker3  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateColorPicker3($sId, $sLabel = "",
;                                        $fR = 1.0, $fG = 1.0, $fB = 1.0,
;                                        $iFlags = 0)
;
;   Always-visible RGB picker. Drag inside the saturation/value square
;   and the hue selector to pick. Right-click shows the runtime options
;   menu (display mode, input mode, picker style, ...).
;
;   Read / write via _ImGui_GetValueFloatN / _ImGui_SetValueFloatN with
;   size 3. Bind OnChange.
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  HueBar variant on the left, HueWheel variant on the right
;                   (well, stacked here because ImGui's default layout is
;                   vertical), plus a main mutable picker with presets.
; ==============================================================================
_ImGui_CreateText("t_title", "ColorPicker3 demo  --  HueBar vs HueWheel + mutable picker")
_ImGui_CreateText("t_hint",  "Drag inside any picker. Right-click for the runtime options menu.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_a_hdr", "PickerHueBar (default style) :")
_ImGui_CreateColorPicker3("cp_bar",   "Hue bar",   0.20, 0.65, 0.95, $ImGuiColorEditFlags_PickerHueBar)
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_b_hdr", "PickerHueWheel + NoSidePreview (more compact) :")
_ImGui_CreateColorPicker3("cp_wheel", "Hue wheel", 0.20, 0.65, 0.95, _
                          BitOR($ImGuiColorEditFlags_PickerHueWheel, $ImGuiColorEditFlags_NoSidePreview))
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_main_hdr", "Mutable picker (default flags) with readout + presets :")
_ImGui_CreateColorPicker3("cp_main", "Main color", 0.50, 0.50, 0.50, 0)
_ImGui_CreateSeparator("sep4")

_ImGui_CreateText("t_read",  "Read-back : R=0.500, G=0.500, B=0.500  (hex=#808080)")
_ImGui_CreateText("t_count", "User edits : 0")
_ImGui_CreateSeparator("sep5")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueFloatN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_red",   "Pure red   (1.0, 0.0, 0.0)")
_ImGui_CreateButton("btn_cyan",  "Cyan       (0.0, 1.0, 1.0)")
_ImGui_CreateButton("btn_purple","Purple     (0.5, 0.0, 0.5)")
_ImGui_CreateButton("btn_white", "White      (1.0, 1.0, 1.0)")
_ImGui_CreateSeparator("sep6")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iEditCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("cp_main",   "_OnColorChanged")
_ImGui_SetOnClick ("btn_red",    "_OnRed")
_ImGui_SetOnClick ("btn_cyan",   "_OnCyan")
_ImGui_SetOnClick ("btn_purple", "_OnPurple")
_ImGui_SetOnClick ("btn_white",  "_OnWhite")
_ImGui_SetOnClick ("btn_quit",   "_OnQuit")


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

Func _OnCyan($sId)
    _ApplyPreset(0.0, 1.0, 1.0, "cyan")
EndFunc

Func _OnPurple($sId)
    _ApplyPreset(0.5, 0.0, 0.5, "purple")
EndFunc

Func _OnWhite($sId)
    _ApplyPreset(1.0, 1.0, 1.0, "white")
EndFunc

Func _ApplyPreset($fR, $fG, $fB, $sTag)
    Local $aNew[3] = [$fR, $fG, $fB]
    _ImGui_SetValueFloatN("cp_main", $aNew)
    _UpdateReadout($fR, $fG, $fB, $sTag)
EndFunc

Func _UpdateReadout($fR, $fG, $fB, $sTag)
    Local $iR8 = Round($fR * 255.0), $iG8 = Round($fG * 255.0), $iB8 = Round($fB * 255.0)
    Local $sSuffix = ($sTag = "") ? "" : (" (" & $sTag & ")")
    _ImGui_SetText("t_read", StringFormat("Read-back : R=%.3f, G=%.3f, B=%.3f  (hex=#%02X%02X%02X)%s", _
                                          $fR, $fG, $fB, $iR8, $iG8, $iB8, $sSuffix))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
