#cs
================================================================================
 Example 128 : _ImGui_CreateMenuItem
================================================================================
 Covers 4 exports of imgui_autoit.dll :

   _ImGui_CreateMenuItem   Clickable row inside a Menu / MainMenuBar
   _ImGui_GetValueBool     Read the selected (check-mark) state
   _ImGui_SetValueBool     Programmatically set the selected state
   _ImGui_HasChanged       Latch user-driven toggles (strict semantics ;
                           backs _ImGui_SetOnChange under the hood)

 MenuItem is a HYBRID widget like Selectable (exemple15). It can latch
 BOTH WasClicked (action use case) AND HasChanged (toggle use case
 when $bSelected = True at creation). Pick the binding that matches
 the item's role :

   Action-style    : "Save", "Quit"        ->  _ImGui_SetOnClick
   Toggle-style    : "Show debug", "Mute"  ->  _ImGui_SetOnChange +
                                                _ImGui_GetValueBool
   Disabled        : visible but greyed    ->  $bEnabled = False
                                                (no event raised)
   Shortcut hint   : "Ctrl+S"              ->  DISPLAY ONLY ; ImGui
                                                does NOT register a
                                                real keyboard shortcut.

 Strict-changed semantics : programmatic _ImGui_SetValueBool does NOT
 latch HasChanged. The OnChange handler only fires for USER clicks.
 Demonstrated here by two buttons that flip the "debug" toggle item
 from script -- the visible check-mark updates but the user-toggle
 counter does NOT increment.

 Borrowed widgets : MainMenuBar + Menu (exemples 127 / 129), Button,
 Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple128_menuitem.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple128_menuitem.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 128 : _ImGui_CreateMenuItem", 820, 560) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateMenuItem  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateMenuItem($sId, $sLabel = "",
;                                    $sShortcut = "",
;                                    $bSelected = False,
;                                    $bEnabled  = True)
;
;   $sShortcut : right-aligned hint such as "Ctrl+S" displayed in the
;                drop-down row. DISPLAY ONLY -- ImGui does not register
;                a real keyboard shortcut. Use AutoIt's HotKeySet() if
;                you actually want the key to do something.
;
;   $bSelected : initial check-mark state. Pass True only for toggle-
;                style items ; the box is drawn only when this is True
;                or once SetValueBool has flipped the underlying bool.
;
;   $bEnabled  : False = the row is rendered greyed and ignores clicks.
;                Useful for context-sensitive items.
;
;   Event model (read via the OnEvent API or the underlying latched
;   queries _ImGui_WasClicked / _ImGui_HasChanged) :
;     SetOnClick  fires once per user click  (action use case)
;     SetOnChange fires once per user TOGGLE (toggle use case)
;     Both are user-driven only -- programmatic SetValueBool never
;     latches either flag.
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded,
;            2=DllCall failed).


; ==============================================================================
; MainMenuBar host
; ==============================================================================
_ImGui_CreateMainMenuBar("mmb")

; Menu : File -- ACTION items
_ImGui_CreateMenu("m_file", "File")
_ImGui_SetParent("m_file", "mmb")
_ImGui_CreateMenuItem("mi_new",  "New",  "Ctrl+N")
_ImGui_CreateMenuItem("mi_save", "Save", "Ctrl+S")
_ImGui_CreateMenuItem("mi_quit", "Quit", "Alt+F4")
_ImGui_SetParent("mi_new",  "m_file")
_ImGui_SetParent("mi_save", "m_file")
_ImGui_SetParent("mi_quit", "m_file")

; Menu : View -- TOGGLE items + a DISABLED item
;                                                shortcut, $bSelected, $bEnabled
_ImGui_CreateMenu("m_view", "View")
_ImGui_SetParent("m_view", "mmb")
_ImGui_CreateMenuItem("mi_debug",    "Show debug panel", "",    False, True)
_ImGui_CreateMenuItem("mi_settings", "Show settings",     "F12", True,  True)
_ImGui_CreateMenuItem("mi_locked",   "Locked feature",    "",    False, False)
_ImGui_SetParent("mi_debug",    "m_view")
_ImGui_SetParent("mi_settings", "m_view")
_ImGui_SetParent("mi_locked",   "m_view")


; ==============================================================================
; Host body  --  status feedback + strict-changed test buttons
; ==============================================================================
_ImGui_CreateText("t_title", "CreateMenuItem demo  --  action / toggle / disabled side by side")
_ImGui_CreateText("t_hint",  "File menu = action items ; View menu = toggles + disabled row.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_actions_hdr", "Action items (SetOnClick) :")
_ImGui_CreateText("t_actions",     "  New: 0   Save: 0   Quit: 0")

_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_toggle_hdr", "Toggle items (SetOnChange + GetValueBool) :")
_ImGui_CreateText("t_toggle",     "  debug = off (user-toggle count: 0)   settings = ON  (user-toggle count: 0)")

_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_strict_hdr", "Strict-changed test  --  programmatic SetValueBool must NOT bump the counter :")
_ImGui_CreateButton("btn_set_debug_on",  "Set debug = True  programmatically")
_ImGui_CreateButton("btn_set_debug_off", "Set debug = False programmatically")
_ImGui_CreateText("t_strict",            "  Watch the 'debug' user-toggle counter above -- it stays put when you click these.")

_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters (kept in script scope so handlers can bump them) ---------------
Global $g_iNewClicks       = 0
Global $g_iSaveClicks      = 0
Global $g_iQuitClicks      = 0
Global $g_iDebugToggles    = 0
Global $g_iSettingsToggles = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick ("mi_new",            "_OnActionNew")
_ImGui_SetOnClick ("mi_save",           "_OnActionSave")
_ImGui_SetOnClick ("mi_quit",           "_OnActionQuit")
_ImGui_SetOnChange("mi_debug",          "_OnToggleDebug")
_ImGui_SetOnChange("mi_settings",       "_OnToggleSettings")
; mi_locked has no binding ; $bEnabled = False, ImGui ignores the click anyway.
_ImGui_SetOnClick ("btn_set_debug_on",  "_OnSetDebugOn")
_ImGui_SetOnClick ("btn_set_debug_off", "_OnSetDebugOff")
_ImGui_SetOnClick ("btn_quit",          "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnActionNew($sId)
    $g_iNewClicks += 1
    _RefreshActions()
EndFunc

Func _OnActionSave($sId)
    $g_iSaveClicks += 1
    _RefreshActions()
EndFunc

Func _OnActionQuit($sId)
    $g_iQuitClicks += 1
    _RefreshActions()
EndFunc

Func _OnToggleDebug($sId)
    $g_iDebugToggles += 1
    _RefreshToggles()
EndFunc

Func _OnToggleSettings($sId)
    $g_iSettingsToggles += 1
    _RefreshToggles()
EndFunc

Func _OnSetDebugOn($sId)
    ; Programmatic flip : updates the check-mark BUT does NOT fire
    ; _OnToggleDebug (strict semantics). The user-toggle counter
    ; stays put -- only the live "debug = ..." state flips.
    _ImGui_SetValueBool("mi_debug", True)
    _RefreshToggles()
EndFunc

Func _OnSetDebugOff($sId)
    _ImGui_SetValueBool("mi_debug", False)
    _RefreshToggles()
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc


Func _RefreshActions()
    _ImGui_SetText("t_actions", StringFormat("  New: %d   Save: %d   Quit: %d", _
        $g_iNewClicks, $g_iSaveClicks, $g_iQuitClicks))
EndFunc

Func _RefreshToggles()
    Local $sDebug    = _ImGui_GetValueBool("mi_debug")    ? "ON " : "off"
    Local $sSettings = _ImGui_GetValueBool("mi_settings") ? "ON " : "off"
    _ImGui_SetText("t_toggle", StringFormat("  debug = %s (user-toggle count: %d)   settings = %s (user-toggle count: %d)", _
        $sDebug, $g_iDebugToggles, $sSettings, $g_iSettingsToggles))
EndFunc
