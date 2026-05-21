#cs
================================================================================
 Example 182 : _ImGui_CalcTextSize
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CalcTextSize   Measure a string in the currently active font
                         (with optional wrapping)  --  array[2] = (w, h)

 Pure measurement helper -- no widget, no marker, no scope. Useful
 for manual layout :
   * Centering         : compute textW, then SetCursorPosX((window
                         W - textW) / 2) before the Text widget.
   * Right-alignment   : same idea with (window W - textW - padding).
   * Custom panels     : pre-size a Child / Group to fit measured
                         content.
   * Wrap simulation   : measure with $fWrapWidth > 0 to predict the
                         multi-line bounding box ahead of render.

 $fWrapWidth :
   * <= 0    no wrap (single-line measurement, height = font line height)
   *  > 0    wrap at the given pixel width (height grows by line count)

 Returns array[2] = (width, height) in CURRENT-FONT pixels. If a
 PushFont scope (exemple86) is active at render time, the result
 reflects that font. From the AutoIt thread between frames, the
 default font is in effect (see exemple172).

 Borrowed widgets : SetCursorPosX (exemple179) for centering,
 InputText (exemple147) for live measurement, Text + Separator +
 Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple182_calctextsize.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple182_calctextsize.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 182 : _ImGui_CalcTextSize", 760, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CalcTextSize  --  doc block
; ==============================================================================
; Signature : _ImGui_CalcTextSize($sText, $fWrapWidth = -1.0)
;
;   $sText      : text to measure (UTF-8).
;   $fWrapWidth : pixel width for wrap simulation. <= 0 = no wrap.
;
;   Return : array[2] = (width, height) in current-font pixels.
;            (0, 0) with @error on failure (1, 2, 3).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CalcTextSize demo  --  measure strings + canonical centering pattern")
_ImGui_CreateText("t_hint",  "Type below to measure live ; toggle wrap to see wrap-aware sizing.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Live measurement of an InputText  --  no wrap
; ==============================================================================
_ImGui_CreateText("t_live_hdr", "Live measure of an InputText (no wrap) :")
_ImGui_CreateInputText("in_text", "##text", "Type something here", 256)
_ImGui_CreateText("t_live_dims", "  CalcTextSize : (w, h) = (0.0, 0.0)")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Wrap-aware measurement  --  wrap a long string at 200 px
; ==============================================================================
_ImGui_CreateText("t_wrap_hdr", "Wrap-aware measurement (same input string, wrap at 200 px) :")
_ImGui_CreateText("t_wrap_dims", "  CalcTextSize(text, 200) : (w, h) = (0.0, 0.0)")
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Centering pattern  --  SetCursorPosX((window_w - text_w) / 2)
; ==============================================================================
_ImGui_CreateText("t_center_hdr", "Centering pattern  --  CalcTextSize + SetCursorPosX :")

; We center on assumed window width = 700 px content region. In real code you'd
; read the live window width via GetWindowSize (exemple107).
Global Const $g_fAssumedWinW = 700.0
Global Const $g_sCenteredText = "I am centered horizontally."
Local $aSize = _ImGui_CalcTextSize($g_sCenteredText)
Local $fX = ($g_fAssumedWinW - $aSize[0]) / 2.0
_ImGui_CreateSetCursorPosX("set_center", $fX)
_ImGui_CreateText("t_centered", $g_sCenteredText)
_ImGui_CreateSeparator("sep3")


; ==============================================================================
; Right-alignment pattern  --  same idea, anchor on (window_w - text_w - pad)
; ==============================================================================
_ImGui_CreateText("t_right_hdr", "Right-alignment  --  similar idiom, anchor at (window_w - text_w - 20) :")
Global Const $g_sRightText = "right-aligned"
Local $aRSize = _ImGui_CalcTextSize($g_sRightText)
Local $fRX = $g_fAssumedWinW - $aRSize[0] - 20.0
_ImGui_CreateSetCursorPosX("set_right", $fRX)
_ImGui_CreateText("t_right", $g_sRightText)
_ImGui_CreateSeparator("sep4")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPoll", 200)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPoll()
    Local $sLive = _ImGui_GetValueString("in_text")
    Local $aNoWrap = _ImGui_CalcTextSize($sLive)
    Local $aWrap   = _ImGui_CalcTextSize($sLive, 200.0)
    If IsArray($aNoWrap) Then _ImGui_SetText("t_live_dims", StringFormat("  CalcTextSize : (w, h) = (%.1f, %.1f)", $aNoWrap[0], $aNoWrap[1]))
    If IsArray($aWrap)   Then _ImGui_SetText("t_wrap_dims", StringFormat("  CalcTextSize(text, 200) : (w, h) = (%.1f, %.1f)", $aWrap[0], $aWrap[1]))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
