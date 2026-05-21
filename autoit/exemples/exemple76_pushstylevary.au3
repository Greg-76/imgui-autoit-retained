#cs
================================================================================
 Example 76 : _ImGui_CreatePushStyleVarY
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePushStyleVarY   Push only the Y-component of a vec2 style var

 The Y mirror of PushStyleVarX (exemple75). Modifies the .y component
 of a vec2 style var while leaving .x untouched. Useful for changing
 vertical spacing without affecting horizontal layout.

 Pairing rule : every PushStyleVar* must be balanced by a PopStyleVar.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple76_pushstylevary.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple76_pushstylevary.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 76 : _ImGui_CreatePushStyleVarY", 620, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePushStyleVarY  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePushStyleVarY($sId, $iVar = 0, $fY = 0.0)
;
;   Same semantics as PushStyleVarX (exemple75) but for the .y axis.
;   Vec2 vars only ; scalars must use PushStyleVarFloat.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three side-by-side stacks showing Y-only changes
; ==============================================================================
_ImGui_CreateText("t_title", "PushStyleVarY demo  --  change ItemSpacing.y without touching ItemSpacing.x")
_ImGui_CreateText("t_hint",  "Compare the vertical gaps between rows. The horizontal gap (where SameLine is used) stays the same.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Default vertical spacing -- control ---------------------------------
_ImGui_CreateText("a_hdr", "(A) Default ItemSpacing.y (control) :")
_ImGui_CreateButton("a_b1", "Row 1")
_ImGui_CreateButton("a_b2", "Row 2")
_ImGui_CreateButton("a_b3", "Row 3")
_ImGui_CreateSeparator("sep_a")

; --- (B) ItemSpacing.y = 20 -- airy vertical layout --------------------------
_ImGui_CreateText("b_hdr", "(B) PushStyleVarY(ItemSpacing, 20) -- vertical gap widens, horizontal unchanged :")
_ImGui_CreatePushStyleVarY("psv_b", $ImGuiStyleVar_ItemSpacing, 20.0)
_ImGui_CreateButton("b_b1", "Row 1 (extra space below)")
_ImGui_CreateButton("b_b2", "Row 2 (extra space below)")
_ImGui_CreateButton("b_b3", "Row 3 (extra space below)")
_ImGui_CreatePopStyleVar("ppv_b", 1)
_ImGui_CreateButton("b_after", "Back to default vertical spacing")
_ImGui_CreateSeparator("sep_b")

; --- (C) ItemSpacing.y = 1 -- packed rows ------------------------------------
_ImGui_CreateText("c_hdr", "(C) PushStyleVarY(ItemSpacing, 1) -- rows pack tight :")
_ImGui_CreatePushStyleVarY("psv_c", $ImGuiStyleVar_ItemSpacing, 1.0)
_ImGui_CreateButton("c_b1", "Row 1")
_ImGui_CreateButton("c_b2", "Row 2")
_ImGui_CreateButton("c_b3", "Row 3")
_ImGui_CreateButton("c_b4", "Row 4")
_ImGui_CreateButton("c_b5", "Row 5")
_ImGui_CreatePopStyleVar("ppv_c", 1)
_ImGui_CreateButton("c_after", "Back to default vertical spacing")
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
