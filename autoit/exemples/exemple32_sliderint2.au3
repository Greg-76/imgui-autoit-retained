#cs
================================================================================
 Example 32 : _ImGui_CreateSliderInt2
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateSliderInt2   Two-component int slider (single widget row)
   _ImGui_GetValueIntN       Read the 2-component vector
   _ImGui_SetValueIntN       Set the 2-component vector

 SliderInt2 packs two int sliders into a single widget row, both clamped
 to [$iMin, $iMax]. Typical use : viewport size (W, H), tile coordinates
 (col, row), pair of counters.

 Strict semantics : see exemple17_sliderint.au3. Programmatic
 _ImGui_SetValueIntN never fires OnChange ; only user drags do.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple32_sliderint2.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple32_sliderint2.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 32 : _ImGui_CreateSliderInt2", 640, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSliderInt2  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSliderInt2($sId, $sLabel = "",
;                                      $iMin = 0, $iMax = 100,
;                                      $iD0 = 0, $iD1 = 0,
;                                      $sFormat = "%d")
;
;   Two integer slider handles on a single row, both clamped to
;   [$iMin, $iMax]. $iD0 / $iD1 are the initial values.
;
;   Read / write the pair as an AutoIt array of size 2 :
;     _ImGui_GetValueIntN($sId, 2)        -> [v0, v1]
;     _ImGui_SetValueIntN($sId, $aVals)   -> 1D array of size 2 ; no OnChange
;
;   Bind user edits with _ImGui_SetOnChange (IntVec2ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  viewport size (W, H) in [1, 1920]
; ==============================================================================
_ImGui_CreateText("t_title", "SliderInt2 demo  --  edit viewport size (W, H)")
_ImGui_CreateText("t_hint",  "Drag either handle. Use presets to switch resolution programmatically.")
_ImGui_CreateSeparator("sep1")

; Range 1..1920, defaults (1280, 720).
_ImGui_CreateSliderInt2("sl_size", "Size (W, H)", 1, 1920, 1280, 720, "%d px")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : W=1280, H=720, aspect=1.78")
_ImGui_CreateText("t_count", "User edits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Resolution presets (SetValueIntN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_svga",  "SVGA  800 x 600")
_ImGui_CreateButton("btn_hd",    "HD    1280 x 720")
_ImGui_CreateButton("btn_fhd",   "FHD   1920 x 1080")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iEditCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("sl_size",  "_OnSizeChanged")
_ImGui_SetOnClick ("btn_svga", "_OnSvga")
_ImGui_SetOnClick ("btn_hd",   "_OnHd")
_ImGui_SetOnClick ("btn_fhd",  "_OnFhd")
_ImGui_SetOnClick ("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnSizeChanged($sId)
    Local $aVal = _ImGui_GetValueIntN($sId, 2)
    If @error Or Not IsArray($aVal) Then Return
    $g_iEditCount += 1
    Local $fAspect = ($aVal[1] = 0) ? 0.0 : ($aVal[0] / $aVal[1])
    _ImGui_SetText("t_read",  StringFormat("Read-back : W=%d, H=%d, aspect=%.2f", _
                                            $aVal[0], $aVal[1], $fAspect))
    _ImGui_SetText("t_count", "User edits : " & $g_iEditCount)
EndFunc

Func _OnSvga($sId)
    _ApplyPreset(800, 600, "SVGA")
EndFunc

Func _OnHd($sId)
    _ApplyPreset(1280, 720, "HD")
EndFunc

Func _OnFhd($sId)
    _ApplyPreset(1920, 1080, "FHD")
EndFunc

Func _ApplyPreset($iW, $iH, $sTag)
    Local $aNew[2] = [$iW, $iH]
    _ImGui_SetValueIntN("sl_size", $aNew)
    Local $fAspect = ($iH = 0) ? 0.0 : ($iW / $iH)
    _ImGui_SetText("t_read", StringFormat("Read-back : W=%d, H=%d, aspect=%.2f (%s)", _
                                          $iW, $iH, $fAspect, $sTag))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
