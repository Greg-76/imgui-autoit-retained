#cs
================================================================================
 Example 8 : _ImGui_CreateInvisibleButton
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateInvisibleButton    Custom-sized click area with no visual

 InvisibleButton is a transparent rectangle that responds to clicks but
 renders nothing. Use it to make arbitrary regions of your layout
 clickable -- around an image, over a custom-drawn area, as a hidden
 "anywhere" hit-zone, etc.

 Click semantics (OnClick, ID uniqueness) : see exemple5_button.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple8_invisiblebutton.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple8_invisiblebutton.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 8 : _ImGui_CreateInvisibleButton", 560, 360) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateInvisibleButton  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateInvisibleButton($sId, $sLabel = "", $fW = 0.0, $fH = 0.0)
;
;   Reserves a rectangle of width $fW and height $fH inside the current
;   layout and treats it as a clickable area. Nothing is drawn -- the
;   user cannot see the hit zone unless something else (Text, Image, raw
;   draw calls) is placed in the same spot.
;
;   $sLabel is decorative ; the button has no visible text either way.
;
;   $fW and $fH must be > 0. Negative values lead to undefined behaviour ;
;   zero collapses the hit area to nothing.
;
;   Typical uses :
;     - large hit zone around a small Image
;     - draggable handle on top of a custom canvas
;     - "click anywhere on this row to expand" affordance
;
;   Click semantics : see exemple5_button.au3.
;
;   Return : True on success, False on failure (@error = 1 not initialised,
;   2 duplicate id, 3 DllCall failed).


; ==============================================================================
; Demo widgets
; ==============================================================================
_ImGui_CreateText("t_title", "InvisibleButton demo")
_ImGui_CreateText("t_hint1", "The 'X' marks below sit on top of three InvisibleButton hit zones")
_ImGui_CreateText("t_hint2", "of different sizes. Click in their general area -- you'll see them")
_ImGui_CreateText("t_hint3", "fire even though no button frame is drawn.")
_ImGui_CreateSeparator("sep1")

; Three invisible buttons of different sizes. We place a Text widget right
; after each so the user has a visual cue of where the hit zone roughly is.
_ImGui_CreateInvisibleButton("btn_small",  "", 60,  30)
_ImGui_CreateText("t_label_small",  "  ^ small hit zone (60 x 30)")

_ImGui_CreateInvisibleButton("btn_medium", "", 200, 30)
_ImGui_CreateText("t_label_medium", "  ^ medium hit zone (200 x 30)")

_ImGui_CreateInvisibleButton("btn_wide",   "", 400, 50)
_ImGui_CreateText("t_label_wide",   "  ^ wide hit zone (400 x 50)")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_last",  "Last clicked  : (none yet)")
_ImGui_CreateText("t_count", "Total clicks  : 0")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iClickCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_small",  "_OnInvisibleClicked")
_ImGui_SetOnClick("btn_medium", "_OnInvisibleClicked")
_ImGui_SetOnClick("btn_wide",   "_OnInvisibleClicked")
_ImGui_SetOnClick("btn_quit",   "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------
Func _OnInvisibleClicked($sId)
    $g_iClickCount += 1
    _ImGui_SetText("t_last",  "Last clicked  : " & $sId)
    _ImGui_SetText("t_count", "Total clicks  : " & $g_iClickCount)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
