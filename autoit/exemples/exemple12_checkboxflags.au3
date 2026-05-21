#cs
================================================================================
 Example 12 : _ImGui_CreateCheckboxFlags
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateCheckboxFlags    Checkbox bound to one bit of an int mask
   _ImGui_GetValueInt            Read the current mask
   _ImGui_SetValueInt            Propagate the mask to the other checkboxes

 CheckboxFlags is the canonical UI for editing a single int that packs
 multiple boolean flags -- think Unix rwx permissions, ImGui flag enums,
 access masks, etc.

 Architecture (important) : each CheckboxFlags widget owns ITS OWN copy
 of the int mask. To make N checkboxes act as N bits of the SAME mask,
 the script must propagate every change via _ImGui_SetValueInt to the
 other widgets. The demo below does exactly that for a 3-bit rwx pattern.

 Event-driven pattern : see exemple5_button.au3 for OnClick / OnChange
 semantics ; same rules apply (strict semantics, no programmatic event).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple12_checkboxflags.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple12_checkboxflags.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 12 : _ImGui_CreateCheckboxFlags", 600, 360) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateCheckboxFlags  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateCheckboxFlags($sId, $sLabel = "", $iDefault = 0, $iFlagsValue = 0)
;
;   Renders a checkbox whose check state is "(mask AND $iFlagsValue) == $iFlagsValue".
;   Clicking it XORs $iFlagsValue into the widget's internal mask.
;
;   Parameters :
;     $sId         Stable identifier.
;     $sLabel      Displayed label. Empty falls back to $sId.
;     $iDefault    Initial mask value. Same default across multiple widgets
;                  is what lets them "share" a logical mask.
;     $iFlagsValue The bit (or bit combo) this checkbox represents.
;
;   Read APIs :
;     _ImGui_GetValueInt($sId)         -> full mask of THIS widget
;     _ImGui_GetValueBool($sId)        -> True iff all bits of $iFlagsValue are set
;     _ImGui_SetValueInt($sId, $iMask) -> overwrite this widget's mask
;
;   Sharing the mask across N widgets : whenever one fires OnChange,
;   propagate its new mask to the other N-1 widgets via SetValueInt.
;   SetValueInt does NOT fire OnChange (strict semantics) -- no cascade.


; ==============================================================================
; Demo widgets  --  three checkboxes acting as rwx bits of a shared mask
; ==============================================================================
; Bit values : Read = 4, Write = 2, Execute = 1  (POSIX-style).
; We initialise all three widgets with the same default (5 = Read + Execute)
; so they start in sync.
Const $g_iBitR = 4
Const $g_iBitW = 2
Const $g_iBitX = 1
Const $g_iInitMask = $g_iBitR + $g_iBitX  ; = 5

_ImGui_CreateText("t_title", "CheckboxFlags demo  --  POSIX rwx pattern")
_ImGui_CreateText("t_hint1", "Three checkboxes share a single 3-bit mask. Toggling any of them")
_ImGui_CreateText("t_hint2", "propagates the new mask to the other two via _ImGui_SetValueInt.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateCheckboxFlags("cb_r", "Read    (bit 4)",  $g_iInitMask, $g_iBitR)
_ImGui_CreateCheckboxFlags("cb_w", "Write   (bit 2)",  $g_iInitMask, $g_iBitW)
_ImGui_CreateCheckboxFlags("cb_x", "Execute (bit 1)",  $g_iInitMask, $g_iBitX)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_mask", "Current mask  : 5 (r-x)")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind  --  same handler for all three, discriminates via $sId ----------
_ImGui_SetOnChange("cb_r",     "_OnRwxToggled")
_ImGui_SetOnChange("cb_w",     "_OnRwxToggled")
_ImGui_SetOnChange("cb_x",     "_OnRwxToggled")
_ImGui_SetOnClick ("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnRwxToggled($sId)
    ; Step 1 : read the new mask from the widget that fired.
    Local $iMask = _ImGui_GetValueInt($sId)

    ; Step 2 : propagate to the OTHER two widgets so they all share the
    ; same mask. SetValueInt does not fire OnChange -- no cascade.
    Switch $sId
        Case "cb_r"
            _ImGui_SetValueInt("cb_w", $iMask)
            _ImGui_SetValueInt("cb_x", $iMask)
        Case "cb_w"
            _ImGui_SetValueInt("cb_r", $iMask)
            _ImGui_SetValueInt("cb_x", $iMask)
        Case "cb_x"
            _ImGui_SetValueInt("cb_r", $iMask)
            _ImGui_SetValueInt("cb_w", $iMask)
    EndSwitch

    ; Step 3 : render the mask in human form for the user.
    Local $sRwx = ""
    $sRwx &= BitAND($iMask, $g_iBitR) ? "r" : "-"
    $sRwx &= BitAND($iMask, $g_iBitW) ? "w" : "-"
    $sRwx &= BitAND($iMask, $g_iBitX) ? "x" : "-"
    _ImGui_SetText("t_mask", StringFormat("Current mask  : %d (%s)", $iMask, $sRwx))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
