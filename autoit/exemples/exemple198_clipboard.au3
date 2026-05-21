#cs
================================================================================
 Example 198 : Clipboard  --  GetClipboardText + SetClipboardText
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_GetClipboardText   Read the ImGui clipboard
   _ImGui_SetClipboardText   Write the ImGui clipboard

 ImGui maintains its OWN clipboard handle, distinct from AutoIt's
 ClipGet / ClipPut. On Windows the two are typically backed by the
 SAME OS clipboard -- so a SetClipboardText from ImGui is visible
 to ClipGet and vice versa -- but routing through these exports
 lets scripts plug into ImGui's clipboard hooks (Ctrl+C / V on
 ImGui widgets) and keep the two ecosystems consistent.

 Buffer sizing for GetClipboardText :
   Default $iBufSize = 4096 wchars. For typical text snippets that's
   plenty ; for log dumps or document content, raise it. Same
   truncation-absorption quirk as SaveSettingsToMemory (exemple187)
   and GetStyleColorName (exemple192) : DLL status 4 ("truncated")
   is silently accepted -- the returned string is valid up to
   (capacity - 1) but missing late chars. Detect by comparing
   StringLen to (buffer - 1).

 SetClipboardText with empty string clears the clipboard.

 Demo layout :
   * InputTextMultiline #1 : "Outgoing" -- script-side text to write.
   * Button "Push to clipboard"   -> SetClipboardText.
   * InputTextMultiline #2 : "Incoming" -- last read from clipboard.
   * Button "Pull from clipboard" -> GetClipboardText.
   * SliderInt for $iBufSize (256..16384) + truncation observation.
   * Side panel : live AutoIt ClipGet readout (300 ms tick) to cross-
     check that the two ecosystems agree on Windows.

 Borrowed widgets : InputTextMultiline (exemple148), SliderInt
 (exemple17), Button, Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple198_clipboard.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple198_clipboard.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 198 : Clipboard", 820, 700) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 2-export cluster
; ==============================================================================
; _ImGui_GetClipboardText([$iBufSize = 4096])   -> String
; _ImGui_SetClipboardText($sText)                -> Bool
;
;   Get : returns the clipboard contents on success ; "" with @error
;         (1 DLL not loaded, 2 DllCall failed, 3 DLL status non-zero
;         AND non-truncation). Truncation (status 4) is silently
;         absorbed -- the returned data is valid up to (capacity - 1)
;         but missing late chars.
;
;   Set : True on success, False on failure (@error = 1, 2). Empty
;         string clears the clipboard.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "Clipboard demo  --  ImGui Get/SetClipboardText vs AutoIt ClipGet/ClipPut")
_ImGui_CreateText("t_hint",  "Push from box A, pull into box B ; the AutoIt ClipGet readout cross-checks the OS clipboard.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Section A  --  Outgoing  (script -> clipboard)
; ==============================================================================
_ImGui_CreateText("t_a_hdr", "Outgoing  --  text to push to the clipboard :")
_ImGui_CreateInputTextMultiline("in_out", "##out", _
    "Hello from ImGui." & @CRLF & "This text was pushed via _ImGui_SetClipboardText.", _
    4096, $ImGuiInputTextFlags_WordWrap, 760, 80)
_ImGui_CreateButton("btn_push",  "Push to clipboard (SetClipboardText)")
_ImGui_CreateButton("btn_clear", "Clear clipboard (SetClipboardText '')")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Section B  --  Incoming  (clipboard -> script)
; ==============================================================================
_ImGui_CreateText("t_b_hdr", "Incoming  --  last read from the clipboard :")
_ImGui_CreateSliderInt("sl_bufsize", "##bufsize", 256, 16384, 4096, "$iBufSize = %d wchars")
_ImGui_CreateButton("btn_pull", "Pull from clipboard (GetClipboardText)")
_ImGui_CreateInputTextMultiline("in_in", "##in", "(no read yet)", _
    16384, $ImGuiInputTextFlags_WordWrap, 760, 100)
_ImGui_CreateText("t_pull_info", "  Last pull : 0 chars  (buffer was 0, fit margin : --)")
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; AutoIt cross-check
; ==============================================================================
_ImGui_CreateText("t_xcheck_hdr", "AutoIt ClipGet() readout (refreshed at 300 ms) :")
_ImGui_CreateText("t_xcheck",     "  (sampling...)")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_status", "Status : ready.")
_ImGui_CreateSeparator("sep4")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_push",  "_OnPush")
_ImGui_SetOnClick("btn_clear", "_OnClear")
_ImGui_SetOnClick("btn_pull",  "_OnPull")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")
_ImGui_SetOnTick("_OnXcheckTick", 300)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPush($sId)
    Local $sOut = _ImGui_GetValueString("in_out", 8192)
    Local $bOk = _ImGui_SetClipboardText($sOut)
    If Not $bOk Then
        _ImGui_SetText("t_status", StringFormat("Status : SetClipboardText FAILED (@error = %d).", @error))
        Return
    EndIf
    _ImGui_SetText("t_status", StringFormat("Status : pushed %d chars to clipboard.", StringLen($sOut)))
EndFunc

Func _OnClear($sId)
    _ImGui_SetClipboardText("")
    _ImGui_SetText("t_status", "Status : clipboard cleared (SetClipboardText with empty string).")
EndFunc

Func _OnPull($sId)
    Local $iBuf = _ImGui_GetValueInt("sl_bufsize")
    Local $sIn  = _ImGui_GetClipboardText($iBuf)
    If @error Then
        _ImGui_SetText("t_status", StringFormat("Status : GetClipboardText FAILED (@error = %d, @extended = %d).", @error, @extended))
        Return
    EndIf
    _ImGui_SetValueString("in_in", $sIn)
    Local $iLen = StringLen($sIn)
    Local $sFit
    If $iLen >= ($iBuf - 1) Then
        $sFit = StringFormat("FULL / likely TRUNCATED -- raise buffer (currently %d).", $iBuf)
    Else
        $sFit = StringFormat("%d unused chars left.", $iBuf - $iLen)
    EndIf
    _ImGui_SetText("t_pull_info", StringFormat( _
        "  Last pull : %d chars  (buffer was %d, %s)", $iLen, $iBuf, $sFit))
    _ImGui_SetText("t_status", "Status : pulled " & $iLen & " chars.")
EndFunc

Func _OnXcheckTick()
    Local $sClip = ClipGet()
    Local $sShow
    If @error Then
        $sShow = "  (ClipGet returned @error = " & @error & ")"
    Else
        Local $iLen = StringLen($sClip)
        Local $sFirst = StringLeft($sClip, 80)
        $sFirst = StringReplace($sFirst, @CRLF, " | ")
        $sFirst = StringReplace($sFirst, @LF, " | ")
        Local $sTail = ""
        If $iLen > 80 Then $sTail = " ..."
        $sShow = StringFormat("  ClipGet (%d chars) : %s%s", $iLen, $sFirst, $sTail)
    EndIf
    _ImGui_SetText("t_xcheck", $sShow)
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
