#cs
================================================================================
 Example 78 : _ImGui_CreatePushItemWidth
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePushItemWidth   Push a default-width override for the next widgets

 PushItemWidth is the stacked, persistent counterpart of
 SetNextItemWidth (exemple70). It pushes a width onto the item-width
 stack that applies to EVERY widget added afterwards until a matching
 PopItemWidth removes it (exemple79).

 Useful when you want a block of consecutive widgets to share the
 same custom width without repeating SetNextItemWidth for each one.

 Same balancing rule as PushStyleColor / PushStyleVar : Push and Pop
 must be balanced or the override bleeds into the rest of the window.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple78_pushitemwidth.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple78_pushitemwidth.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 78 : _ImGui_CreatePushItemWidth", 620, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePushItemWidth  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePushItemWidth($sId, $fWidth = 0.0)
;
;   $fWidth :
;     > 0  : absolute pixel width applied to every widget added next
;     0    : keep current width (no-op push -- still requires a Pop)
;    < 0   : negative offset from the right edge of the available area
;            (e.g. -50 = "fill except for 50 px on the right")
;
;   Effect persists until matching PopItemWidth (exemple79). Pushes
;   stack -- inner Push wins ; popping it restores the outer width.
;
;   Difference vs SetNextItemWidth (exemple70) :
;     - SetNextItemWidth is one-shot ; only the immediately following
;       widget uses the override.
;     - PushItemWidth is persistent ; ALL following widgets use it
;       until popped.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three sections showing absolute, negative, and nested
;                  PushItemWidth use cases.
; ==============================================================================
_ImGui_CreateText("t_title", "PushItemWidth demo  --  persistent item-width override (until Pop)")
_ImGui_CreateText("t_hint",  "Each section pushes ONE width and creates 3-4 widgets that all share it. Resize the window to compare absolute vs negative widths.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Absolute width 180 px shared by 3 InputText -------------------------
_ImGui_CreateText("a_hdr", "(A) PushItemWidth(180) -- three InputText all 180 px wide :")
_ImGui_CreatePushItemWidth("piw_a", 180.0)
_ImGui_CreateInputText("a_in1", "##a1", "row 1 -- 180 px wide", 64, 0)
_ImGui_CreateInputText("a_in2", "##a2", "row 2 -- still 180 px", 64, 0)
_ImGui_CreateInputText("a_in3", "##a3", "row 3 -- still 180 px", 64, 0)
_ImGui_CreatePopItemWidth("ppw_a")
_ImGui_CreateInputText("a_after","##a_after","default width again (after Pop)", 64, 0)
_ImGui_CreateSeparator("sep_a")

; --- (B) Negative width -80 (fill row minus 80 px right gap) -----------------
_ImGui_CreateText("b_hdr", "(B) PushItemWidth(-80) -- fill row except 80 px gap on the right :")
_ImGui_CreatePushItemWidth("piw_b", -80.0)
_ImGui_CreateInputText("b_in1", "##b1", "stretches with window minus 80 px", 64, 0)
_ImGui_CreateSliderFloat("b_sl", "##b_sl", 0.0, 1.0, 0.5, "%.2f")
_ImGui_CreateInputText("b_in2", "##b2", "same negative-width policy", 64, 0)
_ImGui_CreatePopItemWidth("ppw_b")
_ImGui_CreateInputText("b_after","##b_after","default width again", 64, 0)
_ImGui_CreateSeparator("sep_b")

; --- (C) Nested PushItemWidth : inner override wins, outer restored on Pop ---
_ImGui_CreateText("c_hdr", "(C) Nested PushItemWidth : inner wins, outer restored on inner Pop :")
_ImGui_CreatePushItemWidth("piw_c1", 300.0)   ; outer = 300 px
_ImGui_CreateInputText("c_in1", "##c1", "outer scope -- 300 px wide", 64, 0)
_ImGui_CreatePushItemWidth("piw_c2", 120.0)   ; inner = 120 px (wins)
_ImGui_CreateInputText("c_in2", "##c2", "inner scope -- 120 px wide", 64, 0)
_ImGui_CreateInputText("c_in3", "##c3", "still inner scope -- 120 px",   64, 0)
_ImGui_CreatePopItemWidth("ppw_c2")           ; back to outer
_ImGui_CreateInputText("c_in4", "##c4", "back to outer scope -- 300 px", 64, 0)
_ImGui_CreatePopItemWidth("ppw_c1")           ; back to default
_ImGui_CreateInputText("c_in5", "##c5", "default width (both pops done)", 64, 0)
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
