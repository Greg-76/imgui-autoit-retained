#cs
================================================================================
 Example 82 : _ImGui_CreatePushItemFlag
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreatePushItemFlag   Push an item-behavior flag override

 PushItemFlag changes behavioral flags for every widget added next,
 until a matching PopItemFlag (exemple83) restores the previous state.
 Useful for batch-applying behaviors that are not part of a widget's
 constructor :

   - $ImGuiItemFlags_NoTabStop        = 1     ; skip in Tab navigation
   - $ImGuiItemFlags_NoNav            = 2     ; skip in kbd / gamepad navigation
   - $ImGuiItemFlags_NoNavDefaultFocus= 4
   - $ImGuiItemFlags_ButtonRepeat     = 8     ; hold = repeated clicks
   - $ImGuiItemFlags_AutoClosePopups  = 16    ; MenuItem/Selectable close their popup
   - $ImGuiItemFlags_AllowDuplicateId = 32    ; advanced ; bypass duplicate-id assert

 Push/Pop balancing applies. Pop variant has no $iCount fast-path
 (one Pop per Push, like PopItemWidth / PopTextWrapPos).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple82_pushitemflag.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple82_pushitemflag.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 82 : _ImGui_CreatePushItemFlag", 640, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreatePushItemFlag  --  doc block
; ==============================================================================
; Signature : _ImGui_CreatePushItemFlag($sId,
;                                        $iOption = 0,
;                                        $bEnabled = 0)
;
;   $iOption  : one of the $ImGuiItemFlags_* constants (see header). Push
;               a single flag at a time -- compose multiple by stacking
;               multiple Push/Pop pairs (each Pop undoes one Push).
;   $bEnabled : True to ENABLE the flag, False to DISABLE it for the
;               scope. ImGui treats the flag as a tri-state : default,
;               forced on, forced off.
;
;   PITFALL : the wrapper accepts $bEnabled as an integer ; pass 1 / 0
;   (or True / False) consistently. Anything truthy enables.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  ButtonRepeat (most visible), NoTabStop, and a stacked
;                  combination of the two.
; ==============================================================================
_ImGui_CreateText("t_title", "PushItemFlag demo  --  ButtonRepeat, NoTabStop, stacked combinations")
_ImGui_CreateText("t_hint",  "Use the keyboard (Tab) to walk through the controls and try holding the repeat-flag button down.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) ButtonRepeat -- holding the button fires multiple OnClicks ----------
_ImGui_CreateText("a_hdr", "(A) PushItemFlag(ButtonRepeat, True) -- holding the button fires clicks repeatedly :")
_ImGui_CreatePushItemFlag("pif_a", $ImGuiItemFlags_ButtonRepeat, True)
_ImGui_CreateButton("a_b_inc", "Hold me -- I auto-repeat (+1 per repeat)")
_ImGui_CreatePopItemFlag("ppf_a")
_ImGui_CreateText("a_count", "Repeat counter : 0")
_ImGui_CreateButton("a_b_normal", "Normal button (single click only)")
_ImGui_CreateSeparator("sep_a")

; --- (B) NoTabStop -- the button below is skipped during Tab navigation ------
_ImGui_CreateText("b_hdr", "(B) PushItemFlag(NoTabStop, True) -- the styled button is skipped by Tab :")
_ImGui_CreateInputText("b_in_before", "##b_in_before", "Tab focusable -- type Tab", 64, 0)
_ImGui_CreatePushItemFlag("pif_b", $ImGuiItemFlags_NoTabStop, True)
_ImGui_CreateButton("b_b_skip", "Tab SKIPS me (NoTabStop flag pushed)")
_ImGui_CreatePopItemFlag("ppf_b")
_ImGui_CreateInputText("b_in_after",  "##b_in_after",  "Tab focusable again", 64, 0)
_ImGui_CreateSeparator("sep_b")

; --- (C) Stacked : ButtonRepeat + NoTabStop together -------------------------
_ImGui_CreateText("c_hdr", "(C) Stacked Push : both ButtonRepeat AND NoTabStop active for the same button :")
_ImGui_CreatePushItemFlag("pif_c1", $ImGuiItemFlags_ButtonRepeat, True)
_ImGui_CreatePushItemFlag("pif_c2", $ImGuiItemFlags_NoTabStop,    True)
_ImGui_CreateButton("c_b_both", "Hold-to-repeat AND skipped by Tab")
_ImGui_CreatePopItemFlag("ppf_c2")   ; pop NoTabStop first (LIFO)
_ImGui_CreatePopItemFlag("ppf_c1")   ; pop ButtonRepeat next
_ImGui_CreateButton("c_b_normal", "Both pops done -- normal button")
_ImGui_CreateSeparator("sep_c")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iRepeatCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("a_b_inc",  "_OnRepeatTick")
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnRepeatTick($sId)
    $g_iRepeatCount += 1
    _ImGui_SetText("a_count", "Repeat counter : " & $g_iRepeatCount)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
