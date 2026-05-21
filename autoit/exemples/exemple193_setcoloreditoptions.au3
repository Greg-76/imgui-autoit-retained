#cs
================================================================================
 Example 193 : _ImGui_SetColorEditOptions
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetColorEditOptions   Set the global default flags applied
                                to every ColorEdit / ColorPicker
                                CREATED AFTER the call

 CRITICAL trap : SetColorEditOptions is PRE-CREATION only. Calling it
 affects widgets created LATER ; existing ColorEdit / ColorPicker
 instances keep the defaults they had at creation time. Same trap
 class as :
   * "Settings caches apply at first Begin() only"  (exemple186)
   * Push/Pop strictness inconsistencies            (Style stack family)
   * Sibling-order-dependent markers               (Popup + Tooltip)
 -- silent no-op when called in the wrong order, no warning emitted.

 The wrapper docstring is explicit : "Typical use : call once at script
 init right after _ImGui_Init, before creating any color widgets."

 Demo layout : THREE ColorEdit4 widgets, created interleaved with TWO
 SetColorEditOptions calls, all at script startup so the timing is
 visible to the reader as straight-line code :

   1. Widget A   (no SetColorEditOptions yet -> ImGui's startup defaults)
   2. SetColorEditOptions(HSV | HueWheel | AlphaBar)
   3. Widget B   (HSV + HueWheel + AlphaBar)
   4. SetColorEditOptions(RGB | HueBar | NoAlpha)
   5. Widget C   (RGB + HueBar, NO alpha)

 All three widgets are wired with SetOnChange to mirror the picked
 color into the other two -- so the user can pick a color anywhere
 and see the SAME (R, G, B, A) rendered in three different display
 styles. Demonstrates that the difference is purely in the DEFAULT
 flags, not in the underlying value.

 Borrowed widgets : CreateColorEdit4 (exemple55) + GetValueFloatN /
 SetValueFloatN, Text + Separator, Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple193_setcoloreditoptions.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple193_setcoloreditoptions.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 193 : SetColorEditOptions", 820, 700) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetColorEditOptions  --  doc block
; ==============================================================================
; Signature : _ImGui_SetColorEditOptions($iFlags)
;
;   $iFlags : bitmask of $ImGuiColorEditFlags_* constants
;             (DisplayRGB / DisplayHSV / DisplayHex / Float / Uint8 /
;              PickerHueBar / PickerHueWheel / AlphaBar / NoAlpha / ...).
;
;   Return : True on success, False on failure (@error = 1, 2).
;
;   Out-of-range bits are silently ignored by ImGui (no error). The
;   "display format" and "picker style" groups are mutually exclusive
;   within each group ; passing two (e.g. DisplayRGB | DisplayHSV)
;   leaves ImGui to pick one (last bit wins, typically).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "SetColorEditOptions demo  --  PRE-CREATION-only trap class")
_ImGui_CreateText("t_hint",  "Three ColorEdit4 widgets, same color, three different default display flags.")
_ImGui_CreateText("t_hint2", "Pick any color in any widget : the other two mirror the value via SetOnChange.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Widget A  --  no SetColorEditOptions yet, gets ImGui's startup defaults
; ==============================================================================
_ImGui_CreateText("t_a_hdr", "Widget A  --  created BEFORE any SetColorEditOptions :")
_ImGui_CreateColorEdit4("ce_a", "A : startup defaults    ", 0.3, 0.7, 0.9, 1.0, 0)
_ImGui_CreateText("t_a_note",  "  Got ImGui's startup defaults (RGB + HueBar picker, no AlphaBar).")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; First SetColorEditOptions  --  HSV + HueWheel + AlphaBar
; ==============================================================================
Global Const $g_iFlagsHSV = BitOR($ImGuiColorEditFlags_DisplayHSV, _
                                   $ImGuiColorEditFlags_PickerHueWheel, _
                                   $ImGuiColorEditFlags_AlphaBar)
_ImGui_SetColorEditOptions($g_iFlagsHSV)


; ==============================================================================
; Widget B  --  inherits the HSV defaults from above
; ==============================================================================
_ImGui_CreateText("t_b_hdr", "Widget B  --  created AFTER SetColorEditOptions(HSV | HueWheel | AlphaBar) :")
_ImGui_CreateColorEdit4("ce_b", "B : HSV + HueWheel + AB", 0.3, 0.7, 0.9, 1.0, 0)
_ImGui_CreateText("t_b_note", "  Inherited the new defaults.")
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Second SetColorEditOptions  --  flip to RGB + HueBar + NoAlpha
; ==============================================================================
Global Const $g_iFlagsRGB = BitOR($ImGuiColorEditFlags_DisplayRGB, _
                                   $ImGuiColorEditFlags_PickerHueBar, _
                                   $ImGuiColorEditFlags_NoAlpha)
_ImGui_SetColorEditOptions($g_iFlagsRGB)


; ==============================================================================
; Widget C  --  inherits the RGB+NoAlpha defaults ; widgets A and B unchanged
; ==============================================================================
_ImGui_CreateText("t_c_hdr", "Widget C  --  created AFTER SetColorEditOptions(RGB | HueBar | NoAlpha) :")
_ImGui_CreateColorEdit4("ce_c", "C : RGB + HueBar + NoA  ", 0.3, 0.7, 0.9, 1.0, 0)
_ImGui_CreateText("t_c_note", "  Inherited the second-call defaults. A and B did NOT change.")
_ImGui_CreateSeparator("sep3")


_ImGui_CreateText("t_lesson", "Key takeaway : SetColorEditOptions affects only widgets created AFTER the call.")
_ImGui_CreateText("t_lesson2", "Calling it from inside a handler (mid-frame) is technically allowed, but never useful  --  any color widget you'd want it to apply to is already in the tree.")
_ImGui_CreateSeparator("sep4")


_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnChange("ce_a", "_OnColorChanged")
_ImGui_SetOnChange("ce_b", "_OnColorChanged")
_ImGui_SetOnChange("ce_c", "_OnColorChanged")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnColorChanged($sId)
    Local $aRGBA = _ImGui_GetValueFloatN($sId, 4)
    If Not IsArray($aRGBA) Then Return
    If $sId <> "ce_a" Then _ImGui_SetValueFloatN("ce_a", $aRGBA)
    If $sId <> "ce_b" Then _ImGui_SetValueFloatN("ce_b", $aRGBA)
    If $sId <> "ce_c" Then _ImGui_SetValueFloatN("ce_c", $aRGBA)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
