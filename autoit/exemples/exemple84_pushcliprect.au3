#cs
================================================================================
 Example 84 : _ImGui_CreatePushClipRect
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePushClipRect   Push a clipping rectangle onto the draw stack

 PushClipRect restricts subsequent rendering to a screen-space
 rectangle. Anything drawn outside that rect (Text glyphs, Button
 backgrounds, Slider tracks, custom DrawList primitives, ...) is
 visually clipped -- the LAYOUT is unaffected, only the pixels.

 Primary use cases :
   - Custom DrawList overlays where you want to confine your drawing
     to a sub-region.
   - Force-clipping wide widgets that overflow their column in a
     fake table layout.
   - Debugging : push a tiny rect to highlight which widgets fall
     inside vs outside a region.

 The rect is in SCREEN-SPACE pixel coordinates -- not relative to
 the current ImGui window. Resizing or moving the window does NOT
 move the clip rect. For window-relative clipping you have to compute
 the coordinates yourself based on _ImGui_GetWindowPos.

 Pair with PopClipRect (exemple85). Mismatched Push/Pop -> ImGui
 asserts at end of frame.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple84_pushcliprect.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple84_pushcliprect.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 84 : _ImGui_CreatePushClipRect", 680, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePushClipRect  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePushClipRect($sId,
;                                        $fMinX = 0.0, $fMinY = 0.0,
;                                        $fMaxX = 0.0, $fMaxY = 0.0,
;                                        $bIntersect = 1)
;
;   $fMinX / $fMinY / $fMaxX / $fMaxY : top-left and bottom-right of
;     the clip rect, in screen-space pixels.
;
;   $bIntersect (default True / 1) :
;     True  -> intersect with the current clip rect (additive clipping).
;              This is the safest mode -- you can never make the area
;              larger than the parent's clip.
;     False -> replace the current clip rect entirely. Use sparingly
;              -- it lets you draw outside the window's own clip area.
;
;   Coordinates are in screen-space, NOT window-relative. The values
;   below assume the ImGui window is in its initial position.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three sections clipping at different rects
; ==============================================================================
_ImGui_CreateText("t_title", "PushClipRect demo  --  visible clipping of widget rendering")
_ImGui_CreateText("t_hint",  "Wide widgets are clipped on the right by the pushed rectangles. Layout space is reserved but pixels are dropped.")
_ImGui_CreateText("t_caveat","Note : clip rects are SCREEN-SPACE absolute. Moving the window will desync them ; reopen the script if you reposition.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Reference -- no clip ------------------------------------------------
_ImGui_CreateText("a_hdr", "(A) No clip (reference) -- the full button width is visible :")
_ImGui_CreateButton("a_b", "A reasonably long button label so we have something to clip later")
_ImGui_CreateSeparator("sep_a")

; --- (B) Clip rect (0..220 px, 80..200 px) -----------------------------------
; The Y range is wide enough to cover one row of widgets ; the X range cuts
; off the right side of the button label. Adjust if your ImGui window position
; differs from the initial layout.
_ImGui_CreateText("b_hdr", "(B) PushClipRect(0, 0, 220, 999) -- only the leftmost 220 px of the button are drawn :")
_ImGui_CreatePushClipRect("pcr_b", 0.0, 0.0, 220.0, 999.0, 1)
_ImGui_CreateButton("b_b", "Same long button label as above, now clipped at 220 px from the screen left")
_ImGui_CreatePopClipRect("pcr_b_pop")
_ImGui_CreateButton("b_after","After Pop : full width again, clipping gone")
_ImGui_CreateSeparator("sep_b")

; --- (C) Narrower clip + multiple widgets ------------------------------------
_ImGui_CreateText("c_hdr", "(C) PushClipRect(0, 0, 120, 999) -- 120 px slice on the left :")
_ImGui_CreatePushClipRect("pcr_c", 0.0, 0.0, 120.0, 999.0, 1)
_ImGui_CreateButton("c_b1",  "Cut at 120 px")
_ImGui_CreateCheckbox("c_cb","Same here -- 120 px clip applies", True)
_ImGui_CreateInputText("c_in","##c_in", "Input field clipped", 64, 0)
_ImGui_CreatePopClipRect("pcr_c_pop")
_ImGui_CreateButton("c_after","After Pop : unclipped row")
_ImGui_CreateSeparator("sep_c")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
