#cs
================================================================================
 Example 73 : _ImGui_CreatePushStyleVarFloat
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePushStyleVarFloat   Push a single-float style var override

 Some style vars are scalars (one float : Alpha, FrameRounding,
 WindowRounding, ChildRounding, ...). Others are 2D vectors
 (FramePadding, ItemSpacing, WindowPadding ; covered by
 PushStyleVarVec2 in exemple74). PushStyleVarFloat is the dedicated
 single-float variant.

 Pairing rule : every PushStyleVar* must be balanced by a
 PopStyleVar (with appropriate count). See exemple77.

 This file demonstrates several scalar vars side by side and pops
 each at the end of its section.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple73_pushstylevar_float.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple73_pushstylevar_float.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 73 : _ImGui_CreatePushStyleVarFloat", 620, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePushStyleVarFloat  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePushStyleVarFloat($sId, $iVar = 0,
;                                             $fValue = 0.0)
;
;   $iVar : one of the $ImGuiStyleVar_* constants whose underlying
;           ImGui type is `float`. Common scalar vars :
;             $ImGuiStyleVar_Alpha            = 0    (0..1 ; 0.5 = half opaque widgets)
;             $ImGuiStyleVar_DisabledAlpha    = 1    (opacity used when Disabled flag is set)
;             $ImGuiStyleVar_WindowRounding   = 3
;             $ImGuiStyleVar_WindowBorderSize = 4
;             $ImGuiStyleVar_ChildRounding    = 7
;             $ImGuiStyleVar_ChildBorderSize  = 8
;             $ImGuiStyleVar_PopupRounding    = 9
;             $ImGuiStyleVar_PopupBorderSize  = 10
;             $ImGuiStyleVar_FrameRounding    = 12   (button + input + slider corner radius)
;             $ImGuiStyleVar_FrameBorderSize  = 13
;
;   Pushing the WRONG type ($iVar is a vec2 var) is silently rejected
;   by ImGui's assert in debug builds ; release behavior is undefined.
;   Use PushStyleVarVec2 (exemple74) for vec2 vars.
;
;   $fValue : new value for the slot. Range depends on the var.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three sections, each varying one scalar style var
; ==============================================================================
_ImGui_CreateText("t_title", "PushStyleVarFloat demo  --  scalar style overrides (Alpha, FrameRounding, FrameBorderSize)")
_ImGui_CreateText("t_hint",  "Each section pushes one scalar var, draws widgets, then pops it. Compare against the default-themed sentinels between sections.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Alpha = 0.4 (half-transparent widgets) ------------------------------
_ImGui_CreateText("a_hdr", "(A) PushStyleVarFloat(Alpha, 0.4) -- everything becomes semi-transparent :")
_ImGui_CreatePushStyleVarFloat("psv_a", $ImGuiStyleVar_Alpha, 0.4)
_ImGui_CreateButton("a_b1", "I am semi-transparent")
_ImGui_CreateCheckbox("a_cb", "Me too", True)
_ImGui_CreateSliderFloat("a_sl", "Slider", 0.0, 1.0, 0.5, "%.2f")
_ImGui_CreatePopStyleVar("ppv_a", 1)
_ImGui_CreateButton("a_after", "Default Alpha = 1.0 again")
_ImGui_CreateSeparator("sep_a")

; --- (B) FrameRounding = 12 px (very round corners) --------------------------
_ImGui_CreateText("b_hdr", "(B) PushStyleVarFloat(FrameRounding, 12.0) -- pill-shaped frames :")
_ImGui_CreatePushStyleVarFloat("psv_b", $ImGuiStyleVar_FrameRounding, 12.0)
_ImGui_CreateButton("b_b1", "Round button A")
_ImGui_CreateButton("b_b2", "Round button B")
_ImGui_CreateInputText("b_in", "##b_in", "Rounded input field", 64, 0)
_ImGui_CreatePopStyleVar("ppv_b", 1)
_ImGui_CreateButton("b_after", "Default FrameRounding (square corners)")
_ImGui_CreateSeparator("sep_b")

; --- (C) FrameBorderSize = 2 px ----------------------------------------------
_ImGui_CreateText("c_hdr", "(C) PushStyleVarFloat(FrameBorderSize, 2.0) -- bold borders on frames :")
_ImGui_CreatePushStyleVarFloat("psv_c", $ImGuiStyleVar_FrameBorderSize, 2.0)
_ImGui_CreateButton("c_b1", "Outlined button")
_ImGui_CreateInputText("c_in", "##c_in", "Outlined input", 64, 0)
_ImGui_CreatePopStyleVar("ppv_c", 1)
_ImGui_CreateButton("c_after", "Default border (thin)")
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
