#cs
================================================================================
 Example 81 : _ImGui_CreatePopTextWrapPos
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePopTextWrapPos   Pop ONE text-wrap-pos frame off the stack

 Mirror of PushTextWrapPos (exemple80). Removes the topmost
 text-wrap-pos override.

 PITFALL vs PopStyleColor / PopStyleVar : PopTextWrapPos does NOT
 accept a $iCount argument (same constraint as PopItemWidth). Each
 Push must be balanced by exactly ONE Pop call.

 This file focuses on Pop, especially the contrast with the counted
 Pop fast-path available for StyleColor / StyleVar.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple81_poptextwrappos.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple81_poptextwrappos.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 81 : _ImGui_CreatePopTextWrapPos", 700, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePopTextWrapPos  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePopTextWrapPos($sId)
;
;   No $iCount : pops exactly ONE frame off the text-wrap-pos stack.
;   Mirror of PopItemWidth in that regard. To undo N pushes, call N
;   times.
;
;   Stack semantics : LIFO. Most recent Push is undone first.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  nested Push/Pop pattern (outer wide, inner narrow,
;                  back to outer when inner is popped), then final pop
;                  to restore default.
; ==============================================================================
_ImGui_CreateText("t_title", "PopTextWrapPos demo  --  nested wrap positions, one Pop per Push")
_ImGui_CreateText("t_hint",  "Same paragraph rendered four times with different wrap columns via nested Push/Pop.")
_ImGui_CreateSeparator("sep_intro")

Local $sLorem = _
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod " & _
    "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam."

; --- (A) Outer Push : 500 px ; inner Push : 200 px ---------------------------
_ImGui_CreateText("a_hdr", "(A) Outer PushTextWrapPos(500) -- wide wrap (default-ish) :")
_ImGui_CreatePushTextWrapPos("ptw_outer", 500.0)
_ImGui_CreateTextWrapped("a_p", $sLorem)
_ImGui_CreateSeparator("sep_a1")

_ImGui_CreateText("a_inner_hdr", "(B) Inner PushTextWrapPos(200) -- narrow wrap, outer still on stack :")
_ImGui_CreatePushTextWrapPos("ptw_inner", 200.0)
_ImGui_CreateTextWrapped("a_p_inner", $sLorem)
_ImGui_CreatePopTextWrapPos("ppw_inner")
_ImGui_CreateSeparator("sep_a2")

_ImGui_CreateText("a_back_hdr", "(C) After one Pop -- outer wrap (500) is back :")
_ImGui_CreateTextWrapped("a_p_back", $sLorem)
_ImGui_CreatePopTextWrapPos("ppw_outer")
_ImGui_CreateSeparator("sep_a3")

_ImGui_CreateText("a_default_hdr", "(D) After second Pop -- default wrap (full window) :")
_ImGui_CreateTextWrapped("a_p_default", $sLorem)
_ImGui_CreateSeparator("sep_a4")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
