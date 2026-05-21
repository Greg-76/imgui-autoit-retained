#cs
================================================================================
 Example 192 : _ImGui_GetStyleColorName
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_GetStyleColorName   Look up the human-readable name of an
                              ImGuiCol_ slot (e.g. 0 -> "Text",
                              5 -> "Border", 27 -> "HeaderActive")

 Reflection helper -- useful for building a theme inspector / editor
 from scratch (vs the built-in ShowStyleEditor, exemple177). The
 wrapper exposes the slot indices as named constants
 $ImGuiCol_Text / _Border / _WindowBg / ... with $ImGuiCol_COUNT = 63
 as the sentinel (slot indices 0..62 are valid ; 63+ returns "").

 This example iterates all 63 slot indices, builds an InputText-
 filtered list, and shows the live count + selection. The
 selected slot's index + name are mirrored into a Text widget --
 the basic building block of a custom palette editor.

 Buffer size : default 64 wchars is plenty (the longest ImGui color
 name is "TableRowBgAlt" = 13 chars). Status 4 = truncation is
 silently absorbed by the wrapper -- same quirk as
 SaveSettingsToMemory (exemple187) and GetClipboardText (exemple198).

 Borrowed widgets : List + SetListItems (exemple145), InputText
 (exemple147), Text + Separator, Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple192_getstylecolorname.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple192_getstylecolorname.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 192 : GetStyleColorName", 760, 660) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_GetStyleColorName  --  doc block
; ==============================================================================
; Signature : _ImGui_GetStyleColorName($iColIdx, $iBufSize = 64)
;
;   $iColIdx  : $ImGuiCol_* slot index (0..$ImGuiCol_COUNT - 1 valid).
;   $iBufSize : output buffer capacity (wchars). 64 is plenty.
;
;   Return : the name string on success ("Text", "Border", "WindowBg",
;            "FrameBgActive", "TableHeaderBg", ...). Empty "" with
;            @error on failure (1 DLL not loaded, 2 DllCall failed,
;            3 DLL status non-zero and non-truncation).
;
;   Out-of-range indices : ImGui returns the literal string "Unknown"
;   for negative or >= COUNT slots ; the wrapper passes it through
;   verbatim (no error raised).


; ==============================================================================
; Build the full slot name table at startup
; ==============================================================================
Global Const $g_iSlots = $ImGuiCol_COUNT
Global $g_aNames[$g_iSlots]
For $i = 0 To $g_iSlots - 1
    $g_aNames[$i] = _ImGui_GetStyleColorName($i)
Next


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "GetStyleColorName demo  --  reflection over the " & $g_iSlots & " ImGuiCol_ slots")
_ImGui_CreateText("t_hint",  "Type in the filter to narrow the list ; click an entry to see its slot index.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Filter + list
; ==============================================================================
_ImGui_CreateText("t_filter_hdr", "Filter (substring, case-insensitive) :")
_ImGui_CreateInputText("in_filter", "##filter", "", 64)
_ImGui_CreateText("t_count", "Showing : 0 / 0")
_ImGui_CreateList("ls_names", "##names", 0, 220)
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Selection readout
; ==============================================================================
_ImGui_CreateText("t_sel_hdr", "Selection :")
_ImGui_CreateText("t_sel", "  (nothing selected yet)")
_ImGui_CreateSeparator("sep2")


_ImGui_CreateButton("btn_quit", "Quit")


; --- Globals (filter state, must precede bindings) ---------------------------
; $g_aFilteredIdx maps List position -> slot index, so OnChange on the list
; resolves back to the original $ImGuiCol_ value (the list shows a subset).
Global $g_aFilteredIdx[1] = [-1]


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("in_filter", "_OnFilterChanged")
_ImGui_SetOnChange("ls_names",  "_OnListSelected")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")

; Seed the list with the unfiltered set.
_RebuildList("")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnFilterChanged($sId)
    Local $sFilter = _ImGui_GetValueString($sId)
    _RebuildList($sFilter)
EndFunc

Func _OnListSelected($sId)
    Local $iListPos = _ImGui_GetListSelection($sId)
    If $iListPos < 0 Or $iListPos >= UBound($g_aFilteredIdx) Then Return
    Local $iSlot = $g_aFilteredIdx[$iListPos]
    If $iSlot < 0 Then Return
    _ImGui_SetText("t_sel", StringFormat( _
        "  slot index = %d  ->  name = '%s'", $iSlot, $g_aNames[$iSlot]))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc


; Helper : rebuild the displayed list from the current filter, refresh count.
Func _RebuildList($sFilter)
    Local $sLow = StringLower($sFilter)
    Local $aDisplay[$g_iSlots]
    Local $aMap[$g_iSlots]
    Local $iKept = 0
    For $i = 0 To $g_iSlots - 1
        If $sLow = "" Or StringInStr(StringLower($g_aNames[$i]), $sLow) > 0 Then
            $aDisplay[$iKept] = StringFormat("[%2d] %s", $i, $g_aNames[$i])
            $aMap[$iKept] = $i
            $iKept += 1
        EndIf
    Next
    ; Shrink arrays to actual count.
    Local $iSize = $iKept
    If $iSize < 1 Then $iSize = 1
    ReDim $aDisplay[$iSize]
    ReDim $aMap[$iSize]
    If $iKept = 0 Then
        $aDisplay[0] = "(no match)"
        $aMap[0] = -1
    EndIf
    _ImGui_SetListItems("ls_names", $aDisplay)
    $g_aFilteredIdx = $aMap
    _ImGui_SetText("t_count", StringFormat("Showing : %d / %d", $iKept, $g_iSlots))
EndFunc
