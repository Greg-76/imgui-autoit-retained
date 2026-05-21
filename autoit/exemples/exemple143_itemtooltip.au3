#cs
================================================================================
 Example 143 : _ImGui_CreateItemTooltip
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateItemTooltip   Rich tooltip container that opens when
                              the PREVIOUS sibling widget is hovered

 Distinct from the single-line _ImGui_SetTooltip helper (exemple142) :
 ItemTooltip is a CONTAINER -- populate it with children via
 _ImGui_SetParent. Children can be ANY widget (Text, Separator,
 TextColored, Slider snapshot, Image, ...). The popup opens on hover
 of the target for ImGui's default tooltip delay.

 PLACEMENT RULE (sibling-order ; same trap class as ContextPopup
 kind=Item and OpenPopupOnItemClick -- see Decisions log entry
 "Sibling-order-dependent markers") :
   The ItemTooltip MUST be created IMMEDIATELY after the target
   widget in the SAME parent. The DLL reads ImGui's "last item"
   state when entering BeginItemTooltip ; placing the tooltip
   elsewhere makes it observe the wrong item and never open.

 Children re-render every frame the tooltip is visible -- a Text
 child updated via _ImGui_SetText reflects the new value immediately
 (demonstrated below with a tick-driven counter).

 Borrowed widgets : TextColored (exemple48), SliderFloat, Button,
 Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple143_itemtooltip.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple143_itemtooltip.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 143 : _ImGui_CreateItemTooltip", 720, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateItemTooltip  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateItemTooltip($sId)
;
;   Invisible-but-active marker. Place IMMEDIATELY after the target
;   widget at the same parent level (sibling-order rule -- see Decisions
;   log entry 2026-05-21 "Sibling-order-dependent markers"). Populate
;   with children via _ImGui_SetParent.
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateItemTooltip demo  --  rich tooltips with multiple widgets inside")
_ImGui_CreateText("t_hint",  "Hover each target below for ~0.5s. Bodies render only while the tooltip is open.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; 1) Rich tooltip with Title + Separator + Body + Colored note
; ==============================================================================
_ImGui_CreateText("t_rich_hdr", "1) Hover this button :")
_ImGui_CreateButton("btn_rich", "Rich tooltip (Title + sep + body + colored note)")
; Tooltip MUST be the next child after btn_rich at root.
_ImGui_CreateItemTooltip("tip_rich")
_ImGui_CreateText        ("rt_title", "Rich Tooltip Title")
_ImGui_CreateSeparator   ("rt_sep")
_ImGui_CreateText        ("rt_body",  "Body text with an explanation that spans multiple words.")
_ImGui_CreateTextColored ("rt_warn",  "Note : this line is colored.", 1.0, 0.3, 0.3, 1.0)
_ImGui_SetParent("rt_title", "tip_rich")
_ImGui_SetParent("rt_sep",   "tip_rich")
_ImGui_SetParent("rt_body",  "tip_rich")
_ImGui_SetParent("rt_warn",  "tip_rich")

_ImGui_CreateSeparator("sep1")


; ==============================================================================
; 2) Live-counter tooltip  --  body updates while the tooltip is open
; ==============================================================================
_ImGui_CreateText("t_live_hdr", "2) Hover this button to see a live counter inside the tooltip :")
_ImGui_CreateButton("btn_live", "Live counter tooltip")
_ImGui_CreateItemTooltip("tip_live")
_ImGui_CreateText("lc_title", "Hover frame counter")
_ImGui_CreateText("lc_body",  "Open ticks : 0")
_ImGui_SetParent("lc_title", "tip_live")
_ImGui_SetParent("lc_body",  "tip_live")

_ImGui_CreateSeparator("sep2")


; ==============================================================================
; 3) Slider snapshot inside the tooltip  --  proves any widget works
; ==============================================================================
_ImGui_CreateText("t_snap_hdr", "3) Hover this slider to see its current value displayed inside the tooltip :")
_ImGui_CreateSliderFloat("sl_x", "X axis", 0.0, 100.0, 50.0, "%.1f")
_ImGui_CreateItemTooltip("tip_snap")
_ImGui_CreateText("ss_t1", "Slider info")
_ImGui_CreateText("ss_value", "  current value = 50.0")
_ImGui_CreateSeparator("ss_sep")
_ImGui_CreateText("ss_t2", "Range : 0.0 to 100.0  (drag the slider to change)")
_ImGui_SetParent("ss_t1",   "tip_snap")
_ImGui_SetParent("ss_value","tip_snap")
_ImGui_SetParent("ss_sep",  "tip_snap")
_ImGui_SetParent("ss_t2",   "tip_snap")

_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters ---------------------------------------------------------------
Global $g_iLiveCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("sl_x",     "_OnSliderChanged")
_ImGui_SetOnClick ("btn_quit", "_OnQuit")
; Bump the live counter only while the target button is actually hovered ;
; otherwise the number keeps climbing in the background and the demo loses
; meaning.
_ImGui_SetOnTick("_OnLiveTick", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnSliderChanged($sId)
    _ImGui_SetText("ss_value", StringFormat("  current value = %.1f", _ImGui_GetValueFloat($sId)))
EndFunc

Func _OnLiveTick()
    If _ImGui_IsHovered("btn_live") Then
        $g_iLiveCount += 1
        _ImGui_SetText("lc_body", "Open ticks : " & $g_iLiveCount)
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
