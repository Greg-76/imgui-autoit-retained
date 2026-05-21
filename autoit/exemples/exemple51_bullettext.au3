#cs
================================================================================
 Example 51 : _ImGui_CreateBulletText
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateBulletText   Text label prefixed with a bullet point

 BulletText is a plain Text widget with a leading bullet glyph (dot
 plus indent) drawn before the string. Use it for : feature lists,
 enumerated hints, "what's new" summaries. Indentation is constant per
 widget -- there is no nesting / indent-level argument. For nested
 lists, use _ImGui_PushIndent / _ImGui_PopIndent around a BulletText
 (covered in the Layout family).

 Update content via _ImGui_SetText -- the bullet stays.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple51_bullettext.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple51_bullettext.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 51 : _ImGui_CreateBulletText", 600, 400) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateBulletText  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateBulletText($sId, $sText)
;
;   Plain Text with a leading bullet glyph. The bullet is drawn by ImGui
;   and is not part of $sText. Subsequent SetText calls do NOT remove
;   the bullet -- it stays for the life of the widget.
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  feature list with one mutable bullet at the bottom
; ==============================================================================
_ImGui_CreateText("t_title", "BulletText demo  --  bullet-prefixed labels")
_ImGui_CreateText("t_hint",  "Static list above ; the last bullet is mutated via SetText.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_feat_hdr", "What's new in this build :")
_ImGui_CreateBulletText("b_1", "Numeric vector widgets (Slider/Drag/Input * 2/3/4)")
_ImGui_CreateBulletText("b_2", "ProgressBar with _ImGui_SetOnTick animation")
_ImGui_CreateBulletText("b_3", "Reliable double-click detection via WasDoubleClicked")
_ImGui_CreateBulletText("b_4", "Strict OnChange / OnClick semantics across the wrapper")
_ImGui_CreateBulletText("b_5", "Per-component clamp pattern for vector widgets")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_dyn_hdr", "Dynamic bullet (replace its text via SetText) :")
_ImGui_CreateBulletText("b_dyn", "Click a button below to replace this line.")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateButton("btn_t1", "Set bullet to ""Build 1.2.3 published""")
_ImGui_CreateButton("btn_t2", "Set bullet to ""All tests passing on x86 and x64""")
_ImGui_CreateButton("btn_t3", "Set bullet to a very long line of text that probably exceeds the window width and ends up clipped or overflowing")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateButton("btn_quit","Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_t1",  "_OnT1")
_ImGui_SetOnClick("btn_t2",  "_OnT2")
_ImGui_SetOnClick("btn_t3",  "_OnT3")
_ImGui_SetOnClick("btn_quit","_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnT1($sId)
    _ImGui_SetText("b_dyn", "Build 1.2.3 published")
EndFunc

Func _OnT2($sId)
    _ImGui_SetText("b_dyn", "All tests passing on x86 and x64")
EndFunc

Func _OnT3($sId)
    _ImGui_SetText("b_dyn", "A very long line of text that probably exceeds the window width and ends up clipped or overflowing")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
