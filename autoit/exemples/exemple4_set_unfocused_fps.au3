#cs
================================================================================
 Example 4 : _ImGui_SetUnfocusedFps
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetUnfocusedFps    Caps the FPS when the window is unfocused

 The render thread normally runs at ~60 fps when the window has keyboard
 focus, mouse focus, or the mouse hovering. When all three drop, the render
 loop throttles to the value set here.

 To observe the effect : set the slider to 1 fps, then click another
 window (this one loses focus + mouse). Come back, hover over a button --
 the hover highlight may take up to one second to appear. Click anywhere
 and the FPS jumps back to 60.

 Borrowed widgets (each detailed in its own example) :
   - _ImGui_CreateText  (Text + SetText)
   - _ImGui_CreateSliderInt + Get/SetValueInt
   - _ImGui_CreateButton
   - _ImGui_CreateSeparator

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple4_set_unfocused_fps.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple4_set_unfocused_fps.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; ==============================================================================
; --- Init (boilerplate) ---  see exemple1_init_shutdown.au3 for details
; ==============================================================================
If Not _ImGui_Init("Example 4 : _ImGui_SetUnfocusedFps", 560, 360) Then
    MsgBox(16, "Initialisation error", _
        "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetUnfocusedFps  --  doc block
; ==============================================================================
; Signature : _ImGui_SetUnfocusedFps($iFps)
;
;   When the ImGui window has NEITHER keyboard NOR mouse focus AND the
;   mouse is NOT hovering it, the render thread drops to this FPS instead
;   of running at the default 60.
;
;   Clamped to [1, 60] inside the render thread. Default = 20 fps.
;   The framerate snaps back to 60 the moment any of the three signals
;   returns (focus, mouse-down, or hover).
;
;   Useful when several panels are open simultaneously -- idle panels
;   barely cost CPU/GPU. Setting it to 1 also makes hover-only feedback
;   visibly lazy, which is handy to debug whether a refresh is FPS-bound
;   or logic-bound.
;
;   Return : True on success, False otherwise (@error = 1 if not initialised,
;   2 if DllCall failed). The call is accepted even before _ImGui_Init in
;   recent versions -- the value sticks and is read by the render thread
;   on its next loop iteration.
;
; Initial state : 20 fps (the wrapper default, just being explicit here).
_ImGui_SetUnfocusedFps(20)


; ==============================================================================
; Demo widgets (borrowed from other examples)
; ==============================================================================
_ImGui_CreateText("t_title", "UnfocusedFps demo")
_ImGui_CreateText("t_hint1", "Drag the slider, then click another window so this one loses focus.")
_ImGui_CreateText("t_hint2", "Come back and hover this window -- the hover highlights wake up slowly")
_ImGui_CreateText("t_hint3", "at 1-5 fps and snap back to 60 the moment you click.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateSliderInt("sl_fps", "Unfocused FPS", 1, 60, 20, "%d fps")
_ImGui_CreateText("t_fps_now", "Applied : 20 fps")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_preset_hdr", "Presets :")
_ImGui_CreateButton("btn_p1",  "1 fps  (debug)")
_ImGui_CreateButton("btn_p20", "20 fps (default)")
_ImGui_CreateButton("btn_p60", "60 fps (no throttle)")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Bind events
; ==============================================================================
_ImGui_SetOnChange("sl_fps",   "_OnFpsSliderChanged")
_ImGui_SetOnClick ("btn_p1",   "_OnPresetClicked")
_ImGui_SetOnClick ("btn_p20",  "_OnPresetClicked")
_ImGui_SetOnClick ("btn_p60",  "_OnPresetClicked")
_ImGui_SetOnClick ("btn_quit", "_OnQuitClicked")


; ==============================================================================
; Main loop
; ==============================================================================
While _ImGui_IsRunning()
    Sleep(50)
WEnd


; ==============================================================================
; Cleanup
; ==============================================================================
_ImGui_Shutdown()


; ==============================================================================
; Event handlers
; ==============================================================================

Func _OnFpsSliderChanged($sId)
    Local $iFps = _ImGui_GetValueInt($sId)
    _ImGui_SetUnfocusedFps($iFps)
    _ImGui_SetText("t_fps_now", StringFormat("Applied : %d fps", $iFps))
EndFunc

; Preset buttons : apply + mirror back into the slider. Programmatic
; SetValueInt does not fire OnChange (strict semantics) -- no loop.
Func _OnPresetClicked($sId)
    Local $iFps = 20
    Switch $sId
        Case "btn_p1"
            $iFps = 1
        Case "btn_p20"
            $iFps = 20
        Case "btn_p60"
            $iFps = 60
    EndSwitch
    _ImGui_SetUnfocusedFps($iFps)
    _ImGui_SetValueInt("sl_fps", $iFps)
    _ImGui_SetText("t_fps_now", StringFormat("Applied : %d fps (preset)", $iFps))
EndFunc

Func _OnQuitClicked($sId)
    _ImGui_Shutdown()
EndFunc
