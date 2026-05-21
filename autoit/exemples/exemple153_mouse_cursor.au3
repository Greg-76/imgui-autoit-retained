#cs
================================================================================
 Example 153 : _ImGui_GetMouseCursor + _ImGui_SetMouseCursor (cluster)
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_GetMouseCursor   Read ImGui's CURRENT cursor decision
                           (-1 = None ; ~= invisible).
   _ImGui_SetMouseCursor   Queue a cursor override for the CURRENT
                           frame.

 PER-FRAME OVERRIDE (same trap class as SetWindowContentSize -- see
 the "Stickiness is INCONSISTENT" Decisions log entry of lot Window+
 scroll) : ImGui resets the cursor each NewFrame, so the script must
 re-call SetMouseCursor every frame to keep the override active.
 Canonical pattern : _ImGui_SetOnTick at 16 ms, calling SetMouseCursor
 with whatever the current desired cursor is.

 GetMouseCursor reads what ImGui has DECIDED for this frame (override
 + hovered-widget contributions combined). Useful to inspect the
 effective cursor at any time.

 11 cursor values are exposed by the wrapper :
   -1 None        invisible / leave to OS
    0 Arrow       default
    1 TextInput   over editable text
    2 ResizeAll
    3 ResizeNS    north <-> south
    4 ResizeEW    east  <-> west
    5 ResizeNESW  diagonal /
    6 ResizeNWSE  diagonal \
    7 Hand        clickable / link
    8 Wait        spinner
    9 Progress    arrow + spinner
   10 NotAllowed  blocked

 Demo : one button per cursor + a "release override" button (sets
 None) + a SetOnTick that re-applies the desired cursor.

 Borrowed widgets : Button, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple153_mouse_cursor.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple153_mouse_cursor.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 153 : _ImGui_GetMouseCursor + Set", 760, 660) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 2-export cluster
; ==============================================================================
; _ImGui_GetMouseCursor()  -> $ImGuiMouseCursor_* (int)
;
; _ImGui_SetMouseCursor($iCursor)
;   PER-FRAME : ImGui resets the cursor each NewFrame. Re-call at
;   16 ms via SetOnTick to keep the override active. Pass
;   $ImGuiMouseCursor_None (-1) to release.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "GetMouseCursor + SetMouseCursor  --  per-frame override, re-applied every 16 ms")
_ImGui_CreateText("t_hint",  "Click a cursor button to set the override. The status line shows GetMouseCursor live.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; One button per cursor
; ==============================================================================
_ImGui_CreateButton("btn_none",   "None          (-1 = invisible / leave to OS)")
_ImGui_CreateButton("btn_arrow",  "Arrow         (0 = default)")
_ImGui_CreateButton("btn_text",   "TextInput     (1)")
_ImGui_CreateButton("btn_rall",   "ResizeAll     (2)")
_ImGui_CreateButton("btn_rns",    "ResizeNS      (3)")
_ImGui_CreateButton("btn_rew",    "ResizeEW      (4)")
_ImGui_CreateButton("btn_rnesw",  "ResizeNESW    (5)")
_ImGui_CreateButton("btn_rnwse",  "ResizeNWSE    (6)")
_ImGui_CreateButton("btn_hand",   "Hand          (7)")
_ImGui_CreateButton("btn_wait",   "Wait          (8)")
_ImGui_CreateButton("btn_progress","Progress      (9)")
_ImGui_CreateButton("btn_noway",  "NotAllowed    (10)")

_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_status", "Current override : Arrow (0)   |   GetMouseCursor live : 0")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- State (track the desired override across ticks) ------------------------
Global $g_iWantCursor = $ImGuiMouseCursor_Arrow


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_none",     "_OnSetNone")
_ImGui_SetOnClick("btn_arrow",    "_OnSetArrow")
_ImGui_SetOnClick("btn_text",     "_OnSetText")
_ImGui_SetOnClick("btn_rall",     "_OnSetRAll")
_ImGui_SetOnClick("btn_rns",      "_OnSetRNS")
_ImGui_SetOnClick("btn_rew",      "_OnSetREW")
_ImGui_SetOnClick("btn_rnesw",    "_OnSetRNESW")
_ImGui_SetOnClick("btn_rnwse",    "_OnSetRNWSE")
_ImGui_SetOnClick("btn_hand",     "_OnSetHand")
_ImGui_SetOnClick("btn_wait",     "_OnSetWait")
_ImGui_SetOnClick("btn_progress", "_OnSetProgress")
_ImGui_SetOnClick("btn_noway",    "_OnSetNotAllowed")
_ImGui_SetOnClick("btn_quit",     "_OnQuit")
; Re-apply the desired cursor every frame -- per-frame override.
_ImGui_SetOnTick("_OnTickReapply", 16)
; Status text at the persistent rate.
_ImGui_SetOnTick("_OnTickStatus",  100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnSetNone($sId)
    $g_iWantCursor = $ImGuiMouseCursor_None
EndFunc

Func _OnSetArrow($sId)
    $g_iWantCursor = $ImGuiMouseCursor_Arrow
EndFunc

Func _OnSetText($sId)
    $g_iWantCursor = $ImGuiMouseCursor_TextInput
EndFunc

Func _OnSetRAll($sId)
    $g_iWantCursor = $ImGuiMouseCursor_ResizeAll
EndFunc

Func _OnSetRNS($sId)
    $g_iWantCursor = $ImGuiMouseCursor_ResizeNS
EndFunc

Func _OnSetREW($sId)
    $g_iWantCursor = $ImGuiMouseCursor_ResizeEW
EndFunc

Func _OnSetRNESW($sId)
    $g_iWantCursor = $ImGuiMouseCursor_ResizeNESW
EndFunc

Func _OnSetRNWSE($sId)
    $g_iWantCursor = $ImGuiMouseCursor_ResizeNWSE
EndFunc

Func _OnSetHand($sId)
    $g_iWantCursor = $ImGuiMouseCursor_Hand
EndFunc

Func _OnSetWait($sId)
    $g_iWantCursor = $ImGuiMouseCursor_Wait
EndFunc

Func _OnSetProgress($sId)
    $g_iWantCursor = $ImGuiMouseCursor_Progress
EndFunc

Func _OnSetNotAllowed($sId)
    $g_iWantCursor = $ImGuiMouseCursor_NotAllowed
EndFunc

Func _OnTickReapply()
    _ImGui_SetMouseCursor($g_iWantCursor)
EndFunc

Func _OnTickStatus()
    _ImGui_SetText("t_status", "Current override : " & $g_iWantCursor & _
        "   |   GetMouseCursor live : " & _ImGui_GetMouseCursor())
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
