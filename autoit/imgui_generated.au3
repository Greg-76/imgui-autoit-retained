#include-once

#Region clickable
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateButton
; Description ...: Create a Button widget (basic rectangular clickable)
; Syntax.........: _ImGui_CreateButton($sId[, $sLabel = ""])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Poll user clicks with _ImGui_WasClicked($sId).
; ===============================================================================================================================
Func _ImGui_CreateButton($sId, $sLabel = "")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateButton", "wstr", $sId, "wstr", $sLabel)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSmallButton
; Description ...: Create a SmallButton widget (compact, no frame padding)
; Syntax.........: _ImGui_CreateSmallButton($sId[, $sLabel = ""])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Poll user clicks with _ImGui_WasClicked($sId).
; ===============================================================================================================================
Func _ImGui_CreateSmallButton($sId, $sLabel = "")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSmallButton", "wstr", $sId, "wstr", $sLabel)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateArrowButton
; Description ...: Create an ArrowButton widget (directional arrow glyph)
; Syntax.........: _ImGui_CreateArrowButton($sId[, $sLabel = "", $iDir = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $iDir        - Arrow direction (0=Left, 1=Right, 2=Up, 3=Down)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Poll user clicks with _ImGui_WasClicked($sId).
; ===============================================================================================================================
Func _ImGui_CreateArrowButton($sId, $sLabel = "", $iDir = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateArrowButton", "wstr", $sId, "wstr", $sLabel, "int", $iDir)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateInvisibleButton
; Description ...: Create an InvisibleButton (clickable hit area, no rendering)
; Syntax.........: _ImGui_CreateInvisibleButton($sId[, $sLabel = "", $fW = 0.0, $fH = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fW          - Width in pixels (0 = auto)
;                  $fH          - Height in pixels (0 = auto)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Poll user clicks with _ImGui_WasClicked($sId).
; ===============================================================================================================================
Func _ImGui_CreateInvisibleButton($sId, $sLabel = "", $fW = 0.0, $fH = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInvisibleButton", "wstr", $sId, "wstr", $sLabel, "float", $fW, "float", $fH)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTextLink
; Description ...: Create a TextLink widget (clickable underlined text)
; Syntax.........: _ImGui_CreateTextLink($sId[, $sLabel = ""])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Poll user clicks with _ImGui_WasClicked($sId).
; ===============================================================================================================================
Func _ImGui_CreateTextLink($sId, $sLabel = "")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTextLink", "wstr", $sId, "wstr", $sLabel)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc
#EndRegion clickable

#Region value_bool
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateCheckbox
; Description ...: Create a Checkbox widget (toggleable boolean state)
; Syntax.........: _ImGui_CreateCheckbox($sId[, $sLabel = "", $bDefault = False])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $bDefault    - Initial boolean state (False = unchecked)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write the value via _ImGui_GetValueBool / _ImGui_SetValueBool.
;                  User toggles are reported by _ImGui_HasChanged ; programmatic writes never latch.
; ===============================================================================================================================
Func _ImGui_CreateCheckbox($sId, $sLabel = "", $bDefault = False)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $iDef = $bDefault ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateCheckbox", "wstr", $sId, "wstr", $sLabel, "int", $iDef)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc
#EndRegion value_bool

#Region value_numeric
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSliderFloat
; Description ...: Create a slider widget bound to a range (float value)
; Syntax.........: _ImGui_CreateSliderFloat($sId[, $sLabel = "", $fMin = 0.0, $fMax = 1.0, $fDefault = 0.0, $sFormat = "%.3f"])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fMin        - Minimum value of the range
;                  $fMax        - Maximum value of the range
;                  $fDefault    - Initial float value
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
; ===============================================================================================================================
Func _ImGui_CreateSliderFloat($sId, $sLabel = "", $fMin = 0.0, $fMax = 1.0, $fDefault = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSliderFloat", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fMin, "float", $fMax, "float", $fDefault, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSliderInt
; Description ...: Create a slider widget bound to a range (int value)
; Syntax.........: _ImGui_CreateSliderInt($sId[, $sLabel = "", $iMin = 0, $iMax = 100, $iDefault = 0, $sFormat = "%d"])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $iMin        - Minimum integer value
;                  $iMax        - Maximum integer value
;                  $iDefault    - Initial integer value
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
; ===============================================================================================================================
Func _ImGui_CreateSliderInt($sId, $sLabel = "", $iMin = 0, $iMax = 100, $iDefault = 0, $sFormat = "%d")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSliderInt", _
        "wstr", $sId, "wstr", $sLabel, _
        "int", $iMin, "int", $iMax, "int", $iDefault, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateDragFloat
; Description ...: Create a draggable numeric widget (float value)
; Syntax.........: _ImGui_CreateDragFloat($sId[, $sLabel = "", $fSpeed = 1.0, $fMin = 0.0, $fMax = 0.0, $fDefault = 0.0, $sFormat = "%.3f"])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fSpeed      - Drag speed (units per pixel of mouse movement)
;                  $fMin        - Minimum value of the range
;                  $fMax        - Maximum value of the range
;                  $fDefault    - Initial float value
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
; ===============================================================================================================================
Func _ImGui_CreateDragFloat($sId, $sLabel = "", $fSpeed = 1.0, $fMin = 0.0, $fMax = 0.0, $fDefault = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateDragFloat", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fSpeed, "float", $fMin, "float", $fMax, "float", $fDefault, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateDragInt
; Description ...: Create a draggable numeric widget (int value)
; Syntax.........: _ImGui_CreateDragInt($sId[, $sLabel = "", $fSpeed = 1.0, $iMin = 0, $iMax = 0, $iDefault = 0, $sFormat = "%d"])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fSpeed      - Drag speed (units per pixel of mouse movement)
;                  $iMin        - Minimum integer value
;                  $iMax        - Maximum integer value
;                  $iDefault    - Initial integer value
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
; ===============================================================================================================================
Func _ImGui_CreateDragInt($sId, $sLabel = "", $fSpeed = 1.0, $iMin = 0, $iMax = 0, $iDefault = 0, $sFormat = "%d")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateDragInt", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fSpeed, "int", $iMin, "int", $iMax, "int", $iDefault, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateInputFloat
; Description ...: Create a numeric input field with +/- buttons (float value)
; Syntax.........: _ImGui_CreateInputFloat($sId[, $sLabel = "", $fDefault = 0.0, $fStep = 0.0, $fStepFast = 0.0, $sFormat = "%.3f"])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fDefault    - Initial float value
;                  $fStep       - Step value applied by the +/- buttons
;                  $fStepFast   - Fast-step value applied with Ctrl+click
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
; ===============================================================================================================================
Func _ImGui_CreateInputFloat($sId, $sLabel = "", $fDefault = 0.0, $fStep = 0.0, $fStepFast = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInputFloat", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fDefault, "float", $fStep, "float", $fStepFast, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateInputInt
; Description ...: Create a numeric input field with +/- buttons (int value)
; Syntax.........: _ImGui_CreateInputInt($sId[, $sLabel = "", $iDefault = 0, $iStep = 1, $iStepFast = 100])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $iDefault    - Initial integer value
;                  $iStep       - Integer step value applied by the +/- buttons
;                  $iStepFast   - Fast integer step applied with Ctrl+click
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
; ===============================================================================================================================
Func _ImGui_CreateInputInt($sId, $sLabel = "", $iDefault = 0, $iStep = 1, $iStepFast = 100)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInputInt", _
        "wstr", $sId, "wstr", $sLabel, _
        "int", $iDefault, "int", $iStep, "int", $iStepFast)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSliderFloat2
; Description ...: Create a 2-component slider widget (float values)
; Syntax.........: _ImGui_CreateSliderFloat2($sId, $sLabel, ...) - 2 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fMin        - Range minimum (float)
;                  $fMax        - Range maximum (float)
;                  $fD0         - Initial value for component 0
;                  $fD1         - Initial value for component 1
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 2.
; ===============================================================================================================================
Func _ImGui_CreateSliderFloat2($sId, $sLabel = "", $fMin = 0.0, $fMax = 1.0, $fD0 = 0.0, $fD1 = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSliderFloat2", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fMin, "float", $fMax, _
        "float", $fD0, _
        "float", $fD1, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSliderFloat3
; Description ...: Create a 3-component slider widget (float values)
; Syntax.........: _ImGui_CreateSliderFloat3($sId, $sLabel, ...) - 3 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fMin        - Range minimum (float)
;                  $fMax        - Range maximum (float)
;                  $fD0         - Initial value for component 0
;                  $fD1         - Initial value for component 1
;                  $fD2         - Initial value for component 2
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 3.
; ===============================================================================================================================
Func _ImGui_CreateSliderFloat3($sId, $sLabel = "", $fMin = 0.0, $fMax = 1.0, $fD0 = 0.0, $fD1 = 0.0, $fD2 = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSliderFloat3", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fMin, "float", $fMax, _
        "float", $fD0, _
        "float", $fD1, _
        "float", $fD2, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSliderFloat4
; Description ...: Create a 4-component slider widget (float values)
; Syntax.........: _ImGui_CreateSliderFloat4($sId, $sLabel, ...) - 4 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fMin        - Range minimum (float)
;                  $fMax        - Range maximum (float)
;                  $fD0         - Initial value for component 0
;                  $fD1         - Initial value for component 1
;                  $fD2         - Initial value for component 2
;                  $fD3         - Initial value for component 3
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 4.
; ===============================================================================================================================
Func _ImGui_CreateSliderFloat4($sId, $sLabel = "", $fMin = 0.0, $fMax = 1.0, $fD0 = 0.0, $fD1 = 0.0, $fD2 = 0.0, $fD3 = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSliderFloat4", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fMin, "float", $fMax, _
        "float", $fD0, _
        "float", $fD1, _
        "float", $fD2, _
        "float", $fD3, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSliderInt2
; Description ...: Create a 2-component slider widget (int values)
; Syntax.........: _ImGui_CreateSliderInt2($sId, $sLabel, ...) - 2 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $iMin        - Range minimum (int)
;                  $iMax        - Range maximum (int)
;                  $iD0         - Initial value for component 0
;                  $iD1         - Initial value for component 1
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 2.
; ===============================================================================================================================
Func _ImGui_CreateSliderInt2($sId, $sLabel = "", $iMin = 0, $iMax = 100, $iD0 = 0, $iD1 = 0, $sFormat = "%d")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSliderInt2", _
        "wstr", $sId, "wstr", $sLabel, _
        "int", $iMin, "int", $iMax, _
        "int", $iD0, _
        "int", $iD1, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSliderInt3
; Description ...: Create a 3-component slider widget (int values)
; Syntax.........: _ImGui_CreateSliderInt3($sId, $sLabel, ...) - 3 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $iMin        - Range minimum (int)
;                  $iMax        - Range maximum (int)
;                  $iD0         - Initial value for component 0
;                  $iD1         - Initial value for component 1
;                  $iD2         - Initial value for component 2
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 3.
; ===============================================================================================================================
Func _ImGui_CreateSliderInt3($sId, $sLabel = "", $iMin = 0, $iMax = 100, $iD0 = 0, $iD1 = 0, $iD2 = 0, $sFormat = "%d")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSliderInt3", _
        "wstr", $sId, "wstr", $sLabel, _
        "int", $iMin, "int", $iMax, _
        "int", $iD0, _
        "int", $iD1, _
        "int", $iD2, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSliderInt4
; Description ...: Create a 4-component slider widget (int values)
; Syntax.........: _ImGui_CreateSliderInt4($sId, $sLabel, ...) - 4 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $iMin        - Range minimum (int)
;                  $iMax        - Range maximum (int)
;                  $iD0         - Initial value for component 0
;                  $iD1         - Initial value for component 1
;                  $iD2         - Initial value for component 2
;                  $iD3         - Initial value for component 3
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 4.
; ===============================================================================================================================
Func _ImGui_CreateSliderInt4($sId, $sLabel = "", $iMin = 0, $iMax = 100, $iD0 = 0, $iD1 = 0, $iD2 = 0, $iD3 = 0, $sFormat = "%d")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSliderInt4", _
        "wstr", $sId, "wstr", $sLabel, _
        "int", $iMin, "int", $iMax, _
        "int", $iD0, _
        "int", $iD1, _
        "int", $iD2, _
        "int", $iD3, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateDragFloat2
; Description ...: Create a 2-component draggable widget (float values)
; Syntax.........: _ImGui_CreateDragFloat2($sId, $sLabel, ...) - 2 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fSpeed      - Drag speed (units per pixel of mouse movement)
;                  $fMin        - Range minimum (float)
;                  $fMax        - Range maximum (float)
;                  $fD0         - Initial value for component 0
;                  $fD1         - Initial value for component 1
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 2.
; ===============================================================================================================================
Func _ImGui_CreateDragFloat2($sId, $sLabel = "", $fSpeed = 1.0, $fMin = 0.0, $fMax = 0.0, $fD0 = 0.0, $fD1 = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateDragFloat2", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fSpeed, "float", $fMin, "float", $fMax, _
        "float", $fD0, _
        "float", $fD1, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateDragFloat3
; Description ...: Create a 3-component draggable widget (float values)
; Syntax.........: _ImGui_CreateDragFloat3($sId, $sLabel, ...) - 3 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fSpeed      - Drag speed (units per pixel of mouse movement)
;                  $fMin        - Range minimum (float)
;                  $fMax        - Range maximum (float)
;                  $fD0         - Initial value for component 0
;                  $fD1         - Initial value for component 1
;                  $fD2         - Initial value for component 2
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 3.
; ===============================================================================================================================
Func _ImGui_CreateDragFloat3($sId, $sLabel = "", $fSpeed = 1.0, $fMin = 0.0, $fMax = 0.0, $fD0 = 0.0, $fD1 = 0.0, $fD2 = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateDragFloat3", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fSpeed, "float", $fMin, "float", $fMax, _
        "float", $fD0, _
        "float", $fD1, _
        "float", $fD2, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateDragFloat4
; Description ...: Create a 4-component draggable widget (float values)
; Syntax.........: _ImGui_CreateDragFloat4($sId, $sLabel, ...) - 4 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fSpeed      - Drag speed (units per pixel of mouse movement)
;                  $fMin        - Range minimum (float)
;                  $fMax        - Range maximum (float)
;                  $fD0         - Initial value for component 0
;                  $fD1         - Initial value for component 1
;                  $fD2         - Initial value for component 2
;                  $fD3         - Initial value for component 3
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 4.
; ===============================================================================================================================
Func _ImGui_CreateDragFloat4($sId, $sLabel = "", $fSpeed = 1.0, $fMin = 0.0, $fMax = 0.0, $fD0 = 0.0, $fD1 = 0.0, $fD2 = 0.0, $fD3 = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateDragFloat4", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fSpeed, "float", $fMin, "float", $fMax, _
        "float", $fD0, _
        "float", $fD1, _
        "float", $fD2, _
        "float", $fD3, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateDragInt2
; Description ...: Create a 2-component draggable widget (int values)
; Syntax.........: _ImGui_CreateDragInt2($sId, $sLabel, ...) - 2 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fSpeed      - Drag speed (units per pixel of mouse movement)
;                  $iMin        - Range minimum (int)
;                  $iMax        - Range maximum (int)
;                  $iD0         - Initial value for component 0
;                  $iD1         - Initial value for component 1
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 2.
; ===============================================================================================================================
Func _ImGui_CreateDragInt2($sId, $sLabel = "", $fSpeed = 1.0, $iMin = 0, $iMax = 0, $iD0 = 0, $iD1 = 0, $sFormat = "%d")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateDragInt2", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fSpeed, "int", $iMin, "int", $iMax, _
        "int", $iD0, _
        "int", $iD1, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateDragInt3
; Description ...: Create a 3-component draggable widget (int values)
; Syntax.........: _ImGui_CreateDragInt3($sId, $sLabel, ...) - 3 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fSpeed      - Drag speed (units per pixel of mouse movement)
;                  $iMin        - Range minimum (int)
;                  $iMax        - Range maximum (int)
;                  $iD0         - Initial value for component 0
;                  $iD1         - Initial value for component 1
;                  $iD2         - Initial value for component 2
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 3.
; ===============================================================================================================================
Func _ImGui_CreateDragInt3($sId, $sLabel = "", $fSpeed = 1.0, $iMin = 0, $iMax = 0, $iD0 = 0, $iD1 = 0, $iD2 = 0, $sFormat = "%d")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateDragInt3", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fSpeed, "int", $iMin, "int", $iMax, _
        "int", $iD0, _
        "int", $iD1, _
        "int", $iD2, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateDragInt4
; Description ...: Create a 4-component draggable widget (int values)
; Syntax.........: _ImGui_CreateDragInt4($sId, $sLabel, ...) - 4 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fSpeed      - Drag speed (units per pixel of mouse movement)
;                  $iMin        - Range minimum (int)
;                  $iMax        - Range maximum (int)
;                  $iD0         - Initial value for component 0
;                  $iD1         - Initial value for component 1
;                  $iD2         - Initial value for component 2
;                  $iD3         - Initial value for component 3
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 4.
; ===============================================================================================================================
Func _ImGui_CreateDragInt4($sId, $sLabel = "", $fSpeed = 1.0, $iMin = 0, $iMax = 0, $iD0 = 0, $iD1 = 0, $iD2 = 0, $iD3 = 0, $sFormat = "%d")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateDragInt4", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fSpeed, "int", $iMin, "int", $iMax, _
        "int", $iD0, _
        "int", $iD1, _
        "int", $iD2, _
        "int", $iD3, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateInputFloat2
; Description ...: Create a 2-component numeric input (float values)
; Syntax.........: _ImGui_CreateInputFloat2($sId, $sLabel, ...) - 2 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fD0         - Initial value for component 0
;                  $fD1         - Initial value for component 1
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 2.
; ===============================================================================================================================
Func _ImGui_CreateInputFloat2($sId, $sLabel = "", $fD0 = 0.0, $fD1 = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInputFloat2", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fD0, _
        "float", $fD1, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateInputFloat3
; Description ...: Create a 3-component numeric input (float values)
; Syntax.........: _ImGui_CreateInputFloat3($sId, $sLabel, ...) - 3 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fD0         - Initial value for component 0
;                  $fD1         - Initial value for component 1
;                  $fD2         - Initial value for component 2
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 3.
; ===============================================================================================================================
Func _ImGui_CreateInputFloat3($sId, $sLabel = "", $fD0 = 0.0, $fD1 = 0.0, $fD2 = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInputFloat3", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fD0, _
        "float", $fD1, _
        "float", $fD2, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateInputFloat4
; Description ...: Create a 4-component numeric input (float values)
; Syntax.........: _ImGui_CreateInputFloat4($sId, $sLabel, ...) - 4 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fD0         - Initial value for component 0
;                  $fD1         - Initial value for component 1
;                  $fD2         - Initial value for component 2
;                  $fD3         - Initial value for component 3
;                  $sFormat     - printf-style format string
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 4.
; ===============================================================================================================================
Func _ImGui_CreateInputFloat4($sId, $sLabel = "", $fD0 = 0.0, $fD1 = 0.0, $fD2 = 0.0, $fD3 = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInputFloat4", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fD0, _
        "float", $fD1, _
        "float", $fD2, _
        "float", $fD3, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateInputInt2
; Description ...: Create a 2-component numeric input (int values)
; Syntax.........: _ImGui_CreateInputInt2($sId, $sLabel, ...) - 2 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $iD0         - Initial value for component 0
;                  $iD1         - Initial value for component 1
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 2.
; ===============================================================================================================================
Func _ImGui_CreateInputInt2($sId, $sLabel = "", $iD0 = 0, $iD1 = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInputInt2", _
        "wstr", $sId, "wstr", $sLabel, _
        "int", $iD0, _
        "int", $iD1)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateInputInt3
; Description ...: Create a 3-component numeric input (int values)
; Syntax.........: _ImGui_CreateInputInt3($sId, $sLabel, ...) - 3 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $iD0         - Initial value for component 0
;                  $iD1         - Initial value for component 1
;                  $iD2         - Initial value for component 2
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 3.
; ===============================================================================================================================
Func _ImGui_CreateInputInt3($sId, $sLabel = "", $iD0 = 0, $iD1 = 0, $iD2 = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInputInt3", _
        "wstr", $sId, "wstr", $sLabel, _
        "int", $iD0, _
        "int", $iD1, _
        "int", $iD2)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateInputInt4
; Description ...: Create a 4-component numeric input (int values)
; Syntax.........: _ImGui_CreateInputInt4($sId, $sLabel, ...) - 4 components
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $iD0         - Initial value for component 0
;                  $iD1         - Initial value for component 1
;                  $iD2         - Initial value for component 2
;                  $iD3         - Initial value for component 3
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.
;                  User edits are reported by _ImGui_HasChanged ; programmatic writes never latch.
;                  Vector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size 4.
; ===============================================================================================================================
Func _ImGui_CreateInputInt4($sId, $sLabel = "", $iD0 = 0, $iD1 = 0, $iD2 = 0, $iD3 = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInputInt4", _
        "wstr", $sId, "wstr", $sLabel, _
        "int", $iD0, _
        "int", $iD1, _
        "int", $iD2, _
        "int", $iD3)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc
#EndRegion value_numeric

#Region display
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSeparator
; Description ...: Insert a horizontal separator line
; Syntax.........: _ImGui_CreateSeparator($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateSeparator($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSeparator", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateNewLine
; Description ...: Insert a vertical blank line (newline)
; Syntax.........: _ImGui_CreateNewLine($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateNewLine($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateNewLine", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSpacing
; Description ...: Insert a small vertical gap
; Syntax.........: _ImGui_CreateSpacing($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateSpacing($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSpacing", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateBullet
; Description ...: Render a bullet point at the cursor
; Syntax.........: _ImGui_CreateBullet($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateBullet($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateBullet", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSameLine
; Description ...: Keep the next widget on the same line
; Syntax.........: _ImGui_CreateSameLine($sId[, $fOffsetX = 0.0, $fSpacing = -1.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fOffsetX    - Horizontal offset in pixels (0 = use default spacing)
;                  $fSpacing    - Custom spacing in pixels (-1.0 = use default)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateSameLine($sId, $fOffsetX = 0.0, $fSpacing = -1.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSameLine", "wstr", $sId, "float", $fOffsetX, "float", $fSpacing)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateIndent
; Description ...: Move the cursor right by an indent width
; Syntax.........: _ImGui_CreateIndent($sId[, $fIndentW = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fIndentW    - Indent width in pixels (0 = use ImGui default)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateIndent($sId, $fIndentW = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateIndent", "wstr", $sId, "float", $fIndentW)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateUnindent
; Description ...: Move the cursor left by an indent width
; Syntax.........: _ImGui_CreateUnindent($sId[, $fIndentW = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fIndentW    - Indent width in pixels (0 = use ImGui default)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateUnindent($sId, $fIndentW = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateUnindent", "wstr", $sId, "float", $fIndentW)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateDummy
; Description ...: Reserve an invisible rectangular space
; Syntax.........: _ImGui_CreateDummy($sId[, $fW = 0.0, $fH = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fW          - Width in pixels (0 = auto)
;                  $fH          - Height in pixels (0 = auto)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateDummy($sId, $fW = 0.0, $fH = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateDummy", "wstr", $sId, "float", $fW, "float", $fH)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateAlignTextToFramePadding
; Description ...: Align the next Text with a framed widget
; Syntax.........: _ImGui_CreateAlignTextToFramePadding($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateAlignTextToFramePadding($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateAlignTextToFramePadding", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSetNextItemWidth
; Description ...: Override the width of the next item (one-shot)
; Syntax.........: _ImGui_CreateSetNextItemWidth($sId[, $fWidth = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fWidth      - Item width (negative = right-aligned, 0 = auto)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateSetNextItemWidth($sId, $fWidth = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSetNextItemWidth", "wstr", $sId, "float", $fWidth)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSetItemDefaultFocus
; Description ...: Mark the previous item as default-focused
; Syntax.........: _ImGui_CreateSetItemDefaultFocus($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateSetItemDefaultFocus($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSetItemDefaultFocus", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSetNextItemAllowOverlap
; Description ...: Allow the next item to be overlapped
; Syntax.........: _ImGui_CreateSetNextItemAllowOverlap($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateSetNextItemAllowOverlap($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSetNextItemAllowOverlap", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSetKeyboardFocusHere
; Description ...: Set keyboard focus on a following item
; Syntax.........: _ImGui_CreateSetKeyboardFocusHere($sId[, $iOffset = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iOffset     - Focus offset (0 = next item)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateSetKeyboardFocusHere($sId, $iOffset = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSetKeyboardFocusHere", "wstr", $sId, "int", $iOffset)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSetCursorPos
; Description ...: Set the cursor position (window-local)
; Syntax.........: _ImGui_CreateSetCursorPos($sId[, $fX = 0.0, $fY = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fX          - X coordinate in pixels
;                  $fY          - Y coordinate in pixels
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateSetCursorPos($sId, $fX = 0.0, $fY = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSetCursorPos", "wstr", $sId, "float", $fX, "float", $fY)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSetCursorPosX
; Description ...: Set the X component of the cursor (window-local)
; Syntax.........: _ImGui_CreateSetCursorPosX($sId[, $fX = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fX          - X coordinate in pixels
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateSetCursorPosX($sId, $fX = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSetCursorPosX", "wstr", $sId, "float", $fX)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSetCursorPosY
; Description ...: Set the Y component of the cursor (window-local)
; Syntax.........: _ImGui_CreateSetCursorPosY($sId[, $fY = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fY          - Y coordinate in pixels
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateSetCursorPosY($sId, $fY = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSetCursorPosY", "wstr", $sId, "float", $fY)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateLogButtons
; Description ...: Create a LogButtons layout marker
; Syntax.........: _ImGui_CreateLogButtons($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateLogButtons($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateLogButtons", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSetCursorScreenPos
; Description ...: Set the cursor position in screen-space
; Syntax.........: _ImGui_CreateSetCursorScreenPos($sId[, $fScreenX = 0.0, $fScreenY = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fScreenX    - X coordinate in screen-space pixels
;                  $fScreenY    - Y coordinate in screen-space pixels
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateSetCursorScreenPos($sId, $fScreenX = 0.0, $fScreenY = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSetCursorScreenPos", "wstr", $sId, "float", $fScreenX, "float", $fScreenY)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc
#EndRegion display

#Region config (style stack)
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePushStyleColor
; Description ...: Push a color override onto the style stack
; Syntax.........: _ImGui_CreatePushStyleColor($sId[, $iCol = 0, $fR = 1.0, $fG = 1.0, $fB = 1.0, $fA = 1.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iCol        - Style color enum index ($ImGuiCol_*)
;                  $fR          - Red component [0.0 - 1.0]
;                  $fG          - Green component [0.0 - 1.0]
;                  $fB          - Blue component [0.0 - 1.0]
;                  $fA          - Alpha component [0.0 - 1.0]
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePushStyleColor($sId, $iCol = 0, $fR = 1.0, $fG = 1.0, $fB = 1.0, $fA = 1.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePushStyleColor", "wstr", $sId, "int", $iCol, "float", $fR, "float", $fG, "float", $fB, "float", $fA)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePopStyleColor
; Description ...: Pop one or more color overrides from the style stack
; Syntax.........: _ImGui_CreatePopStyleColor($sId[, $iCount = 1])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iCount      - Number of stack entries to pop
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePopStyleColor($sId, $iCount = 1)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePopStyleColor", "wstr", $sId, "int", $iCount)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePushStyleVarFloat
; Description ...: Push a scalar style variable override
; Syntax.........: _ImGui_CreatePushStyleVarFloat($sId[, $iVar = 0, $fValue = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iVar        - Style variable enum index ($ImGuiStyleVar_*)
;                  $fValue      - Float value to push onto the style stack
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePushStyleVarFloat($sId, $iVar = 0, $fValue = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePushStyleVarFloat", "wstr", $sId, "int", $iVar, "float", $fValue)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePushStyleVarVec2
; Description ...: Push a Vec2 style variable override
; Syntax.........: _ImGui_CreatePushStyleVarVec2($sId[, $iVar = 0, $fX = 0.0, $fY = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iVar        - Style variable enum index ($ImGuiStyleVar_*)
;                  $fX          - X coordinate in pixels
;                  $fY          - Y coordinate in pixels
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePushStyleVarVec2($sId, $iVar = 0, $fX = 0.0, $fY = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePushStyleVarVec2", "wstr", $sId, "int", $iVar, "float", $fX, "float", $fY)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePopStyleVar
; Description ...: Pop one or more style variable overrides
; Syntax.........: _ImGui_CreatePopStyleVar($sId[, $iCount = 1])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iCount      - Number of stack entries to pop
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePopStyleVar($sId, $iCount = 1)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePopStyleVar", "wstr", $sId, "int", $iCount)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePushStyleVarX
; Description ...: Push only the X component of a Vec2 style variable
; Syntax.........: _ImGui_CreatePushStyleVarX($sId[, $iVar = 0, $fX = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iVar        - Style variable enum index ($ImGuiStyleVar_*)
;                  $fX          - X coordinate in pixels
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePushStyleVarX($sId, $iVar = 0, $fX = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePushStyleVarX", "wstr", $sId, "int", $iVar, "float", $fX)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePushStyleVarY
; Description ...: Push only the Y component of a Vec2 style variable
; Syntax.........: _ImGui_CreatePushStyleVarY($sId[, $iVar = 0, $fY = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iVar        - Style variable enum index ($ImGuiStyleVar_*)
;                  $fY          - Y coordinate in pixels
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePushStyleVarY($sId, $iVar = 0, $fY = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePushStyleVarY", "wstr", $sId, "int", $iVar, "float", $fY)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePushItemWidth
; Description ...: Push an item-width override onto the layout stack
; Syntax.........: _ImGui_CreatePushItemWidth($sId[, $fWidth = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fWidth      - Item width (negative = right-aligned, 0 = auto)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePushItemWidth($sId, $fWidth = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePushItemWidth", "wstr", $sId, "float", $fWidth)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePopItemWidth
; Description ...: Pop the last item-width override
; Syntax.........: _ImGui_CreatePopItemWidth($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePopItemWidth($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePopItemWidth", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePushTextWrapPos
; Description ...: Push a text-wrap position onto the stack
; Syntax.........: _ImGui_CreatePushTextWrapPos($sId[, $fWrapPos = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fWrapPos    - Wrap position in pixels (<0 = no wrap, 0 = window edge, >0 = local x)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePushTextWrapPos($sId, $fWrapPos = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePushTextWrapPos", "wstr", $sId, "float", $fWrapPos)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePopTextWrapPos
; Description ...: Pop the last text-wrap position
; Syntax.........: _ImGui_CreatePopTextWrapPos($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePopTextWrapPos($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePopTextWrapPos", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePushItemFlag
; Description ...: Push an item flag (enable/disable a behavior)
; Syntax.........: _ImGui_CreatePushItemFlag($sId[, $iOption = 0, $bEnabled = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iOption     - Item flag option ($ImGuiItemFlags_*)
;                  $bEnabled    - True = enable, False = disable
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePushItemFlag($sId, $iOption = 0, $bEnabled = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePushItemFlag", "wstr", $sId, "int", $iOption, "int", $bEnabled)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePopItemFlag
; Description ...: Pop the last pushed item flag
; Syntax.........: _ImGui_CreatePopItemFlag($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePopItemFlag($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePopItemFlag", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePushClipRect
; Description ...: Push a clipping rectangle onto the draw stack
; Syntax.........: _ImGui_CreatePushClipRect($sId[, $fMinX = 0.0, $fMinY = 0.0, $fMaxX = 0.0, $fMaxY = 0.0, $bIntersect = 1])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fMinX       - Minimum X coordinate (screen-space)
;                  $fMinY       - Minimum Y coordinate (screen-space)
;                  $fMaxX       - Maximum X coordinate (screen-space)
;                  $fMaxY       - Maximum Y coordinate (screen-space)
;                  $bIntersect  - True = intersect with current clip rect, False = replace
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePushClipRect($sId, $fMinX = 0.0, $fMinY = 0.0, $fMaxX = 0.0, $fMaxY = 0.0, $bIntersect = 1)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePushClipRect", "wstr", $sId, "float", $fMinX, "float", $fMinY, "float", $fMaxX, "float", $fMaxY, "int", $bIntersect)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePopClipRect
; Description ...: Pop the last clipping rectangle
; Syntax.........: _ImGui_CreatePopClipRect($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.
; ===============================================================================================================================
Func _ImGui_CreatePopClipRect($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePopClipRect", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc
#EndRegion config (style stack)

#Region container
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTabBar
; Description ...: Create a TabBar container (holds TabItem children)
; Syntax.........: _ImGui_CreateTabBar($sId[, $sLabel = "", $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $iFlags      - Bitmask of widget-specific flags ($ImGuiXxxFlags_*)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Attach children with _ImGui_SetParent($sChildId, $sId).
; ===============================================================================================================================
Func _ImGui_CreateTabBar($sId, $sLabel = "", $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTabBar", "wstr", $sId, "wstr", $sLabel, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateGroup
; Description ...: Create a Group container (treats children as a single item)
; Syntax.........: _ImGui_CreateGroup($sId[, $sLabel = ""])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Attach children with _ImGui_SetParent($sChildId, $sId).
; ===============================================================================================================================
Func _ImGui_CreateGroup($sId, $sLabel = "")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateGroup", "wstr", $sId, "wstr", $sLabel)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateMenuBar
; Description ...: Create a MenuBar container (must be inside a Window)
; Syntax.........: _ImGui_CreateMenuBar($sId[, $sLabel = ""])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Attach children with _ImGui_SetParent($sChildId, $sId).
; ===============================================================================================================================
Func _ImGui_CreateMenuBar($sId, $sLabel = "")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateMenuBar", "wstr", $sId, "wstr", $sLabel)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateMainMenuBar
; Description ...: Create the main viewport menu bar (top of the screen)
; Syntax.........: _ImGui_CreateMainMenuBar($sId[, $sLabel = ""])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Attach children with _ImGui_SetParent($sChildId, $sId).
; ===============================================================================================================================
Func _ImGui_CreateMainMenuBar($sId, $sLabel = "")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateMainMenuBar", "wstr", $sId, "wstr", $sLabel)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateMenu
; Description ...: Create a Menu (drop-down within a MenuBar)
; Syntax.........: _ImGui_CreateMenu($sId[, $sLabel = ""])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Attach children with _ImGui_SetParent($sChildId, $sId).
; ===============================================================================================================================
Func _ImGui_CreateMenu($sId, $sLabel = "")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateMenu", "wstr", $sId, "wstr", $sLabel)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc
#EndRegion container

#Region text
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTextColored
; Description ...: Create a colored Text widget (RGBA tint)
; Syntax.........: _ImGui_CreateTextColored($sId, $sText[, $fR = 1.0, $fG = 1.0, $fB = 1.0, $fA = 1.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sText       - Text content (UTF-8)
;                  $fR          - Red component [0.0 - 1.0]
;                  $fG          - Green component [0.0 - 1.0]
;                  $fB          - Blue component [0.0 - 1.0]
;                  $fA          - Alpha component [0.0 - 1.0]
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Update the text content later via _ImGui_SetText.
; ===============================================================================================================================
Func _ImGui_CreateTextColored($sId, $sText, $fR = 1.0, $fG = 1.0, $fB = 1.0, $fA = 1.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTextColored", _
        "wstr", $sId, "wstr", $sText, _
        "float", $fR, "float", $fG, "float", $fB, "float", $fA)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTextWrapped
; Description ...: Create a Text widget that wraps at the available width
; Syntax.........: _ImGui_CreateTextWrapped($sId, $sText)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sText       - Text content (UTF-8)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Update the text content later via _ImGui_SetText.
; ===============================================================================================================================
Func _ImGui_CreateTextWrapped($sId, $sText)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTextWrapped", _
        "wstr", $sId, "wstr", $sText)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTextDisabled
; Description ...: Create a Text widget rendered with disabled style
; Syntax.........: _ImGui_CreateTextDisabled($sId, $sText)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sText       - Text content (UTF-8)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Update the text content later via _ImGui_SetText.
; ===============================================================================================================================
Func _ImGui_CreateTextDisabled($sId, $sText)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTextDisabled", _
        "wstr", $sId, "wstr", $sText)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateBulletText
; Description ...: Create a bulleted Text widget
; Syntax.........: _ImGui_CreateBulletText($sId, $sText)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sText       - Text content (UTF-8)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Update the text content later via _ImGui_SetText.
; ===============================================================================================================================
Func _ImGui_CreateBulletText($sId, $sText)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateBulletText", _
        "wstr", $sId, "wstr", $sText)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSeparatorText
; Description ...: Create a separator line with embedded text
; Syntax.........: _ImGui_CreateSeparatorText($sId, $sText)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sText       - Text content (UTF-8)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Update the text content later via _ImGui_SetText.
; ===============================================================================================================================
Func _ImGui_CreateSeparatorText($sId, $sText)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSeparatorText", _
        "wstr", $sId, "wstr", $sText)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateLabelText
; Description ...: Create a key/value Text widget (value left, key right)
; Syntax.........: _ImGui_CreateLabelText($sId, $sValue[, $sKey = ""])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sValue      - Displayed value (formatted on the right)
;                  $sKey        - Displayed key/label (left side)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Update the value later via _ImGui_SetText($sId, $sNewValue).
; ===============================================================================================================================
Func _ImGui_CreateLabelText($sId, $sValue, $sKey = "")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateLabelText", _
        "wstr", $sId, "wstr", $sValue, "wstr", $sKey)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc
#EndRegion text

#Region color
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateColorEdit3
; Description ...: Create a ColorEdit3 widget (RGB color edit field)
; Syntax.........: _ImGui_CreateColorEdit3($sId[, $sLabel = "", $fR = 1.0, $fG = 1.0, $fB = 1.0, $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fR          - Red component [0.0 - 1.0]
;                  $fG          - Green component [0.0 - 1.0]
;                  $fB          - Blue component [0.0 - 1.0]
;                  $iFlags      - Bitmask of widget-specific flags ($ImGuiXxxFlags_*)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Read/write the 3-component value with _ImGui_GetValueFloatN/_ImGui_SetValueFloatN.
; ===============================================================================================================================
Func _ImGui_CreateColorEdit3($sId, $sLabel = "", $fR = 1.0, $fG = 1.0, $fB = 1.0, $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateColorEdit3", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fR, _
        "float", $fG, _
        "float", $fB, _
        "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateColorEdit4
; Description ...: Create a ColorEdit4 widget (RGBA color edit field)
; Syntax.........: _ImGui_CreateColorEdit4($sId[, $sLabel = "", $fR = 1.0, $fG = 1.0, $fB = 1.0, $fA = 1.0, $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fR          - Red component [0.0 - 1.0]
;                  $fG          - Green component [0.0 - 1.0]
;                  $fB          - Blue component [0.0 - 1.0]
;                  $fA          - Alpha component [0.0 - 1.0]
;                  $iFlags      - Bitmask of widget-specific flags ($ImGuiXxxFlags_*)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Read/write the 4-component value with _ImGui_GetValueFloatN/_ImGui_SetValueFloatN.
; ===============================================================================================================================
Func _ImGui_CreateColorEdit4($sId, $sLabel = "", $fR = 1.0, $fG = 1.0, $fB = 1.0, $fA = 1.0, $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateColorEdit4", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fR, _
        "float", $fG, _
        "float", $fB, _
        "float", $fA, _
        "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateColorPicker3
; Description ...: Create a ColorPicker3 widget (RGB color picker)
; Syntax.........: _ImGui_CreateColorPicker3($sId[, $sLabel = "", $fR = 1.0, $fG = 1.0, $fB = 1.0, $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fR          - Red component [0.0 - 1.0]
;                  $fG          - Green component [0.0 - 1.0]
;                  $fB          - Blue component [0.0 - 1.0]
;                  $iFlags      - Bitmask of widget-specific flags ($ImGuiXxxFlags_*)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Read/write the 3-component value with _ImGui_GetValueFloatN/_ImGui_SetValueFloatN.
; ===============================================================================================================================
Func _ImGui_CreateColorPicker3($sId, $sLabel = "", $fR = 1.0, $fG = 1.0, $fB = 1.0, $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateColorPicker3", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fR, _
        "float", $fG, _
        "float", $fB, _
        "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateColorPicker4
; Description ...: Create a ColorPicker4 widget (RGBA color picker)
; Syntax.........: _ImGui_CreateColorPicker4($sId[, $sLabel = "", $fR = 1.0, $fG = 1.0, $fB = 1.0, $fA = 1.0, $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $fR          - Red component [0.0 - 1.0]
;                  $fG          - Green component [0.0 - 1.0]
;                  $fB          - Blue component [0.0 - 1.0]
;                  $fA          - Alpha component [0.0 - 1.0]
;                  $iFlags      - Bitmask of widget-specific flags ($ImGuiXxxFlags_*)
; Return values .: Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)
; Information ...: Read/write the 4-component value with _ImGui_GetValueFloatN/_ImGui_SetValueFloatN.
; ===============================================================================================================================
Func _ImGui_CreateColorPicker4($sId, $sLabel = "", $fR = 1.0, $fG = 1.0, $fB = 1.0, $fA = 1.0, $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateColorPicker4", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fR, _
        "float", $fG, _
        "float", $fB, _
        "float", $fA, _
        "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc
#EndRegion color
