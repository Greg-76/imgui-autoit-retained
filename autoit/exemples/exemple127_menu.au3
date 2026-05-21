#cs
================================================================================
 Example 127 : _ImGui_CreateMenu
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateMenu   Create a drop-down inside a MenuBar / MainMenuBar

 STRUCTURAL MARKER : Menu has no standalone visual. It must be
 reparented inside a MenuBar (per-window, exemple126) or a
 MainMenuBar (top-of-viewport, exemple129). Its children are the
 MenuItems / Separators / nested Menus that appear when the user
 clicks the menu title.

 No getter / setter / event flag : a Menu is pure layout. Drive logic
 from its MenuItem children (exemple128).

 This file uses _ImGui_CreateMainMenuBar as the host because it
 sidesteps the Window + MenuBar-flag setup. The Menu API is identical
 when attached to a per-window MenuBar.

 Three Menus shown side by side :
   File   - MenuItems only
   Edit   - MenuItems + a Separator splitting the list in two
   Empty  - No children (renders the title, drop-down body is empty)

 Borrowed widgets : MainMenuBar (exemple129), MenuItem (exemple128),
 Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple127_menu.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple127_menu.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 127 : _ImGui_CreateMenu", 760, 460) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateMenu  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateMenu($sId, $sLabel = "")
;
;   Pure structural marker : opens an ImGui::BeginMenu($sLabel) scope.
;   No event flags (clicks happen on MenuItem children, not on the
;   title itself), no value, no getter / setter.
;
;   $sLabel    : the visible drop-down title shown on the menu strip
;                (empty falls back to $sId, like other Create* helpers).
;
;   Parent : MenuBar (per-window, exemple126) or MainMenuBar
;            (top-of-viewport, exemple129).
;
;   Children : MenuItem, Separator. A nested Menu is also valid : just
;              reparent another _ImGui_CreateMenu inside this one to
;              build a sub-menu.
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded,
;            2=DllCall failed).


; ==============================================================================
; MainMenuBar host  --  three Menus showing different content patterns
; ==============================================================================
_ImGui_CreateMainMenuBar("mmb")

; Menu 1 : File -- MenuItems only
_ImGui_CreateMenu("m_file", "File")
_ImGui_SetParent("m_file", "mmb")
_ImGui_CreateMenuItem("mi_new",   "New",  "Ctrl+N")
_ImGui_CreateMenuItem("mi_open",  "Open", "Ctrl+O")
_ImGui_CreateMenuItem("mi_save",  "Save", "Ctrl+S")
_ImGui_SetParent("mi_new",  "m_file")
_ImGui_SetParent("mi_open", "m_file")
_ImGui_SetParent("mi_save", "m_file")

; Menu 2 : Edit -- MenuItems split by a Separator
_ImGui_CreateMenu("m_edit", "Edit")
_ImGui_SetParent("m_edit", "mmb")
_ImGui_CreateMenuItem("mi_undo", "Undo", "Ctrl+Z")
_ImGui_CreateMenuItem("mi_redo", "Redo", "Ctrl+Y")
_ImGui_CreateSeparator("mi_sep")
_ImGui_CreateMenuItem("mi_cut",   "Cut",   "Ctrl+X")
_ImGui_CreateMenuItem("mi_copy",  "Copy",  "Ctrl+C")
_ImGui_CreateMenuItem("mi_paste", "Paste", "Ctrl+V")
_ImGui_SetParent("mi_undo",  "m_edit")
_ImGui_SetParent("mi_redo",  "m_edit")
_ImGui_SetParent("mi_sep",   "m_edit")
_ImGui_SetParent("mi_cut",   "m_edit")
_ImGui_SetParent("mi_copy",  "m_edit")
_ImGui_SetParent("mi_paste", "m_edit")

; Menu 3 : Empty -- title only, drop-down body has no rows
_ImGui_CreateMenu("m_empty", "Empty")
_ImGui_SetParent("m_empty", "mmb")


; ==============================================================================
; Host body  --  status feedback
; ==============================================================================
_ImGui_CreateText("t_title", "CreateMenu demo  --  three drop-downs in the MainMenuBar above")
_ImGui_CreateText("t_hint",  "Hover the titles 'File', 'Edit', 'Empty'. The Empty menu shows a title but no rows.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_status_hdr", "Last MenuItem clicked :")
_ImGui_CreateText("t_status",     "  (none)")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("mi_new",   "_OnMenuClick")
_ImGui_SetOnClick("mi_open",  "_OnMenuClick")
_ImGui_SetOnClick("mi_save",  "_OnMenuClick")
_ImGui_SetOnClick("mi_undo",  "_OnMenuClick")
_ImGui_SetOnClick("mi_redo",  "_OnMenuClick")
_ImGui_SetOnClick("mi_cut",   "_OnMenuClick")
_ImGui_SetOnClick("mi_copy",  "_OnMenuClick")
_ImGui_SetOnClick("mi_paste", "_OnMenuClick")
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnMenuClick($sId)
    _ImGui_SetText("t_status", "  " & $sId & " clicked")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
