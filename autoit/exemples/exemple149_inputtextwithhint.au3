#cs
================================================================================
 Example 149 : _ImGui_CreateInputTextWithHint
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateInputTextWithHint   Single-line InputText with a
                                    placeholder string shown when the
                                    buffer is empty

 Same data model + event flags as _ImGui_CreateInputText (exemple147)
 -- the only difference is the extra $sHint parameter. ImGui renders
 $sHint in greyed-out style WHEN the buffer is empty and the widget
 does NOT have focus. As soon as the user types a single character
 (or SetValueString puts content in), the hint disappears.

 The hint is COSMETIC -- it never becomes part of the buffer. Reading
 with _ImGui_GetValueString returns "" while only the hint is shown.

 Typical UX patterns :
   * Search box     : "Type to search..."
   * Login form     : "user@example.com"
   * Numeric input  : "0.00 USD"
   * Multi-language : the hint can be localized while the widget id
                      stays stable.

 The $iMaxLength + $iFlags arguments work exactly as in the standard
 InputText variant.

 Borrowed widgets : Button, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple149_inputtextwithhint.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple149_inputtextwithhint.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 149 : _ImGui_CreateInputTextWithHint", 760, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateInputTextWithHint  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateInputTextWithHint($sId, $sLabel = "",
;                                             $sHint = "",
;                                             $sDefault = "",
;                                             $iMaxLength = 256,
;                                             $iFlags = 0)
;
;   $sHint   : greyed-out placeholder shown when the buffer is empty
;              and the widget is not focused. Never enters the buffer.
;
;   The other arguments mirror _ImGui_CreateInputText (exemple147) :
;   $sDefault = initial content, $iMaxLength = buffer cap (default
;   256), $iFlags = $ImGuiInputTextFlags_* bitmask.
;
;   Return : True on success, False on failure (@error = 1, 2).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateInputTextWithHint demo  --  three search-style fields with placeholder text")
_ImGui_CreateText("t_hint",  "Hints fade as soon as you type. Use the 'Clear' buttons to bring them back.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; A) Generic search box  --  no special flags
; ==============================================================================
_ImGui_CreateInputTextWithHint("in_search", "Search", "Type to search...", "", 128)


; ==============================================================================
; B) Login email field  --  AutoSelectAll for easy retyping
; ==============================================================================
_ImGui_CreateInputTextWithHint("in_email", "Email", "user@example.com", "", 128, _
                                $ImGuiInputTextFlags_AutoSelectAll)


; ==============================================================================
; C) Numeric ID field  --  CharsDecimal restricts to digits
; ==============================================================================
_ImGui_CreateInputTextWithHint("in_id", "User ID", "e.g. 12345", "", 16, _
                                $ImGuiInputTextFlags_CharsDecimal)


; ==============================================================================
; Programmatic controls
; ==============================================================================
_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_ctrl_hdr", "Controls (programmatic) :")
_ImGui_CreateButton("btn_clear_all",   "Clear all three fields (hints re-appear)")
_ImGui_CreateButton("btn_seed_search", "Seed Search with 'imgui'")
_ImGui_CreateButton("btn_seed_email",  "Seed Email with 'alice@example.com'")


; ==============================================================================
; Status footer
; ==============================================================================
_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_status_hdr", "Live state (polled at 100ms) :")
_ImGui_CreateText("t_status_search", "  Search : <empty>")
_ImGui_CreateText("t_status_email",  "  Email  : <empty>")
_ImGui_CreateText("t_status_id",     "  UserID : <empty>")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_clear_all",   "_OnClearAll")
_ImGui_SetOnClick("btn_seed_search", "_OnSeedSearch")
_ImGui_SetOnClick("btn_seed_email",  "_OnSeedEmail")
_ImGui_SetOnClick("btn_quit",        "_OnQuit")
_ImGui_SetOnTick("_OnPollStatus", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnClearAll($sId)
    _ImGui_SetValueString("in_search", "")
    _ImGui_SetValueString("in_email",  "")
    _ImGui_SetValueString("in_id",     "")
EndFunc

Func _OnSeedSearch($sId)
    _ImGui_SetValueString("in_search", "imgui")
EndFunc

Func _OnSeedEmail($sId)
    _ImGui_SetValueString("in_email", "alice@example.com")
EndFunc

Func _OnPollStatus()
    Local $sS = _ImGui_GetValueString("in_search")
    Local $sE = _ImGui_GetValueString("in_email")
    Local $sI = _ImGui_GetValueString("in_id")
    _ImGui_SetText("t_status_search", "  Search : " & ($sS = "" ? "<empty -- hint visible>" : $sS))
    _ImGui_SetText("t_status_email",  "  Email  : " & ($sE = "" ? "<empty -- hint visible>" : $sE))
    _ImGui_SetText("t_status_id",     "  UserID : " & ($sI = "" ? "<empty -- hint visible>" : $sI))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
