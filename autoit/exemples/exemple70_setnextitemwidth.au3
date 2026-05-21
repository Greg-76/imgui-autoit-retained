#cs
================================================================================
 Example 70 : _ImGui_CreateSetNextItemWidth
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateSetNextItemWidth   One-shot width override for the next widget

 SetNextItemWidth overrides the layout width of the next widget added
 to the tree. Used for : narrowing an InputText to fit a column,
 widening a Slider to span a window, making sets of widgets align in
 a table-like layout.

 Effect is ONE-SHOT : it applies to the immediately-following widget
 only. Widgets after that one revert to the default width. This is
 the per-item complement of the (separate) "push item width on the
 style stack" mechanism, which affects every widget until popped.

 Value convention :
     > 0  : absolute pixel width
     0    : auto width (default ; depends on widget type and remaining
            horizontal space)
     < 0  : right-aligned ; the negative magnitude is the offset from
            the right edge (so -50 = "fill the row except for a 50 px
            gap on the right")

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple70_setnextitemwidth.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple70_setnextitemwidth.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 70 : _ImGui_CreateSetNextItemWidth", 640, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSetNextItemWidth  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSetNextItemWidth($sId, $fWidth = 0.0)
;
;   $fWidth :
;     > 0  : absolute pixel width for the next widget
;     0    : reset / auto (default size for the widget type)
;    < 0   : negative offset from the right edge of the available area
;            (e.g. -50 means "fill except for 50 px of gap on the right")
;
;   One-shot : consumed by the next widget added to the tree. Has NO
;   effect on widgets added after that one.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  five variants of an InputText with different widths
; ==============================================================================
_ImGui_CreateText("t_title", "SetNextItemWidth demo  --  precise widths and right-alignment")
_ImGui_CreateText("t_hint",  "Resize the window horizontally to see how absolute, auto, and negative widths react.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Default auto width --------------------------------------------------
_ImGui_CreateText("a_hdr", "(A) No SetNextItemWidth (default auto-width) :")
_ImGui_CreateInputText("a_in", "##a", "default width", 64, 0)
_ImGui_CreateSeparator("sep_a")

; --- (B) Absolute width 150 px -----------------------------------------------
_ImGui_CreateText("b_hdr", "(B) SetNextItemWidth(150) -- fixed 150 px regardless of window size :")
_ImGui_CreateSetNextItemWidth("snw_b", 150.0)
_ImGui_CreateInputText("b_in", "##b", "150 px", 64, 0)
_ImGui_CreateSeparator("sep_b")

; --- (C) Absolute width 350 px -----------------------------------------------
_ImGui_CreateText("c_hdr", "(C) SetNextItemWidth(350) -- wider fixed pixel width :")
_ImGui_CreateSetNextItemWidth("snw_c", 350.0)
_ImGui_CreateInputText("c_in", "##c", "350 px", 64, 0)
_ImGui_CreateSeparator("sep_c")

; --- (D) Right-aligned with -50 px gap ---------------------------------------
_ImGui_CreateText("d_hdr", "(D) SetNextItemWidth(-50) -- fill row except 50 px gap on the right (right-aligned) :")
_ImGui_CreateSetNextItemWidth("snw_d", -50.0)
_ImGui_CreateInputText("d_in", "##d", "stretches with the window", 64, 0)
_ImGui_CreateSeparator("sep_d")

; --- (E) One-shot proof : SetNextItemWidth affects ONLY the next widget ------
_ImGui_CreateText("e_hdr", "(E) Proof that the override is one-shot : the second InputText falls back to default :")
_ImGui_CreateSetNextItemWidth("snw_e", 200.0)
_ImGui_CreateInputText("e_in_first",  "##e_first",  "200 px (override applied)", 64, 0)
_ImGui_CreateInputText("e_in_second", "##e_second", "default width again", 64, 0)
_ImGui_CreateSeparator("sep_e")

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
