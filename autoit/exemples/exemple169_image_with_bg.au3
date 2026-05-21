#cs
================================================================================
 Example 169 : _ImGui_CreateImageWithBg
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateImageWithBg   Image widget with a background color drawn
                              UNDER the texture (visible through
                              transparent pixels) + a tint color
                              multiplied per-pixel

 The two extras vs plain CreateImage (exemple167) :
   * Background : drawn BEFORE the texture, visible only where the
                  texture has alpha < 1.0. Default (0,0,0,0) = fully
                  transparent = same look as plain CreateImage.
   * Tint       : multiplied per-pixel with the texture. Default
                  (1,1,1,1) = identity = no tint. Useful for grey-
                  out / colorize / highlight effects.

 All color components are in [0.0, 1.0].

 Demo : the same texture rendered 5 ways side by side -- baseline,
 white background, red background, grey-out tint, red tint.

 Borrowed widgets : LoadTexture (exemple166), SameLine, Text +
 Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple169_image_with_bg.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple169_image_with_bg.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 169 : _ImGui_CreateImageWithBg", 760, 460) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateImageWithBg  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateImageWithBg($sId, $iTexId, $fW, $fH,
;                                       $fBgR=0, $fBgG=0, $fBgB=0, $fBgA=0,
;                                       $fTintR=1, $fTintG=1, $fTintB=1, $fTintA=1)
;
;   Background : drawn UNDER the texture ; visible through alpha < 1
;                pixels. Default (0,0,0,0) = transparent.
;   Tint       : multiplied per-pixel with the texture. Default
;                (1,1,1,1) = identity.
;
;   All components in [0.0, 1.0].
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Load the demo texture
; ==============================================================================
Global $g_iW = 0, $g_iH = 0
Global $g_iTex = _ImGui_LoadTexture(@ScriptDir & "\images.png", $g_iW, $g_iH)

_ImGui_CreateText("t_title", "CreateImageWithBg  --  5 variants of the same texture : bg + tint combos")
_ImGui_CreateText("t_status", StringFormat("tex_id = %d   native (W, H) = (%d, %d)", $g_iTex, $g_iW, $g_iH))
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Five variants in a row
; ==============================================================================
_ImGui_CreateText("t_row_hdr", "Each thumbnail is 80x80. Hover any to confirm interactivity is purely display.")
If $g_iTex >= 0 Then
    ; 1) Default bg + default tint = same as plain CreateImage
    _ImGui_CreateImageWithBg("img_default", $g_iTex, 80, 80)
    _ImGui_CreateSameLine("sl1")

    ; 2) White bg (fully opaque) -- visible only where texture has alpha
    _ImGui_CreateImageWithBg("img_bg_white", $g_iTex, 80, 80, _
                              1.0, 1.0, 1.0, 1.0, _
                              1.0, 1.0, 1.0, 1.0)
    _ImGui_CreateSameLine("sl2")

    ; 3) Red bg -- same alpha-visibility, just red
    _ImGui_CreateImageWithBg("img_bg_red", $g_iTex, 80, 80, _
                              0.85, 0.15, 0.15, 1.0, _
                              1.0,  1.0,  1.0,  1.0)
    _ImGui_CreateSameLine("sl3")

    ; 4) Grey-out tint -- multiply RGB by 0.5 (darker), alpha 1.0
    _ImGui_CreateImageWithBg("img_tint_grey", $g_iTex, 80, 80, _
                              0.0, 0.0, 0.0, 0.0, _
                              0.5, 0.5, 0.5, 1.0)
    _ImGui_CreateSameLine("sl4")

    ; 5) Red tint -- multiply RGB by (1.0, 0.3, 0.3) for a red wash
    _ImGui_CreateImageWithBg("img_tint_red", $g_iTex, 80, 80, _
                              0.0, 0.0, 0.0, 0.0, _
                              1.0, 0.3, 0.3, 1.0)
EndIf

_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_legend", "Left to right :  baseline  --  white bg  --  red bg  --  grey-out tint  --  red tint")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
