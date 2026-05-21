#cs
================================================================================
 Example 152 : _ImGui_IsMouseHoveringRect
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_IsMouseHoveringRect   True iff the mouse is inside the given
                                screen-space rectangle

 Rect is in IMGUI SCREEN-SPACE (same coordinate system as
 _ImGui_GetMousePos and _ImGui_GetItemRectMin/Max -- exemple98).
 Useful for custom hit-tests on a region that isn't itself a widget :
 a hand-painted hot-zone, a layout cell in a manually-drawn grid, a
 collision target you compute from script-side data.

 Two demo rects side by side :
   * STATIC  --  hard-coded screen coords, never moves.
   * DYNAMIC --  follows the live position of a host widget via
                 _ImGui_GetItemRectMin/Max (exemple98). When the
                 user resizes the window or scrolls, the rect tracks.

 PITFALL : the $bClip parameter is accepted for API symmetry but
 TREATED AS FALSE by the DLL. clip=true would dereference ImGui's
 current window pointer, which is null on the AutoIt thread (we run
 between frames). If you need window-local clipping, intersect the
 rect with _ImGui_GetWindowPos + _ImGui_GetWindowSize BEFORE calling.

 Borrowed widgets : GetItemRectMin/Max (exemple98), Button, Text +
 Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple152_mouse_hovering_rect.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple152_mouse_hovering_rect.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 152 : _ImGui_IsMouseHoveringRect", 760, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsMouseHoveringRect  --  doc block
; ==============================================================================
; Signature : _ImGui_IsMouseHoveringRect($fMinX, $fMinY,
;                                         $fMaxX, $fMaxY,
;                                         $bClip = True)
;
;   $fMinX / $fMinY : top-left corner    (screen pixels)
;   $fMaxX / $fMaxY : bottom-right corner (screen pixels)
;
;   $bClip : accepted for API symmetry ONLY -- the DLL always uses
;            False. For window-local clipping, intersect the rect
;            with the host window's GetWindowPos + GetWindowSize
;            BEFORE the call.
;
;   Return : True while the mouse is inside the rect, False
;            otherwise / DLL not loaded.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "IsMouseHoveringRect  --  custom screen-space hit test (static + dynamic rects)")
_ImGui_CreateText("t_hint",  "Hover the area defined by the rects. Static = hard-coded. Dynamic = follows the target button.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; The DYNAMIC target  --  a regular Button. We read its rect every tick.
; ==============================================================================
_ImGui_CreateButton("btn_target", "  DYNAMIC target button  --  hover me, the rect under me reports True  ")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; STATIC rect coords  --  arbitrary screen-space (chosen to leave room above
;                        and below the demo widgets ; tweak if needed).
; ==============================================================================
Global Const $g_fStaticMinX = 240.0
Global Const $g_fStaticMinY = 240.0
Global Const $g_fStaticMaxX = 480.0
Global Const $g_fStaticMaxY = 320.0

_ImGui_CreateText("t_static_hdr", StringFormat("STATIC rect  --  (%.0f, %.0f) -> (%.0f, %.0f) :", _
    $g_fStaticMinX, $g_fStaticMinY, $g_fStaticMaxX, $g_fStaticMaxY))
_ImGui_CreateText("t_static_status", "  hover state : False")


; ==============================================================================
; DYNAMIC rect coords  --  follow btn_target via GetItemRectMin/Max
; ==============================================================================
_ImGui_CreateText("t_dyn_hdr", "DYNAMIC rect  --  tracks btn_target via GetItemRectMin/Max :")
_ImGui_CreateText("t_dyn_coords", "  rect = (0, 0) -> (0, 0)")
_ImGui_CreateText("t_dyn_status", "  hover state : False")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_mouse", "Live mouse pos : (0.0, 0.0)")

_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPollHover", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollHover()
    ; Live mouse pos -----------------------------------------------------------
    Local $aPos = _ImGui_GetMousePos()
    If IsArray($aPos) Then
        _ImGui_SetText("t_mouse", StringFormat("Live mouse pos : (%.1f, %.1f)", $aPos[0], $aPos[1]))
    EndIf

    ; STATIC rect --------------------------------------------------------------
    Local $bStaticIn = _ImGui_IsMouseHoveringRect( _
        $g_fStaticMinX, $g_fStaticMinY, $g_fStaticMaxX, $g_fStaticMaxY)
    _ImGui_SetText("t_static_status", "  hover state : " & ($bStaticIn ? "True " : "False"))

    ; DYNAMIC rect -- live from GetItemRectMin / Max --------------------------
    Local $aMin = _ImGui_GetItemRectMin("btn_target")
    Local $aMax = _ImGui_GetItemRectMax("btn_target")
    If IsArray($aMin) And IsArray($aMax) Then
        _ImGui_SetText("t_dyn_coords", StringFormat( _
            "  rect = (%.0f, %.0f) -> (%.0f, %.0f)", $aMin[0], $aMin[1], $aMax[0], $aMax[1]))
        Local $bDynIn = _ImGui_IsMouseHoveringRect($aMin[0], $aMin[1], $aMax[0], $aMax[1])
        _ImGui_SetText("t_dyn_status", "  hover state : " & ($bDynIn ? "True " : "False"))
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
