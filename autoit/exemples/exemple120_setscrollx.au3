#cs
================================================================================
 Example 120 : _ImGui_SetScrollX
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetScrollX   Queue an absolute horizontal scroll for the next frame

 Sets the window's horizontal scroll to an absolute pixel offset.
 Applied AFTER the children are laid out -- distinct from
 _ImGui_SetWindowScroll (exemple115) which applies BEFORE the
 window's next Begin.

 Practical difference :
   - SetWindowScroll : "restore a saved scroll position when reopening"
   - SetScrollX / SetScrollY : "scroll to a specific position relative to
     the laid-out content" (canonical use : auto-scroll a log panel to
     the right end after appending a new line)

 Persistent across frames? No -- this is a one-shot per call. Re-call
 from OnTick if you want continuous tracking (e.g. animated scroll).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple120_setscrollx.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple120_setscrollx.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 120 : _ImGui_SetScrollX", 720, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetScrollX  --  doc block
; ==============================================================================
; Signature : _ImGui_SetScrollX($sId, $fScroll)
;
;   $fScroll : horizontal scroll target in pixels. 0 = left-most.
;              Values >= GetScrollMaxX clamp to the maximum.
;
;   One-shot ; applied AFTER children are rendered. Use SetWindowScroll
;   (exemple115) for the BEFORE-Begin variant.
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded,
;     2=DllCall failed, 3=unknown id or not a scrollable widget).


; ==============================================================================
; Host area widgets  --  buttons to scroll the target horizontally
; ==============================================================================
_ImGui_CreateText("t_title", "SetScrollX demo  --  absolute horizontal scroll set after children render")
_ImGui_CreateText("t_hint",  "Click a preset to snap the target's horizontal scroll. The status panel shows the current X.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_btn_hdr", "Snap horizontal scroll :")
_ImGui_CreateButton("btn_left",  "Snap to 0    (left-most)")
_ImGui_CreateButton("btn_mid",   "Snap to 200  (mid-ish)")
_ImGui_CreateButton("btn_far",   "Snap to 600  (or clamped to ScrollMaxX)")
_ImGui_CreateButton("btn_end",   "Snap to 99999 (clamps to ScrollMaxX = right-most)")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Live readout :")
_ImGui_CreateText("t_x",          "  ScrollX    : 0 px")
_ImGui_CreateText("t_max",        "  ScrollMaxX : 0 px")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window  --  HorizontalScrollbar + wide content
; ==============================================================================
_ImGui_CreateWindow("tgt", "Target window (horizontal scroll)", True, $ImGuiWindowFlags_HorizontalScrollbar)
_ImGui_CreateText("tgt_t1", "Drag the host buttons to snap me.")
_ImGui_SetParent("tgt_t1", "tgt")
_ImGui_CreateText("tgt_long", "(wide single-line) -- aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
_ImGui_SetParent("tgt_long", "tgt")
_ImGui_SetWindowPos ("tgt", 280, 240, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 380, 180, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_left", "_OnLeft")
_ImGui_SetOnClick("btn_mid",  "_OnMid")
_ImGui_SetOnClick("btn_far",  "_OnFar")
_ImGui_SetOnClick("btn_end",  "_OnEnd")
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollX", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnLeft($sId)
    _ImGui_SetScrollX("tgt", 0.0)
EndFunc

Func _OnMid($sId)
    _ImGui_SetScrollX("tgt", 200.0)
EndFunc

Func _OnFar($sId)
    _ImGui_SetScrollX("tgt", 600.0)
EndFunc

Func _OnEnd($sId)
    _ImGui_SetScrollX("tgt", 99999.0)
EndFunc

Func _OnPollX()
    _ImGui_SetText("t_x",   StringFormat("  ScrollX    : %.0f px", _ImGui_GetScrollX("tgt")))
    _ImGui_SetText("t_max", StringFormat("  ScrollMaxX : %.0f px", _ImGui_GetScrollMaxX("tgt")))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
