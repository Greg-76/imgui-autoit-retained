#cs
================================================================================
 Example 111 : _ImGui_SetWindowContentSize
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetWindowContentSize   Pin the content area used to compute scrollbar extents

 By default ImGui computes the window's scrollbar extents from the
 cumulative bounding rect of the child widgets. SetWindowContentSize
 lets you OVERRIDE that : you declare the content size yourself, and
 ImGui sizes its scrollbars accordingly -- even if the actual visible
 widgets occupy less space.

 This is mostly useful with the HorizontalScrollbar window flag : it
 lets you simulate "this window holds a 1000-pixel-wide canvas" even
 if you only drew a few labels into it.

 PITFALL : SetWindowContentSize is NOT sticky like
 SetWindowSizeConstraints. It must be re-called every frame to keep
 the override active. This file uses _ImGui_SetOnTick to enforce
 the size each tick.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple111_setwindowcontentsize.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple111_setwindowcontentsize.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 111 : _ImGui_SetWindowContentSize", 720, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetWindowContentSize  --  doc block
; ==============================================================================
; Signature : _ImGui_SetWindowContentSize($sId, $fW, $fH)
;
;   $fW / $fH : pinned content width / height in pixels. Pass 0 on an
;               axis to let ImGui auto-fit on that axis (the default).
;
;   NOT sticky : re-call each frame (typically from OnTick) to keep
;   the override active. Re-calling with (0, 0) restores auto-fit
;   on the next frame.
;
;   Combined with $ImGuiWindowFlags_HorizontalScrollbar this lets you
;   simulate a wide virtual canvas inside a narrow window.
;
;   Return : True on success, False on failure (@error = 1, 2, or 3).


; ==============================================================================
; Host area widgets  --  toggle the content-size override on / off
; ==============================================================================
_ImGui_CreateText("t_title", "SetWindowContentSize demo  --  pin content extent for scrollbars")
_ImGui_CreateText("t_hint",  "The target window has HorizontalScrollbar enabled. Toggle the override to see the scrollbar extent change.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateCheckbox("cb_override", "Enforce ContentSize = 1200 x 600 (re-called each tick)", False)
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Status :")
_ImGui_CreateText("t_active",     "  Override : OFF -- ImGui auto-fits to children")
_ImGui_CreateText("t_scroll",     "  Target ScrollMaxX : 0 px  (no horizontal overflow without override)")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window  --  HorizontalScrollbar enabled, narrow visible width.
; ==============================================================================
_ImGui_CreateWindow("tgt", "Target window (HorizontalScrollbar)", True, $ImGuiWindowFlags_HorizontalScrollbar)
_ImGui_CreateText("tgt_t1", "Few children -- auto-fit gives a small horizontal extent.")
_ImGui_CreateText("tgt_t2", "Enable the override above to force a 1200-wide content.")
_ImGui_CreateText("tgt_t3", "Then scroll horizontally with the bar at the bottom.")
_ImGui_SetParent("tgt_t1", "tgt")
_ImGui_SetParent("tgt_t2", "tgt")
_ImGui_SetParent("tgt_t3", "tgt")
_ImGui_SetWindowPos ("tgt", 220, 240, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 360, 160, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit",   "_OnQuit")
_ImGui_SetOnChange("cb_override","_OnToggleOverride")
; Re-call the override each frame when the checkbox is on (the override is
; not sticky -- see the doc block).
_ImGui_SetOnTick("_OnEnforceContentSize", 16)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnToggleOverride($sId)
    Local $bOn = _ImGui_GetValueBool($sId)
    _ImGui_SetText("t_active", "  Override : " & ($bOn ? "ON  -- ContentSize pinned at 1200 x 600" _
                                                       : "OFF -- ImGui auto-fits to children"))
EndFunc

Func _OnEnforceContentSize()
    If _ImGui_GetValueBool("cb_override") Then
        _ImGui_SetWindowContentSize("tgt", 1200.0, 600.0)
    EndIf
    ; Live readout of the horizontal scroll extent.
    Local $fMaxX = _ImGui_GetScrollMaxX("tgt")
    _ImGui_SetText("t_scroll", StringFormat("  Target ScrollMaxX : %.0f px  %s", _
                                            $fMaxX, _
                                            ($fMaxX > 0) ? "(scroll horizontally with the bar)" : "(no horizontal overflow yet)"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
