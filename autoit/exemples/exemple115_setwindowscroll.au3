#cs
================================================================================
 Example 115 : _ImGui_SetWindowScroll
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetWindowScroll   Set the scroll BEFORE the window's next Begin (one-shot)

 The "restore saved scroll" setter : applied BEFORE the window
 lays out its children. This is the right call when you reopen a
 window and want to start at a specific scroll offset (e.g. restore
 a previously-saved position).

 DISTINCT from _ImGui_SetScrollX / _ImGui_SetScrollY (exemple122/123)
 which fire AFTER children render -- those are for "scroll to
 bottom" semantics in a log panel that just got a new line appended.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple115_setwindowscroll.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple115_setwindowscroll.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 115 : _ImGui_SetWindowScroll", 740, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetWindowScroll  --  doc block
; ==============================================================================
; Signature : _ImGui_SetWindowScroll($sId, $fX, $fY)
;
;   $fX / $fY : scroll offsets in pixels. Negative values clamp to 0 ;
;               values larger than ScrollMax* clamp to that max.
;
;   Applied BEFORE the window's next Begin -- ideal for restoring a
;   saved scroll position when a panel reopens.
;
;   Return : True on success, False on failure (@error = 1, 2, or 3).


; ==============================================================================
; Host area widgets  --  preset buttons + save / restore demo
; ==============================================================================
_ImGui_CreateText("t_title", "SetWindowScroll demo  --  pre-Begin scroll override + save / restore pattern")
_ImGui_CreateText("t_hint",  "Click a preset to snap the target's scroll. Save then scroll then Restore to see the round-trip.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_btn_hdr", "Snap to a specific scroll offset :")
_ImGui_CreateButton("btn_top",  "Snap to (0, 0)        -- scroll to top")
_ImGui_CreateButton("btn_mid",  "Snap to (0, 300)     -- middle-ish")
_ImGui_CreateButton("btn_end",  "Snap to (0, 99999)  -- ImGui clamps to ScrollMaxY")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_save_hdr", "Save / restore pattern (canonical use case) :")
_ImGui_CreateButton("btn_save",    "Save current scroll")
_ImGui_CreateButton("btn_restore", "Restore the saved scroll")
_ImGui_CreateText("t_saved",       "  Saved Y = (none yet)")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_status_hdr", "Live scroll readout :")
_ImGui_CreateText("t_scroll",     "  Target scroll : Y = 0 / max 0")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window  --  fill with enough widgets to require scrolling
; ==============================================================================
_ImGui_CreateWindow("tgt", "Target window (scrollable)", True, 0)
_ImGui_CreateText("tgt_head", "Top of the list -- scroll down to see all items.")
_ImGui_SetParent("tgt_head", "tgt")

; 30 items so there is clearly more than fits in the visible area.
For $i = 1 To 30
    Local $sId = "tgt_item_" & $i
    _ImGui_CreateText($sId, "  Item #" & $i & " in the scrollable list.")
    _ImGui_SetParent($sId, "tgt")
Next

_ImGui_CreateText("tgt_tail", "Bottom of the list -- you can see me when scrolled fully down.")
_ImGui_SetParent("tgt_tail", "tgt")

_ImGui_SetWindowPos ("tgt", 280, 220, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 360, 200, $ImGuiCond_FirstUseEver)


; --- Script-side state -------------------------------------------------------
Global $g_fSavedScrollY = -1.0   ; -1 sentinel = nothing saved yet


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_top",     "_OnSnapTop")
_ImGui_SetOnClick("btn_mid",     "_OnSnapMid")
_ImGui_SetOnClick("btn_end",     "_OnSnapEnd")
_ImGui_SetOnClick("btn_save",    "_OnSave")
_ImGui_SetOnClick("btn_restore", "_OnRestore")
_ImGui_SetOnClick("btn_quit",    "_OnQuit")
_ImGui_SetOnTick ("_OnPollScroll", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnSnapTop($sId)
    _ImGui_SetWindowScroll("tgt", 0.0, 0.0)
EndFunc

Func _OnSnapMid($sId)
    _ImGui_SetWindowScroll("tgt", 0.0, 300.0)
EndFunc

Func _OnSnapEnd($sId)
    ; Pass a very large value -- ImGui clamps to ScrollMaxY.
    _ImGui_SetWindowScroll("tgt", 0.0, 99999.0)
EndFunc

Func _OnSave($sId)
    Local $fY = _ImGui_GetScrollY("tgt")
    $g_fSavedScrollY = $fY
    _ImGui_SetText("t_saved", StringFormat("  Saved Y = %.0f px", $fY))
EndFunc

Func _OnRestore($sId)
    If $g_fSavedScrollY < 0 Then
        _ImGui_SetText("t_saved", "  Saved Y = (none yet -- click Save first)")
        Return
    EndIf
    _ImGui_SetWindowScroll("tgt", 0.0, $g_fSavedScrollY)
EndFunc

Func _OnPollScroll()
    Local $fY    = _ImGui_GetScrollY("tgt")
    Local $fMaxY = _ImGui_GetScrollMaxY("tgt")
    _ImGui_SetText("t_scroll", StringFormat("  Target scroll : Y = %.0f / max %.0f", $fY, $fMaxY))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
