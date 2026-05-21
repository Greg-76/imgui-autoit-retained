#cs
================================================================================
 Example 52 : _ImGui_CreateLabelText
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateLabelText   Two-column key/value text widget

 LabelText draws two strings on one row : the VALUE on the left in the
 normal text style, and the KEY (a label, like a field name) on the
 right in a slightly muted style. This is the canonical "read-only
 field" widget : think the right-hand side of a key/value table, or
 the static rows of a settings dialog.

 PITFALL : the wrapper's parameter order is ($sId, $sValue, $sKey)
 -- value comes FIRST, key second. This matches the underlying
 ImGui::LabelText(label, fmt) where the format string is the VALUE.
 Reading the wrapper signature top-to-bottom is unintuitive -- annotate
 the call site if it matters.

 _ImGui_SetText($sId, $sNewValue) updates ONLY the value half. There is
 no separate setter for the key.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple52_labeltext.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple52_labeltext.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 52 : _ImGui_CreateLabelText", 600, 380) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateLabelText  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateLabelText($sId, $sValue, $sKey = "")
;
;   Two strings on a single row :
;     - $sValue : the LEFT side, rendered in normal text style.
;                 Update at runtime with _ImGui_SetText($sId, $sNewValue).
;     - $sKey   : the RIGHT side, the "label", muted style. Locked at
;                 creation time -- no runtime setter in the wrapper.
;
;   Convention reminder : value left, key right -- this looks reversed
;   compared to most key/value layouts. Pick one and document it at the
;   call site.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  fake system info table
; ==============================================================================
_ImGui_CreateText("t_title", "LabelText demo  --  key/value rows (value left, key right)")
_ImGui_CreateText("t_hint",  "Bottom row is mutated by the buttons via SetText (value only ; key cannot change).")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_sysinfo_hdr", "Fake system info :")

; Each call : ($sId, $sValue, $sKey)
_ImGui_CreateLabelText("lt_arch",   (@AutoItX64 ? "x64" : "x86"), "Interpreter architecture")
_ImGui_CreateLabelText("lt_os",     "Windows 10",                 "Operating system")
_ImGui_CreateLabelText("lt_cores",  "8",                          "CPU cores")
_ImGui_CreateLabelText("lt_ram",    "16 GB",                      "Total RAM")
_ImGui_CreateLabelText("lt_uptime", "0d 00h 00m 00s",             "Uptime")

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_dyn_hdr", "Mutate the uptime VALUE (the KEY stays ""Uptime"") :")
_ImGui_CreateButton("btn_u1", "5 minutes")
_ImGui_CreateButton("btn_u2", "2 hours 15 min")
_ImGui_CreateButton("btn_u3", "3 days 4 h")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit","Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_u1",   "_OnU1")
_ImGui_SetOnClick("btn_u2",   "_OnU2")
_ImGui_SetOnClick("btn_u3",   "_OnU3")
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnU1($sId)
    _ImGui_SetText("lt_uptime", "0d 00h 05m 00s")
EndFunc

Func _OnU2($sId)
    _ImGui_SetText("lt_uptime", "0d 02h 15m 00s")
EndFunc

Func _OnU3($sId)
    _ImGui_SetText("lt_uptime", "3d 04h 00m 00s")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
