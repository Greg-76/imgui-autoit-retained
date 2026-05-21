#cs
================================================================================
 Example 197 : Value widgets  --  CreateValueBool + CreateValueInt + CreateValueFloat
================================================================================
 Covers 3 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_CreateValueBool    Inline "prefix: True/False"
   _ImGui_CreateValueInt     Inline "prefix: 42"
   _ImGui_CreateValueFloat   Inline "prefix: 3.14" (with $sFormat)

 ImGui's Value() helpers : a thin layer over Text() that renders
 "prefix: value" in a single call. Pure DISPLAY widgets -- they have
 no clicked / changed latch, no event surface. Updates happen via
 the polymorphic value setters that the rest of the wrapper already
 exposes :

   _ImGui_SetValueBool($sId, $bValue)
   _ImGui_SetValueInt($sId, $iValue)
   _ImGui_SetValueFloat($sId, $fValue)

 Overlaps with _ImGui_SetText concatenation -- but the helpers are
 marginally faster (one call instead of one concat + one SetText),
 and they're standard ImGui API surface, included here for parity.

 Constructor parameters worth noting :
   * $sPrefix : the part BEFORE the colon. ImGui appends ": <value>"
     automatically.
   * Float variant also takes $sFormat (printf-style, default "%.3f").
     Bool / Int have no format parameter -- always rendered as
     "True" / "False" / signed decimal.

 Demo : three interactive driver widgets (Checkbox / SliderInt /
 SliderFloat) mirror their values into the matching Value* via
 SetOnChange + the polymorphic SetValue*. A tick handler also
 animates a Value with a sine-wave float to demonstrate that
 updates are programmatic (the Value widget itself is not
 interactive -- the user can't click it).

 Borrowed widgets : Checkbox, SliderInt, SliderFloat, Text +
 Separator, Button. SetOnTick (exemple4) for the animation.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple197_value_widgets.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple197_value_widgets.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 197 : Value widgets", 760, 620) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 3-export cluster
; ==============================================================================
; _ImGui_CreateValueBool ($sId, $sPrefix, $bInitial = False)
; _ImGui_CreateValueInt  ($sId, $sPrefix, $iInitial = 0)
; _ImGui_CreateValueFloat($sId, $sPrefix, $fInitial = 0.0, $sFormat = "%.3f")
;
;   $sId      : stable widget identifier.
;   $sPrefix  : text before the ":" separator.
;   $b/$i/$fInitial : seed value -- updated via SetValue*.
;   $sFormat  : Float variant only ; printf-style.
;
;   Return : True on success, False on failure (@error = 1, 2).
;
;   Pure display ; no SetOnClick / SetOnChange (Value widgets have
;   no event latches). Update via _ImGui_SetValueBool / Int / Float.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "Value widgets demo  --  CreateValueBool / Int / Float")
_ImGui_CreateText("t_hint",  "Drive the three Value widgets via the matching driver widget below each.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Bool driver + Value
; ==============================================================================
_ImGui_CreateText("t_b_hdr", "Bool :")
_ImGui_CreateCheckbox("cb_drive_b", "Driver checkbox (CreateValueBool mirrors this)", False)
_ImGui_CreateValueBool("v_bool", "  State", False)
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Int driver + Value
; ==============================================================================
_ImGui_CreateText("t_i_hdr", "Int :")
_ImGui_CreateSliderInt("sl_drive_i", "Driver slider", 0, 100, 42, "%d")
_ImGui_CreateValueInt("v_int", "  Count", 42)
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Float driver + Value (with custom format)
; ==============================================================================
_ImGui_CreateText("t_f_hdr", "Float :")
_ImGui_CreateSliderFloat("sl_drive_f", "Driver slider", 0.0, 6.283, 0.0, "%.2f rad")
_ImGui_CreateValueFloat("v_float", "  Angle (rad)", 0.0, "%.4f")
_ImGui_CreateSeparator("sep3")


; ==============================================================================
; Animated Value  --  no user driver, just SetOnTick at 50 ms
; ==============================================================================
_ImGui_CreateText("t_anim_hdr", "Animated float (50 ms tick pushes sin(t)) :")
_ImGui_CreateValueFloat("v_anim", "  sin(t)", 0.0, "%+.3f")
_ImGui_CreateSeparator("sep4")


_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("cb_drive_b",  "_OnDriveBool")
_ImGui_SetOnChange("sl_drive_i",  "_OnDriveInt")
_ImGui_SetOnChange("sl_drive_f",  "_OnDriveFloat")
_ImGui_SetOnClick("btn_quit",     "_OnQuit")
_ImGui_SetOnTick("_OnAnimTick", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnDriveBool($sId)
    _ImGui_SetValueBool("v_bool", _ImGui_GetValueBool($sId))
EndFunc

Func _OnDriveInt($sId)
    _ImGui_SetValueInt("v_int", _ImGui_GetValueInt($sId))
EndFunc

Func _OnDriveFloat($sId)
    _ImGui_SetValueFloat("v_float", _ImGui_GetValueFloat($sId))
EndFunc

Func _OnAnimTick()
    Local $fT = _ImGui_GetTime()
    _ImGui_SetValueFloat("v_anim", Sin($fT))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
