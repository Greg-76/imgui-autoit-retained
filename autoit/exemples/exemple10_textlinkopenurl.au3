#cs
================================================================================
 Example 10 : _ImGui_CreateTextLinkOpenURL
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateTextLinkOpenURL    Hyperlink-styled clickable that opens a URL

 Like _ImGui_CreateTextLink (exemple9) but ALSO launches the URL via the OS
 default browser on click (Windows ShellExecuteW). The click is still
 latched by OnClick so the script can react in addition to the launch.

 SECURITY : only http:// and https:// schemes are honored. file://,
 javascript:, mailto:, ftp:// and any custom protocol are silently
 ignored (the widget still latches the click). This protects scripts that
 build URLs from untrusted data -- a poisoned "file://C:/Windows/System32/cmd.exe"
 cannot trigger an arbitrary local executable.

 Click semantics (OnClick, ID uniqueness) : see exemple5_button.au3.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple10_textlinkopenurl.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple10_textlinkopenurl.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 10 : _ImGui_CreateTextLinkOpenURL", 600, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateTextLinkOpenURL  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateTextLinkOpenURL($sId, $sLabel, $sUrl)
;
;   Renders $sLabel as a hyperlink-styled span (same visual as
;   _ImGui_CreateTextLink). On click :
;     1. The click is latched -- OnClick / WasClicked sees it.
;     2. The widget calls ShellExecuteW on $sUrl IF the scheme is http(s).
;
;   Whitelisted schemes : http:// and https:// only.
;   Anything else (file://, javascript:, mailto:, ftp://, custom:) is
;   silently ignored on the launch side. The latched click is delivered
;   regardless -- the script's OnClick fires and can show its own warning.
;
;   $sLabel is what the user sees. $sUrl is what the OS receives.
;
;   Click semantics : see exemple5_button.au3.
;
;   Return : True on success, False on failure (@error = 1 not initialised,
;   2 DllCall failed).


; ==============================================================================
; Demo widgets  --  one allowed link, one allowed link, one refused link
; ==============================================================================
_ImGui_CreateText("t_title", "TextLinkOpenURL demo")
_ImGui_CreateText("t_hint1", "Click any of the three links below. The script reports what happened.")
_ImGui_CreateText("t_hint2", "Only http:// and https:// links actually open in the browser ; the")
_ImGui_CreateText("t_hint3", "file:// link silently fails its launch but the script still notices the click.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateTextLinkOpenURL("lnk_https", "https://github.com (allowed, https://)",       "https://github.com/Greg-76/imgui-autoit-retained")
_ImGui_CreateTextLinkOpenURL("lnk_http",  "http://example.com (allowed, http://)",       "http://example.com")
_ImGui_CreateTextLinkOpenURL("lnk_file",  "file:///C:/Windows (refused, file:// scheme)", "file:///C:/Windows")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_last", "Last click : (none yet)")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("lnk_https", "_OnLinkClicked")
_ImGui_SetOnClick("lnk_http",  "_OnLinkClicked")
_ImGui_SetOnClick("lnk_file",  "_OnLinkClicked")
_ImGui_SetOnClick("btn_quit",  "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------
Func _OnLinkClicked($sId)
    Switch $sId
        Case "lnk_https"
            _ImGui_SetText("t_last", "Last click : " & $sId & " (browser should open https://github.com)")
        Case "lnk_http"
            _ImGui_SetText("t_last", "Last click : " & $sId & " (browser should open http://example.com)")
        Case "lnk_file"
            _ImGui_SetText("t_last", "Last click : " & $sId & " (click latched, file:// scheme refused -- no launch)")
    EndSwitch
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
