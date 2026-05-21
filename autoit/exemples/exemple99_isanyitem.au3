#cs
================================================================================
 Example 99 : _ImGui_IsAnyItemHovered / Active / Focused
================================================================================
 Covers 3 exports of imgui_autoit.dll (inseparable cluster -- the natural
 demo asks the same question across all three predicates at once) :

   _ImGui_IsAnyItemHovered   Any widget in the entire tree is hovered?
   _ImGui_IsAnyItemActive    Any widget is currently held / dragged / edited?
   _ImGui_IsAnyItemFocused   Any widget owns the keyboard focus?

 These are GLOBAL queries -- no $sId argument. The DLL walks the
 tree and returns True if ANY widget matches the predicate.

 Canonical use case (mentioned in the wrapper source) : "is the user
 currently interacting with the panel at all ?" -- check before
 passing input through to the bot logic / underlying game / etc.
 If any of the three returns True, the click / key press is meant
 for ImGui ; otherwise it goes to your own code.

 PERSISTENT state across frames -- polling at 50 ms is reliable.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple99_isanyitem.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple99_isanyitem.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 99 : _ImGui_IsAnyItem*", 620, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_IsAnyItemHovered / Active / Focused  --  doc block
; ==============================================================================
; Signatures (no $sId -- global) :
;   _ImGui_IsAnyItemHovered()  -> True if any widget in the tree is hovered
;   _ImGui_IsAnyItemActive()   -> True if any widget is held/dragged/edited
;   _ImGui_IsAnyItemFocused()  -> True if any widget owns keyboard focus
;
;   All return False on DLL not loaded (no @error -- defensive, like
;   the per-id Is* queries).
;
;   Use these for "should I pass this input to ImGui or to my own
;   code ?" gating logic in a polling loop.


; ==============================================================================
; Demo widgets  --  a mixed panel of clickable / interactive widgets, plus a
;                  live status banner showing the three global predicates.
; ==============================================================================
_ImGui_CreateText("t_title", "IsAnyItem* demo  --  global hover / active / focus across the whole tree")
_ImGui_CreateText("t_hint",  "Hover anywhere, drag any slider, type in the input. The status banner reacts to the global state of the whole panel.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_status_hdr", "Global status panel (~20 Hz poll) :")
_ImGui_CreateText("t_any_hov",    "  IsAnyItemHovered : no")
_ImGui_CreateText("t_any_act",    "  IsAnyItemActive  : no")
_ImGui_CreateText("t_any_foc",    "  IsAnyItemFocused : no")
_ImGui_CreateText("t_combined",   "  Any of the three : NO  --> input would pass through to underlying app")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_targets_hdr", "Mixed widget panel (interact to flip the status above) :")
_ImGui_CreateButton("tg_btn1",      "Button 1")
_ImGui_CreateButton("tg_btn2",      "Button 2")
_ImGui_CreateSliderFloat("tg_sl",   "Slider", 0.0, 1.0, 0.5, "%.2f")
_ImGui_CreateInputText("tg_in",     "Input", "type here", 64, 0)
_ImGui_CreateCheckbox("tg_cb1",     "Checkbox A", True)
_ImGui_CreateCheckbox("tg_cb2",     "Checkbox B", False)
_ImGui_CreateText("tg_text",        "Text (still hoverable)")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollAny", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollAny()
    Local $bHov = _ImGui_IsAnyItemHovered()
    Local $bAct = _ImGui_IsAnyItemActive()
    Local $bFoc = _ImGui_IsAnyItemFocused()
    _ImGui_SetText("t_any_hov", "  IsAnyItemHovered : " & ($bHov ? "YES" : "no"))
    _ImGui_SetText("t_any_act", "  IsAnyItemActive  : " & ($bAct ? "YES" : "no"))
    _ImGui_SetText("t_any_foc", "  IsAnyItemFocused : " & ($bFoc ? "YES" : "no"))
    Local $bAny = $bHov Or $bAct Or $bFoc
    _ImGui_SetText("t_combined", "  Any of the three : " & ($bAny ? "YES --> input is for ImGui" _
                                                                  : "NO  --> input would pass through to underlying app"))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
