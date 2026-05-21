#cs
================================================================================
 Example 75 : _ImGui_CreatePushStyleVarX
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePushStyleVarX   Push only the X-component of a vec2 style var

 PushStyleVarX overrides the .x component of a vec2 style var while
 leaving the .y component at its current value. Use it when you need
 horizontal spacing / padding changes without touching the vertical
 axis (or vice versa, see PushStyleVarY in exemple76).

 Compared to PushStyleVarVec2, which sets BOTH components in one call,
 the X / Y variants are sugar for the common case "I only want to
 change one axis".

 Pairing rule : every PushStyleVar* must be balanced by a PopStyleVar.
 X and Y variants count as one push each.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple75_pushstylevarx.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple75_pushstylevarx.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 75 : _ImGui_CreatePushStyleVarX", 620, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePushStyleVarX  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePushStyleVarX($sId, $iVar = 0, $fX = 0.0)
;
;   $iVar : one of the $ImGuiStyleVar_* constants for a vec2 var (same
;           list as exemple74). Scalar vars (Alpha, FrameRounding, ...)
;           are NOT compatible -- use PushStyleVarFloat (exemple73).
;
;   $fX   : new value for the .x component. The .y component is taken
;           from the current style and pushed alongside (so PopStyleVar
;           sees one frame to undo).
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three side-by-side rows showing X-only changes
; ==============================================================================
_ImGui_CreateText("t_title", "PushStyleVarX demo  --  change ItemSpacing.x without touching ItemSpacing.y")
_ImGui_CreateText("t_hint",  "Compare horizontal vs vertical gaps in each section. Vertical spacing stays the same in (B) and (C) ; only horizontal changes.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Default ItemSpacing -------------------------------------------------
_ImGui_CreateText("a_hdr", "(A) Default ItemSpacing (control row) :")
_ImGui_CreateButton("a_b1", "1")
_ImGui_CreateSameLine("sl_a_2")
_ImGui_CreateButton("a_b2", "2")
_ImGui_CreateSameLine("sl_a_3")
_ImGui_CreateButton("a_b3", "3")
_ImGui_CreateButton("a_b4", "Next row")
_ImGui_CreateSeparator("sep_a")

; --- (B) ItemSpacing.x = 30 (wide gap horizontally, default vertical) --------
_ImGui_CreateText("b_hdr", "(B) PushStyleVarX(ItemSpacing, 30) -- horizontal gap widens, vertical unchanged :")
_ImGui_CreatePushStyleVarX("psv_b", $ImGuiStyleVar_ItemSpacing, 30.0)
_ImGui_CreateButton("b_b1", "1")
_ImGui_CreateSameLine("sl_b_2")
_ImGui_CreateButton("b_b2", "2")
_ImGui_CreateSameLine("sl_b_3")
_ImGui_CreateButton("b_b3", "3")
_ImGui_CreateButton("b_b4", "Next row (vertical gap = default)")
_ImGui_CreatePopStyleVar("ppv_b", 1)
_ImGui_CreateButton("b_after", "Back to default ItemSpacing")
_ImGui_CreateSeparator("sep_b")

; --- (C) ItemSpacing.x = 2 (tight horizontal, default vertical) --------------
_ImGui_CreateText("c_hdr", "(C) PushStyleVarX(ItemSpacing, 2) -- buttons almost touch horizontally :")
_ImGui_CreatePushStyleVarX("psv_c", $ImGuiStyleVar_ItemSpacing, 2.0)
_ImGui_CreateButton("c_b1", "1")
_ImGui_CreateSameLine("sl_c_2")
_ImGui_CreateButton("c_b2", "2")
_ImGui_CreateSameLine("sl_c_3")
_ImGui_CreateButton("c_b3", "3")
_ImGui_CreateButton("c_b4", "Next row (vertical gap = default)")
_ImGui_CreatePopStyleVar("ppv_c", 1)
_ImGui_CreateButton("c_after", "Back to default ItemSpacing")
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
