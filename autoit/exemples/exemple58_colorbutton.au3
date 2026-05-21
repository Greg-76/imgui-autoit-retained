#cs
================================================================================
 Example 58 : _ImGui_CreateColorButton
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateColorButton   Display-only clickable color swatch
   _ImGui_GetValueFloatN      Read the 4-component RGBA value
   _ImGui_SetValueFloatN      Set the 4-component RGBA value programmatically

 ColorButton is a CLICKABLE widget (inherits from ClickableWidget on
 the C++ side, NOT from a ValueWidget). Consequences :

   - Bind with _ImGui_SetOnClick, NOT _ImGui_SetOnChange. The latter
     will never fire on a ColorButton.
   - The user CANNOT edit the color through the swatch itself -- it is
     "display only" from their point of view. To make the color
     interactive, pair the ColorButton with a ColorEdit / ColorPicker
     and propagate state via OnChange + SetValueFloatN.
   - There is no "value-changed" latch on this widget ; the only event
     it raises is "clicked".

 The flag bitmask is still $ImGuiColorEditFlags_* (shared with all
 Color widgets). Useful values here :
     NoBorder         -> swatch without the dark outline
     NoDragDrop       -> disable drag-and-drop from the swatch
     NoTooltip        -> no hover tooltip with the RGBA breakdown
     AlphaPreviewHalf -> half-checkerboard preview to show alpha
     AlphaNoBg        -> remove the checkerboard entirely

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple58_colorbutton.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple58_colorbutton.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 58 : _ImGui_CreateColorButton", 640, 460) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateColorButton  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateColorButton($sId, $sLabel = "",
;                                       $fR = 1.0, $fG = 0.0,
;                                       $fB = 0.0, $fA = 1.0,
;                                       $iFlags = 0,
;                                       $fW = 0.0, $fH = 0.0)
;
;   Clickable swatch. $sLabel acts as the tooltip / accessibility
;   label (shown on hover unless NoTooltip is set). $fW / $fH let you
;   size the swatch -- 0 means "auto" (one line height).
;
;   Read / write the RGBA via _ImGui_GetValueFloatN / _ImGui_SetValueFloatN
;   with size 4.
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  four side-by-side swatches with different flag combos,
;                  plus a main mutable swatch that counts clicks and can be
;                  recolored via buttons.
; ==============================================================================
_ImGui_CreateText("t_title", "ColorButton demo  --  clickable swatches, OnClick (not OnChange)")
_ImGui_CreateText("t_hint",  "Hover any swatch to see the auto-generated tooltip. Click the bottom row.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_flags_hdr", "Same default RGBA shown with different flags :")
_ImGui_CreateColorButton("cb_default",    "Default",          0.30, 0.55, 0.95, 0.80, 0, 80, 32)
_ImGui_CreateColorButton("cb_noborder",   "NoBorder",         0.30, 0.55, 0.95, 0.80, $ImGuiColorEditFlags_NoBorder, 80, 32)
_ImGui_CreateColorButton("cb_alphahalf",  "AlphaPreviewHalf", 0.30, 0.55, 0.95, 0.80, $ImGuiColorEditFlags_AlphaPreviewHalf, 80, 32)
_ImGui_CreateColorButton("cb_nodragdrop", "NoDragDrop + NoTooltip", 0.30, 0.55, 0.95, 0.80, _
                          BitOR($ImGuiColorEditFlags_NoDragDrop, $ImGuiColorEditFlags_NoTooltip), 80, 32)
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_main_hdr", "Mutable ColorButton (click it -- counter goes up) :")
_ImGui_CreateColorButton("cb_main", "Click me", 0.5, 0.5, 0.5, 1.0, $ImGuiColorEditFlags_AlphaPreviewHalf, 160, 48)
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_read",  "Read-back : R=0.500, G=0.500, B=0.500, A=1.000  (hex=#808080FF)")
_ImGui_CreateText("t_count", "Click count : 0")
_ImGui_CreateSeparator("sep4")

_ImGui_CreateText("t_ctl_hdr", "Recolor the main swatch (SetValueFloatN, instant) :")
_ImGui_CreateButton("btn_red",   "Red    (1.0, 0.0, 0.0, 1.0)")
_ImGui_CreateButton("btn_green", "Green  (0.0, 1.0, 0.0, 1.0)")
_ImGui_CreateButton("btn_blue",  "Blue   (0.0, 0.0, 1.0, 1.0)")
_ImGui_CreateButton("btn_half",  "Half-alpha grey (0.5, 0.5, 0.5, 0.5)")
_ImGui_CreateSeparator("sep5")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iClickCount = 0


; --- Bind --------------------------------------------------------------------
; NOTE : OnClick, NOT OnChange. ColorButton is a ClickableWidget.
_ImGui_SetOnClick("cb_main",   "_OnSwatchClicked")
_ImGui_SetOnClick("btn_red",   "_OnRed")
_ImGui_SetOnClick("btn_green", "_OnGreen")
_ImGui_SetOnClick("btn_blue",  "_OnBlue")
_ImGui_SetOnClick("btn_half",  "_OnHalf")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnSwatchClicked($sId)
    $g_iClickCount += 1
    Local $aVal = _ImGui_GetValueFloatN($sId, 4)
    If @error Or Not IsArray($aVal) Then Return
    _UpdateReadout($aVal[0], $aVal[1], $aVal[2], $aVal[3])
    _ImGui_SetText("t_count", "Click count : " & $g_iClickCount)
EndFunc

Func _OnRed($sId)
    _ApplyPreset(1.0, 0.0, 0.0, 1.0)
EndFunc

Func _OnGreen($sId)
    _ApplyPreset(0.0, 1.0, 0.0, 1.0)
EndFunc

Func _OnBlue($sId)
    _ApplyPreset(0.0, 0.0, 1.0, 1.0)
EndFunc

Func _OnHalf($sId)
    _ApplyPreset(0.5, 0.5, 0.5, 0.5)
EndFunc

Func _ApplyPreset($fR, $fG, $fB, $fA)
    Local $aNew[4] = [$fR, $fG, $fB, $fA]
    _ImGui_SetValueFloatN("cb_main", $aNew)
    _UpdateReadout($fR, $fG, $fB, $fA)
EndFunc

Func _UpdateReadout($fR, $fG, $fB, $fA)
    Local $iR8 = Round($fR * 255.0), $iG8 = Round($fG * 255.0)
    Local $iB8 = Round($fB * 255.0), $iA8 = Round($fA * 255.0)
    _ImGui_SetText("t_read", StringFormat("Read-back : R=%.3f, G=%.3f, B=%.3f, A=%.3f  (hex=#%02X%02X%02X%02X)", _
                                          $fR, $fG, $fB, $fA, $iR8, $iG8, $iB8, $iA8))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
