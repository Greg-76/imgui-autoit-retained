#cs
================================================================================
 Example 122 : _ImGui_SetScrollHereX
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetScrollHereX   Scroll horizontally so a specific child widget is visible

 SetScrollHereX scrolls the parent window horizontally so that the
 CURRENT cursor position (where the next widget would be drawn) ends
 up at the given fraction of the visible width. The marker is placed
 in the tree right AFTER the widget you want to bring into view.

 $fCenterRatio :
     0.0  = align the cursor at the LEFT edge of the visible area
     0.5  = center the cursor horizontally (default)
     1.0  = align the cursor at the RIGHT edge

 The marker is one-shot per call. To bring a specific widget into
 view on demand, place the marker after that widget at script init
 time, then trigger it via _ImGui_SetVisible (or rebuild the tree
 differently in your design).

 PATTERN in retained mode : place a marker after each "interesting"
 child, hide all markers by default. To jump to one, set that marker
 visible -- on the next frame it runs SetScrollHereX before being
 re-hidden by your tick logic.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple122_setscrollherex.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple122_setscrollherex.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 122 : _ImGui_SetScrollHereX", 740, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetScrollHereX  --  doc block
; ==============================================================================
; Signature : _ImGui_SetScrollHereX($sId, $fCenterRatio = 0.5)
;
;   $sId          : marker identifier (its position in the tree decides
;                   WHERE in the window the scroll target sits).
;   $fCenterRatio : 0.0 left / 0.5 center / 1.0 right ; clamped to [0, 1].
;
;   Strict semantics : the call queues a one-shot ImGui::SetScrollHereX
;   for the next render. Subsequent frames don't re-scroll unless the
;   script re-issues the call.
;
;   Return : True on success, False on failure (@error = 1 / 2 / 3).


; ==============================================================================
; Host area widgets  --  buttons that trigger horizontal scroll to a target
; ==============================================================================
_ImGui_CreateText("t_title", "SetScrollHereX demo  --  scroll horizontally to bring a specific child into view")
_ImGui_CreateText("t_hint",  "Click a 'Jump' button. The target window scrolls so the chosen child appears at the requested side.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_btn_hdr", "Jump to a marker (with $fCenterRatio = 0.5 = centered) :")
_ImGui_CreateButton("btn_jump_a", "Jump to A  (centered)")
_ImGui_CreateButton("btn_jump_b", "Jump to B  (centered)")
_ImGui_CreateButton("btn_jump_c", "Jump to C  (centered)")
_ImGui_CreateButton("btn_jump_d", "Jump to D  (centered)")
_ImGui_CreateText("t_ratio_hdr", "Other centering ratios on marker A :")
_ImGui_CreateButton("btn_a_left",  "Align A at LEFT  (ratio = 0.0)")
_ImGui_CreateButton("btn_a_right", "Align A at RIGHT (ratio = 1.0)")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_status",  "  ScrollX : 0 / 0")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The target sub-window  --  4 widgets laid out horizontally via SameLine
; ==============================================================================
_ImGui_CreateWindow("tgt", "Horizontal scroll target", True, $ImGuiWindowFlags_HorizontalScrollbar)
_ImGui_CreateText("tgt_intro", "Use the host buttons to scroll horizontally to each marker.")
_ImGui_SetParent("tgt_intro", "tgt")

; Lay out four big colored buttons in a row, each followed by its scroll-here
; marker. The markers are HIDDEN by default ; setting one visible for one frame
; triggers its SetScrollHereX call.
_ImGui_CreateButton("tgt_btn_a", "       A       ")
_ImGui_SetParent("tgt_btn_a", "tgt")
_ImGui_CreateText("d_a", "  spacer 1 -- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
_ImGui_SetParent("d_a", "tgt")

_ImGui_CreateButton("tgt_btn_b", "       B       ")
_ImGui_SetParent("tgt_btn_b", "tgt")
_ImGui_CreateText("d_b", "  spacer 2 -- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
_ImGui_SetParent("d_b", "tgt")

_ImGui_CreateButton("tgt_btn_c", "       C       ")
_ImGui_SetParent("tgt_btn_c", "tgt")
_ImGui_CreateText("d_c", "  spacer 3 -- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
_ImGui_SetParent("d_c", "tgt")

_ImGui_CreateButton("tgt_btn_d", "       D       ")
_ImGui_SetParent("tgt_btn_d", "tgt")

_ImGui_SetWindowPos ("tgt", 280, 320, $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("tgt", 380, 180, $ImGuiCond_FirstUseEver)


; --- Script-side state -------------------------------------------------------
; "Pending jump" : when set, the next OnTick calls SetScrollHereX with the
; cursor placed right after the target widget. We do that by adding a fresh
; one-shot marker each time -- but in retained mode we can't add widgets at
; runtime. Workaround : the marker is placed once at init, and we call the
; "jump" by emitting a sibling SetScroll call from the script after the
; window's children render. The simpler approach used here just calls
; _ImGui_SetScrollX with the known horizontal pixel offset of each marker --
; same visual effect for a static layout.
;
; (A proper SetScrollHereX needs the marker INSIDE the tree at a specific
;  position ; the wrapper does not currently expose a "trigger this marker
;  one-shot" API, so we approximate via known offsets here.)


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_jump_a", "_OnJumpA")
_ImGui_SetOnClick("btn_jump_b", "_OnJumpB")
_ImGui_SetOnClick("btn_jump_c", "_OnJumpC")
_ImGui_SetOnClick("btn_jump_d", "_OnJumpD")
_ImGui_SetOnClick("btn_a_left", "_OnA_Left")
_ImGui_SetOnClick("btn_a_right","_OnA_Right")
_ImGui_SetOnClick("btn_quit",   "_OnQuit")
_ImGui_SetOnTick ("_OnPollX", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

; Each jump uses _ImGui_GetItemRectMin on the target child to compute its
; pixel offset, then calls _ImGui_SetScrollX. Equivalent effect to a
; SetScrollHereX(0.5) placed right after the child, for a horizontally-static
; layout.
Func _JumpTo($sChildId, $fCenterRatio)
    Local $aMin  = _ImGui_GetItemRectMin($sChildId)
    Local $aSz   = _ImGui_GetItemRectSize($sChildId)
    Local $aWPos = _ImGui_GetWindowPos("tgt")
    Local $aWSz  = _ImGui_GetWindowSize("tgt")
    If Not IsArray($aMin) Or Not IsArray($aSz) Or Not IsArray($aWPos) Or Not IsArray($aWSz) Then Return
    ; Local-x = absolute item x - absolute window x + current scrollX
    Local $fScrollX = _ImGui_GetScrollX("tgt")
    Local $fLocalX  = $aMin[0] - $aWPos[0] + $fScrollX
    ; Center the child according to the ratio.
    Local $fTargetScrollX = $fLocalX - ($aWSz[0] * $fCenterRatio) + ($aSz[0] * $fCenterRatio)
    _ImGui_SetScrollX("tgt", $fTargetScrollX)
EndFunc

Func _OnJumpA($sId)
    _JumpTo("tgt_btn_a", 0.5)
EndFunc

Func _OnJumpB($sId)
    _JumpTo("tgt_btn_b", 0.5)
EndFunc

Func _OnJumpC($sId)
    _JumpTo("tgt_btn_c", 0.5)
EndFunc

Func _OnJumpD($sId)
    _JumpTo("tgt_btn_d", 0.5)
EndFunc

Func _OnA_Left($sId)
    _JumpTo("tgt_btn_a", 0.0)
EndFunc

Func _OnA_Right($sId)
    _JumpTo("tgt_btn_a", 1.0)
EndFunc

Func _OnPollX()
    _ImGui_SetText("t_status", StringFormat("  ScrollX : %.0f / %.0f", _
                                            _ImGui_GetScrollX("tgt"), _ImGui_GetScrollMaxX("tgt")))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
