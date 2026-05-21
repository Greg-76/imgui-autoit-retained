#cs
================================================================================
 Example 109 : _ImGui_SetWindowSize
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetWindowSize   Queue a one-shot SetNextWindowSize for the next Render

 Mirror of SetWindowPos (exemple108) for the dimensions. Same $iCond
 semantics ; same one-shot vs continuous-override discussion. Use
 $fW = 0 (or $fH = 0) on an axis to keep the current size on that axis.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple109_setwindowsize.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple109_setwindowsize.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 109 : _ImGui_SetWindowSize", 700, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetWindowSize  --  doc block
; ==============================================================================
; Signature : _ImGui_SetWindowSize($sId, $fW, $fH, $iCond = 0)
;
;   $fW / $fH : target width / height in pixels. Pass 0 on an axis to
;               keep the current size on that axis.
;   $iCond    : same condition variants as SetWindowPos (Always /
;               Once / FirstUseEver / Appearing).
;
;   Return : True on success, False on failure (@error = 1, 2, or 3
;            same as SetWindowPos).


; ==============================================================================
; Host area widgets  --  preset buttons
; ==============================================================================
_ImGui_CreateText("t_title", "SetWindowSize demo  --  preset sizes with the four $iCond variants")
_ImGui_CreateText("t_hint",  "Click a preset to resize the target. Drag its edges between clicks to see how each condition behaves.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_btn_hdr", "Resize presets (target = the sub-window below) :")
_ImGui_CreateButton("btn_compact",  "Compact  (200 x 100)  Cond_Always")
_ImGui_CreateButton("btn_default",  "Default  (320 x 200)  Cond_Always")
_ImGui_CreateButton("btn_wide",     "Wide     (500 x 150)  Cond_Always")
_ImGui_CreateButton("btn_tall",     "Tall     (220 x 320)  Cond_Always")
_ImGui_CreateButton("btn_widthonly","Width only (400 x 0)  Cond_Always  -- height kept")
_ImGui_CreateButton("btn_appearing","Snap to (300 x 240) Cond_Appearing -- applies when hidden -> visible")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateButton("btn_hide_target","Hide the target window")
_ImGui_CreateButton("btn_show_target","Show the target window")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_status_hdr", "Live size :")
_ImGui_CreateText("t_size",       "  Target size : 0 x 0  (aspect 0.00)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window
; ==============================================================================
_ImGui_CreateWindow("tgt", "Target window (resize me)", True, 0)
_ImGui_CreateText("tgt_t1", "Resize via host buttons OR drag my edges.")
_ImGui_CreateText("tgt_t2", "Live size shown in the host panel.")
_ImGui_SetParent("tgt_t1", "tgt")
_ImGui_SetParent("tgt_t2", "tgt")
_ImGui_SetWindowPos ("tgt", 200, 220, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 320, 160, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_compact",     "_OnCompact")
_ImGui_SetOnClick("btn_default",     "_OnDefault")
_ImGui_SetOnClick("btn_wide",        "_OnWide")
_ImGui_SetOnClick("btn_tall",        "_OnTall")
_ImGui_SetOnClick("btn_widthonly",   "_OnWidthOnly")
_ImGui_SetOnClick("btn_appearing",   "_OnAppearing")
_ImGui_SetOnClick("btn_hide_target", "_OnHideTarget")
_ImGui_SetOnClick("btn_show_target", "_OnShowTarget")
_ImGui_SetOnClick("btn_quit",        "_OnQuit")
_ImGui_SetOnTick ("_OnPollSize", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnCompact($sId)
    _ImGui_SetWindowSize("tgt", 200, 100, $ImGuiCond_Always)
EndFunc

Func _OnDefault($sId)
    _ImGui_SetWindowSize("tgt", 320, 200, $ImGuiCond_Always)
EndFunc

Func _OnWide($sId)
    _ImGui_SetWindowSize("tgt", 500, 150, $ImGuiCond_Always)
EndFunc

Func _OnTall($sId)
    _ImGui_SetWindowSize("tgt", 220, 320, $ImGuiCond_Always)
EndFunc

Func _OnWidthOnly($sId)
    _ImGui_SetWindowSize("tgt", 400, 0, $ImGuiCond_Always)
EndFunc

Func _OnAppearing($sId)
    _ImGui_SetWindowSize("tgt", 300, 240, $ImGuiCond_Appearing)
EndFunc

Func _OnHideTarget($sId)
    _ImGui_SetVisible("tgt", False)
EndFunc

Func _OnShowTarget($sId)
    _ImGui_SetVisible("tgt", True)
EndFunc

Func _OnPollSize()
    Local $aSz = _ImGui_GetWindowSize("tgt")
    If IsArray($aSz) Then
        Local $fAsp = ($aSz[1] = 0) ? 0.0 : ($aSz[0] / $aSz[1])
        _ImGui_SetText("t_size", StringFormat("  Target size : %d x %d  (aspect %.2f)", _
                                              $aSz[0], $aSz[1], $fAsp))
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
