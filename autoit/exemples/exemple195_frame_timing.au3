#cs
================================================================================
 Example 195 : Frame timing  --  GetTime + GetFrameCount
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_GetTime         ImGui's monotonic time (seconds, double)
   _ImGui_GetFrameCount   Frames rendered since _ImGui_Init (int)

 Both advance with the render thread (one tick of GetTime per
 io.DeltaTime, one tick of GetFrameCount per rendered frame). They
 are PURE READERS -- no side effect, no @error in normal use.

 Why bundle these two : they're useless individually but powerful
 together. Pair them at two points T0 and T1 to derive :

     fps    = (frames_T1 - frames_T0) / (time_T1 - time_T0)
     mspf   = 1000 * (time_T1 - time_T0) / (frames_T1 - frames_T0)

 ImGui already exposes io.Framerate internally, but that's a smoothed
 average ; the explicit pair gives the script direct access to the
 raw counters.

 Distinct from AutoIt's TimerInit / TimerDiff :
   * AutoIt clock     monotonic wall time on the script thread
                      (microsecond resolution, runs while ImGui
                      is paused or unfocused).
   * ImGui clock      monotonic ANIMATION time on the render thread
                      (advances by io.DeltaTime each frame ; throttled
                      to SetUnfocusedFps when the window loses focus).
 The two desync naturally when the window is unfocused -- the demo
 shows them side by side so the difference is visible.

 Borrowed widgets : Text + Separator, Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple195_frame_timing.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple195_frame_timing.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 195 : Frame timing  --  GetTime + GetFrameCount", 760, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 2-export cluster
; ==============================================================================
; _ImGui_GetTime()         -> Double   -- monotonic seconds since Init
; _ImGui_GetFrameCount()   -> Int      -- rendered frames since Init
;
;   Both : @error = 1 (DLL not loaded), 2 (DllCall failed), 3 (DLL
;   status non-zero -- GetTime only). GetFrameCount has no status code.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "Frame timing demo  --  GetTime + GetFrameCount with derived FPS")
_ImGui_CreateText("t_hint",  "Drag the window off-screen / minimize to see the ImGui clock throttle (vs the AutoIt clock).")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Raw readouts
; ==============================================================================
_ImGui_CreateText("t_raw_hdr", "Raw readouts (polled at 100 ms) :")
_ImGui_CreateText("t_imgui_time",  "  ImGui clock     : 0.000 s")
_ImGui_CreateText("t_imgui_frame", "  ImGui frames    : 0")
_ImGui_CreateText("t_autoit_time", "  AutoIt clock    : 0.000 s   (TimerDiff since launch)")
_ImGui_CreateText("t_drift",       "  ImGui - AutoIt  : +0.000 s  (negative if window was unfocused)")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Derived FPS  --  over a 1 s window
; ==============================================================================
_ImGui_CreateText("t_fps_hdr", "Derived FPS (computed over the last 1 s sample window) :")
_ImGui_CreateText("t_fps",  "  FPS  : --     (sampling, wait 1 s)")
_ImGui_CreateText("t_mspf", "  ms/f : --")
_ImGui_CreateSeparator("sep2")


_ImGui_CreateButton("btn_quit", "Quit")


; --- Globals (sampling state) ------------------------------------------------
Global Const $g_hAutoItStart = TimerInit()
; Sample window endpoints -- updated by the 1 s tick.
Global $g_fT0 = _ImGui_GetTime()
Global $g_iF0 = _ImGui_GetFrameCount()


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnReadoutTick", 100)
_ImGui_SetOnTick("_OnFpsTick",     1000)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnReadoutTick()
    Local $fImGuiT  = _ImGui_GetTime()
    Local $iImGuiF  = _ImGui_GetFrameCount()
    Local $fAutoItT = TimerDiff($g_hAutoItStart) / 1000.0
    Local $fDrift   = $fImGuiT - $fAutoItT
    _ImGui_SetText("t_imgui_time",  StringFormat("  ImGui clock     : %.3f s",  $fImGuiT))
    _ImGui_SetText("t_imgui_frame", StringFormat("  ImGui frames    : %d", $iImGuiF))
    _ImGui_SetText("t_autoit_time", StringFormat("  AutoIt clock    : %.3f s   (TimerDiff since launch)", $fAutoItT))
    _ImGui_SetText("t_drift",       StringFormat("  ImGui - AutoIt  : %+.3f s  (negative if window was unfocused)", $fDrift))
EndFunc

Func _OnFpsTick()
    Local $fT1 = _ImGui_GetTime()
    Local $iF1 = _ImGui_GetFrameCount()
    Local $fDt = $fT1 - $g_fT0
    Local $iDf = $iF1 - $g_iF0
    If $fDt > 0.0 And $iDf > 0 Then
        Local $fFps  = $iDf / $fDt
        Local $fMspf = 1000.0 * $fDt / $iDf
        _ImGui_SetText("t_fps",  StringFormat("  FPS  : %5.1f   (%d frames over %.3f s)", $fFps, $iDf, $fDt))
        _ImGui_SetText("t_mspf", StringFormat("  ms/f : %5.2f", $fMspf))
    Else
        _ImGui_SetText("t_fps",  "  FPS  : --     (no frames rendered in this window  --  unfocused ?)")
        _ImGui_SetText("t_mspf", "  ms/f : --")
    EndIf
    $g_fT0 = $fT1
    $g_iF0 = $iF1
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
