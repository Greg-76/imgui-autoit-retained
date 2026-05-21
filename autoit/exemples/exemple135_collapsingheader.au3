#cs
================================================================================
 Example 135 : _ImGui_CreateCollapsingHeader
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateCollapsingHeader   Top-level expandable section with a
                                   framed title bar

 Visually a "framed TreeNode" : draws a full-width bar with the
 label, an arrow / caret, and (optionally) an X close button.
 Children render below the bar when expanded. Equivalent to a
 TreeNode created with the composite flag set
 $ImGuiTreeNodeFlags_CollapsingHeader (Framed | NoTreePushOnOpen |
 NoAutoOpenOnLog = 26), wired into a single hand-written wrapper for
 clarity.

 Two flavors :
   $bClosable = False   no X button ; only the arrow toggles
                        (legacy default of the auto-generator).
   $bClosable = True    adds an X button on the right of the bar.
                        Clicking X writes Widget::visible = false
                        (same mechanism as Window / TabItem). Restore
                        via _ImGui_SetVisible($sId, True).

 Reacts to user-driven expand / collapse with the same edge-frame
 query as TreeNode -- _ImGui_IsToggledOpen, introduced in
 exemple134. Polled at 16 ms here.

 Borrowed widgets : TreeNode flag constants + IsToggledOpen
 (exemple134), Text + Button + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple135_collapsingheader.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple135_collapsingheader.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 135 : _ImGui_CreateCollapsingHeader", 720, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateCollapsingHeader  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateCollapsingHeader($sId, $sLabel = "",
;                                            $bClosable = False,
;                                            $iFlags = 0)
;
;   $bClosable : True adds an X button on the right side of the bar.
;                The X writes Widget::visible = false ; read with
;                _ImGui_GetVisible, restore with _ImGui_SetVisible.
;
;   $iFlags    : bitmask of $ImGuiTreeNodeFlags_* (same constants as
;                TreeNode, exemple134). The composite
;                "CollapsingHeader" flag set (Framed | NoTreePushOnOpen
;                | NoAutoOpenOnLog = 26) is always applied implicitly
;                -- $iFlags ORs onto it. Useful additions :
;     32       = DefaultOpen     start expanded
;     2048     = SpanAvailWidth  hitbox to right edge
;
;   Children : reparent with _ImGui_SetParent ; render below the bar
;              when expanded.
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded,
;            2=DllCall failed).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateCollapsingHeader demo  --  plain vs DefaultOpen vs Closable (X)")
_ImGui_CreateText("t_hint",  "Click bar titles / arrows to expand. Click [X] on the closable header to dismiss it.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; 1) Plain header  --  no X, no DefaultOpen (collapsed at start)
; ==============================================================================
_ImGui_CreateCollapsingHeader("ch_plain", "1) Plain  --  no X, collapsed at start", False, 0)
_ImGui_CreateText("ch_p_t1", "  Plain header payload 1")
_ImGui_CreateText("ch_p_t2", "  Plain header payload 2")
_ImGui_SetParent("ch_p_t1", "ch_plain")
_ImGui_SetParent("ch_p_t2", "ch_plain")


; ==============================================================================
; 2) DefaultOpen header
; ==============================================================================
_ImGui_CreateCollapsingHeader("ch_def", "2) DefaultOpen  --  starts expanded", False, _
                                $ImGuiTreeNodeFlags_DefaultOpen)
_ImGui_CreateText("ch_d_t1", "  Already visible at startup ; click the bar to collapse.")
_ImGui_SetParent("ch_d_t1", "ch_def")


; ==============================================================================
; 3) Closable header  --  X button via Widget::visible
; ==============================================================================
_ImGui_CreateCollapsingHeader("ch_close", "3) Closable  --  click X to dismiss", True, _
                                $ImGuiTreeNodeFlags_DefaultOpen)
_ImGui_CreateText("ch_c_t1", "  Dismiss me via the X on the right of the bar.")
_ImGui_CreateText("ch_c_t2", "  Use 'Restore closable' in the host footer to bring me back.")
_ImGui_SetParent("ch_c_t1", "ch_close")
_ImGui_SetParent("ch_c_t2", "ch_close")


; ==============================================================================
; Host footer  --  restore + toggle counters + Quit
; ==============================================================================
_ImGui_CreateSeparator("sep1")
_ImGui_CreateButton("btn_restore",   "Restore closable (after X)")
_ImGui_CreateText  ("t_close_state", "ch_close visible : True")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_tog_hdr",  "IsToggledOpen counters (polled at 16 ms) :")
_ImGui_CreateText("t_counters", "  ch_plain: 0   ch_def: 0   ch_close: 0")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters ---------------------------------------------------------------
Global $g_iTogPlain = 0
Global $g_iTogDef   = 0
Global $g_iTogClose = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_restore", "_OnRestoreClose")
_ImGui_SetOnClick("btn_quit",    "_OnQuit")
_ImGui_SetOnTick("_OnPollToggles",    16)
_ImGui_SetOnTick("_OnPollVisibility", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnRestoreClose($sId)
    _ImGui_SetVisible("ch_close", True)
EndFunc

Func _OnPollToggles()
    Local $bPlain = _ImGui_IsToggledOpen("ch_plain")
    Local $bDef   = _ImGui_IsToggledOpen("ch_def")
    Local $bClose = _ImGui_IsToggledOpen("ch_close")
    If $bPlain Then $g_iTogPlain += 1
    If $bDef   Then $g_iTogDef   += 1
    If $bClose Then $g_iTogClose += 1
    _ImGui_SetText("t_counters", StringFormat( _
        "  ch_plain: %d   ch_def: %d   ch_close: %d", _
        $g_iTogPlain, $g_iTogDef, $g_iTogClose))
EndFunc

Func _OnPollVisibility()
    Local $bVis = _ImGui_GetVisible("ch_close")
    _ImGui_SetText("t_close_state", "ch_close visible : " & ($bVis ? "True" : "False  (click Restore closable to bring it back)"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
