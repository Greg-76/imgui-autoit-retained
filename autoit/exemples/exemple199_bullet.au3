#cs
================================================================================
 Example 199 : _ImGui_CreateBullet
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateBullet   Render a bullet glyph (no accompanying text)

 The minimalist sibling of _ImGui_CreateBulletText (exemple51) :

   * CreateBulletText : bullet glyph + text in one widget. The text
                        is part of the same item.
   * CreateBullet     : bullet glyph alone. Pair it with a separate
                        Text widget on the SAME line (via SameLine
                        or just by virtue of ImGui's normal flow --
                        the bullet does NOT terminate the line on
                        its own) to compose custom prefixed entries.

 Why use the standalone variant ? When the trailing content is not
 a plain string but a richer cluster -- a TextColored, a TextLink,
 a Button, a small InputText, etc. CreateBulletText only accepts
 a string ; CreateBullet + SameLine + <anything> handles the rest.

 Demo layout :
   Section A  -- CreateBulletText baselines (for comparison).
   Section B  -- CreateBullet + SameLine + Text (the canonical
                 hand-rolled "bullet text" pattern).
   Section C  -- CreateBullet + SameLine + richer widgets
                 (TextColored, TextLink, Button, small InputText).
   Section D  -- Three CreateBullet on the same line via SameLine
                 (atypical but legal -- shows the glyph stacks left).

 Borrowed widgets : SameLine (exemple66), Text (exemple47),
 TextColored (exemple48), TextLink (exemple9), Button (exemple5),
 InputText (exemple147), BulletText (exemple51), Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple199_bullet.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple199_bullet.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 199 : CreateBullet", 760, 600) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateBullet  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateBullet($sId)
;
;   $sId : stable widget identifier.
;
;   Return : True on success, False on failure (@error = 1, 2).
;
;   No text, no flags, no events. Pure layout glyph that consumes
;   the same vertical space as a bullet-prefixed line. Combine with
;   SameLine + any sibling widget for the trailing content.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateBullet demo  --  standalone bullet glyph (no text)")
_ImGui_CreateText("t_hint",  "Pair Bullet + SameLine + <anything> when the trailing content is not a plain string.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Section A  --  baselines : CreateBulletText for comparison
; ==============================================================================
_ImGui_CreateText("t_a_hdr", "Section A  --  baselines using CreateBulletText (text built-in) :")
_ImGui_CreateBulletText("bt1", "Bullet + plain text  --  the simple case")
_ImGui_CreateBulletText("bt2", "Bullet + plain text  --  second line")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Section B  --  CreateBullet + SameLine + Text  (canonical pair)
; ==============================================================================
_ImGui_CreateText("t_b_hdr", "Section B  --  CreateBullet + SameLine + Text (hand-rolled bullet text) :")
_ImGui_CreateBullet("bu_b1")
_ImGui_CreateSameLine("sl_b1")
_ImGui_CreateText("t_b1", "Equivalent to BulletText, but built from primitives")

_ImGui_CreateBullet("bu_b2")
_ImGui_CreateSameLine("sl_b2")
_ImGui_CreateText("t_b2", "Useful when SetText updates need to mutate the trailing string at runtime")
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Section C  --  CreateBullet + SameLine + richer widget per line
; ==============================================================================
_ImGui_CreateText("t_c_hdr", "Section C  --  CreateBullet paired with non-Text widgets :")

_ImGui_CreateBullet("bu_c1")
_ImGui_CreateSameLine("sl_c1")
_ImGui_CreateTextColored("tc_c1", "Bullet + TextColored", 0.4, 1.0, 0.4, 1.0)

_ImGui_CreateBullet("bu_c2")
_ImGui_CreateSameLine("sl_c2")
_ImGui_CreateTextLink("tl_c2", "Bullet + TextLink (click me to see WasClicked)")

_ImGui_CreateBullet("bu_c3")
_ImGui_CreateSameLine("sl_c3")
_ImGui_CreateButton("btn_c3", "Bullet + Button")

_ImGui_CreateBullet("bu_c4")
_ImGui_CreateSameLine("sl_c4")
_ImGui_CreateInputText("in_c4", "Bullet + InputText", "edit me", 128)
_ImGui_CreateSeparator("sep3")


; ==============================================================================
; Section D  --  three Bullets on the same line (atypical but legal)
; ==============================================================================
_ImGui_CreateText("t_d_hdr", "Section D  --  three Bullet glyphs stacked horizontally via SameLine :")
_ImGui_CreateBullet("bu_d1")
_ImGui_CreateSameLine("sl_d1")
_ImGui_CreateBullet("bu_d2")
_ImGui_CreateSameLine("sl_d2")
_ImGui_CreateBullet("bu_d3")
_ImGui_CreateSameLine("sl_d3")
_ImGui_CreateText("t_d_note", "(three bullets used as visual decoration)")
_ImGui_CreateSeparator("sep4")


; ==============================================================================
; Status (for the TextLink + Button counters)
; ==============================================================================
_ImGui_CreateText("t_status", "Status : ready  --  link clicks: 0   button clicks: 0")
_ImGui_CreateSeparator("sep5")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Globals -----------------------------------------------------------------
Global $g_iLinkClicks   = 0
Global $g_iButtonClicks = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("tl_c2",    "_OnLink")
_ImGui_SetOnClick("btn_c3",   "_OnButton")
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnLink($sId)
    $g_iLinkClicks += 1
    _RefreshStatus()
EndFunc

Func _OnButton($sId)
    $g_iButtonClicks += 1
    _RefreshStatus()
EndFunc

Func _RefreshStatus()
    _ImGui_SetText("t_status", StringFormat( _
        "Status : ready  --  link clicks: %d   button clicks: %d", _
        $g_iLinkClicks, $g_iButtonClicks))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
