#cs
================================================================================
 Example 45 : _ImGui_CreateInputInt3
================================================================================
 Covers 3 exports of imgui_autoit.dll :

   _ImGui_CreateInputInt3   Three-component int text-input widget
   _ImGui_GetValueIntN      Read the 3-component vector
   _ImGui_SetValueIntN      Set the 3-component vector

 InputInt3 = three editable int fields, keyboard-driven, no drag.

 PITFALL : InputInt*N has NO $sFormat argument in the wrapper (always
 displayed as "%d"). Format human-readable strings yourself in a
 separate Text widget driven by OnChange -- this example demonstrates
 the pattern with a "vM.m.p" version triplet readout.

 Strict semantics : see exemple21_inputint.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple45_inputint3.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple45_inputint3.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 45 : _ImGui_CreateInputInt3", 620, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateInputInt3  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateInputInt3($sId, $sLabel = "",
;                                     $iD0 = 0, $iD1 = 0, $iD2 = 0)
;
;   Three editable int text fields, "%d" formatting only. Commit on
;   Enter / Tab / focus loss.
;
;   Read / write the triple as an AutoIt array of size 3 :
;     _ImGui_GetValueIntN($sId, 3)        -> [v0, v1, v2]
;     _ImGui_SetValueIntN($sId, $aVals)   -> 1D array of size 3 ; no OnChange
;
;   Bind user commits with _ImGui_SetOnChange (IntVec3ValueWidget).
;
;   Return : True on success, False on failure.


; ==============================================================================
; Demo widgets  --  semver-style version triplet (major, minor, patch)
;                  with a human-readable "vM.m.p" readout
; ==============================================================================
_ImGui_CreateText("t_title", "InputInt3 demo  --  version triplet (major, minor, patch)")
_ImGui_CreateText("t_hint",  "Type integers then Enter or Tab to commit. The vM.m.p readout is composed by the script.")
_ImGui_CreateSeparator("sep1")

; Default 1.0.0.
_ImGui_CreateInputInt3("in_ver", "Version (M, m, p)", 1, 0, 0)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_read", "Read-back : major=1, minor=0, patch=0")
_ImGui_CreateText("t_ver",  "Version string : v1.0.0")
_ImGui_CreateText("t_count","User commits : 0")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_ctl_hdr", "Programmatic presets (SetValueIntN, do NOT fire OnChange) :")
_ImGui_CreateButton("btn_v100",  "v1.0.0   (initial release)")
_ImGui_CreateButton("btn_bump_p","Bump patch (.., .., +1)")
_ImGui_CreateButton("btn_bump_m","Bump minor (.., +1, 0)")
_ImGui_CreateButton("btn_bump_M","Bump major (+1, 0, 0)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit",  "Quit")


; --- Script-side state -------------------------------------------------------
Global $g_iCommitCount = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnChange("in_ver",     "_OnVerChanged")
_ImGui_SetOnClick ("btn_v100",   "_OnV100")
_ImGui_SetOnClick ("btn_bump_p", "_OnBumpPatch")
_ImGui_SetOnClick ("btn_bump_m", "_OnBumpMinor")
_ImGui_SetOnClick ("btn_bump_M", "_OnBumpMajor")
_ImGui_SetOnClick ("btn_quit",   "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnVerChanged($sId)
    Local $aVal = _ImGui_GetValueIntN($sId, 3)
    If @error Or Not IsArray($aVal) Then Return
    $g_iCommitCount += 1
    _UpdateReadout($aVal[0], $aVal[1], $aVal[2], "")
    _ImGui_SetText("t_count", "User commits : " & $g_iCommitCount)
EndFunc

Func _OnV100($sId)
    _ApplyPreset(1, 0, 0, "initial release")
EndFunc

Func _OnBumpPatch($sId)
    Local $aVal = _ImGui_GetValueIntN("in_ver", 3)
    If @error Or Not IsArray($aVal) Then Return
    _ApplyPreset($aVal[0], $aVal[1], $aVal[2] + 1, "bumped patch")
EndFunc

Func _OnBumpMinor($sId)
    Local $aVal = _ImGui_GetValueIntN("in_ver", 3)
    If @error Or Not IsArray($aVal) Then Return
    _ApplyPreset($aVal[0], $aVal[1] + 1, 0, "bumped minor")
EndFunc

Func _OnBumpMajor($sId)
    Local $aVal = _ImGui_GetValueIntN("in_ver", 3)
    If @error Or Not IsArray($aVal) Then Return
    _ApplyPreset($aVal[0] + 1, 0, 0, "bumped major")
EndFunc

Func _ApplyPreset($iMajor, $iMinor, $iPatch, $sTag)
    Local $aNew[3] = [$iMajor, $iMinor, $iPatch]
    _ImGui_SetValueIntN("in_ver", $aNew)
    _UpdateReadout($iMajor, $iMinor, $iPatch, $sTag)
EndFunc

Func _UpdateReadout($iMajor, $iMinor, $iPatch, $sTag)
    Local $sSuffix = ($sTag = "") ? "" : (" (" & $sTag & ")")
    _ImGui_SetText("t_read", StringFormat("Read-back : major=%d, minor=%d, patch=%d%s", $iMajor, $iMinor, $iPatch, $sSuffix))
    _ImGui_SetText("t_ver",  StringFormat("Version string : v%d.%d.%d", $iMajor, $iMinor, $iPatch))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
