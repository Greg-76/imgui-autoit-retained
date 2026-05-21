#cs
================================================================================
 Example 129 : _ImGui_CreateMainMenuBar
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateMainMenuBar   Create the viewport-top global menu bar

 Variant of MenuBar (exemple126) that anchors to the top of the main
 viewport instead of being attached to a Window. No Window flag is
 required -- ImGui::BeginMainMenuBar() owns its own scope. Typical
 use : the global application menu (File / Edit / View / Help) you
 find at the top of most desktop apps.

 Behavior with $ConfigFlags_ViewportsEnable (our default) : the bar
 still renders inside the main viewport, NOT inside each sub-window's
 OS title bar. Sub-windows can be dragged around freely -- the bar
 stays put as part of the host frame.

 Only ONE MainMenuBar per frame is supported by ImGui ; creating two
 widgets of this type is undefined.

 No getter / setter / event of its own. Drive logic through the
 MenuItem children (exemple128).

 Borrowed widgets : Menu + MenuItem (exemples 127 / 128), Window
 (exemple100), Button, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple129_mainmenubar.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple129_mainmenubar.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 129 : _ImGui_CreateMainMenuBar", 780, 500) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateMainMenuBar  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateMainMenuBar($sId, $sLabel = "")
;
;   Pure structural marker : opens an ImGui::BeginMainMenuBar() scope.
;   Anchored to the top of the main viewport ; no Window flag required.
;
;   $sLabel    : unused by current ImGui builds (no body label) ; kept
;                for API uniformity with the rest of the family.
;
;   Children : Menu (drop-down columns). Each Menu in turn holds
;              MenuItems / Separators / nested Menus.
;
;   Only ONE MainMenuBar per frame is supported. Two of them in the
;   same tree is undefined behaviour.
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded,
;            2=DllCall failed).


; ==============================================================================
; MainMenuBar  --  the global top strip
; ==============================================================================
_ImGui_CreateMainMenuBar("mmb")

; File menu
_ImGui_CreateMenu("m_file", "File")
_ImGui_SetParent("m_file", "mmb")
_ImGui_CreateMenuItem("mi_new",  "New",  "Ctrl+N")
_ImGui_CreateMenuItem("mi_open", "Open", "Ctrl+O")
_ImGui_CreateMenuItem("mi_save", "Save", "Ctrl+S")
_ImGui_CreateSeparator("mi_sep1")
_ImGui_CreateMenuItem("mi_quit", "Quit", "Alt+F4")
_ImGui_SetParent("mi_new",  "m_file")
_ImGui_SetParent("mi_open", "m_file")
_ImGui_SetParent("mi_save", "m_file")
_ImGui_SetParent("mi_sep1", "m_file")
_ImGui_SetParent("mi_quit", "m_file")

; View menu (toggle items so we exercise OnChange + GetValueBool)
_ImGui_CreateMenu("m_view", "View")
_ImGui_SetParent("m_view", "mmb")
_ImGui_CreateMenuItem("mi_show_status", "Show status bar", "", True,  True)
_ImGui_CreateMenuItem("mi_show_grid",   "Show grid",       "", False, True)
_ImGui_SetParent("mi_show_status", "m_view")
_ImGui_SetParent("mi_show_grid",   "m_view")

; Help menu
_ImGui_CreateMenu("m_help", "Help")
_ImGui_SetParent("m_help", "mmb")
_ImGui_CreateMenuItem("mi_about", "About...")
_ImGui_SetParent("mi_about", "m_help")


; ==============================================================================
; Host body  --  status feedback
; ==============================================================================
_ImGui_CreateText("t_title", "CreateMainMenuBar demo  --  global top-of-viewport strip")
_ImGui_CreateText("t_hint",  "Click around in the menu above. The bar is anchored to the viewport, not to any Window.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_status_hdr", "Last action :")
_ImGui_CreateText("t_status",     "  (none)")

_ImGui_CreateText("t_view_hdr",   "View toggles :")
_ImGui_CreateText("t_view",       "  status bar = ON   grid = off")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit  (Help -> About also works)")


; ==============================================================================
; A small floating Window  --  proves the MainMenuBar stays put
; ==============================================================================
_ImGui_CreateWindow("win_extra", "I am a regular sub-window", True, 0)
_ImGui_CreateText  ("ex_t", "Drag me around. The MainMenuBar stays at the top of the viewport.")
_ImGui_SetParent   ("ex_t", "win_extra")
_ImGui_SetWindowPos ("win_extra", 280, 200, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_extra", 380, 120, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick ("mi_new",         "_OnAction")
_ImGui_SetOnClick ("mi_open",        "_OnAction")
_ImGui_SetOnClick ("mi_save",        "_OnAction")
_ImGui_SetOnClick ("mi_quit",        "_OnQuit")
_ImGui_SetOnClick ("mi_about",       "_OnAction")
_ImGui_SetOnChange("mi_show_status", "_OnViewToggle")
_ImGui_SetOnChange("mi_show_grid",   "_OnViewToggle")
_ImGui_SetOnClick ("btn_quit",       "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnAction($sId)
    _ImGui_SetText("t_status", "  " & $sId & " clicked")
EndFunc

Func _OnViewToggle($sId)
    Local $sStatusBar = _ImGui_GetValueBool("mi_show_status") ? "ON " : "off"
    Local $sGrid      = _ImGui_GetValueBool("mi_show_grid")   ? "ON " : "off"
    _ImGui_SetText("t_view", "  status bar = " & $sStatusBar & "  grid = " & $sGrid)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
