#cs
================================================================================
 Example 28 : _ImGui_CreateProgressBar
================================================================================
 Covers 5 exports of imgui_autoit.dll :

   _ImGui_CreateProgressBar       Display-only progress bar (0..1)
   _ImGui_SetProgressBarOverlay   Change the overlay text dynamically
   _ImGui_GetValueFloat           Read the current fraction
   _ImGui_SetValueFloat           Update the fraction
   _ImGui_SetOnTick               (wrapper helper) periodic timer callback

 ProgressBar is display-only -- the value is set ONLY from the script.
 There is no OnChange. To animate one, register a tick handler via
 _ImGui_SetOnTick : the wrapper drives it through a hidden timer, the
 script never touches AdlibRegister.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple28_progressbar.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple28_progressbar.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 28 : _ImGui_CreateProgressBar", 580, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateProgressBar  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateProgressBar($sId, $fDefault = 0.0,
;                                       $sOverlay = "",
;                                       $fW = -1.0, $fH = 0.0)
;
;   Display-only progress indicator. $fDefault is the fraction in
;   [0.0, 1.0] -- ImGui clamps anything outside.
;
;   $sOverlay : optional text drawn centred over the fill. Empty string
;   = no overlay. Useful for showing "42 %", "loaded 320 of 1000",
;   "00:42 elapsed", etc. Update at runtime via
;   _ImGui_SetProgressBarOverlay($sId, $sNewOverlay).
;
;   $fW : width in pixels. -1.0 (default) -> fills the available
;        horizontal space. 0.0 -> ImGui default minimum width.
;   $fH : height in pixels. 0.0 (default) -> ImGui default (current
;        line height + frame padding).
;
;   Read / write the fraction (it's a FloatValueWidget) :
;     _ImGui_GetValueFloat($sId)             -> 0..1 fraction
;     _ImGui_SetValueFloat($sId, $fValue)    -> update the fill
;
;   No OnChange : ProgressBar is not interactive.
;
;   Return : True on success, False on failure.

; ==============================================================================
; _ImGui_SetOnTick  --  doc block (wrapper-level helper)
; ==============================================================================
; Signature : _ImGui_SetOnTick($sFuncName, $iIntervalMs)
;
;   Registers a parameter-less function to be called every $iIntervalMs
;   milliseconds. The wrapper drives the timer internally so the script
;   never deals with AdlibRegister. Pass $iIntervalMs <= 0 to unregister.
;
;   _ImGui_Shutdown unregisters every tick handler automatically.
;
;   Multiple handlers can run side by side at different intervals --
;   each call to _ImGui_SetOnTick creates a separate timer.


; ==============================================================================
; Script-side state for the animated bar
; ==============================================================================
; Declared BEFORE the bindings so the tick handler can see them on its
; first invocation. The tick fires from the wrapper's timer, which is
; itself driven by AdlibRegister -- so the handler can be called at any
; point after _ImGui_SetOnTick is invoked.
Global $g_fAnimValue   = 0.0
Global $g_bAnimRunning = True
Const  $g_fAnimStep    = 0.02     ; +2 % per tick = 50 ticks for a full cycle
Const  $g_iAnimTickMs  = 50       ; ~20 ticks/s -> ~2.5 s for 0 -> 100 %


; ==============================================================================
; Demo widgets  --  three static bars + one animated bar + controls
; ==============================================================================
_ImGui_CreateText("t_title", "ProgressBar demo")
_ImGui_CreateText("t_hint",  "Static bars are mutated by buttons. The animated bar is driven by _ImGui_SetOnTick.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_a_hdr", "Default size (fills row), 30 %% initial :")
_ImGui_CreateProgressBar("pb_main", 0.30, "")

_ImGui_CreateText("t_b_hdr", "Custom overlay, 50 %% initial :")
_ImGui_CreateProgressBar("pb_named", 0.50, "Loading...")

_ImGui_CreateText("t_c_hdr", "Fixed size 200 x 24 px, 80 %% initial :")
_ImGui_CreateProgressBar("pb_small", 0.80, "almost there", 200.0, 24.0)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_anim_hdr", "Animated bar (driven by _ImGui_SetOnTick, ~2.5 s per cycle) :")
_ImGui_CreateProgressBar("pb_anim", 0.0, "0 %%")
_ImGui_CreateButton("btn_anim_toggle", "Pause animation")

_ImGui_CreateSeparator("sep3")
_ImGui_CreateText("t_ctl_hdr", "Manual controls for the three static bars (SetValueFloat, no OnChange) :")
_ImGui_CreateButton("btn_p0",   "Set 0 %%")
_ImGui_CreateButton("btn_p25",  "Set 25 %%")
_ImGui_CreateButton("btn_p50",  "Set 50 %%")
_ImGui_CreateButton("btn_p75",  "Set 75 %%")
_ImGui_CreateButton("btn_p100", "Set 100 %%")
_ImGui_CreateButton("btn_overlay_dyn",   "Make overlay show ""x.x %%""")
_ImGui_CreateButton("btn_overlay_done",  "Overlay : ""Done""")
_ImGui_CreateButton("btn_overlay_blank", "Overlay : (empty)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
; No OnChange anywhere : ProgressBar is non-interactive. Everything is
; either button-driven or tick-driven.
_ImGui_SetOnClick("btn_p0",            "_OnSetPct")
_ImGui_SetOnClick("btn_p25",           "_OnSetPct")
_ImGui_SetOnClick("btn_p50",           "_OnSetPct")
_ImGui_SetOnClick("btn_p75",           "_OnSetPct")
_ImGui_SetOnClick("btn_p100",          "_OnSetPct")
_ImGui_SetOnClick("btn_overlay_dyn",   "_OnOverlayDyn")
_ImGui_SetOnClick("btn_overlay_done",  "_OnOverlayDone")
_ImGui_SetOnClick("btn_overlay_blank", "_OnOverlayBlank")
_ImGui_SetOnClick("btn_anim_toggle",   "_OnAnimToggle")
_ImGui_SetOnClick("btn_quit",          "_OnQuit")

; Start the animation immediately. Pass 0 to unregister.
_ImGui_SetOnTick("_OnAnimTick", $g_iAnimTickMs)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnSetPct($sId)
    Local $fValue = 0.0
    Switch $sId
        Case "btn_p0"
            $fValue = 0.0
        Case "btn_p25"
            $fValue = 0.25
        Case "btn_p50"
            $fValue = 0.5
        Case "btn_p75"
            $fValue = 0.75
        Case "btn_p100"
            $fValue = 1.0
    EndSwitch
    _ImGui_SetValueFloat("pb_main",  $fValue)
    _ImGui_SetValueFloat("pb_named", $fValue)
    _ImGui_SetValueFloat("pb_small", $fValue)
EndFunc

Func _OnOverlayDyn($sId)
    Local $fValue = _ImGui_GetValueFloat("pb_main")
    Local $sNew = StringFormat("%.1f %%", $fValue * 100.0)
    _ImGui_SetProgressBarOverlay("pb_main",  $sNew)
    _ImGui_SetProgressBarOverlay("pb_named", $sNew)
    _ImGui_SetProgressBarOverlay("pb_small", $sNew)
EndFunc

Func _OnOverlayDone($sId)
    _ImGui_SetProgressBarOverlay("pb_main",  "Done")
    _ImGui_SetProgressBarOverlay("pb_named", "Done")
    _ImGui_SetProgressBarOverlay("pb_small", "Done")
EndFunc

Func _OnOverlayBlank($sId)
    _ImGui_SetProgressBarOverlay("pb_main",  "")
    _ImGui_SetProgressBarOverlay("pb_named", "")
    _ImGui_SetProgressBarOverlay("pb_small", "")
EndFunc

; Tick handler -- called every $g_iAnimTickMs ms by the wrapper. Advances
; the animation value and wraps from 1.0 back to 0.0.
Func _OnAnimTick()
    If Not $g_bAnimRunning Then Return
    $g_fAnimValue += $g_fAnimStep
    If $g_fAnimValue > 1.0 Then $g_fAnimValue = 0.0
    _ImGui_SetValueFloat("pb_anim", $g_fAnimValue)
    _ImGui_SetProgressBarOverlay("pb_anim", StringFormat("%.0f %%", $g_fAnimValue * 100.0))
EndFunc

; Pause / resume button : we keep the tick running (so the wrapper book-
; keeping stays simple) and just gate the increment on $g_bAnimRunning.
Func _OnAnimToggle($sId)
    $g_bAnimRunning = Not $g_bAnimRunning
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
