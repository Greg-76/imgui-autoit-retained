#cs
================================================================================
 Example 200 : _ImGui_CreateChild
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateChild   Scrollable sub-region INSIDE another widget
                        (typically inside a top-level Window)

 Distinct from _ImGui_CreateWindow (exemple100) :
   * Window  -> top-level Begin() ; has its own title bar, position,
                size, [X] close button, and exists in the viewport
                grid alongside other top-level windows.
   * Child   -> Begin()-less sub-region OF a parent (usually a
                Window). No title bar, no close button. Position is
                wherever its parent's flow places it. Width / height
                are explicit pixel values ; 0 = auto.

 ScrollableState : Child widgets carry the same latched scroll state
 as Windows, so the entire _ImGui_GetScroll* / _ImGui_SetScroll*
 family (exemples 116-125) works on a Child id. This is the canonical
 pattern for log panels : a parent Window with toolbar widgets at top,
 then a Child with a long list of log lines that auto-scrolls to the
 bottom.

 Border flag : $bBorder = True draws a 1-pixel frame around the
 child region. Useful as a visual separator inside a busy panel.

 Demo layout : three Child widgets side by side (via SameLine) in
 the main viewport :
   A  -- small (240 x 160), bordered, 30-line content -> shows the
         vertical scrollbar appears automatically when content
         overflows.
   B  -- medium (260 x 160), no border, identical content -> same
         content fits without the frame for comparison.
   C  -- auto-sized (0, 0), bordered, short content -> shrinks to
         its content's bounding box ; no scrolling needed.

 Borrowed widgets : SameLine (exemple66), SetParent (exemple100),
 Text + Separator, Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple200_createchild.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple200_createchild.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 200 : CreateChild", 880, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateChild  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateChild($sId, $sLabel = "", $fW = 0, $fH = 0,
;                                $bBorder = False)
;
;   $sId    : stable widget identifier.
;   $sLabel : optional label (rarely used -- Child has no title bar).
;   $fW     : explicit width in pixels. 0 = auto (fit to content
;             or fill horizontal space, depending on parent layout).
;   $fH     : explicit height in pixels. 0 = auto.
;   $bBorder : True draws a 1-pixel border around the child region.
;
;   Return : True on success, False on failure (@error = 1, 2).
;
;   Attach children via _ImGui_SetParent($childId, $childContainerId).
;   Scroll via _ImGui_SetScrollY($childContainerId, ...).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateChild demo  --  scrollable sub-region inside a parent widget")
_ImGui_CreateText("t_hint",  "Scroll the bordered children below ; the same content fits without scrolling in box B.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Three side-by-side Child widgets
; ==============================================================================

; A : small + bordered + 30 lines
_ImGui_CreateChild("child_a", "##child_a", 240, 160, True)
For $i = 1 To 30
    Local $sIdA = "t_a_" & $i
    _ImGui_CreateText($sIdA, "  A line " & $i & "  --  scroll me down")
    _ImGui_SetParent($sIdA, "child_a")
Next

_ImGui_CreateSameLine("sl1")

; B : medium + no border + same 30 lines
_ImGui_CreateChild("child_b", "##child_b", 260, 160, False)
For $i = 1 To 30
    Local $sIdB = "t_b_" & $i
    _ImGui_CreateText($sIdB, "  B line " & $i)
    _ImGui_SetParent($sIdB, "child_b")
Next

_ImGui_CreateSameLine("sl2")

; C : auto-sized + bordered + 5 lines (will shrink to content)
_ImGui_CreateChild("child_c", "##child_c", 0, 0, True)
For $i = 1 To 5
    Local $sIdC = "t_c_" & $i
    _ImGui_CreateText($sIdC, "  C line " & $i)
    _ImGui_SetParent($sIdC, "child_c")
Next

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Scroll readouts  --  show that Child has its own ScrollableState
; ==============================================================================
_ImGui_CreateText("t_scroll_hdr", "Live scroll readouts (Child has its own ScrollableState, like Window) :")
_ImGui_CreateText("t_scroll_a", "  child_a : scrollY = 0.0 / 0.0  (max scroll set by content height)")
_ImGui_CreateText("t_scroll_b", "  child_b : scrollY = 0.0 / 0.0")
_ImGui_CreateText("t_scroll_c", "  child_c : scrollY = 0.0 / 0.0  (auto-sized -> max likely 0)")
_ImGui_CreateSeparator("sep2")


_ImGui_CreateButton("btn_top",  "Scroll all to TOP (SetScrollY 0)")
_ImGui_CreateButton("btn_bot",  "Scroll all to BOTTOM (SetScrollY GetScrollMaxY)")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_top",  "_OnTop")
_ImGui_SetOnClick("btn_bot",  "_OnBot")
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnScrollTick", 200)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnScrollTick()
    _UpdateScrollLine("child_a", "t_scroll_a")
    _UpdateScrollLine("child_b", "t_scroll_b")
    _UpdateScrollLine("child_c", "t_scroll_c")
EndFunc

Func _UpdateScrollLine($sChildId, $sTextId)
    Local $fY    = _ImGui_GetScrollY($sChildId)
    Local $fYMax = _ImGui_GetScrollMaxY($sChildId)
    _ImGui_SetText($sTextId, StringFormat( _
        "  %s : scrollY = %.1f / %.1f", $sChildId, $fY, $fYMax))
EndFunc

Func _OnTop($sId)
    _ImGui_SetScrollY("child_a", 0)
    _ImGui_SetScrollY("child_b", 0)
    _ImGui_SetScrollY("child_c", 0)
EndFunc

Func _OnBot($sId)
    _ImGui_SetScrollY("child_a", _ImGui_GetScrollMaxY("child_a"))
    _ImGui_SetScrollY("child_b", _ImGui_GetScrollMaxY("child_b"))
    _ImGui_SetScrollY("child_c", _ImGui_GetScrollMaxY("child_c"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
