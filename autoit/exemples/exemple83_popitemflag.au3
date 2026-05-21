#cs
================================================================================
 Example 83 : _ImGui_CreatePopItemFlag
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePopItemFlag   Pop ONE item-flag frame off the stack

 Mirror of PushItemFlag (exemple82). Removes the topmost item-flag
 override.

 PITFALL : same as PopItemWidth / PopTextWrapPos -- NO $iCount
 argument. Each Push must be balanced by exactly ONE Pop. Stacked
 flags (e.g. NoTabStop + ButtonRepeat together) require multiple Pop
 calls.

 Stack semantics : LIFO. Most recent Push is undone first. Pops do
 not "merge" -- each Pop reverses exactly one Push, regardless of
 which flag was pushed.

 This file focuses on Pop, showing the LIFO behavior with a
 stacked-flag scenario and demonstrating that Pop order matches
 (reverse) Push order.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple83_popitemflag.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple83_popitemflag.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 83 : _ImGui_CreatePopItemFlag", 640, 500) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePopItemFlag  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePopItemFlag($sId)
;
;   No $iCount : pops ONE frame off the item-flag stack. Multiple
;   pushed flags require multiple Pop calls.
;
;   Stack semantics : LIFO. The most recent Push is undone first ; the
;   flag identity does not matter -- whatever was last pushed comes
;   off first.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three sections showing : a single Pop after a single
;                  Push, LIFO order with a stacked Push, and a deliberate
;                  partial-Pop scenario.
; ==============================================================================
_ImGui_CreateText("t_title", "PopItemFlag demo  --  no $iCount, LIFO order, partial-Pop scenarios")
_ImGui_CreateText("t_hint",  "Each section pushes flags, then pops them. Observe the order in which the buttons recover their default behavior.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Single Push / single Pop -- canonical ------------------------------
_ImGui_CreateText("a_hdr", "(A) Canonical : single Push(NoTabStop) -> single Pop -> back to default :")
_ImGui_CreateInputText("a_in1", "##a1", "Tab stops here", 64, 0)
_ImGui_CreatePushItemFlag("pif_a", $ImGuiItemFlags_NoTabStop, True)
_ImGui_CreateButton("a_btn_skip", "Tab SKIPS me (NoTabStop pushed)")
_ImGui_CreatePopItemFlag("ppf_a")
_ImGui_CreateInputText("a_in2", "##a2", "Tab stops here again", 64, 0)
_ImGui_CreateSeparator("sep_a")

; --- (B) Two stacked Pushes / two Pops -- LIFO order ------------------------
_ImGui_CreateText("b_hdr", "(B) Stacked Push(ButtonRepeat) + Push(NoTabStop), then ONE Pop reverts NoTabStop first :")
_ImGui_CreatePushItemFlag("pif_b1", $ImGuiItemFlags_ButtonRepeat, True)
_ImGui_CreatePushItemFlag("pif_b2", $ImGuiItemFlags_NoTabStop,    True)
_ImGui_CreateButton("b_btn_both", "ButtonRepeat AND NoTabStop active here")
_ImGui_CreatePopItemFlag("ppf_b1")   ; pops NoTabStop (most recent = LIFO)
_ImGui_CreateButton("b_btn_after_first", "After 1st Pop : ONLY ButtonRepeat (NoTabStop gone). Tab stops here.")
_ImGui_CreatePopItemFlag("ppf_b2")   ; pops ButtonRepeat
_ImGui_CreateButton("b_btn_after_both","After 2nd Pop : both flags cleared. Single-click button.")
_ImGui_CreateSeparator("sep_b")

; --- (C) Three Pushes / three Pops with mixed flags -------------------------
_ImGui_CreateText("c_hdr", "(C) Three Pushes (NoNav -> ButtonRepeat -> NoTabStop), three Pops -- LIFO unwinding :")
_ImGui_CreatePushItemFlag("pif_c1", $ImGuiItemFlags_NoNav,        True)
_ImGui_CreatePushItemFlag("pif_c2", $ImGuiItemFlags_ButtonRepeat, True)
_ImGui_CreatePushItemFlag("pif_c3", $ImGuiItemFlags_NoTabStop,    True)
_ImGui_CreateButton("c_btn_3", "All three flags : NoNav, ButtonRepeat, NoTabStop")
_ImGui_CreatePopItemFlag("ppf_c3")   ; clears NoTabStop
_ImGui_CreateButton("c_btn_2", "After Pop : NoTabStop gone (NoNav + ButtonRepeat still)")
_ImGui_CreatePopItemFlag("ppf_c2")   ; clears ButtonRepeat
_ImGui_CreateButton("c_btn_1", "After Pop : ButtonRepeat gone (NoNav still)")
_ImGui_CreatePopItemFlag("ppf_c1")   ; clears NoNav
_ImGui_CreateButton("c_btn_0", "After Pop : default behaviour fully restored")
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
