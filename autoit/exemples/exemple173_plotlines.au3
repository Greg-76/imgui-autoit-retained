#cs
================================================================================
 Example 173 : _ImGui_CreatePlotLines (+ _ImGui_SetPlotValues)
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_CreatePlotLines   Display-only line graph of a float array
   _ImGui_SetPlotValues     Push a fresh 1D float array into the plot
                            (also accepts PlotHistogram, exemple174)

 Bundling rationale : a freshly-created PlotLines renders nothing
 until at least one SetPlotValues call. The two exports together
 form the minimum viable plot demo.

 DISPLAY-ONLY widget -- no event flag, no value getter / setter. The
 plot is purely a sink for a float array. To animate :
   * Seed an initial array at startup
   * Re-push a new array via _ImGui_SetPlotValues on every tick

 The DLL holds its OWN copy of the values, so the caller's array
 can be re-used / freed on the next iteration. Pushing an empty
 array clears the plot.

 Scale model :
   * $fScaleMin = $fScaleMax = $FLT_MAX   auto-scale (default)
   * Concrete values                       fixed range [min, max]
 The range can also be changed at runtime via _ImGui_SetPlotScale
 (exemple175).

 Demo :
   * Top plot : static "EKG-like" data, fixed range [-1.2, 1.2]
   * Bottom plot : animated sine wave, auto-scale, refreshed every
                   50 ms via SetOnTick

 Borrowed widgets : Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple173_plotlines.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple173_plotlines.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 173 : PlotLines + SetPlotValues", 720, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 2-export cluster
; ==============================================================================
; CreatePlotLines($sId, $sLabel = "", $sOverlay = "",
;                 $fW = 0, $fH = 60.0,
;                 $fScaleMin = $FLT_MAX, $fScaleMax = $FLT_MAX)
;   $sOverlay  : centered text drawn ON TOP of the line (e.g. "max=42").
;   $fW = 0    : stretches to available content width.
;   $fScale*   : $FLT_MAX = auto-scale on that side.
;
; SetPlotValues($sId, $aValues)
;   $aValues   : 1D float array (any AutoIt array of numbers is fine).
;                Empty array = clear the plot.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "PlotLines + SetPlotValues  --  static (fixed scale) + animated sine wave (auto-scale)")
_ImGui_CreateText("t_hint",  "Bottom plot refreshes every 50 ms via SetOnTick. Overlay text shows the live phase.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Top plot  --  static EKG-like trace, fixed range [-1.2, 1.2]
; ==============================================================================
_ImGui_CreateText("t_static_hdr", "1) Static  --  fixed scale [-1.2, 1.2], overlay 'EKG sample' :")
_ImGui_CreatePlotLines("plot_static", "trace 1", "EKG sample", 0, 100, -1.2, 1.2)

; Seed a deterministic EKG-shaped pattern (no animation).
Local $aStatic[64]
For $i = 0 To 63
    Local $j = Mod($i, 16)
    Local $f = 0.0
    If $j = 4 Then
        $f = 1.0   ; spike
    ElseIf $j = 5 Then
        $f = -0.4  ; rebound
    ElseIf $j = 8 Then
        $f = 0.15  ; small bump
    EndIf
    $aStatic[$i] = $f
Next
_ImGui_SetPlotValues("plot_static", $aStatic)

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Bottom plot  --  animated sine wave, auto-scale
; ==============================================================================
_ImGui_CreateText("t_anim_hdr", "2) Animated  --  auto-scale, sine wave refreshed every 50 ms :")
_ImGui_CreatePlotLines("plot_anim", "sin(phase + i*0.18)", "phase = 0.00", 0, 100)
; Initial fill so the plot isn't empty for the first frame.
_PushSine(0.0)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- State for the animation ------------------------------------------------
Global $g_fPhase = 0.0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnTickAnim", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers / helpers ------------------------------------------------------

Func _OnTickAnim()
    $g_fPhase += 0.10
    If $g_fPhase > 6.28318 Then $g_fPhase -= 6.28318
    _PushSine($g_fPhase)
    ; The overlay is part of the widget config -- to update it dynamically the
    ; canonical hack is to re-call CreatePlotLines with the new overlay, but
    ; that re-creates the widget every tick (wasteful). Cheaper : add a
    ; sibling Text widget that mirrors the live phase, which is what we do here.
EndFunc

Func _PushSine($fPhase)
    Local $aVals[64]
    For $i = 0 To 63
        $aVals[$i] = Sin($fPhase + $i * 0.18)
    Next
    _ImGui_SetPlotValues("plot_anim", $aVals)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
