#cs
================================================================================
 Example 77 : _ImGui_CreatePopStyleVar
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePopStyleVar   Pop one or more style-var overrides off the stack

 PopStyleVar is the unified pop for all PushStyleVar variants : Float,
 Vec2, X, Y. Each Push adds exactly one frame to the stack, regardless
 of which variant created it. The $iCount argument pops N frames at
 once -- idiomatic when you pushed several vars at the start of a
 section and want to unwind them all together.

 Pairing rule (same as Indent/Unindent and Push/PopStyleColor) :
   - Total Pops must equal total Pushes (across all variants).
   - Under-pop or over-pop silently drifts the style for every later
     widget. The wrapper does not enforce balancing.

 This file focuses on Pop, especially the $iCount fast-path. The
 Pushes shown are supporting setup ; see exemple73-76 for the Push
 side.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple77_popstylevar.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple77_popstylevar.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 77 : _ImGui_CreatePopStyleVar", 620, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePopStyleVar  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePopStyleVar($sId, $iCount = 1)
;
;   $iCount : number of style-var frames to pop, default 1. ONE call
;             undoes N pushes, in reverse push order (most recent first).
;
;   Mixed variants work transparently : a PopStyleVar(3) after Push,
;   PushVec2, and PushX undoes all three in LIFO order regardless of
;   which Push variant created each frame.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three Pop patterns : individual pops, counted pop,
;                  and a mixed-variant stack popped all at once.
; ==============================================================================
_ImGui_CreateText("t_title", "PopStyleVar demo  --  individual pops vs counted pop vs mixed-variant stack")
_ImGui_CreateText("t_hint",  "Each section pushes 3-4 style vars (possibly mixing variants), then pops them. Visual result is the same regardless of the strategy.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Three Pushes balanced by three individual Pops ----------------------
_ImGui_CreateText("a_hdr", "(A) 3 Pushes (Alpha, FrameRounding, ItemSpacing) balanced by 3 individual Pops :")
_ImGui_CreatePushStyleVarFloat("psv_a1", $ImGuiStyleVar_Alpha, 0.8)
_ImGui_CreatePushStyleVarFloat("psv_a2", $ImGuiStyleVar_FrameRounding, 8.0)
_ImGui_CreatePushStyleVarVec2 ("psv_a3", $ImGuiStyleVar_ItemSpacing, 18.0, 12.0)
_ImGui_CreateButton("a_b1", "Styled button (Alpha + Rounding + Spacing pushed)")
_ImGui_CreateButton("a_b2", "Another styled button")
; -- 3 individual pops --
_ImGui_CreatePopStyleVar("ppv_a1", 1)
_ImGui_CreatePopStyleVar("ppv_a2", 1)
_ImGui_CreatePopStyleVar("ppv_a3", 1)
_ImGui_CreateButton("a_after", "Default style (after 3 individual pops)")
_ImGui_CreateSeparator("sep_a")

; --- (B) Same 3 Pushes balanced by ONE counted Pop ---------------------------
_ImGui_CreateText("b_hdr", "(B) Same 3 Pushes balanced by ONE PopStyleVar(count=3) :")
_ImGui_CreatePushStyleVarFloat("psv_b1", $ImGuiStyleVar_Alpha, 0.8)
_ImGui_CreatePushStyleVarFloat("psv_b2", $ImGuiStyleVar_FrameRounding, 8.0)
_ImGui_CreatePushStyleVarVec2 ("psv_b3", $ImGuiStyleVar_ItemSpacing, 18.0, 12.0)
_ImGui_CreateButton("b_b1", "Styled button")
_ImGui_CreateButton("b_b2", "Another styled button")
_ImGui_CreatePopStyleVar("ppv_b_all", 3)
_ImGui_CreateButton("b_after", "Default style (after PopStyleVar(3))")
_ImGui_CreateSeparator("sep_b")

; --- (C) Mixed variants : Float + Vec2 + X + Y all popped together -----------
_ImGui_CreateText("c_hdr", "(C) Mixed-variant stack : Float + Vec2 + X + Y, popped by ONE PopStyleVar(4) :")
_ImGui_CreatePushStyleVarFloat("psv_c1", $ImGuiStyleVar_FrameRounding, 10.0)
_ImGui_CreatePushStyleVarVec2 ("psv_c2", $ImGuiStyleVar_FramePadding,  14.0, 8.0)
_ImGui_CreatePushStyleVarX    ("psv_c3", $ImGuiStyleVar_ItemSpacing,   24.0)
_ImGui_CreatePushStyleVarY    ("psv_c4", $ImGuiStyleVar_ItemSpacing,   18.0)
_ImGui_CreateButton("c_b1", "All four push variants active")
_ImGui_CreateButton("c_b2", "All four push variants active")
_ImGui_CreatePopStyleVar("ppv_c_all", 4)
_ImGui_CreateButton("c_after", "Default style (after PopStyleVar(4))")
_ImGui_CreateSeparator("sep_c")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
