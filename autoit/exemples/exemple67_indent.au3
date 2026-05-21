#cs
================================================================================
 Example 67 : _ImGui_CreateIndent
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateIndent   Push the cursor right by an indent width

 Indent advances the left margin for ALL subsequent widgets in the
 current window / group until a matching Unindent is added to the
 tree. Use it to build nested list layouts (TreeNode-like indent
 without the disclosure triangles), or to visually group widgets
 under a header.

 Indent and Unindent MUST be balanced. An extra Indent without
 matching Unindent leaves every later widget shifted right ; an extra
 Unindent shifts later widgets left (possibly past the window edge).
 See [exemple68_unindent.au3](exemple68_unindent.au3).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple67_indent.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple67_indent.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 67 : _ImGui_CreateIndent", 600, 520) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateIndent  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateIndent($sId, $fIndentW = 0.0)
;
;   $fIndentW : indent amount in pixels. 0 = ImGui's default
;               IndentSpacing from the active style (~21 px by default
;               with the dark theme).
;
;   Indents stack. Two Indents at the same level produce twice the
;   horizontal shift. Each Indent should be balanced by an Unindent
;   later in the tree (exemple68 explains the pairing rule).
;
;   Return : True on success, False on failure
;     @error = 1 (DLL not loaded), 2 (DllCall failed)


; ==============================================================================
; Demo widgets  --  nested list at three depths (default width)
;                  + a custom-width indent variant
; ==============================================================================
_ImGui_CreateText("t_title", "Indent demo  --  nested layout via repeated Indent + matching Unindent")
_ImGui_CreateText("t_hint",  "The labels below sit at 0, 1, 2, and 3 levels of indent from the left edge.")
_ImGui_CreateSeparator("sep_intro")

; --- (A) Default indent width -- three levels --------------------------------
_ImGui_CreateText("a_hdr", "(A) Default IndentSpacing (~21 px) :")

_ImGui_CreateText("a_l0",  "Level 0 -- root")
_ImGui_CreateIndent("ind_a1")
_ImGui_CreateText("a_l1a", "Level 1 -- child A")
_ImGui_CreateText("a_l1b", "Level 1 -- child B")
_ImGui_CreateIndent("ind_a2")
_ImGui_CreateText("a_l2a", "Level 2 -- grandchild")
_ImGui_CreateIndent("ind_a3")
_ImGui_CreateText("a_l3",  "Level 3 -- great-grandchild")
_ImGui_CreateUnindent("uni_a3")
_ImGui_CreateText("a_l2b", "Level 2 -- back at grandchild depth")
_ImGui_CreateUnindent("uni_a2")
_ImGui_CreateText("a_l1c", "Level 1 -- back at child depth")
_ImGui_CreateUnindent("uni_a1")
_ImGui_CreateText("a_l0b", "Level 0 -- back at root, fully unindented")

_ImGui_CreateSeparator("sep_a")

; --- (B) Custom indent width = 60 px -- two levels ---------------------------
_ImGui_CreateText("b_hdr", "(B) Custom indent width = 60 px (almost three times default) :")

_ImGui_CreateText("b_l0", "Level 0 -- root")
_ImGui_CreateIndent("ind_b1", 60.0)
_ImGui_CreateText("b_l1", "Level 1 -- at +60 px")
_ImGui_CreateIndent("ind_b2", 60.0)
_ImGui_CreateText("b_l2", "Level 2 -- at +120 px")
_ImGui_CreateUnindent("uni_b2", 60.0)
_ImGui_CreateText("b_l1b","Level 1 -- back at +60 px")
_ImGui_CreateUnindent("uni_b1", 60.0)
_ImGui_CreateText("b_l0b","Level 0 -- back at root")

_ImGui_CreateSeparator("sep_b")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
