#cs
================================================================================
 Example 144 : _ImGui_CreateTooltip
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateTooltip   Unconditional tooltip container -- NO hover
                          gating ; visibility is the caller's job

 Distinct from _ImGui_CreateItemTooltip (exemple143) which opens on
 hover of the previous sibling. CreateTooltip calls
 ImGui::BeginTooltip() every frame the widget is visible -- no
 "previous item" lookup, no auto-show.

 Gating is up to the script :
   * Manual toggle  : _ImGui_SetVisible($tooltipId, True / False)
                      from a button handler.
   * Timer-driven   : _ImGui_SetOnTick that flips visibility on a
                      schedule (e.g. blink every 2s).
   * Hit test       : custom logic from any event (mouse pos test,
                      keyboard chord, IPC, ...).

 NO sibling-order rule -- the tooltip lives anywhere in the tree
 (here we declare it at root and gate it from a host button). It
 still renders as a top-level floating popup, positioned by ImGui
 near the current cursor.

 Initial visibility : True (per Widget::visible default). Either
 SetVisible(False) at startup if you want it hidden by default, or
 declare the body widgets to render only what makes sense in the
 chosen UX.

 Borrowed widgets : Text + Separator + Button + Checkbox + TextColored
 (exemple48).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple144_tooltip.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple144_tooltip.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 144 : _ImGui_CreateTooltip", 720, 500) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateTooltip  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateTooltip($sId)
;
;   Invisible-but-active container. Place anywhere in the tree ;
;   placement order does NOT matter (unlike _ImGui_CreateItemTooltip).
;   Populate with children via _ImGui_SetParent.
;
;   ImGui::BeginTooltip() fires every frame the widget is visible --
;   so display gating is the script's job :
;     _ImGui_SetVisible($tooltipId, True)   -> tooltip shows
;     _ImGui_SetVisible($tooltipId, False)  -> tooltip hidden
;
;   Position is automatic (near the current cursor) -- ImGui owns it ;
;   no $fX / $fY override.
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateTooltip demo  --  unconditional container, visibility driven from script")
_ImGui_CreateText("t_hint",  "Toggle the tooltip with the buttons below. The body has a live counter that ticks while visible.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Controls
; ==============================================================================
_ImGui_CreateButton("btn_show",   "Show tooltip   (SetVisible True)")
_ImGui_CreateButton("btn_hide",   "Hide tooltip   (SetVisible False)")
_ImGui_CreateButton("btn_toggle", "Toggle tooltip (flip current state)")
_ImGui_CreateCheckbox("cb_blink", "Auto-blink (flip every 1s via SetOnTick)", False)

_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_status", "Tooltip currently : HIDDEN")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; ==============================================================================
; The Tooltip container  --  declared at root, hidden at startup
; ==============================================================================
_ImGui_CreateTooltip("tip_free")
_ImGui_CreateText        ("ft_title", "Free-floating tooltip")
_ImGui_CreateSeparator   ("ft_sep")
_ImGui_CreateText        ("ft_body",  "Visibility is script-controlled -- not bound to hover.")
_ImGui_CreateTextColored ("ft_meta",  "Visible ticks : 0", 0.5, 0.9, 1.0, 1.0)
_ImGui_SetParent("ft_title", "tip_free")
_ImGui_SetParent("ft_sep",   "tip_free")
_ImGui_SetParent("ft_body",  "tip_free")
_ImGui_SetParent("ft_meta",  "tip_free")

; Hide by default so the demo starts cleanly.
_ImGui_SetVisible("tip_free", False)


; --- Counters ---------------------------------------------------------------
Global $g_iVisibleTicks = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_show",   "_OnShow")
_ImGui_SetOnClick("btn_hide",   "_OnHide")
_ImGui_SetOnClick("btn_toggle", "_OnToggle")
_ImGui_SetOnClick("btn_quit",   "_OnQuit")
; Two independent ticks : counter every 100ms, blink driver every 1000ms.
_ImGui_SetOnTick("_OnCounterTick", 100)
_ImGui_SetOnTick("_OnBlinkTick",   1000)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnShow($sId)
    _ImGui_SetVisible("tip_free", True)
    _UpdateStatus()
EndFunc

Func _OnHide($sId)
    _ImGui_SetVisible("tip_free", False)
    _UpdateStatus()
EndFunc

Func _OnToggle($sId)
    _ImGui_SetVisible("tip_free", Not _ImGui_GetVisible("tip_free"))
    _UpdateStatus()
EndFunc

Func _OnCounterTick()
    ; Increment only while the tooltip is shown ; reflect it in the colored
    ; body line. Note that SetText on a child re-renders the next frame the
    ; tooltip renders -- which is every frame as long as visible=True.
    If _ImGui_GetVisible("tip_free") Then
        $g_iVisibleTicks += 1
        _ImGui_SetText("ft_meta", "Visible ticks : " & $g_iVisibleTicks)
    EndIf
    _UpdateStatus()
EndFunc

Func _OnBlinkTick()
    ; If the user opted into auto-blink, flip visibility once per second.
    ; Demonstrates that two SetOnTick handlers run side by side at independent
    ; intervals (counter at 100ms, blink at 1000ms).
    If _ImGui_GetValueBool("cb_blink") Then
        _ImGui_SetVisible("tip_free", Not _ImGui_GetVisible("tip_free"))
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc


Func _UpdateStatus()
    _ImGui_SetText("t_status", "Tooltip currently : " & (_ImGui_GetVisible("tip_free") ? "VISIBLE" : "HIDDEN"))
EndFunc
