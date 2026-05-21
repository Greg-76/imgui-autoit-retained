#cs
================================================================================
 Example 114 : _ImGui_SetWindowBgAlpha
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetWindowBgAlpha   Set the background alpha of a window (sticky)

 Background alpha [0.0 = fully transparent, 1.0 = opaque]. Clamped
 DLL-side. Useful for overlay panels (e.g. HUD over a game) where
 you want some see-through effect.

 STICKY behavior : unlike SetWindowPos / Size / Scroll (one-shot
 with $iCond), SetWindowBgAlpha persists -- once set, the alpha
 re-applies every frame until the script calls it again with a new
 value. No need to keep re-calling from OnTick. Pass 1.0 to restore
 opaque.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple114_setwindowbgalpha.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple114_setwindowbgalpha.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 114 : _ImGui_SetWindowBgAlpha", 720, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetWindowBgAlpha  --  doc block
; ==============================================================================
; Signature : _ImGui_SetWindowBgAlpha($sId, $fAlpha)
;
;   $fAlpha : [0.0, 1.0]. Clamped DLL-side. 0 = fully transparent,
;             1 = opaque (default).
;
;   No $iCond -- and sticky : the override stays in effect on every
;   subsequent render until you call this again with a new alpha.
;   To restore default opaque, pass 1.0.
;
;   Return : True on success, False on failure (@error = 1, 2, or 3).


; ==============================================================================
; Host area widgets  --  slider driving the alpha + preset buttons
; ==============================================================================
_ImGui_CreateText("t_title", "SetWindowBgAlpha demo  --  see-through floating panels (sticky)")
_ImGui_CreateText("t_hint",  "Drag the slider to fade the target window background. Sticky : one call sets it for good.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateSliderFloat("sl_alpha", "Background alpha [0..1]", 0.0, 1.0, 0.6, "%.2f")
_ImGui_CreateButton("btn_a_opaque",  "Preset : opaque       (1.00)")
_ImGui_CreateButton("btn_a_semi",    "Preset : semi (0.50)")
_ImGui_CreateButton("btn_a_ghost",   "Preset : ghost       (0.15)")
_ImGui_CreateButton("btn_a_clear",   "Preset : fully clear (0.00)")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Current applied alpha :")
_ImGui_CreateText("t_status",     "  alpha = 0.60")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window (the one whose bg alpha we tune)
; ==============================================================================
_ImGui_CreateWindow("tgt", "Target window (bg alpha)", True, 0)
_ImGui_CreateText("tgt_t1", "I am the target. Drag the host's slider to fade my background.")
_ImGui_CreateText("tgt_t2", "Foreground (text, widgets) stays opaque ; only the bg fades.")
_ImGui_CreateButton("tgt_btn", "Some button inside")
_ImGui_SetParent("tgt_t1", "tgt")
_ImGui_SetParent("tgt_t2", "tgt")
_ImGui_SetParent("tgt_btn","tgt")
_ImGui_SetWindowPos ("tgt", 280, 200, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 340, 160, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("sl_alpha",     "_OnSliderChanged")
_ImGui_SetOnClick ("btn_a_opaque", "_OnPresetOpaque")
_ImGui_SetOnClick ("btn_a_semi",   "_OnPresetSemi")
_ImGui_SetOnClick ("btn_a_ghost",  "_OnPresetGhost")
_ImGui_SetOnClick ("btn_a_clear",  "_OnPresetClear")
_ImGui_SetOnClick ("btn_quit",     "_OnQuit")

; Apply once at init so the slider's default value (0.6) takes effect from
; the first render. Sticky : no OnTick needed.
_ImGui_SetWindowBgAlpha("tgt", _ImGui_GetValueFloat("sl_alpha"))


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnSliderChanged($sId)
    Local $fA = _ImGui_GetValueFloat($sId)
    _ImGui_SetWindowBgAlpha("tgt", $fA)
    _ImGui_SetText("t_status", StringFormat("  alpha = %.2f", $fA))
EndFunc

Func _OnPresetOpaque($sId)
    _ImGui_SetValueFloat("sl_alpha", 1.0)
    _ImGui_SetWindowBgAlpha("tgt", 1.0)
    _ImGui_SetText("t_status", "  alpha = 1.00 (opaque preset)")
EndFunc

Func _OnPresetSemi($sId)
    _ImGui_SetValueFloat("sl_alpha", 0.5)
    _ImGui_SetWindowBgAlpha("tgt", 0.5)
    _ImGui_SetText("t_status", "  alpha = 0.50 (semi preset)")
EndFunc

Func _OnPresetGhost($sId)
    _ImGui_SetValueFloat("sl_alpha", 0.15)
    _ImGui_SetWindowBgAlpha("tgt", 0.15)
    _ImGui_SetText("t_status", "  alpha = 0.15 (ghost preset)")
EndFunc

Func _OnPresetClear($sId)
    _ImGui_SetValueFloat("sl_alpha", 0.0)
    _ImGui_SetWindowBgAlpha("tgt", 0.0)
    _ImGui_SetText("t_status", "  alpha = 0.00 (clear preset)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
