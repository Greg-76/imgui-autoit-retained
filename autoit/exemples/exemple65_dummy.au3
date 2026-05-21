#cs
================================================================================
 Example 65 : _ImGui_CreateDummy
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateDummy   Reserve an invisible rectangle of given size

 Dummy reserves a width x height rectangle at the cursor position
 without drawing anything. The cursor advances past it like any other
 item. Use it for :

   - Forcing a specific gap (vertical OR horizontal) larger than what
     Spacing / NewLine provide.
   - Reserving a "todo : widget will go here" placeholder during
     layout prototyping.
   - Combined with SameLine, push subsequent items horizontally by a
     fixed pixel amount.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple65_dummy.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple65_dummy.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 65 : _ImGui_CreateDummy", 600, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateDummy  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateDummy($sId, $fW = 0.0, $fH = 0.0)
;
;   $fW : reserved width in pixels.  0 = auto (defaults to one line).
;   $fH : reserved height in pixels. 0 = auto (defaults to one line).
;
;   Nothing is drawn -- it is invisible by design. The widget still
;   participates in cursor advancement, so the next widget appears
;   below (or to the right, after SameLine) by exactly ($fW, $fH).
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  vertical Dummy, horizontal Dummy (with SameLine), and a
;                  big visual placeholder Dummy.
; ==============================================================================
_ImGui_CreateText("t_title", "Dummy demo  --  invisible-but-sized rectangles")
_ImGui_CreateText("t_hint",  "The gaps below are produced by _ImGui_CreateDummy. Resize the window to confirm they keep their pixel size.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Vertical gap of 40 px -----------------------------------------------
_ImGui_CreateText("a_hdr", "(A) Vertical gap of 40 px via Dummy(0, 40) :")
_ImGui_CreateButton("a_b1", "Above the gap")
_ImGui_CreateDummy("d_a", 0.0, 40.0)
_ImGui_CreateButton("a_b2", "Below the gap (40 px of empty space above me)")
_ImGui_CreateSeparator("sep_a")

; --- (B) Horizontal gap of 80 px after SameLine ------------------------------
_ImGui_CreateText("b_hdr", "(B) Horizontal gap of 80 px in a SameLine chain :")
_ImGui_CreateButton("b_b1", "Left")
_ImGui_CreateSameLine("sl_b1")
_ImGui_CreateDummy("d_b", 80.0, 0.0)
_ImGui_CreateSameLine("sl_b2")
_ImGui_CreateButton("b_b2", "Right (80 px of empty space to my left)")
_ImGui_CreateSeparator("sep_b")

; --- (C) Big placeholder area (200 x 80 px) ----------------------------------
_ImGui_CreateText("c_hdr", "(C) Big placeholder rectangle of 200 x 80 px (think : a widget will eventually go here) :")
_ImGui_CreateText("c_above", "Header above the placeholder")
_ImGui_CreateDummy("d_c", 200.0, 80.0)
_ImGui_CreateText("c_below", "Footer below the placeholder")
_ImGui_CreateSeparator("sep_c")

; --- (D) Right-align a button via leading horizontal Dummy -------------------
_ImGui_CreateText("d_hdr", "(D) Push a button to the right by 320 px on its row :")
_ImGui_CreateDummy("d_d", 320.0, 0.0)
_ImGui_CreateSameLine("sl_d")
_ImGui_CreateButton("d_b", "Right-pushed button")
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
