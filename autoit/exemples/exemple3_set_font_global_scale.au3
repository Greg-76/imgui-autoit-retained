#cs
================================================================================
 Example 3 : _ImGui_SetFontGlobalScale
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetFontGlobalScale    Global UI zoom multiplier

 Drag the slider or click a preset -- every text widget in this window
 scales live, including the labels of the buttons and the slider itself.

 Borrowed widgets (each detailed in its own example) :
   - _ImGui_CreateText  (Text + SetText)
   - _ImGui_CreateSliderFloat + Get/SetValueFloat
   - _ImGui_CreateButton
   - _ImGui_CreateSeparator

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple3_set_font_global_scale.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple3_set_font_global_scale.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; ==============================================================================
; --- Init (boilerplate) ---  see exemple1_init_shutdown.au3 for details
; ==============================================================================
If Not _ImGui_Init("Example 3 : _ImGui_SetFontGlobalScale", 560, 380) Then
    MsgBox(16, "Initialisation error", _
        "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetFontGlobalScale  --  doc block
; ==============================================================================
; Signature : _ImGui_SetFontGlobalScale($fScale)
;
;   Multiplier applied to the rendered text size. 1.0 = normal, 2.0 = double,
;   0.5 = half. Must be > 0. Takes effect on the next frame.
;
;   Independent from the system DPI scaling -- this is a manual override on
;   top of whatever DPI ImGui already detected.
;
;   Return : True on success, False otherwise (@error = 1 if not initialised,
;   2 if scale <= 0, 3 if DllCall failed).
;
; Initial state : 1.0 (no zoom). The OnChange handler below mutates this
; live whenever the slider moves ; the OnClick handlers (presets) set the
; slider value programmatically + apply.
_ImGui_SetFontGlobalScale(1.0)


; ==============================================================================
; Demo widgets (borrowed from other examples)
; ==============================================================================
_ImGui_CreateText("t_title", "FontGlobalScale demo")
_ImGui_CreateText("t_hint",  "Drag the slider or click a preset ; everything on this window scales.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateSliderFloat("sl_scale", "Scale", 0.25, 4.0, 1.0, "%.2f x")
_ImGui_CreateText("t_scale_now", "Applied : 1.00 x")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_preset_hdr", "Presets :")
_ImGui_CreateButton("btn_p050", "0.5 x")
_ImGui_CreateButton("btn_p100", "1.0 x")
_ImGui_CreateButton("btn_p150", "1.5 x")
_ImGui_CreateButton("btn_p200", "2.0 x")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Bind events
; ==============================================================================
_ImGui_SetOnChange("sl_scale",  "_OnScaleSliderChanged")
_ImGui_SetOnClick ("btn_p050",  "_OnPresetClicked")
_ImGui_SetOnClick ("btn_p100",  "_OnPresetClicked")
_ImGui_SetOnClick ("btn_p150",  "_OnPresetClicked")
_ImGui_SetOnClick ("btn_p200",  "_OnPresetClicked")
_ImGui_SetOnClick ("btn_quit",  "_OnQuitClicked")


; ==============================================================================
; Main loop
; ==============================================================================
While _ImGui_IsRunning()
    Sleep(50)
WEnd


; ==============================================================================
; Cleanup  (also unbinds all OnEvent subscriptions)
; ==============================================================================
_ImGui_Shutdown()


; ==============================================================================
; Event handlers
; ==============================================================================

; Slider drove the value live.
Func _OnScaleSliderChanged($sId)
    Local $fScale = _ImGui_GetValueFloat($sId)
    _ImGui_SetFontGlobalScale($fScale)
    _ImGui_SetText("t_scale_now", StringFormat("Applied : %.2f x", $fScale))
EndFunc

; A preset button was clicked. We :
;   1. apply the new scale,
;   2. mirror the value back into the slider via _ImGui_SetValueFloat
;      -- a programmatic write that does NOT fire OnChange (strict semantics),
;         so no loop preset -> slider -> preset.
Func _OnPresetClicked($sId)
    Local $fScale = 1.0
    Switch $sId
        Case "btn_p050"
            $fScale = 0.5
        Case "btn_p100"
            $fScale = 1.0
        Case "btn_p150"
            $fScale = 1.5
        Case "btn_p200"
            $fScale = 2.0
    EndSwitch
    _ImGui_SetFontGlobalScale($fScale)
    _ImGui_SetValueFloat("sl_scale", $fScale)
    _ImGui_SetText("t_scale_now", StringFormat("Applied : %.2f x (preset)", $fScale))
EndFunc

Func _OnQuitClicked($sId)
    _ImGui_Shutdown()
EndFunc
