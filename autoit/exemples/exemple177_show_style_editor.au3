#cs
================================================================================
 Example 177 : _ImGui_ShowStyleEditor (+ _ImGui_IsShowingStyleEditor)
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_ShowStyleEditor       Show / hide ImGui's built-in Style Editor
   _ImGui_IsShowingStyleEditor  Query the editor's visibility state

 The Style Editor is ImGui's live theme tuner : tweak ImGuiCol_* and
 ImGuiStyleVar_* values interactively, save / load style snapshots,
 swap themes (Dark / Light / Classic), preview colors in context.
 Same round-trip semantics as the D.2 debug windows (exemple176) --
 the editor's X close button propagates back into the AutoIt state
 visible via IsShowingStyleEditor.

 Distinct from `_ImGui_CreateShowStyleSelector` (a small Combo widget
 you can place inline in your panel to swap themes) -- the editor is
 the FULL tuner ; the selector is the lightweight cousin.

 Borrowed widgets : Checkbox, Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple177_show_style_editor.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple177_show_style_editor.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 177 : ShowStyleEditor", 720, 440) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 2-export cluster
; ==============================================================================
; ShowStyleEditor($bShow = True)
;   Setter. Idempotent : re-calling with the same value is a no-op.
;
; IsShowingStyleEditor()
;   Query. Reflects ImGui's internal state, including X-button closes.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "ShowStyleEditor  --  live theme tuner with round-trip [X]-close sync")
_ImGui_CreateText("t_hint",  "Toggle the editor with the checkbox. Closing it via [X] updates the checkbox at the next tick.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Controls
; ==============================================================================
_ImGui_CreateCheckbox("cb_se",  "Show the Style Editor", False)
_ImGui_CreateText    ("t_se",   "  IsShowingStyleEditor = False")

_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_help_hdr", "Inside the editor :")
_ImGui_CreateText("t_help_1",   "  * 'Colors' tab -- preview + edit every $ImGuiCol_* slot.")
_ImGui_CreateText("t_help_2",   "  * 'Sizes' tab  -- $ImGuiStyleVar_* live (FramePadding, ItemSpacing, ...).")
_ImGui_CreateText("t_help_3",   "  * 'Fonts' tab  -- pick from the loaded font registry (see exemple170).")
_ImGui_CreateText("t_help_4",   "  * Save / Load  -- copy style as C++ code into the clipboard, or load preset.")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("cb_se",  "_OnToggle")
_ImGui_SetOnClick ("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPollState", 200)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnToggle($sId)
    _ImGui_ShowStyleEditor(_ImGui_GetValueBool($sId))
EndFunc

Func _OnPollState()
    Local $bShowing = _ImGui_IsShowingStyleEditor()
    _ImGui_SetText("t_se", "  IsShowingStyleEditor = " & ($bShowing ? "True" : "False"))
    ; Re-sync the checkbox if user closed via [X].
    If _ImGui_GetValueBool("cb_se") <> $bShowing Then _ImGui_SetValueBool("cb_se", $bShowing)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
