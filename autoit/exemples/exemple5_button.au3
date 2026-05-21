#cs
================================================================================
 Example 5 : _ImGui_CreateButton
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateButton    Standard rectangular push button

 Click any of the three demo buttons -- a single OnClick handler serves
 them all and discriminates via the $sId argument the wrapper passes.

 Borrowed widgets (each detailed in its own example) :
   - _ImGui_CreateText  (Text + SetText)
   - _ImGui_CreateSeparator

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple5_button.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple5_button.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; ==============================================================================
; --- Init (boilerplate) ---  see exemple1_init_shutdown.au3 for details
; ==============================================================================
If Not _ImGui_Init("Example 5 : _ImGui_CreateButton", 560, 340) Then
    MsgBox(16, "Initialisation error", _
        "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateButton  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateButton($sId, $sLabel = "")
;
;   Adds a clickable rectangular button to the widget tree. The button is
;   auto-sized to fit its label plus the current FramePadding ; no manual
;   width/height (use _ImGui_CreateInvisibleButton if you need a custom
;   hit area).
;
;   Parameters :
;     $sId     Stable identifier ; must be unique in the entire widget tree.
;              Use it later with _ImGui_SetOnClick, _ImGui_WasClicked,
;              _ImGui_IsHovered, _ImGui_SetVisible, _ImGui_SetEnabled, etc.
;     $sLabel  Text rendered on the button. Optional ; empty label = an empty
;              button (still has a hit area though). The label is decorative,
;              the $sId is what every API call uses.
;
;   Return : True on success, False on failure (@error = 1 if not initialised,
;   2 if $sId is empty/duplicate, 3 if DllCall failed).
;
;   Strict semantics :
;     _ImGui_SetOnClick (and _ImGui_WasClicked underneath) only fires for
;     ACTUAL user clicks inside Render(). There is no programmatic "click"
;     API ; you cannot synthesise a click from the AutoIt side.


; ==============================================================================
; Demo widgets
; ==============================================================================
_ImGui_CreateText("t_title", "Button demo")
_ImGui_CreateText("t_hint",  "Click any of the three demo buttons. One shared handler discriminates")
_ImGui_CreateText("t_hint2", "via the $sId argument that the wrapper passes to it.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateButton("btn_a", "Button A")
_ImGui_CreateButton("btn_b", "Button B")
_ImGui_CreateButton("btn_c", "Button with a deliberately long label, just to show that it auto-sizes")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_count", "Total clicks : 0")
_ImGui_CreateText("t_last",  "Last clicked : (none yet)")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Shared script state (kept outside the handlers so it persists between calls)
; ==============================================================================
Global $g_iClickCount = 0


; ==============================================================================
; Bind events  --  one handler shared by the three demo buttons,
;                  one dedicated to the Quit button
; ==============================================================================
_ImGui_SetOnClick("btn_a",    "_OnDemoButtonClicked")
_ImGui_SetOnClick("btn_b",    "_OnDemoButtonClicked")
_ImGui_SetOnClick("btn_c",    "_OnDemoButtonClicked")
_ImGui_SetOnClick("btn_quit", "_OnQuitClicked")


; ==============================================================================
; Main loop
; ==============================================================================
While _ImGui_IsRunning()
    Sleep(50)
WEnd


; ==============================================================================
; Cleanup
; ==============================================================================
_ImGui_Shutdown()


; ==============================================================================
; Event handlers
; ==============================================================================

; The same function serves btn_a, btn_b and btn_c. $sId tells us which one
; fired -- we use it directly for the "Last clicked" label.
Func _OnDemoButtonClicked($sId)
    $g_iClickCount += 1
    _ImGui_SetText("t_count", "Total clicks : " & $g_iClickCount)
    _ImGui_SetText("t_last",  "Last clicked : " & $sId)
EndFunc

Func _OnQuitClicked($sId)
    _ImGui_Shutdown()
EndFunc
