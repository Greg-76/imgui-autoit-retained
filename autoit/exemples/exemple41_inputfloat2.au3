#cs
================================================================================
 Example 41 : _ImGui_CreateInputFloat2
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateInputFloat2   Two-component float text-input widget
   _ImGui_GetValueFloatN      Read the 2-component vector
   _ImGui_SetValueFloatN      Set the 2-component vector

 InputFloat2 is the keyboard-friendly cousin of SliderFloat2 and
 DragFloat2 : no track, no drag, just two editable text fields side by
 side. There is no $fSpeed and no $fMin/$fMax -- the widget is
 inherently unbounded ; clamping is up to the script (cf. exemple39).

 Strict semantics : see exemple20_inputfloat.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple41_inputfloat2.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple41_inputfloat2.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 41 : _ImGui_CreateInputFloat2", 600, 360) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateInputFloat2  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateInputFloat2($sId, $sLabel = "",
;                                       $fD0 = 0.0, $fD1 = 0.0,
;                                       $sFormat = "%.3f")
;
;   Two editable float text fields on a single row. No speed, no
;   min/max -- type any IEEE-754 value. The widget commits the typed
;   value (and fires OnChange) when the user presses Enter or Tab, or
;   when focus leaves the field.
;
;   $sFormat : printf-style display format ("%.3f", "%.4f", "%e", ...).
;   It affects ONLY rendering ; the underlying value keeps full float
;   precision.
;
;   Read / write the pair as an AutoIt array of size 2 :
;     _ImGui_GetValueFloatN($sId, 2)        -> [v0, v1]
;     _ImGui_SetValueFloatN($sId, $aVals)   -> 1D array of size 2 ; no OnChange
;
;   Bind user commits with _ImGui_SetOnChange (FloatVec2ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  UV texture coordinates (u, v) with high-precision format
; ==============================================================================
_ImGui_CreateText("t_title", "InputFloat2 demo  --  UV texture coordinates (u, v) at %.4f precision")
_ImGui_CreateText("t_hint",  "Click a field, type a value, press Enter or Tab to commit. OnChange fires on commit, not on each keystroke.")
_ImGui_CreateSeparator("sep1")

; defaults (0, 0), 4-decimal format.
_ImGui_CreateInputFloat2("in_uv", "UV (u, v)", 0.0, 0.0, "%.4f")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : u=0.0000, v=0.0000")
_ImGui_CreateText("t_count", "User commits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueFloatN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_tl",     "Top-left  (0.0, 0.0)")
_ImGui_CreateButton("btn_center", "Center    (0.5, 0.5)")
_ImGui_CreateButton("btn_br",     "Bot-right (1.0, 1.0)")
_ImGui_CreateButton("btn_tile",   "Tile 2x   (2.0, 2.0)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",   "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iCommitCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("in_uv",      "_OnUvChanged")
_ImGui_SetOnClick ("btn_tl",     "_OnTopLeft")
_ImGui_SetOnClick ("btn_center", "_OnCenter")
_ImGui_SetOnClick ("btn_br",     "_OnBotRight")
_ImGui_SetOnClick ("btn_tile",   "_OnTile2x")
_ImGui_SetOnClick ("btn_quit",   "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnUvChanged($sId)
    Local $aVal = _ImGui_GetValueFloatN($sId, 2)
    If @error Or Not IsArray($aVal) Then Return
    $g_iCommitCount += 1
    _ImGui_SetText("t_read",  StringFormat("Read-back : u=%.4f, v=%.4f", $aVal[0], $aVal[1]))
    _ImGui_SetText("t_count", "User commits : " & $g_iCommitCount)
EndFunc

Func _OnTopLeft($sId)
    _ApplyPreset(0.0, 0.0, "top-left")
EndFunc

Func _OnCenter($sId)
    _ApplyPreset(0.5, 0.5, "center")
EndFunc

Func _OnBotRight($sId)
    _ApplyPreset(1.0, 1.0, "bottom-right")
EndFunc

Func _OnTile2x($sId)
    _ApplyPreset(2.0, 2.0, "tile 2x")
EndFunc

Func _ApplyPreset($f0, $f1, $sTag)
    Local $aNew[2] = [$f0, $f1]
    _ImGui_SetValueFloatN("in_uv", $aNew)
    _ImGui_SetText("t_read", StringFormat("Read-back : u=%.4f, v=%.4f (%s)", $f0, $f1, $sTag))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
