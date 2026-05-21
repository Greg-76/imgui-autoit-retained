#cs
================================================================================
 Example 146 : _ImGui_CreateCombo  (+ _ImGui_SetComboItems)
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_CreateCombo     Dropdown selector widget
   _ImGui_SetComboItems   Replace the dropdown items (1D AutoIt array)

 Combo SHARES its data model with List (exemple145) -- same base
 class under the hood. As a consequence :
   * Selection read   : _ImGui_GetListSelection($sId)  (or the alias
                        _ImGui_GetValueInt)
   * Selection write  : _ImGui_SetListSelection($sId, $iIndex)
   * Event            : _ImGui_SetOnChange (latched HasChanged)
   * Item marshalling : same "|" separator with optional override
                        (see exemple145 caveat).

 Combo-only differences from List :
   * Visual : dropdown button + preview text rather than a fixed box.
   * Sizing : no $fW/$fH at create time -- ImGui auto-sizes ; tune via
              $iFlags ($ImGuiComboFlags_HeightSmall / HeightLarge /
              HeightLargest control dropdown height ; NoArrowButton /
              NoPreview / WidthFitPreview tweak the trigger).

 Demo : three combos side by side with different flag combinations,
 plus a button row that mutates their content / selection.

 Borrowed widgets : List verbs (exemple145 -- GetListSelection /
 SetListSelection), Button, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple146_combo.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple146_combo.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 146 : _ImGui_CreateCombo", 760, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateCombo  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateCombo($sId, $sLabel = "", $iFlags = 0)
;
;   $iFlags : bitmask of $ImGuiComboFlags_*. Useful values :
;     0    = None
;     1    = PopupAlignLeft       popup leans left
;     2    = HeightSmall          max ~4 items visible
;     4    = HeightRegular        default, max ~8 items
;     8    = HeightLarge          max ~20 items
;     16   = HeightLargest        as many as fit on screen
;     32   = NoArrowButton        hide the square arrow
;     64   = NoPreview            only the arrow, no preview text
;     128  = WidthFitPreview      trigger width tracks preview
;
;   Return : True on success, False on failure (@error = 1, 2).

; ==============================================================================
; _ImGui_SetComboItems  --  doc block
; ==============================================================================
; Signature : _ImGui_SetComboItems($sId, $aItems, $sSep = "|")
;
;   Identical marshalling rules to _ImGui_SetListItems (exemple145) :
;   1D string array, "|" separator by default, @error = 4 on collision.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateCombo demo  --  three flag combos + List-shared verbs (Get/SetListSelection)")
_ImGui_CreateText("t_hint",  "Click a combo, pick a row. Status below polls GetListSelection at 100ms.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Combo 1  --  default flags
; ==============================================================================
_ImGui_CreateText("t_a_hdr", "1) Default flags (HeightRegular implicit) :")
_ImGui_CreateCombo("cmb_a", "Pick a fruit", 0)
Local $aFruits[5] = ["apple", "banana", "cherry", "date", "elderberry"]
_ImGui_SetComboItems("cmb_a", $aFruits)
_ImGui_SetListSelection("cmb_a", 0)


; ==============================================================================
; Combo 2  --  HeightSmall + WidthFitPreview
; ==============================================================================
_ImGui_CreateText("t_b_hdr", "2) HeightSmall + WidthFitPreview :")
_ImGui_CreateCombo("cmb_b", "Pick a metal", _
                    BitOR($ImGuiComboFlags_HeightSmall, $ImGuiComboFlags_WidthFitPreview))
Local $aMetals[6] = ["iron", "copper", "silver", "gold", "platinum", "titanium"]
_ImGui_SetComboItems("cmb_b", $aMetals)
_ImGui_SetListSelection("cmb_b", 2)


; ==============================================================================
; Combo 3  --  NoPreview + NoArrowButton (just a triggerless square button)
; ==============================================================================
_ImGui_CreateText("t_c_hdr", "3) NoPreview + NoArrowButton (compact trigger ; preview text replaced by label only) :")
_ImGui_CreateCombo("cmb_c", "Pick a planet", _
                    BitOR($ImGuiComboFlags_NoPreview, $ImGuiComboFlags_NoArrowButton))
Local $aPlanets[4] = ["Mercury", "Venus", "Earth", "Mars"]
_ImGui_SetComboItems("cmb_c", $aPlanets)


; ==============================================================================
; Status footer
; ==============================================================================
_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_status",  "Selections  --  cmb_a: 0   cmb_b: 2   cmb_c: -1")
_ImGui_CreateText("t_changes", "User-change counts  --  cmb_a: 0   cmb_b: 0   cmb_c: 0")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_ctrl_hdr", "Controls :")
_ImGui_CreateButton("btn_reload_a", "Reload cmb_a with citrus (3 items)")
_ImGui_CreateButton("btn_pick_b",   "Set cmb_b selection to last (titanium)")
_ImGui_CreateButton("btn_clear_c",  "Clear cmb_c selection (-1)")

_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters ---------------------------------------------------------------
Global $g_iChgA = 0
Global $g_iChgB = 0
Global $g_iChgC = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("cmb_a", "_OnChgA")
_ImGui_SetOnChange("cmb_b", "_OnChgB")
_ImGui_SetOnChange("cmb_c", "_OnChgC")
_ImGui_SetOnClick ("btn_reload_a", "_OnReloadA")
_ImGui_SetOnClick ("btn_pick_b",   "_OnPickB")
_ImGui_SetOnClick ("btn_clear_c",  "_OnClearC")
_ImGui_SetOnClick ("btn_quit",     "_OnQuit")
_ImGui_SetOnTick("_OnPollStatus", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnChgA($sId)
    $g_iChgA += 1
EndFunc

Func _OnChgB($sId)
    $g_iChgB += 1
EndFunc

Func _OnChgC($sId)
    $g_iChgC += 1
EndFunc

Func _OnReloadA($sId)
    Local $aCitrus[3] = ["lemon", "lime", "orange"]
    _ImGui_SetComboItems("cmb_a", $aCitrus)
    ; Selection is preserved by CONTENT -- after a reload, old index may now
    ; point at a different row. Set explicitly if you need a clean state.
    _ImGui_SetListSelection("cmb_a", 0)
EndFunc

Func _OnPickB($sId)
    _ImGui_SetListSelection("cmb_b", 5)   ; "titanium" in the seeded array
EndFunc

Func _OnClearC($sId)
    _ImGui_SetListSelection("cmb_c", -1)
EndFunc

Func _OnPollStatus()
    _ImGui_SetText("t_status", StringFormat("Selections  --  cmb_a: %d   cmb_b: %d   cmb_c: %d", _
        _ImGui_GetListSelection("cmb_a"), _
        _ImGui_GetListSelection("cmb_b"), _
        _ImGui_GetListSelection("cmb_c")))
    _ImGui_SetText("t_changes", StringFormat("User-change counts  --  cmb_a: %d   cmb_b: %d   cmb_c: %d", _
        $g_iChgA, $g_iChgB, $g_iChgC))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
