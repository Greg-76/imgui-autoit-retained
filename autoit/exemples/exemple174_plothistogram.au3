#cs
================================================================================
 Example 174 : _ImGui_CreatePlotHistogram
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePlotHistogram   Display-only bar histogram of a float
                                array  --  same data model as PlotLines

 Identical API surface to CreatePlotLines (exemple173) -- same
 parameters, same SetPlotValues + SetPlotScale verbs. The only
 difference is the visual : bars instead of a connected line.

 Use case : best for sparse / unordered samples where the line
 between consecutive points would imply a (non-existent) continuity.
 Frequency distributions, score breakdowns, monthly counters, ...

 Same DISPLAY-ONLY nature : no events, no value getter, no per-bar
 click. The script controls everything via SetPlotValues.

 Demo :
   * Top plot : static "monthly counts" (12 bars, fixed scale)
   * Bottom plot : dynamic random refresh on button click (16 bars,
                   auto-scale)

 Borrowed widgets : SetPlotValues (exemple173), Button, Text +
 Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple174_plothistogram.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple174_plothistogram.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 174 : _ImGui_CreatePlotHistogram", 720, 500) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePlotHistogram  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePlotHistogram($sId, $sLabel = "",
;                                         $sOverlay = "",
;                                         $fW = 0, $fH = 60.0,
;                                         $fScaleMin = $FLT_MAX,
;                                         $fScaleMax = $FLT_MAX)
;
; Identical to CreatePlotLines (exemple173) -- only the rendering
; style differs.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "PlotHistogram demo  --  static monthly counts (fixed scale) + random refresh (auto)")
_ImGui_CreateText("t_hint",  "Click 'Randomize' to push a fresh array into the lower histogram.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Top plot  --  static monthly counts, 12 bars, fixed scale [0, 120]
; ==============================================================================
_ImGui_CreateText("t_static_hdr", "1) Static  --  12 monthly counts, fixed scale [0, 120], overlay = 'orders' :")
_ImGui_CreatePlotHistogram("h_static", "Jan..Dec", "orders", 0, 110, 0.0, 120.0)
Local $aMonth[12] = [45, 51, 68, 73, 89, 102, 117, 110, 92, 76, 58, 49]
_ImGui_SetPlotValues("h_static", $aMonth)

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Bottom plot  --  random refresh on button click, 16 bars, auto-scale
; ==============================================================================
_ImGui_CreateText("t_rand_hdr", "2) Dynamic  --  16 random values in [0, 100], auto-scale :")
_ImGui_CreatePlotHistogram("h_rand", "random", "", 0, 110)
_RandomFill()   ; seed initial content so the bottom plot isn't empty
_ImGui_CreateButton("btn_randomize", "Randomize  --  push a fresh array via SetPlotValues")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_randomize", "_OnRandomize")
_ImGui_SetOnClick("btn_quit",      "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers / helpers ------------------------------------------------------

Func _OnRandomize($sId)
    _RandomFill()
EndFunc

Func _RandomFill()
    Local $aVals[16]
    For $i = 0 To 15
        $aVals[$i] = Random(0, 100, 1)
    Next
    _ImGui_SetPlotValues("h_rand", $aVals)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
