#cs
================================================================================
 Example 80 : _ImGui_CreatePushTextWrapPos
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePushTextWrapPos   Push a text-wrap horizontal limit

 PushTextWrapPos overrides where ImGui's word-wrap algorithm breaks
 lines for subsequently added Text-family widgets. Useful when you
 want a paragraph to wrap at a specific pixel column instead of the
 default "available width" of the current window.

 The matching PopTextWrapPos (exemple81) restores the previous wrap
 position. As with the other style stacks, Push/Pop must be balanced.

 Note : ImGui only applies wrap to widgets that already wrap on
 their own (TextWrapped, the value column of LabelText when wider
 than the field, etc.). Plain Text (single-line) ignores wrap pos.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple80_pushtextwrappos.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple80_pushtextwrappos.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 80 : _ImGui_CreatePushTextWrapPos", 700, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePushTextWrapPos  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePushTextWrapPos($sId, $fWrapPos = 0.0)
;
;   $fWrapPos :
;     0    : wrap to the end of the window (default behaviour, same
;            as having no Push at all)
;     > 0  : wrap at this absolute pixel column (relative to the
;            window's left content edge)
;    < 0   : disable wrapping for the subsequent text widgets
;
;   Pairs with PopTextWrapPos. Push without Pop bleeds the override
;   into later widgets (silent drift -- see Decisions log).
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  three TextWrapped paragraphs with different wrap policies
; ==============================================================================
_ImGui_CreateText("t_title", "PushTextWrapPos demo  --  wrap a paragraph at a specific pixel column")
_ImGui_CreateText("t_hint",  "Resize the window horizontally to see how each section reacts.")
_ImGui_CreateSeparator("sep_intro")

; A reusable paragraph string -- same text fed to each section so the wrap
; effect is the only visual difference.
Local $sLorem = _
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod " & _
    "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, " & _
    "quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo."

; --- (A) Default : wrap at the window edge ----------------------------------
_ImGui_CreateText("a_hdr", "(A) Default wrap (full window width -- same as no Push) :")
_ImGui_CreateTextWrapped("a_p", $sLorem)
_ImGui_CreateSeparator("sep_a")

; --- (B) Wrap at column 240 px ----------------------------------------------
_ImGui_CreateText("b_hdr", "(B) PushTextWrapPos(240) -- wraps at column 240 px regardless of window width :")
_ImGui_CreatePushTextWrapPos("ptw_b", 240.0)
_ImGui_CreateTextWrapped("b_p", $sLorem)
_ImGui_CreatePopTextWrapPos("ppw_b")
_ImGui_CreateSeparator("sep_b")

; --- (C) Wrap at column 420 px (wider column, fewer line breaks) ------------
_ImGui_CreateText("c_hdr", "(C) PushTextWrapPos(420) -- wraps later, longer visual lines :")
_ImGui_CreatePushTextWrapPos("ptw_c", 420.0)
_ImGui_CreateTextWrapped("c_p", $sLorem)
_ImGui_CreatePopTextWrapPos("ppw_c")
_ImGui_CreateSeparator("sep_c")

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
