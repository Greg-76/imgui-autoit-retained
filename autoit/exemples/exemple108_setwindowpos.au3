#cs
================================================================================
 Example 108 : _ImGui_SetWindowPos
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetWindowPos   Queue a one-shot SetNextWindowPos for the next Render

 Sets the window's top-left corner for the NEXT render, subject to
 the $iCond condition. The wrapper queues a one-shot ImGui::
 SetNextWindowPos -- it does NOT continuously override every frame
 unless you call it from a per-frame OnTick handler.

 $iCond options ($ImGuiCond_*) :
     0 / 1  = Always       (apply unconditionally)
     2      = Once         (apply only the first time this widget is
                            encountered during the session)
     4      = FirstUseEver (apply only if no saved .ini state exists)
     8      = Appearing    (apply each time the window goes hidden -> visible)

 This file demonstrates each condition on the same target window.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple108_setwindowpos.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple108_setwindowpos.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 108 : _ImGui_SetWindowPos", 700, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetWindowPos  --  doc block
; ==============================================================================
; Signature : _ImGui_SetWindowPos($sId, $fX, $fY, $iCond = 0)
;
;   $fX / $fY : top-left target in pixels.
;   $iCond    : application condition ($ImGuiCond_* ; 0 = Always by default).
;
;   Strict semantics : the call queues a SetNextWindowPos ; the user
;   can then drag the window unless you call SetWindowPos again next
;   frame (e.g. from OnTick) with $iCond = Always.
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded,
;     2=DllCall failed, 3=unknown id or not a window).


; ==============================================================================
; Host area widgets  --  4 buttons, one per condition variant
; ==============================================================================
_ImGui_CreateText("t_title", "SetWindowPos demo  --  one-shot snap with each $iCond variant")
_ImGui_CreateText("t_hint",  "Click a button to snap the target window. Each button uses a different condition.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_btn_hdr", "Snap target to a known position :")
_ImGui_CreateButton("btn_always",       "(A) (40, 60) with Cond_Always (works every click)")
_ImGui_CreateButton("btn_once",         "(B) (300, 60) with Cond_Once (works on the first click only ; subsequent clicks are no-ops)")
_ImGui_CreateButton("btn_firstuseever", "(C) (560, 60) with Cond_FirstUseEver (no-op if a saved .ini position exists)")
_ImGui_CreateButton("btn_appearing",    "(D) (300, 280) with Cond_Appearing (applies next time the window appears)")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateButton("btn_hide_target",  "Hide the target window (then re-show it to trigger Cond_Appearing)")
_ImGui_CreateButton("btn_show_target",  "Show the target window")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_status_hdr", "Live position :")
_ImGui_CreateText("t_pos",        "  Target pos : (0, 0)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window (one ; we move it via the buttons above)
; ==============================================================================
_ImGui_CreateWindow("tgt", "Target window (snap me with the buttons)", True, 0)
_ImGui_CreateText("tgt_t1", "Move me with the host buttons.")
_ImGui_CreateText("tgt_t2", "Or drag my title bar -- after a Cond_Once / FirstUseEver snap, I stay draggable.")
_ImGui_SetParent("tgt_t1", "tgt")
_ImGui_SetParent("tgt_t2", "tgt")
_ImGui_SetWindowPos ("tgt", 160, 200, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 320, 120, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_always",       "_OnSnapAlways")
_ImGui_SetOnClick("btn_once",         "_OnSnapOnce")
_ImGui_SetOnClick("btn_firstuseever", "_OnSnapFirstUseEver")
_ImGui_SetOnClick("btn_appearing",    "_OnSnapAppearing")
_ImGui_SetOnClick("btn_hide_target",  "_OnHideTarget")
_ImGui_SetOnClick("btn_show_target",  "_OnShowTarget")
_ImGui_SetOnClick("btn_quit",         "_OnQuit")
_ImGui_SetOnTick ("_OnPollPos", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnSnapAlways($sId)
    _ImGui_SetWindowPos("tgt", 40, 60, $ImGuiCond_Always)
EndFunc

Func _OnSnapOnce($sId)
    _ImGui_SetWindowPos("tgt", 300, 60, $ImGuiCond_Once)
EndFunc

Func _OnSnapFirstUseEver($sId)
    _ImGui_SetWindowPos("tgt", 560, 60, $ImGuiCond_FirstUseEver)
EndFunc

Func _OnSnapAppearing($sId)
    _ImGui_SetWindowPos("tgt", 300, 280, $ImGuiCond_Appearing)
EndFunc

Func _OnHideTarget($sId)
    _ImGui_SetVisible("tgt", False)
EndFunc

Func _OnShowTarget($sId)
    _ImGui_SetVisible("tgt", True)
EndFunc

Func _OnPollPos()
    Local $aPos = _ImGui_GetWindowPos("tgt")
    If IsArray($aPos) Then
        _ImGui_SetText("t_pos", StringFormat("  Target pos : (%.0f, %.0f) px", $aPos[0], $aPos[1]))
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
