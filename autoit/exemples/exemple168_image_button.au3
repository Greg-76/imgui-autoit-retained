#cs
================================================================================
 Example 168 : _ImGui_CreateImageButton
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateImageButton   Clickable image button rendering a previously
                              loaded texture (latches Widget::clicked)

 ClickableWidget under the hood -- latches `clicked` exactly like
 Button (exemple5). Bind _ImGui_SetOnClick or poll _ImGui_WasClicked.
 SetOnChange is NOT meaningful here (no value to change).

 $sLabel is the ImGui id seed -- it is NOT rendered visually (the
 texture is what the user sees). Different buttons can reuse the
 same texture as long as $sId is unique.

 Same sizing rules as CreateImage (exemple167) : 0, 0 = native ;
 otherwise stretches.

 Borrowed widgets : LoadTexture (exemple166), Image (exemple167),
 SameLine, Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple168_image_button.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple168_image_button.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 168 : _ImGui_CreateImageButton", 720, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateImageButton  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateImageButton($sId, $sLabel, $iTexId,
;                                       $fW = 0.0, $fH = 0.0)
;
;   $sLabel  : ImGui id seed only -- NOT drawn. Useful when the same
;              texture is reused across multiple buttons (each gets
;              its own unique $sId, ImGui's id stack reads $sLabel).
;
;   $iTexId  : tex_id returned by _ImGui_LoadTexture (exemple166).
;
;   $fW, $fH : 0, 0 = native ; otherwise stretches the texture.
;
;   Event model :
;     ClickableWidget. Latches Widget::clicked. Bind via
;     _ImGui_SetOnClick or poll _ImGui_WasClicked. No SetOnChange.
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Load the demo texture
; ==============================================================================
Global $g_iW = 0, $g_iH = 0
Global $g_iTex = _ImGui_LoadTexture(@ScriptDir & "\images.png", $g_iW, $g_iH)

_ImGui_CreateText("t_title", "CreateImageButton demo  --  3 clickable thumbnails (same texture, different ids)")
_ImGui_CreateText("t_status", StringFormat("tex_id = %d   native (W, H) = (%d, %d)", $g_iTex, $g_iW, $g_iH))
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Three 80x80 image buttons in a row, same texture, distinct ids
; ==============================================================================
_ImGui_CreateText("t_btn_hdr", "Click any button below ; counters update via SetOnClick.")
If $g_iTex >= 0 Then
    _ImGui_CreateImageButton("ib_one",   "one",   $g_iTex, 80, 80)
    _ImGui_CreateSameLine("sl1")
    _ImGui_CreateImageButton("ib_two",   "two",   $g_iTex, 80, 80)
    _ImGui_CreateSameLine("sl2")
    _ImGui_CreateImageButton("ib_three", "three", $g_iTex, 80, 80)
Else
    _ImGui_CreateText("t_no_tex", "  (texture missing -- buttons skipped)")
EndIf

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Native-size button + bad tex_id placeholder
; ==============================================================================
_ImGui_CreateText("t_native_hdr", "Native-size button + bad-id placeholder :")
If $g_iTex >= 0 Then
    _ImGui_CreateImageButton("ib_native", "native", $g_iTex, 0, 0)
    _ImGui_CreateSameLine("sl3")
EndIf
_ImGui_CreateImageButton("ib_bad", "bad", 999, 80, 80)

_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Counters
; ==============================================================================
_ImGui_CreateText("t_counters", "  Clicks  --  one: 0   two: 0   three: 0   native: 0   bad: 0")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters ---------------------------------------------------------------
Global $g_iCnt1 = 0
Global $g_iCnt2 = 0
Global $g_iCnt3 = 0
Global $g_iCntN = 0
Global $g_iCntB = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("ib_one",    "_OnClick1")
_ImGui_SetOnClick("ib_two",    "_OnClick2")
_ImGui_SetOnClick("ib_three",  "_OnClick3")
_ImGui_SetOnClick("ib_native", "_OnClickN")
_ImGui_SetOnClick("ib_bad",    "_OnClickB")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnClick1($sId)
    $g_iCnt1 += 1
    _Refresh()
EndFunc

Func _OnClick2($sId)
    $g_iCnt2 += 1
    _Refresh()
EndFunc

Func _OnClick3($sId)
    $g_iCnt3 += 1
    _Refresh()
EndFunc

Func _OnClickN($sId)
    $g_iCntN += 1
    _Refresh()
EndFunc

Func _OnClickB($sId)
    ; The bad-id placeholder still responds to clicks -- the widget exists
    ; even when the texture lookup fails.
    $g_iCntB += 1
    _Refresh()
EndFunc

Func _Refresh()
    _ImGui_SetText("t_counters", StringFormat("  Clicks  --  one: %d   two: %d   three: %d   native: %d   bad: %d", _
        $g_iCnt1, $g_iCnt2, $g_iCnt3, $g_iCntN, $g_iCntB))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
