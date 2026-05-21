#cs
================================================================================
 Example 145 : _ImGui_CreateList
                (+ _ImGui_SetListItems + _ImGui_GetListSelection
                 + _ImGui_SetListSelection)
================================================================================
 Covers 4 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_CreateList         Dynamic list-box widget
   _ImGui_SetListItems       Replace the list's content (1D AutoIt array)
   _ImGui_GetListSelection   Read the currently selected index (-1 = none)
   _ImGui_SetListSelection   Programmatically set the selected index

 The four are bundled in the same file because a List is not useful
 without its driver verbs (populate / read / write selection) -- same
 bundling rule as exemple100 (CreateWindow + verbs).

 Selection model :
   * Selected index is preserved BY CONTENT across SetListItems --
     reloading the same items keeps the selection.
   * -1 = no selection. Out-of-range SetListSelection also clears it.
   * _ImGui_GetValueInt is an ALIAS of _ImGui_GetListSelection on
     list widgets (shared base class).
   * Strict-changed semantics : programmatic SetListSelection does
     NOT latch HasChanged. SetOnChange fires only on user click.

 Item marshalling caveat :
   SetListItems joins the array with "|" by default. If your items
   may contain "|", pass a custom $sSep (e.g. Chr(31), the ASCII
   "Unit Separator" control char never present in normal text).
   Wrapper returns @error = 4 with @extended = offending index if a
   collision is detected.

 Borrowed widgets : Button, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple145_list.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple145_list.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 145 : _ImGui_CreateList", 720, 560) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateList  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateList($sId, $sLabel = "", $fW = 0, $fH = 0)
;
;   $fW / $fH = 0 means "fill the remaining content region". Sensible
;   defaults inside a sized Window or Child ; at root, give explicit
;   pixels to avoid the list eating the whole frame.
;
;   Return : True on success, False on failure (@error = 1, 2).

; ==============================================================================
; _ImGui_SetListItems  --  doc block
; ==============================================================================
; Signature : _ImGui_SetListItems($sId, $aItems, $sSep = "|")
;
;   $aItems  : 1D AutoIt string array. Each element becomes one row.
;   $sSep    : marshalling separator (default "|"). Items must NOT
;              contain $sSep ; @error = 4 with @extended = offending
;              index on collision. Use Chr(31) if "|" can appear.
;
;   Return : True on success, False on failure (@error = 1/2/3/4/5).

; ==============================================================================
; _ImGui_GetListSelection / _ImGui_SetListSelection  --  doc block
; ==============================================================================
; Get : returns the selected index (>= 0) or -1 if no selection.
;       _ImGui_GetValueInt is an alias.
;
; Set : $iIndex = -1 clears ; out-of-range also clears. Programmatic
;       writes never latch HasChanged (strict semantics).


; ==============================================================================
; Host header  --  the list + a few controls
; ==============================================================================
_ImGui_CreateText("t_title", "CreateList demo  --  dynamic list-box with programmatic + user-driven selection")
_ImGui_CreateText("t_hint",  "Click a row to select. Buttons below mutate selection / content programmatically.")
_ImGui_CreateSeparator("sep0")

_ImGui_CreateList("lst", "##items", 360, 160)
; Seed the initial content with a 1D AutoIt array.
Local $aSeed[6] = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta"]
_ImGui_SetListItems("lst", $aSeed)


; ==============================================================================
; Selection controls
; ==============================================================================
_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_sel_hdr", "Selection :")
_ImGui_CreateButton("btn_sel_first", "Select FIRST (index 0)")
_ImGui_CreateButton("btn_sel_last",  "Select LAST  (last index)")
_ImGui_CreateButton("btn_sel_clear", "Clear selection (-1)")
_ImGui_CreateButton("btn_sel_oob",   "Try out-of-range (999)  --  also clears")
_ImGui_CreateText("t_sel_status", "  GetListSelection() = -1   (user-change count: 0)")


; ==============================================================================
; Content controls
; ==============================================================================
_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_content_hdr", "Content :")
_ImGui_CreateButton("btn_load_greek", "Load Greek letters (6 rows ; preserves selection by content)")
_ImGui_CreateButton("btn_load_nato",  "Load NATO alphabet (10 rows)")
_ImGui_CreateButton("btn_load_empty", "Load empty list (clears selection)")

_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters + state ------------------------------------------------------
Global $g_iUserChanges = 0
; Track the size of the last-loaded item array so 'Select LAST' can target it
; (the wrapper exposes no read-back for list size). MUST be declared BEFORE
; the Bind block -- AutoIt's strict mode (MustDeclareVars) refuses to read or
; write an undeclared global from inside a handler.
Global $g_iCurCount = 6   ; matches the seed array above


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("lst",            "_OnListChanged")
_ImGui_SetOnClick ("btn_sel_first",  "_OnSelFirst")
_ImGui_SetOnClick ("btn_sel_last",   "_OnSelLast")
_ImGui_SetOnClick ("btn_sel_clear",  "_OnSelClear")
_ImGui_SetOnClick ("btn_sel_oob",    "_OnSelOob")
_ImGui_SetOnClick ("btn_load_greek", "_OnLoadGreek")
_ImGui_SetOnClick ("btn_load_nato",  "_OnLoadNato")
_ImGui_SetOnClick ("btn_load_empty", "_OnLoadEmpty")
_ImGui_SetOnClick ("btn_quit",       "_OnQuit")
_ImGui_SetOnTick("_OnPollStatus", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnListChanged($sId)
    ; Fires only on USER-driven row click (strict-changed semantics).
    $g_iUserChanges += 1
EndFunc

Func _OnSelFirst($sId)
    _ImGui_SetListSelection("lst", 0)
EndFunc

Func _OnSelLast($sId)
    ; We don't have a "size" accessor for the list, but the AutoIt-side
    ; $g_iCurCount tracks the array size of the last load. For dynamic apps,
    ; keep an AutoIt-side count of the last array passed to SetListItems.
    _ImGui_SetListSelection("lst", $g_iCurCount - 1)
EndFunc

Func _OnSelClear($sId)
    _ImGui_SetListSelection("lst", -1)
EndFunc

Func _OnSelOob($sId)
    ; Out-of-range index also clears (per docstring).
    _ImGui_SetListSelection("lst", 999)
EndFunc

Func _OnLoadGreek($sId)
    Local $aGreek[6] = ["alpha", "beta", "gamma", "delta", "epsilon", "zeta"]
    _ImGui_SetListItems("lst", $aGreek)
    $g_iCurCount = 6
EndFunc

Func _OnLoadNato($sId)
    Local $aNato[10] = ["Alfa", "Bravo", "Charlie", "Delta", "Echo", _
                        "Foxtrot", "Golf", "Hotel", "India", "Juliett"]
    _ImGui_SetListItems("lst", $aNato)
    $g_iCurCount = 10
EndFunc

Func _OnLoadEmpty($sId)
    Local $aEmpty[0]
    _ImGui_SetListItems("lst", $aEmpty)
    $g_iCurCount = 0
EndFunc

Func _OnPollStatus()
    _ImGui_SetText("t_sel_status", StringFormat("  GetListSelection() = %d   (user-change count: %d)", _
        _ImGui_GetListSelection("lst"), $g_iUserChanges))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
