#cs
================================================================================
 Example 126 : _ImGui_CreateMenuBar
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateMenuBar   Create a MenuBar container inside a Window

 STRUCTURAL MARKER : MenuBar has no standalone visual. It must be
 reparented INSIDE a Window whose flags include
 $ImGuiWindowFlags_MenuBar (= 1024). Without that flag,
 ImGui::BeginMenuBar() returns false and the entire MenuBar + Menu +
 MenuItem subtree is silently skipped (no warning, no error).

 The chain is always :
   Window (flag MenuBar) -> MenuBar -> Menu(s) -> MenuItem(s)
 with _ImGui_SetParent at each step.

 This file shows the correct setup on the LEFT and the broken setup
 (same tree, but the Window misses the flag) on the RIGHT for visual
 contrast.

 Borrowed widgets : Window (exemple100), Menu + MenuItem (exemples 127
 and 128), Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple126_menubar.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple126_menubar.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 126 : _ImGui_CreateMenuBar", 840, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateMenuBar  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateMenuBar($sId, $sLabel = "")
;
;   Pure structural marker : opens an ImGui::BeginMenuBar() scope. No
;   visible widget of its own, no event flags, no value, no getter.
;
;   $sLabel    : kept for API uniformity ; current ImGui builds do not
;                draw a label for the bar itself.
;
;   Requires the parent Window to carry $ImGuiWindowFlags_MenuBar (1024).
;   Without that flag the entire subtree is silently dropped at render
;   time -- the children (Menus, MenuItems) still exist in the retained
;   tree but ImGui draws nothing for them.
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded,
;            2=DllCall failed).


; ==============================================================================
; Host area  --  controls + a status text driven by MenuItem clicks
; ==============================================================================
_ImGui_CreateText("t_title", "CreateMenuBar demo  --  proper setup (left) vs missing flag (right)")
_ImGui_CreateText("t_hint",  "Click items in the LEFT window's menu strip. They update the status below.")
_ImGui_CreateText("t_hint2", "The RIGHT window has the SAME tree but its Window misses the MenuBar flag : strip is invisible.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_status_hdr", "Last menu click :")
_ImGui_CreateText("t_status",     "  (none)")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Sub-window A  --  CORRECT setup : Window has $ImGuiWindowFlags_MenuBar
; ==============================================================================
_ImGui_CreateWindow("win_ok", "OK : Window + MenuBar flag", True, _
                    $ImGuiWindowFlags_MenuBar)

_ImGui_CreateMenuBar("mb_ok")
_ImGui_SetParent("mb_ok", "win_ok")

_ImGui_CreateMenu("ok_m_file", "File")
_ImGui_SetParent("ok_m_file", "mb_ok")
_ImGui_CreateMenuItem("ok_mi_new",  "New",  "Ctrl+N")
_ImGui_CreateMenuItem("ok_mi_save", "Save", "Ctrl+S")
_ImGui_SetParent("ok_mi_new",  "ok_m_file")
_ImGui_SetParent("ok_mi_save", "ok_m_file")

_ImGui_CreateMenu("ok_m_view", "View")
_ImGui_SetParent("ok_m_view", "mb_ok")
_ImGui_CreateMenuItem("ok_mi_zoom_in",  "Zoom in",  "Ctrl++")
_ImGui_CreateMenuItem("ok_mi_zoom_out", "Zoom out", "Ctrl+-")
_ImGui_SetParent("ok_mi_zoom_in",  "ok_m_view")
_ImGui_SetParent("ok_mi_zoom_out", "ok_m_view")

_ImGui_CreateText("ok_body", "I am the body of the OK window. The strip above is a real MenuBar.")
_ImGui_SetParent("ok_body", "win_ok")

_ImGui_SetWindowPos ("win_ok", 30,  60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_ok", 380, 200, $ImGuiCond_FirstUseEver)


; ==============================================================================
; Sub-window B  --  BROKEN setup : same tree but no MenuBar flag.
;                   ImGui::BeginMenuBar returns false -- strip is invisible.
; ==============================================================================
_ImGui_CreateWindow("win_bad", "BAD : Window WITHOUT the MenuBar flag", True, 0)

_ImGui_CreateMenuBar("mb_bad")
_ImGui_SetParent("mb_bad", "win_bad")

_ImGui_CreateMenu("bad_m_file", "File")
_ImGui_SetParent("bad_m_file", "mb_bad")
_ImGui_CreateMenuItem("bad_mi_new", "New (invisible)")
_ImGui_SetParent("bad_mi_new", "bad_m_file")

_ImGui_CreateText("bad_body", "No menu strip above me. The tree exists but ImGui draws nothing.")
_ImGui_SetParent("bad_body", "win_bad")

_ImGui_SetWindowPos ("win_bad", 430, 60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_bad", 380, 200, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("ok_mi_new",      "_OnMenuClick")
_ImGui_SetOnClick("ok_mi_save",     "_OnMenuClick")
_ImGui_SetOnClick("ok_mi_zoom_in",  "_OnMenuClick")
_ImGui_SetOnClick("ok_mi_zoom_out", "_OnMenuClick")
; The next bind is registered for completeness ; the handler will NEVER fire
; because bad_mi_new lives under a MenuBar that ImGui never enters.
_ImGui_SetOnClick("bad_mi_new",     "_OnMenuClick")
_ImGui_SetOnClick("btn_quit",       "_OnQuit")


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
