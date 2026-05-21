#cs
================================================================================
 Example 100 : _ImGui_CreateWindow
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateWindow   Create a draggable / resizable sub-window scope

 So far every example has added widgets to the HOST area -- the implicit
 root area of the ImGui frame. _ImGui_CreateWindow opens a separate,
 draggable, optionally-closable ImGui sub-window. Widgets added to it
 via _ImGui_SetParent are rendered inside that floating window's
 client area.

 Two related APIs used here :
   _ImGui_SetParent($childId, $windowId)   reparent a widget into a window
   _ImGui_SetVisible($winId, $bShow)       show / hide the window at runtime
   _ImGui_GetVisible($winId)               True if the window is currently shown

 In retained mode you CANNOT call CreateWindow inside a handler -- the
 widget tree is built once at script startup. The runtime knob is
 SetVisible.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple100_createwindow.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple100_createwindow.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 100 : _ImGui_CreateWindow", 800, 560) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateWindow  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateWindow($sId, $sTitle = "",
;                                  $bClosable = True, $iFlags = 0)
;
;   $bClosable : True adds an X close button on the title bar that the
;                user can press to set the window's visible state to
;                False. Query the result with _ImGui_GetVisible.
;
;   $iFlags : $ImGuiWindowFlags_* bitmask. Useful values :
;     1     = NoTitleBar
;     2     = NoResize
;     4     = NoMove
;     8     = NoScrollbar
;     32    = NoCollapse
;     64    = AlwaysAutoResize     (window shrinks/grows to content)
;     128   = NoBackground         (transparent over the host)
;     1024  = MenuBar              (required for _ImGui_CreateMenuBar inside)
;     2048  = HorizontalScrollbar
;     43    = NoDecoration         (composite : NoTitleBar | NoResize | NoScrollbar | NoCollapse)
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded, 2=DllCall failed)


; ==============================================================================
; Host area widgets  --  controls that affect the floating windows
; ==============================================================================
_ImGui_CreateText("t_title", "CreateWindow demo  --  three floating sub-windows with different flags")
_ImGui_CreateText("t_hint",  "Each sub-window contains its own widgets via _ImGui_SetParent. The host area below drives their visibility.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_ctl_hdr", "Toggle each floating window :")
_ImGui_CreateCheckbox("cb_show_a", "Show window A (default flags, closable)",        True)
_ImGui_CreateCheckbox("cb_show_b", "Show window B (NoResize | NoCollapse, closable)", True)
_ImGui_CreateCheckbox("cb_show_c", "Show window C (NoDecoration, NOT closable)",     True)
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; Window A  --  default flags, draggable, resizable, closable
; ==============================================================================
_ImGui_CreateWindow("win_a", "Window A (default)", True, 0)
_ImGui_CreateText  ("a_t1", "I am in window A.")
_ImGui_CreateText  ("a_t2", "All default flags : drag the title bar, resize from edges, collapse via caret, close via [X].")
_ImGui_CreateButton("a_btn","Button inside A")
_ImGui_SetParent("a_t1",  "win_a")
_ImGui_SetParent("a_t2",  "win_a")
_ImGui_SetParent("a_btn", "win_a")
; Seed a starting position so the three windows do not stack on top of each other.
_ImGui_SetWindowPos ("win_a", 40,  40,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_a", 240, 140, $ImGuiCond_FirstUseEver)


; ==============================================================================
; Window B  --  NoResize | NoCollapse, closable. User can still move and close.
; ==============================================================================
_ImGui_CreateWindow("win_b", "Window B (NoResize|NoCollapse)", True, _
                    BitOR($ImGuiWindowFlags_NoResize, $ImGuiWindowFlags_NoCollapse))
_ImGui_CreateText  ("b_t1", "I am in window B.")
_ImGui_CreateText  ("b_t2", "Flags : NoResize + NoCollapse. You can drag and close but not resize and not collapse.")
_ImGui_CreateButton("b_btn","Button inside B")
_ImGui_SetParent("b_t1",  "win_b")
_ImGui_SetParent("b_t2",  "win_b")
_ImGui_SetParent("b_btn", "win_b")
_ImGui_SetWindowPos ("win_b", 320, 40,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_b", 320, 140, $ImGuiCond_FirstUseEver)


; ==============================================================================
; Window C  --  NoDecoration (no title bar, no resize, no scrollbar, no collapse).
;               $bClosable=False so the X button cannot be drawn anyway. Visibility
;               is fully script-controlled.
; ==============================================================================
_ImGui_CreateWindow("win_c", "Window C (NoDecoration)", False, $ImGuiWindowFlags_NoDecoration)
_ImGui_CreateText  ("c_t1", "I am in window C.")
_ImGui_CreateText  ("c_t2", "Flags : NoDecoration. Stripped UI ; visibility controlled only from the host's checkbox.")
_ImGui_CreateButton("c_btn","Button inside C")
_ImGui_SetParent("c_t1",  "win_c")
_ImGui_SetParent("c_t2",  "win_c")
_ImGui_SetParent("c_btn", "win_c")
_ImGui_SetWindowPos ("win_c", 40,  220, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_c", 600, 100, $ImGuiCond_FirstUseEver)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("cb_show_a", "_OnToggleA")
_ImGui_SetOnChange("cb_show_b", "_OnToggleB")
_ImGui_SetOnChange("cb_show_c", "_OnToggleC")
_ImGui_SetOnClick ("btn_quit",  "_OnQuit")
; Sync the checkboxes when the user closes a window via its [X] (window A and B).
_ImGui_SetOnTick("_OnSyncCloseButtons", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnToggleA($sId)
    _ImGui_SetVisible("win_a", _ImGui_GetValueBool($sId))
EndFunc

Func _OnToggleB($sId)
    _ImGui_SetVisible("win_b", _ImGui_GetValueBool($sId))
EndFunc

Func _OnToggleC($sId)
    _ImGui_SetVisible("win_c", _ImGui_GetValueBool($sId))
EndFunc

Func _OnSyncCloseButtons()
    ; If the user clicked the [X] on a closable window, GetVisible returns
    ; False -- mirror that into the matching host checkbox so the script
    ; state stays consistent.
    If Not _ImGui_GetVisible("win_a") And _ImGui_GetValueBool("cb_show_a") Then _ImGui_SetValueBool("cb_show_a", False)
    If Not _ImGui_GetVisible("win_b") And _ImGui_GetValueBool("cb_show_b") Then _ImGui_SetValueBool("cb_show_b", False)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
