#cs
================================================================================
 Example 167 : _ImGui_CreateImage
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateImage   Display-only Image widget rendering a previously
                        loaded texture (no click handling)

 Sizing model :
   * $fW = 0 AND $fH = 0   render at the texture's native size
   * $fW > 0, $fH > 0      stretch / squash to the given pixel size
                            (aspect ratio is NOT preserved -- compute it
                             yourself from GetTextureSize if you need it)
   * Setting one of them to 0 currently behaves like 0,0 (native)

 The texture must be loaded BEFORE the widget is created. Wrong tex_id
 (unknown / -1) renders a placeholder "[bad tex_id]" rectangle and a
 hover tooltip explaining the issue -- no crash.

 Borrowed widgets : LoadTexture + GetTextureSize (exemple166),
 SliderFloat, SameLine, Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple167_image.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple167_image.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 167 : _ImGui_CreateImage", 760, 700) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateImage  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateImage($sId, $iTexId, $fW = 0.0, $fH = 0.0)
;
;   $iTexId : tex_id returned by _ImGui_LoadTexture (exemple166).
;             Unknown ids render a placeholder rectangle (no crash).
;
;   $fW, $fH : pixel size. 0, 0 = native ; otherwise stretches the
;              texture to the requested rect. Preserving aspect ratio
;              is the script's job (compute from GetTextureSize).
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Load the demo texture
; ==============================================================================
Global $g_iW = 0, $g_iH = 0
Global $g_iTex = _ImGui_LoadTexture(@ScriptDir & "\images.png", $g_iW, $g_iH)

_ImGui_CreateText("t_title", "CreateImage demo  --  native / fixed 64x64 / stretched / aspect-preserving")
_ImGui_CreateText("t_status", StringFormat("tex_id = %d   native (W, H) = (%d, %d)   (-1 = file missing)", $g_iTex, $g_iW, $g_iH))
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; 1) Native size
; ==============================================================================
_ImGui_CreateText("t_n_hdr", "1) Native size  --  $fW = $fH = 0 :")
If $g_iTex >= 0 Then
    _ImGui_CreateImage("img_native", $g_iTex, 0, 0)
EndIf
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; 2) Fixed square 64x64
; ==============================================================================
_ImGui_CreateText("t_64_hdr", "2) Fixed 64 x 64  --  thumbnail / icon strip :")
If $g_iTex >= 0 Then
    _ImGui_CreateImage("img_64a", $g_iTex, 64, 64)
    _ImGui_CreateSameLine("sl_64a")
    _ImGui_CreateImage("img_64b", $g_iTex, 64, 64)
    _ImGui_CreateSameLine("sl_64b")
    _ImGui_CreateImage("img_64c", $g_iTex, 64, 64)
EndIf
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; 3) Stretched 320 x 80 (no aspect ratio preservation)
; ==============================================================================
_ImGui_CreateText("t_st_hdr", "3) Stretched 320 x 80  --  aspect ratio NOT preserved (texture is squashed) :")
If $g_iTex >= 0 Then
    _ImGui_CreateImage("img_stretch", $g_iTex, 320, 80)
EndIf
_ImGui_CreateSeparator("sep3")


; ==============================================================================
; 4) Aspect-preserving 200-wide  --  classic "fit width" pattern
; ==============================================================================
_ImGui_CreateText("t_ap_hdr", "4) Aspect-preserving 200 px wide  --  height computed from native ratio :")
If $g_iTex >= 0 Then
    Local $iTargetW = 200
    Local $iTargetH = ($g_iW > 0) ? Int($g_iH * $iTargetW / $g_iW) : 0
    _ImGui_CreateImage("img_apw", $g_iTex, $iTargetW, $iTargetH)
EndIf
_ImGui_CreateSeparator("sep4")


; ==============================================================================
; 5) Bad tex_id placeholder
; ==============================================================================
_ImGui_CreateText("t_bad_hdr", "5) Unknown tex_id 999  --  placeholder rectangle (no crash) :")
_ImGui_CreateImage("img_bad", 999, 80, 80)

_ImGui_CreateSeparator("sep5")
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
