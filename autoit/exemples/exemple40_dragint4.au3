#cs
================================================================================
 Example 40 : _ImGui_CreateDragInt4
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateDragInt4   Four-component int "drag" widget
   _ImGui_GetValueIntN     Read the 4-component vector
   _ImGui_SetValueIntN     Set the 4-component vector

 DragInt4 packs four click-and-drag int fields into one widget row.

 Same "shared range" caveat as DragInt3 (exemple39) -- here applied to
 a time-of-day quad (H, M, S, ms) where each component has its own
 valid interval. The fix is the same : create unbounded, clamp in the
 OnChange handler, write the corrected quad back with SetValueIntN.

 Strict semantics : see exemple19_dragint.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple40_dragint4.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple40_dragint4.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 40 : _ImGui_CreateDragInt4", 680, 460) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateDragInt4  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateDragInt4($sId, $sLabel = "",
;                                    $fSpeed = 1.0,
;                                    $iMin = 0, $iMax = 0,
;                                    $iD0 = 0, $iD1 = 0, $iD2 = 0, $iD3 = 0,
;                                    $sFormat = "%d")
;
;   Four draggable int fields, ONE shared ($iMin, $iMax) range. For
;   per-component bounds, clamp inside the OnChange handler and write
;   the fixed quad back -- the strict-semantics rule prevents the
;   corrective Set from re-firing OnChange.
;
;   Read / write the quad as an AutoIt array of size 4 :
;     _ImGui_GetValueIntN($sId, 4)        -> [v0, v1, v2, v3]
;     _ImGui_SetValueIntN($sId, $aVals)   -> 1D array of size 4 ; no OnChange
;
;   Bind user drags with _ImGui_SetOnChange (IntVec4ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  time of day (H, M, S, ms), per-component clamping in
;                  OnChange (same pattern as exemple39_dragint3.au3).
; ==============================================================================
_ImGui_CreateText("t_title", "DragInt4 demo  --  time-of-day (H, M, S, ms) with per-component clamping")
_ImGui_CreateText("t_hint",  "Each field has its own valid range. Drag past the bound -- the handler snaps it back.")
_ImGui_CreateSeparator("sep1")

; Speed 1.0, unbounded ; default 12:30:00.000.
_ImGui_CreateDragInt4("dr_time", "Time (H, M, S, ms)", _
                      1.0, _                  ; speed
                      0, 0, _                 ; unbounded -- clamp in handler
                      12, 30, 0, 0, _         ; default
                      "%d")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : 12:30:00.000 (clamped : no, valid)")
_ImGui_CreateText("t_count", "User edits  : 0   Clamp events : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueIntN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_noon",     "Noon          (12,  0,  0,   0)")
_ImGui_CreateButton("btn_eom",      "End-of-min    (23, 59, 59, 999)")
_ImGui_CreateButton("btn_bad",      "Trigger clamp (99, 99, 99, 9999)")
_ImGui_CreateButton("btn_addsec",   "Add 1 second (carry-over not done here)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",     "Quit")


; --- Script-side state + per-component bounds --------------------------------
Global $g_iEditCount  = 0
Global $g_iClampCount = 0
Const  $g_iHMin = 0, $g_iHMax = 23
Const  $g_iMMin = 0, $g_iMMax = 59
Const  $g_iSMin = 0, $g_iSMax = 59
Const  $g_iMsMin = 0, $g_iMsMax = 999


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("dr_time",    "_OnTimeChanged")
_ImGui_SetOnClick ("btn_noon",   "_OnNoon")
_ImGui_SetOnClick ("btn_eom",    "_OnEndOfMin")
_ImGui_SetOnClick ("btn_bad",    "_OnBad")
_ImGui_SetOnClick ("btn_addsec", "_OnAddSecond")
_ImGui_SetOnClick ("btn_quit",   "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnTimeChanged($sId)
    Local $aVal = _ImGui_GetValueIntN($sId, 4)
    If @error Or Not IsArray($aVal) Then Return
    $g_iEditCount += 1

    Local $iH = $aVal[0], $iM = $aVal[1], $iS = $aVal[2], $iMs = $aVal[3]
    Local $iHc  = _Clamp($iH,  $g_iHMin,  $g_iHMax)
    Local $iMc  = _Clamp($iM,  $g_iMMin,  $g_iMMax)
    Local $iSc  = _Clamp($iS,  $g_iSMin,  $g_iSMax)
    Local $iMsc = _Clamp($iMs, $g_iMsMin, $g_iMsMax)

    Local $bClamped = ($iHc <> $iH) Or ($iMc <> $iM) Or ($iSc <> $iS) Or ($iMsc <> $iMs)
    If $bClamped Then
        Local $aFixed[4] = [$iHc, $iMc, $iSc, $iMsc]
        _ImGui_SetValueIntN("dr_time", $aFixed)
        $g_iClampCount += 1
    EndIf

    _ImGui_SetText("t_read",  StringFormat("Read-back : %02d:%02d:%02d.%03d (clamped : %s)", _
                                            $iHc, $iMc, $iSc, $iMsc, ($bClamped ? "yes" : "no, valid")))
    _ImGui_SetText("t_count", StringFormat("User edits  : %d   Clamp events : %d", _
                                            $g_iEditCount, $g_iClampCount))
EndFunc

Func _OnNoon($sId)
    _ApplyPreset(12, 0, 0, 0, "noon")
EndFunc

Func _OnEndOfMin($sId)
    _ApplyPreset(23, 59, 59, 999, "end-of-day")
EndFunc

Func _OnBad($sId)
    ; Set raw out-of-range values. Since SetValueIntN does NOT fire OnChange,
    ; no clamping happens here -- the next USER drag will trigger the clamp.
    _ApplyPreset(99, 99, 99, 9999, "raw out-of-range, drag once to clamp")
EndFunc

Func _OnAddSecond($sId)
    ; Add 1 to the seconds. Note : we intentionally do NOT propagate carry
    ; (60s -> +1min) in this demo. A real time editor would either do that,
    ; or use a different model (single int = ms since midnight).
    Local $aVal = _ImGui_GetValueIntN("dr_time", 4)
    If @error Or Not IsArray($aVal) Then Return
    _ApplyPreset($aVal[0], $aVal[1], $aVal[2] + 1, $aVal[3], "+1 second (no carry)")
EndFunc

Func _ApplyPreset($iH, $iM, $iS, $iMs, $sTag)
    Local $aNew[4] = [$iH, $iM, $iS, $iMs]
    _ImGui_SetValueIntN("dr_time", $aNew)
    _ImGui_SetText("t_read", StringFormat("Read-back : %02d:%02d:%02d.%03d (programmatic, %s)", _
                                          $iH, $iM, $iS, $iMs, $sTag))
EndFunc

Func _Clamp($iVal, $iLo, $iHi)
    If $iVal < $iLo Then Return $iLo
    If $iVal > $iHi Then Return $iHi
    Return $iVal
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
