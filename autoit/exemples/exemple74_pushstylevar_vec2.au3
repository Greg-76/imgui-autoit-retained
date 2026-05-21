#cs
================================================================================
 Example 74 : _ImGui_CreatePushStyleVarVec2
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePushStyleVarVec2   Push a 2D-vector style var override

 The dual of PushStyleVarFloat (exemple73). Many ImGui style vars are
 2D vectors (FramePadding, ItemSpacing, WindowPadding,
 ItemInnerSpacing, ButtonTextAlign, ...). PushStyleVarVec2 lets you
 override BOTH components of one such var in a single call.

 For X-only or Y-only changes, use PushStyleVarX (exemple75) or
 PushStyleVarY (exemple76) -- they keep the other component intact.

 Pairing rule : every PushStyleVar* must be balanced by a PopStyleVar.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple74_pushstylevar_vec2.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple74_pushstylevar_vec2.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 74 : _ImGui_CreatePushStyleVarVec2", 620, 560) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePushStyleVarVec2  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePushStyleVarVec2($sId, $iVar = 0,
;                                            $fX = 0.0, $fY = 0.0)
;
;   $iVar : one of the $ImGuiStyleVar_* constants whose underlying
;           ImGui type is `ImVec2`. Common vec2 vars :
;             $ImGuiStyleVar_WindowPadding     = 2
;             $ImGuiStyleVar_WindowMinSize     = 5
;             $ImGuiStyleVar_WindowTitleAlign  = 6     (0..1, 0=left, 1=right)
;             $ImGuiStyleVar_FramePadding      = 11
;             $ImGuiStyleVar_ItemSpacing       = 14
;             $ImGuiStyleVar_ItemInnerSpacing  = 15
;
;   Pushing a SCALAR var ($iVar is a float var) is silently rejected
;   by ImGui's assert. Use PushStyleVarFloat (exemple73) for scalar vars.
;
;   $fX / $fY : new values for the .x and .y components of the slot.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three sections varying common vec2 style vars
; ==============================================================================
_ImGui_CreateText("t_title", "PushStyleVarVec2 demo  --  vec2 overrides (ItemSpacing, FramePadding, ItemInnerSpacing)")
_ImGui_CreateText("t_hint",  "Each section pushes one vec2 var. Compare the spacing / padding against the default sections between them.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Increase ItemSpacing to (20, 16) ------------------------------------
_ImGui_CreateText("a_hdr", "(A) PushStyleVarVec2(ItemSpacing, 20, 16) -- widgets breathe more :")
_ImGui_CreatePushStyleVarVec2("psv_a", $ImGuiStyleVar_ItemSpacing, 20.0, 16.0)
_ImGui_CreateButton("a_b1", "Spaced 1")
_ImGui_CreateButton("a_b2", "Spaced 2")
_ImGui_CreateButton("a_b3", "Spaced 3")
_ImGui_CreatePopStyleVar("ppv_a", 1)
_ImGui_CreateButton("a_after", "Default ItemSpacing")
_ImGui_CreateSeparator("sep_a")

; --- (B) Decrease ItemSpacing to (2, 2) (tight) ------------------------------
_ImGui_CreateText("b_hdr", "(B) PushStyleVarVec2(ItemSpacing, 2, 2) -- very tight :")
_ImGui_CreatePushStyleVarVec2("psv_b", $ImGuiStyleVar_ItemSpacing, 2.0, 2.0)
_ImGui_CreateButton("b_b1", "Tight 1")
_ImGui_CreateButton("b_b2", "Tight 2")
_ImGui_CreateButton("b_b3", "Tight 3")
_ImGui_CreatePopStyleVar("ppv_b", 1)
_ImGui_CreateSeparator("sep_b")

; --- (C) Bigger FramePadding -> chunky buttons -------------------------------
_ImGui_CreateText("c_hdr", "(C) PushStyleVarVec2(FramePadding, 16, 10) -- chunky buttons :")
_ImGui_CreatePushStyleVarVec2("psv_c", $ImGuiStyleVar_FramePadding, 16.0, 10.0)
_ImGui_CreateButton("c_b1", "Chunky 1")
_ImGui_CreateButton("c_b2", "Chunky 2")
_ImGui_CreateInputText("c_in", "##chunky_input", "Chunky input field", 64, 0)
_ImGui_CreatePopStyleVar("ppv_c", 1)
_ImGui_CreateButton("c_after", "Default FramePadding")
_ImGui_CreateSeparator("sep_c")

; --- (D) Reduce ItemInnerSpacing : checkbox closer to label ------------------
_ImGui_CreateText("d_hdr", "(D) PushStyleVarVec2(ItemInnerSpacing, 2, 2) -- checkbox glyph closer to label :")
_ImGui_CreatePushStyleVarVec2("psv_d", $ImGuiStyleVar_ItemInnerSpacing, 2.0, 2.0)
_ImGui_CreateCheckbox("d_cb1", "Tight label", True)
_ImGui_CreateCheckbox("d_cb2", "Another tight label", False)
_ImGui_CreatePopStyleVar("ppv_d", 1)
_ImGui_CreateCheckbox("d_cb_after", "Default ItemInnerSpacing", True)
_ImGui_CreateSeparator("sep_d")

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
