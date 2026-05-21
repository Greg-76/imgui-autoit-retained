#cs
================================================================================
 Example 7 : _ImGui_CreateArrowButton
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateArrowButton    Small square button with an arrow glyph

 The widget exposes a single discrete parameter -- the arrow direction.
 We render one button per valid value (4 total) so you can see them all
 side by side. A single handler discriminates via $sId.

 Click semantics (OnClick, ID uniqueness) : see exemple5_button.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple7_arrowbutton.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple7_arrowbutton.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 7 : _ImGui_CreateArrowButton", 520, 280) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateArrowButton  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateArrowButton($sId, $sLabel = "", $iDir = 0)
;
;   Renders a small square button containing a triangular arrow glyph.
;   $sLabel is decorative (kept for symmetry with other clickable APIs --
;   usually empty since the arrow itself is the visual).
;
;   $iDir is the arrow direction. The valid values come from ImGui's
;   internal ImGuiDir_ enum -- not currently exposed as AutoIt constants in
;   the wrapper, so we pass the integer literally :
;
;     -1 = ImGuiDir_None   (no arrow ; rarely useful)
;      0 = ImGuiDir_Left
;      1 = ImGuiDir_Right
;      2 = ImGuiDir_Up
;      3 = ImGuiDir_Down
;
;   Click semantics : see exemple5_button.au3.
;
;   Return : True on success, False on failure (@error = 1 not initialised,
;   2 duplicate id, 3 DllCall failed).


; ==============================================================================
; Demo widgets  --  one ArrowButton per direction
; ==============================================================================
_ImGui_CreateText("t_title", "ArrowButton demo")
_ImGui_CreateText("t_hint",  "Four arrows, one per direction. Same handler discriminates via $sId.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateArrowButton("btn_left",  "", 0)   ; ImGuiDir_Left
_ImGui_CreateArrowButton("btn_right", "", 1)   ; ImGuiDir_Right
_ImGui_CreateArrowButton("btn_up",    "", 2)   ; ImGuiDir_Up
_ImGui_CreateArrowButton("btn_down",  "", 3)   ; ImGuiDir_Down

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_last", "Last clicked direction : (none yet)")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_left",  "_OnArrowClicked")
_ImGui_SetOnClick("btn_right", "_OnArrowClicked")
_ImGui_SetOnClick("btn_up",    "_OnArrowClicked")
_ImGui_SetOnClick("btn_down",  "_OnArrowClicked")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------
Func _OnArrowClicked($sId)
    Local $sDir = "?"
    Switch $sId
        Case "btn_left"
            $sDir = "Left  (0)"
        Case "btn_right"
            $sDir = "Right (1)"
        Case "btn_up"
            $sDir = "Up    (2)"
        Case "btn_down"
            $sDir = "Down  (3)"
    EndSwitch
    _ImGui_SetText("t_last", "Last clicked direction : " & $sDir)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
