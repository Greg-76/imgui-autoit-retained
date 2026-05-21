#cs
================================================================================
 Example 172 : _ImGui_GetFontSize (+ _ImGui_GetFontCount)
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_GetFontSize    Current font's pixel size at the moment of the
                         call ; honors any active PushFont scope
   _ImGui_GetFontCount   Total number of fonts in the atlas (>= 1, the
                         default font is always index 0)

 Bundling rationale : the two exports answer different questions about
 the same registry (how many fonts ? at what size am I rendering ?) ;
 they are commonly used together by debug / style-editor code that
 needs to inspect font state at runtime.

 GetFontSize quirk : when called from the AutoIt thread between
 frames (which is when SetOnTick handlers fire), it reflects ImGui's
 "current font" -- typically the default unless a PushFont scope is
 active for the rendering pass.

 Demo : load two fonts, show their ids + the live font count + the
 live GetFontSize readout. The PushFont scope in the host area
 changes the font for the wrapped text widgets ; GetFontSize from
 the AutoIt poll still reads the default (since the poll runs
 between frames, not inside a render pass).

 Borrowed widgets : LoadFont (exemple170), PushFont + PopFont
 (exemple86 / 87), Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple172_font_meta.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple172_font_meta.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 172 : GetFontSize + GetFontCount", 720, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 2-export cluster
; ==============================================================================
; GetFontSize()   -> float ; current font's pixel size (honors active
;                          PushFont scope ; reflects default outside
;                          any scope).
; GetFontCount()  -> int >= 1 ; total fonts in the atlas (default at
;                              index 0 + any LoadFont* additions).


; ==============================================================================
; Pre-load two fonts at distinct sizes so the count + readout vary
; ==============================================================================
Global Const $g_sFontsDir = @ScriptDir & "\..\..\dll\imgui-docking\misc\fonts"
Global $g_iBig    = _ImGui_LoadFont($g_sFontsDir & "\DroidSans.ttf",     24.0)
Global $g_iSmall  = _ImGui_LoadFont($g_sFontsDir & "\ProggyClean.ttf",   13.0)


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "GetFontSize + GetFontCount  --  live metadata readout of the font atlas")
_ImGui_CreateText("t_ids",   StringFormat("font_ids :  big (DroidSans 24) = %d   small (ProggyClean 13) = %d   (-1 = file missing)", $g_iBig, $g_iSmall))
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Live readouts
; ==============================================================================
_ImGui_CreateText("t_count",  "GetFontCount : (waiting)")
_ImGui_CreateText("t_size",   "GetFontSize  : (waiting)  -- reflects ImGui's current font between frames")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Three text widgets, each in a different font scope
; ==============================================================================
_ImGui_CreateText("t_def_hdr", "Default font (font_id = 0) :")
_ImGui_CreateText("t_def_txt", "  Sample line in the default font.")
_ImGui_CreateSeparator("sep2")

If $g_iBig >= 0 Then
    _ImGui_CreateText("t_big_hdr", "Big font scope (DroidSans 24pt) :")
    _ImGui_CreatePushFont("pf_big", $g_iBig)
    _ImGui_CreateText("t_big_txt", "  Sample line in big font.")
    _ImGui_CreatePopFont("pop_big")
    _ImGui_CreateSeparator("sep3")
EndIf

If $g_iSmall >= 0 Then
    _ImGui_CreateText("t_sm_hdr", "Small font scope (ProggyClean 13pt) :")
    _ImGui_CreatePushFont("pf_sm", $g_iSmall)
    _ImGui_CreateText("t_sm_txt", "  Sample line in the small font.")
    _ImGui_CreatePopFont("pop_sm")
    _ImGui_CreateSeparator("sep4")
EndIf

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPollMeta", 200)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollMeta()
    Local $iCount = _ImGui_GetFontCount()
    Local $fSize  = _ImGui_GetFontSize()
    _ImGui_SetText("t_count", "GetFontCount : " & $iCount & "  (1 default + any LoadFont additions above)")
    _ImGui_SetText("t_size",  StringFormat("GetFontSize  : %.2f px  --  reflects current font between frames (= default outside any render-time PushFont scope)", $fSize))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
