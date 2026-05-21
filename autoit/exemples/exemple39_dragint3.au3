#cs
================================================================================
 Example 39 : _ImGui_CreateDragInt3
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateDragInt3   Three-component int "drag" widget
   _ImGui_GetValueIntN     Read the 3-component vector
   _ImGui_SetValueIntN     Set the 3-component vector

 DragInt3 packs three click-and-drag int fields into one widget row.

 IMPORTANT : the widget has ONE shared ($iMin, $iMax) range for all
 three components. When you need DIFFERENT bounds per component (e.g.
 a date Y/M/D where Y in 1900..2100, M in 1..12, D in 1..31), the
 standard pattern is :

     1. Create the widget unbounded ($iMin = $iMax = 0).
     2. In the OnChange handler, read the values, clamp each component
        independently in AutoIt, and SetValueIntN the corrected vector.
     3. Strict-semantics guarantee : calling SetValueIntN from OnChange
        does NOT re-fire OnChange -- no infinite loop, no extra latency.

 This file demonstrates that pattern with a Y/M/D date.

 Strict semantics : see exemple19_dragint.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple39_dragint3.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple39_dragint3.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 39 : _ImGui_CreateDragInt3", 660, 440) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateDragInt3  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateDragInt3($sId, $sLabel = "",
;                                    $fSpeed = 1.0,
;                                    $iMin = 0, $iMax = 0,
;                                    $iD0 = 0, $iD1 = 0, $iD2 = 0,
;                                    $sFormat = "%d")
;
;   Three draggable int fields, ONE shared ($iMin, $iMax) range. To
;   enforce per-component bounds, clamp in the OnChange handler and
;   write back with SetValueIntN -- the strict-semantics rule prevents
;   the corrective Set from re-firing OnChange.
;
;   Read / write the triple as an AutoIt array of size 3 :
;     _ImGui_GetValueIntN($sId, 3)        -> [v0, v1, v2]
;     _ImGui_SetValueIntN($sId, $aVals)   -> 1D array of size 3 ; no OnChange
;
;   Bind user drags with _ImGui_SetOnChange (IntVec3ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  date (Y, M, D), unbounded widget, per-component clamping
;                  enforced in the OnChange handler.
; ==============================================================================
_ImGui_CreateText("t_title", "DragInt3 demo  --  date (Y, M, D) with per-component clamping in OnChange")
_ImGui_CreateText("t_hint",  "Drag any field past its valid bound -- the handler snaps it back.")
_ImGui_CreateSeparator("sep1")

; Speed 1.0, unbounded ; defaults Y=2026, M=5, D=21 (today per the brief).
_ImGui_CreateDragInt3("dr_date", "Date (Y, M, D)", _
                      1.0, _                ; speed
                      0, 0, _               ; unbounded -- clamp in handler
                      2026, 5, 21, _        ; default
                      "%d")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read",  "Read-back : 2026-05-21 (clamped : no, valid)")
_ImGui_CreateText("t_count", "User edits  : 0   Clamp events : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueIntN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_today",  "Today        (2026,  5, 21)")
_ImGui_CreateButton("btn_bad",    "Trigger clamp (-50, 99, 999)")
_ImGui_CreateButton("btn_y2k",    "Y2K          (2000,  1,  1)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",   "Quit")


; --- Script-side state + per-component bounds --------------------------------
Global $g_iEditCount  = 0
Global $g_iClampCount = 0
Const  $g_iYMin = 1900, $g_iYMax = 2100
Const  $g_iMMin = 1,    $g_iMMax = 12
Const  $g_iDMin = 1,    $g_iDMax = 31


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("dr_date",   "_OnDateChanged")
_ImGui_SetOnClick ("btn_today", "_OnToday")
_ImGui_SetOnClick ("btn_bad",   "_OnBad")
_ImGui_SetOnClick ("btn_y2k",   "_OnY2K")
_ImGui_SetOnClick ("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

; User-edit handler : clamp each component to its own bounds and write back if
; we had to fix anything. The corrective SetValueIntN does NOT re-fire OnChange,
; so the user can keep dragging without lag.
Func _OnDateChanged($sId)
    Local $aVal = _ImGui_GetValueIntN($sId, 3)
    If @error Or Not IsArray($aVal) Then Return
    $g_iEditCount += 1

    Local $iY = $aVal[0], $iM = $aVal[1], $iD = $aVal[2]
    Local $iYc = _Clamp($iY, $g_iYMin, $g_iYMax)
    Local $iMc = _Clamp($iM, $g_iMMin, $g_iMMax)
    Local $iDc = _Clamp($iD, $g_iDMin, $g_iDMax)

    Local $bClamped = ($iYc <> $iY) Or ($iMc <> $iM) Or ($iDc <> $iD)
    If $bClamped Then
        Local $aFixed[3] = [$iYc, $iMc, $iDc]
        _ImGui_SetValueIntN("dr_date", $aFixed)
        $g_iClampCount += 1
    EndIf

    _ImGui_SetText("t_read",  StringFormat("Read-back : %04d-%02d-%02d (clamped : %s)", _
                                            $iYc, $iMc, $iDc, ($bClamped ? "yes" : "no, valid")))
    _ImGui_SetText("t_count", StringFormat("User edits  : %d   Clamp events : %d", _
                                            $g_iEditCount, $g_iClampCount))
EndFunc

Func _OnToday($sId)
    _ApplyPreset(2026, 5, 21, "today")
EndFunc

Func _OnBad($sId)
    ; Out-of-range values on purpose -- OnChange does NOT fire from SetValueIntN,
    ; so the readout below is what we set, not the clamped version.
    _ApplyPreset(-50, 99, 999, "raw out-of-range, no clamp because no OnChange")
EndFunc

Func _OnY2K($sId)
    _ApplyPreset(2000, 1, 1, "Y2K")
EndFunc

Func _ApplyPreset($iY, $iM, $iD, $sTag)
    Local $aNew[3] = [$iY, $iM, $iD]
    _ImGui_SetValueIntN("dr_date", $aNew)
    _ImGui_SetText("t_read", StringFormat("Read-back : %04d-%02d-%02d (programmatic, %s)", _
                                          $iY, $iM, $iD, $sTag))
EndFunc

Func _Clamp($iVal, $iLo, $iHi)
    If $iVal < $iLo Then Return $iLo
    If $iVal > $iHi Then Return $iHi
    Return $iVal
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
