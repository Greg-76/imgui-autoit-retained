#cs
================================================================================
 Example 60 : _ImGui_ColorFloat4ToU32
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_ColorFloat4ToU32   Encode 4 floats [R, G, B, A] into a packed ImU32

 The inverse of _ImGui_ColorU32ToFloat4 (exemple59). Encodes four
 normalised [0..1] components into a 32-bit unsigned integer with the
 ImGui-native byte layout : 0xAABBGGRR.

 Use case : feed the resulting U32 to any ImGui API that expects packed
 colors (ImDrawList line/rect/text, table cell background via
 _ImGui_CreateTableSetBgColor, etc.).

 Round-trip exact (mod float quantization) against ColorU32ToFloat4.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple60_colorconvert_float4_to_u32.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple60_colorconvert_float4_to_u32.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 60 : _ImGui_ColorFloat4ToU32", 640, 460) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_ColorFloat4ToU32  --  doc block
; ==============================================================================
; Signature : _ImGui_ColorFloat4ToU32($fR, $fG, $fB, $fA)
;
;   Components are normalised floats in [0.0, 1.0]. Out-of-range inputs
;   are NOT clamped by the wrapper -- ImGui itself maps any IEEE-754
;   value via "value * 255" with overflow wrap. Clamp on the script
;   side if your inputs may exceed [0..1].
;
;   Output layout (high to low byte) : Alpha, Blue, Green, Red. The
;   hex string "0x{AA}{BB}{GG}{RR}" reads in that order.
;
;   Examples :
;     (1, 0, 0, 1) -> 0xFF0000FF  (opaque red ; AA=FF, BB=00, GG=00, RR=FF)
;     (0, 0, 1, 1) -> 0xFFFF0000  (opaque blue)
;     (0.5, 0.5, 0.5, 0.5) -> 0x80808080
;
;   Return : the packed U32 on success. 0 with @error set on failure
;            (1 = DLL not loaded, 2 = DllCall failed).


; ==============================================================================
; Demo widgets  --  interactive ColorEdit4 drives the conversion live
; ==============================================================================
_ImGui_CreateText("t_title", "ColorFloat4ToU32 demo  --  interactive encoding of an RGBA pick into ImU32")
_ImGui_CreateText("t_hint",  "Edit the color below. The encoded U32 is recomputed on every OnChange.")
_ImGui_CreateSeparator("sep1")

; A ColorEdit4 with AlphaBar gives the user every control they need.
_ImGui_CreateColorEdit4("ce_src", "Source RGBA", 0.30, 0.55, 0.95, 0.80, $ImGuiColorEditFlags_AlphaBar)
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_decoded",  "Read-back : R=0.300, G=0.549, B=0.949, A=0.800")
_ImGui_CreateText("t_encoded",  "Encoded U32 : 0x00000000  (decimal : 0)")
_ImGui_CreateText("t_breakdown","Byte breakdown : AA=00, BB=00, GG=00, RR=00")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueFloatN on the source, fires OnChange? -- no, strict) :")
_ImGui_CreateButton("btn_red",       "Set source to opaque red")
_ImGui_CreateButton("btn_blue_half", "Set source to half-alpha blue")
_ImGui_CreateButton("btn_white",     "Set source to opaque white")
_ImGui_CreateButton("btn_clear",     "Set source to transparent black")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",      "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("ce_src",       "_OnColorChanged")
_ImGui_SetOnClick ("btn_red",      "_OnRed")
_ImGui_SetOnClick ("btn_blue_half","_OnBlueHalf")
_ImGui_SetOnClick ("btn_white",    "_OnWhite")
_ImGui_SetOnClick ("btn_clear",    "_OnClear")
_ImGui_SetOnClick ("btn_quit",     "_OnQuit")

; Seed the readout with the actual initial color so the user can see what's there.
_RefreshReadout(0.30, 0.55, 0.95, 0.80)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnColorChanged($sId)
    Local $aVal = _ImGui_GetValueFloatN($sId, 4)
    If @error Or Not IsArray($aVal) Then Return
    _RefreshReadout($aVal[0], $aVal[1], $aVal[2], $aVal[3])
EndFunc

Func _OnRed($sId)
    _ApplyPreset(1.0, 0.0, 0.0, 1.0)
EndFunc

Func _OnBlueHalf($sId)
    _ApplyPreset(0.0, 0.0, 1.0, 0.5)
EndFunc

Func _OnWhite($sId)
    _ApplyPreset(1.0, 1.0, 1.0, 1.0)
EndFunc

Func _OnClear($sId)
    _ApplyPreset(0.0, 0.0, 0.0, 0.0)
EndFunc

Func _ApplyPreset($fR, $fG, $fB, $fA)
    Local $aNew[4] = [$fR, $fG, $fB, $fA]
    _ImGui_SetValueFloatN("ce_src", $aNew)
    _RefreshReadout($fR, $fG, $fB, $fA)
EndFunc

Func _RefreshReadout($fR, $fG, $fB, $fA)
    Local $iU32 = _ImGui_ColorFloat4ToU32($fR, $fG, $fB, $fA)
    If @error Then
        _ImGui_SetText("t_encoded", "Encoded U32 : <error " & @error & ">")
        Return
    EndIf

    ; Pull the individual bytes out of the U32 (AutoIt has no native u32 type,
    ; so we use bitmask arithmetic).
    Local $iA = BitAND(BitShift($iU32, 24), 0xFF)
    Local $iB = BitAND(BitShift($iU32, 16), 0xFF)
    Local $iG = BitAND(BitShift($iU32, 8),  0xFF)
    Local $iR = BitAND($iU32,               0xFF)

    _ImGui_SetText("t_decoded",   StringFormat("Read-back : R=%.3f, G=%.3f, B=%.3f, A=%.3f", _
                                                $fR, $fG, $fB, $fA))
    _ImGui_SetText("t_encoded",   StringFormat("Encoded U32 : 0x%08X  (decimal : %u)", $iU32, $iU32))
    _ImGui_SetText("t_breakdown", StringFormat("Byte breakdown : AA=%02X, BB=%02X, GG=%02X, RR=%02X", _
                                                $iA, $iB, $iG, $iR))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
