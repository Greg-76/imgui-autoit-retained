#cs
================================================================================
 Example 59 : _ImGui_ColorU32ToFloat4
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_ColorU32ToFloat4   Decode a packed ImU32 into 4 floats [R, G, B, A]

 ImGui's "native" color encoding is a 32-bit unsigned integer where the
 four bytes are laid out as 0xAABBGGRR. This is the format expected by
 ImDrawList APIs (line/rect/text colors) and the format returned by
 ColorFloat4ToU32. _ImGui_ColorU32ToFloat4 decodes that integer into
 normalized [0..1] RGBA components.

 Byte-order reminder (most common pitfall) : the high byte holds Alpha,
 then Blue, then Green, then Red in the LOW byte. Writing 0xFF0000FF
 in hex literal therefore produces opaque RED, not opaque BLUE.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple59_colorconvert_u32_to_float4.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple59_colorconvert_u32_to_float4.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 59 : _ImGui_ColorU32ToFloat4", 640, 460) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_ColorU32ToFloat4  --  doc block
; ==============================================================================
; Signature : _ImGui_ColorU32ToFloat4($iU32)
;
;   Decodes a 32-bit packed color into a 4-element AutoIt array of
;   floats in [0..1].
;
;   Byte layout of $iU32 (low to high) : R, G, B, A
;   Hex literal layout (read left-to-right) : 0xAABBGGRR
;
;   Examples :
;     0xFF0000FF -> [1.0, 0.0, 0.0, 1.0]  (opaque red, A=FF)
;     0xFFFF0000 -> [0.0, 0.0, 1.0, 1.0]  (opaque blue, A=FF)
;     0x80808080 -> [0.5, 0.5, 0.5, 0.5]  (50%% grey, 50%% alpha)
;     0x00000000 -> [0.0, 0.0, 0.0, 0.0]  (fully transparent black)
;
;   Round-trip exact (mod float quantization) against
;   _ImGui_ColorFloat4ToU32 (covered in exemple60).
;
;   Return : array[4] = [R, G, B, A] on success.
;            0 with @error set (1 = DLL not loaded, 2 = DllCall failed,
;            3 = DLL status non-zero).


; ==============================================================================
; Demo widgets  --  four hard-coded U32 inputs decoded into RGBA + swatch
; ==============================================================================
_ImGui_CreateText("t_title", "ColorU32ToFloat4 demo  --  decode packed ImU32 into RGBA")
_ImGui_CreateText("t_hint",  "Each row shows the input hex constant, the decoded floats, and a swatch built from those floats.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_layout_hdr", "Reminder : 0x" & "AABBGGRR" & "  --  AA=alpha (high byte), RR=red (low byte)")
_ImGui_CreateSeparator("sep2")

; Decode each constant ONCE up front, then build a ColorButton swatch from the
; decoded floats. The Text labels show the math explicitly.
Global $g_aRed   = _ImGui_ColorU32ToFloat4(0xFF0000FF)   ; A=FF, B=00, G=00, R=FF  -> red
Global $g_aBlue  = _ImGui_ColorU32ToFloat4(0xFFFF0000)   ; A=FF, B=FF, G=00, R=00  -> blue
Global $g_aHalf  = _ImGui_ColorU32ToFloat4(0x80808080)   ; A=80, B=80, G=80, R=80  -> 50%% grey 50%% alpha
Global $g_aZero  = _ImGui_ColorU32ToFloat4(0x00000000)   ; all zero                -> transparent black

_ImGui_CreateText("t_red_lbl",  _FormatRow("0xFF0000FF", $g_aRed))
_ImGui_CreateColorButton("cb_red",  "Decoded red",   $g_aRed[0],  $g_aRed[1],  $g_aRed[2],  $g_aRed[3],  $ImGuiColorEditFlags_AlphaPreviewHalf, 100, 24)

_ImGui_CreateText("t_blue_lbl", _FormatRow("0xFFFF0000", $g_aBlue))
_ImGui_CreateColorButton("cb_blue", "Decoded blue",  $g_aBlue[0], $g_aBlue[1], $g_aBlue[2], $g_aBlue[3], $ImGuiColorEditFlags_AlphaPreviewHalf, 100, 24)

_ImGui_CreateText("t_half_lbl", _FormatRow("0x80808080", $g_aHalf))
_ImGui_CreateColorButton("cb_half", "Decoded half",  $g_aHalf[0], $g_aHalf[1], $g_aHalf[2], $g_aHalf[3], $ImGuiColorEditFlags_AlphaPreviewHalf, 100, 24)

_ImGui_CreateText("t_zero_lbl", _FormatRow("0x00000000", $g_aZero))
_ImGui_CreateColorButton("cb_zero", "Decoded zero",  $g_aZero[0], $g_aZero[1], $g_aZero[2], $g_aZero[3], $ImGuiColorEditFlags_AlphaPreviewHalf, 100, 24)

_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Helpers + handlers -------------------------------------------------------

; Format one row of human-readable "0x12345678  ->  R=.., G=.., B=.., A=..".
Func _FormatRow($sHex, $aRgba)
    Return StringFormat("%s  ->  R=%.3f, G=%.3f, B=%.3f, A=%.3f", _
                        $sHex, $aRgba[0], $aRgba[1], $aRgba[2], $aRgba[3])
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
