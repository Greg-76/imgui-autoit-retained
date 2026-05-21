#cs
================================================================================
 Example 2 : _ImGui_SetConfigFlags
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetConfigFlags    Toggles global ImGui options (nav, mouse, ...)

 Uses the OnEvent-style API : each user interaction calls a bound function,
 the main loop stays minimal. Wrapper-level mechanism, mimics native AutoIt
 GUIOnEventMode.

 Borrowed widgets (each detailed in its own example) :
   - _ImGui_CreateText  (Text + SetText)
   - _ImGui_CreateCheckbox + Get/SetValueBool
   - _ImGui_CreateButton
   - _ImGui_CreateSeparator

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple2_set_config_flags.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple2_set_config_flags.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; ==============================================================================
; --- Init (boilerplate) ---  see exemple1_init_shutdown.au3 for details
; ==============================================================================
If Not _ImGui_Init("Example 2 : _ImGui_SetConfigFlags", 640, 400) Then
    MsgBox(16, "Initialisation error", _
        "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetConfigFlags  --  doc block
; ==============================================================================
; Signature : _ImGui_SetConfigFlags($iFlags)
;
;   Bit-OR combination of $ImGuiConfigFlags_* constants. Applied to the next
;   frame. Must be called AFTER _ImGui_Init (the wrapper returns @error=1
;   otherwise).
;
;   Useful values (defined in imgui_retained.au3) :
;
;     $ImGuiConfigFlags_None                = 0   (nothing enabled)
;     $ImGuiConfigFlags_NavEnableKeyboard   = 1   ; Tab/Shift+Tab/arrows/Enter
;     $ImGuiConfigFlags_NavEnableGamepad    = 2   ; nav with a gamepad
;     $ImGuiConfigFlags_NoMouse             = 16  ; ignore the mouse entirely
;     $ImGuiConfigFlags_NoMouseCursorChange = 32  ; don't change the OS cursor
;     $ImGuiConfigFlags_NoKeyboard          = 64  ; ignore the keyboard
;
;   Combinations are free : BitOR($flag1, $flag2, ...).
;
;   Return : True on success, False otherwise (@error = 1 if not initialised,
;   2 if DllCall failed).
;
;   Note : ViewportsEnable (windows draggable out of the host OS window) is
;   enabled PERMANENTLY by the render thread -- not exposed here.
;   DockingEnable is intentionally not available (the project does not
;   support docking).
;
; Initial state : keyboard navigation only. The OnChange handler below
; mutates this whenever the user toggles a checkbox.
_ImGui_SetConfigFlags($ImGuiConfigFlags_NavEnableKeyboard)


; ==============================================================================
; Demo widgets (borrowed from other examples)
; ==============================================================================
_ImGui_CreateText("t_title",  "ConfigFlags demo")
_ImGui_CreateText("t_hint",   "Toggle the checkboxes -- _ImGui_SetConfigFlags is")
_ImGui_CreateText("t_hint2",  "re-applied live with the bit-OR of the selection.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateCheckbox("cb_nav",      "NavEnableKeyboard    (1)  Tab + arrows navigate between widgets", True)
_ImGui_CreateCheckbox("cb_gamepad",  "NavEnableGamepad     (2)  Navigate with a plugged-in gamepad",    False)
_ImGui_CreateCheckbox("cb_nomouse",  "NoMouse              (16) Disable the mouse entirely",           False)
_ImGui_CreateCheckbox("cb_nocursor", "NoMouseCursorChange  (32) ImGui won't change the OS cursor",     False)
_ImGui_CreateCheckbox("cb_nokb",     "NoKeyboard           (64) Disable the keyboard entirely",        False)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_flags_now", "Applied flags : NavEnableKeyboard (1)")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Bind events  --  one OnChange handler shared by all 5 checkboxes,
;                  one OnClick handler for the Quit button.
; ==============================================================================
; Same handler can serve several widgets : the wrapper passes the widget id
; as the only argument, but here we don't need it (we just recompute the
; combined mask from all five values every time).

_ImGui_SetOnChange("cb_nav",      "_OnAnyFlagChanged")
_ImGui_SetOnChange("cb_gamepad",  "_OnAnyFlagChanged")
_ImGui_SetOnChange("cb_nomouse",  "_OnAnyFlagChanged")
_ImGui_SetOnChange("cb_nocursor", "_OnAnyFlagChanged")
_ImGui_SetOnChange("cb_nokb",     "_OnAnyFlagChanged")
_ImGui_SetOnClick ("btn_quit",    "_OnQuitClicked")


; ==============================================================================
; Main loop  --  identical in every example
; ==============================================================================
While _ImGui_IsRunning()
    Sleep(50)
WEnd


; ==============================================================================
; Cleanup
; ==============================================================================
; _ImGui_Shutdown also unbinds all OnEvent subscriptions internally.
_ImGui_Shutdown()


; ==============================================================================
; Event handlers
; ==============================================================================

; Called whenever any of the 5 ConfigFlags checkboxes is toggled. Recompose
; the bit-OR mask and re-apply it via _ImGui_SetConfigFlags.
;   $sId is the widget that triggered (cb_nav, cb_gamepad, ...). We don't use
;   it here because we rebuild the mask from scratch every time -- a single
;   shared handler is enough.
Func _OnAnyFlagChanged($sId)
    Local $iFlags = $ImGuiConfigFlags_None
    Local $sLabel = ""
    If _ImGui_GetValueBool("cb_nav") Then
        $iFlags = BitOR($iFlags, $ImGuiConfigFlags_NavEnableKeyboard)
        $sLabel &= "NavEnableKeyboard (1) | "
    EndIf
    If _ImGui_GetValueBool("cb_gamepad") Then
        $iFlags = BitOR($iFlags, $ImGuiConfigFlags_NavEnableGamepad)
        $sLabel &= "NavEnableGamepad (2) | "
    EndIf
    If _ImGui_GetValueBool("cb_nomouse") Then
        $iFlags = BitOR($iFlags, $ImGuiConfigFlags_NoMouse)
        $sLabel &= "NoMouse (16) | "
    EndIf
    If _ImGui_GetValueBool("cb_nocursor") Then
        $iFlags = BitOR($iFlags, $ImGuiConfigFlags_NoMouseCursorChange)
        $sLabel &= "NoMouseCursorChange (32) | "
    EndIf
    If _ImGui_GetValueBool("cb_nokb") Then
        $iFlags = BitOR($iFlags, $ImGuiConfigFlags_NoKeyboard)
        $sLabel &= "NoKeyboard (64) | "
    EndIf
    If $sLabel = "" Then
        $sLabel = "None (0)"
    Else
        $sLabel = StringTrimRight($sLabel, 3) ; strip trailing " | "
    EndIf

    _ImGui_SetConfigFlags($iFlags)
    _ImGui_SetText("t_flags_now", "Applied flags : " & $sLabel)
EndFunc

; Quit button. _ImGui_Shutdown flips _ImGui_IsRunning() to False ; the main
; loop exits naturally on its next iteration.
Func _OnQuitClicked($sId)
    _ImGui_Shutdown()
EndFunc
