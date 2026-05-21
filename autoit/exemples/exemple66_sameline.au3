#cs
================================================================================
 Example 66 : _ImGui_CreateSameLine
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateSameLine   Keep the next widget on the same horizontal line

 SameLine is the horizontal layout marker : after a widget, inserting
 SameLine BEFORE the next widget tells ImGui "do not start a new line
 -- place the next item to the right of the previous one".

 Without SameLine, ImGui stacks widgets vertically (the default).
 With SameLine, you build rows. Combine it with Dummy + Indent to
 build precise multi-column layouts.

 NOTE : SameLine takes effect on the NEXT widget added to the tree.
 Adding two SameLine markers back-to-back has no extra effect ; only
 the latest one before the next visible widget matters.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple66_sameline.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple66_sameline.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 66 : _ImGui_CreateSameLine", 640, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateSameLine  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateSameLine($sId,
;                                    $fOffsetX = 0.0,
;                                    $fSpacing = -1.0)
;
;   $fOffsetX : if > 0, places the next widget at that exact pixel
;               offset from the LEFT edge of the current group (column
;               alignment). 0 = use default placement (right after the
;               previous widget plus $fSpacing).
;
;   $fSpacing : custom gap in pixels between the previous widget and
;               the next one. -1.0 = use the style's ItemSpacing.x.
;               Pass 0 for "stuck together", larger values for tighter
;               or looser placement.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  four SameLine usage patterns
; ==============================================================================
_ImGui_CreateText("t_title", "SameLine demo  --  build rows of widgets and align columns")
_ImGui_CreateText("t_hint",  "Compare the four rows below : default spacing, custom spacing, tight, and column-aligned.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Default : three buttons inline with ImGui's default ItemSpacing -----
_ImGui_CreateText("a_hdr", "(A) Default ItemSpacing :")
_ImGui_CreateButton("a_b1", "One")
_ImGui_CreateSameLine("sl_a_2")
_ImGui_CreateButton("a_b2", "Two")
_ImGui_CreateSameLine("sl_a_3")
_ImGui_CreateButton("a_b3", "Three")
_ImGui_CreateSeparator("sep_a")

; --- (B) Custom $fSpacing = 40 px between items ------------------------------
_ImGui_CreateText("b_hdr", "(B) Custom spacing = 40 px between items :")
_ImGui_CreateButton("b_b1", "One")
_ImGui_CreateSameLine("sl_b_2", 0.0, 40.0)
_ImGui_CreateButton("b_b2", "Two")
_ImGui_CreateSameLine("sl_b_3", 0.0, 40.0)
_ImGui_CreateButton("b_b3", "Three")
_ImGui_CreateSeparator("sep_b")

; --- (C) Tight $fSpacing = 0 (buttons stuck together) ------------------------
_ImGui_CreateText("c_hdr", "(C) Tight spacing = 0 (buttons touch) :")
_ImGui_CreateButton("c_b1", "[<")
_ImGui_CreateSameLine("sl_c_2", 0.0, 0.0)
_ImGui_CreateButton("c_b2", "Item 1 of 5")
_ImGui_CreateSameLine("sl_c_3", 0.0, 0.0)
_ImGui_CreateButton("c_b3", ">]")
_ImGui_CreateSeparator("sep_c")

; --- (D) Column-aligned via $fOffsetX -----------------------------------------
_ImGui_CreateText("d_hdr", "(D) Column alignment via $fOffsetX (each label sits at column 0, value at column 160) :")

_ImGui_CreateText("d_l1", "Username :")
_ImGui_CreateSameLine("sl_d1", 160.0)
_ImGui_CreateText("d_v1", "alice")

_ImGui_CreateText("d_l2", "Role :")
_ImGui_CreateSameLine("sl_d2", 160.0)
_ImGui_CreateText("d_v2", "administrator")

_ImGui_CreateText("d_l3", "Last login :")
_ImGui_CreateSameLine("sl_d3", 160.0)
_ImGui_CreateText("d_v3", "2026-05-21 09 :42")

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
