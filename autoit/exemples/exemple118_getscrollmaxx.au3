#cs
================================================================================
 Example 118 : _ImGui_GetScrollMaxX
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_GetScrollMaxX   Read the maximum horizontal scroll offset of a window

 Returns a float in pixels : the largest value GetScrollX can reach,
 i.e. how far the content extends beyond the visible width. 0 means
 the content fits horizontally without overflow.

 Use case : detect when a window does or doesn't need a horizontal
 scrollbar, or compute a horizontal scroll progress percent (
 GetScrollX / GetScrollMaxX).

 Persistent state ; 50 ms polling reliable. Value changes when the
 content size changes (e.g. user resizes a child widget, or
 SetWindowContentSize is updated).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple118_getscrollmaxx.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple118_getscrollmaxx.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 118 : _ImGui_GetScrollMaxX", 720, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_GetScrollMaxX  --  doc block
; ==============================================================================
; Signature : _ImGui_GetScrollMaxX($sId)
;
;   Returns the largest valid horizontal scroll offset, in pixels.
;   0 means the content fits horizontally without overflow.
;
;   Persistent state ; refreshes each frame. Returns 0 on unknown id
;   (no @error).


; ==============================================================================
; Host area widgets  --  buttons to expand / shrink the target content via
;                       SetWindowContentSize, so the user sees MaxX change.
; ==============================================================================
_ImGui_CreateText("t_title", "GetScrollMaxX demo  --  live ScrollMaxX driven by SetWindowContentSize")
_ImGui_CreateText("t_hint",  "Click the preset buttons. Each one changes the pinned content width, so ScrollMaxX changes accordingly.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_btn_hdr", "Pin the target's content width :")
_ImGui_CreateButton("btn_w_off",  "No pin (auto-fit)  -- MaxX usually 0")
_ImGui_CreateButton("btn_w_600",  "Pin width = 600  -- MaxX = 600 - inner-width")
_ImGui_CreateButton("btn_w_1200", "Pin width = 1200 -- bigger MaxX")
_ImGui_CreateButton("btn_w_3000", "Pin width = 3000 -- huge MaxX")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status_hdr", "Live readout :")
_ImGui_CreateText("t_max",      "  ScrollMaxX : 0 px")
_ImGui_CreateText("t_x",        "  ScrollX    : 0 px  (drag the bar to scroll)")
_ImGui_CreateText("t_overflow", "  Overflow ratio (Max / WindowWidth) : 0.00")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window  --  HorizontalScrollbar + small visible width
; ==============================================================================
_ImGui_CreateWindow("tgt", "Target window (HorizontalScrollbar)", True, $ImGuiWindowFlags_HorizontalScrollbar)
_ImGui_CreateText("tgt_t1", "Sparse content -- relies on SetWindowContentSize to declare its extent.")
_ImGui_CreateText("tgt_t2", "Try the preset buttons in the host.")
_ImGui_SetParent("tgt_t1", "tgt")
_ImGui_SetParent("tgt_t2", "tgt")
_ImGui_SetWindowPos ("tgt", 280, 240, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 360, 200, $ImGuiCond_FirstUseEver)


; --- Script-side state -------------------------------------------------------
Global $g_fPinnedW = 0.0   ; 0 = no pin


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_w_off",  "_OnPinOff")
_ImGui_SetOnClick("btn_w_600",  "_OnPin600")
_ImGui_SetOnClick("btn_w_1200", "_OnPin1200")
_ImGui_SetOnClick("btn_w_3000", "_OnPin3000")
_ImGui_SetOnClick("btn_quit",   "_OnQuit")
; ContentSize is NOT sticky : re-apply each tick. Also use the tick to refresh
; the live readout panel.
_ImGui_SetOnTick("_OnTick", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPinOff($sId)
    $g_fPinnedW = 0.0
EndFunc

Func _OnPin600($sId)
    $g_fPinnedW = 600.0
EndFunc

Func _OnPin1200($sId)
    $g_fPinnedW = 1200.0
EndFunc

Func _OnPin3000($sId)
    $g_fPinnedW = 3000.0
EndFunc

Func _OnTick()
    ; Re-apply the pinned content width every tick (not sticky -- see exemple111).
    If $g_fPinnedW > 0 Then
        _ImGui_SetWindowContentSize("tgt", $g_fPinnedW, 0.0)
    EndIf
    ; Live readouts.
    Local $fMaxX = _ImGui_GetScrollMaxX("tgt")
    Local $fX    = _ImGui_GetScrollX("tgt")
    Local $aSz   = _ImGui_GetWindowSize("tgt")
    Local $fWinW = IsArray($aSz) ? $aSz[0] : 0
    Local $fRatio = ($fWinW = 0) ? 0.0 : ($fMaxX / $fWinW)
    _ImGui_SetText("t_max", StringFormat("  ScrollMaxX : %.0f px", $fMaxX))
    _ImGui_SetText("t_x",   StringFormat("  ScrollX    : %.0f px  (drag the bar to scroll)", $fX))
    _ImGui_SetText("t_overflow", StringFormat("  Overflow ratio (Max / WindowWidth) : %.2f", $fRatio))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
