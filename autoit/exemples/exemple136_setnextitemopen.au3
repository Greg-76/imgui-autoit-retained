#cs
================================================================================
 Example 136 : _ImGui_SetNextItemOpen
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_SetNextItemOpen   Queue a one-shot open / close on a TreeNode
                            or CollapsingHeader for the next render

 Applies to the same widget kinds introduced in exemples 134 / 135 :
 TreeNode and CollapsingHeader. On the next Render() ImGui consumes
 the pending state ; whether it overwrites the user's current toggle
 depends on $iCond :

   $ImGuiCond_None        = 0   functionally identical to Always
   $ImGuiCond_Always      = 1   overwrite every time the setter is called
   $ImGuiCond_Once        = 2   set ONCE, then yield to user toggles
   $ImGuiCond_FirstUseEver = 4  same as Once for fresh widgets
   $ImGuiCond_Appearing   = 8   set when the widget re-appears

 Three patterns demonstrated here, side by side :

   A) Cond_Always  --  buttons that force-open / force-close target A.
                       Single one-shot call, user toggles work in between.
   B) Cond_Once    --  button that seeds target B open ONCE. The second
                       click is a no-op (state already seeded) so the
                       user keeps control.
   C) Pin-open     --  a checkbox that calls Cond_Always EVERY tick (16
                       ms) while on. The user CANNOT collapse target A
                       as long as the pin is active.

 Borrowed widgets : TreeNode (exemple134), CollapsingHeader
 (exemple135), Button + Checkbox + Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple136_setnextitemopen.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple136_setnextitemopen.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 136 : _ImGui_SetNextItemOpen", 740, 600) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_SetNextItemOpen  --  doc block
; ==============================================================================
; Signature : _ImGui_SetNextItemOpen($sId, $bOpen, $iCond = 0)
;
;   Target $sId : MUST identify a TreeNode (exemple134) or
;                 CollapsingHeader (exemple135). Any other widget type
;                 returns @error = 3 with @extended carrying the DLL
;                 status (2 = unknown id, 3 = wrong widget kind).
;
;   $bOpen      : True to open, False to close.
;
;   $iCond      : bitmask of $ImGuiCond_*. Default 0 (= None) is
;                 functionally Always. Useful values :
;     1 = Always         overwrite each time
;     2 = Once           set once, then yield to user toggles
;     4 = FirstUseEver   first-time only (like Once for fresh widgets)
;     8 = Appearing      set when the widget appears
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded,
;            2=DllCall failed, 3=unknown id or wrong widget kind).


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "SetNextItemOpen demo  --  Cond_Always (one-shot), Cond_Once (seed), Pin (every tick)")
_ImGui_CreateText("t_hint",  "Toggle the targets freely. Then try the buttons and the Pin checkbox.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Target A  --  TreeNode driven by Always / Pin
; ==============================================================================
_ImGui_CreateTreeNode("tn_a", "Target A  --  TreeNode driven by Cond_Always + Pin")
_ImGui_CreateText("tn_a_t1", "  Body of target A.")
_ImGui_CreateText("tn_a_t2", "  Toggle freely except while the Pin checkbox is on.")
_ImGui_SetParent("tn_a_t1", "tn_a")
_ImGui_SetParent("tn_a_t2", "tn_a")


; ==============================================================================
; Target B  --  CollapsingHeader driven by Cond_Once
; ==============================================================================
_ImGui_CreateCollapsingHeader("ch_b", "Target B  --  CollapsingHeader driven by Cond_Once", False, 0)
_ImGui_CreateText("ch_b_t1", "  Body of target B. The 'Seed B open' button uses Cond_Once.")
_ImGui_CreateText("ch_b_t2", "  After the first seed call, ImGui keeps the user's current state on every subsequent call.")
_ImGui_SetParent("ch_b_t1", "ch_b")
_ImGui_SetParent("ch_b_t2", "ch_b")


; ==============================================================================
; Controls
; ==============================================================================
_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_a_hdr", "Target A controls (Cond_Always = overwrite every call) :")
_ImGui_CreateButton("btn_a_open",  "Force-open A   (Always, one-shot)")
_ImGui_CreateButton("btn_a_close", "Force-close A  (Always, one-shot)")
_ImGui_CreateCheckbox("cb_pin", "Pin A open  --  re-applies Cond_Always every 16 ms", False)

_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_b_hdr", "Target B controls (Cond_Once = seed initial state) :")
_ImGui_CreateButton("btn_b_seed", "Seed B open (Once)  --  click again : no-op once state is set")

_ImGui_CreateSeparator("sep3")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_a_open",  "_OnForceOpenA")
_ImGui_SetOnClick("btn_a_close", "_OnForceCloseA")
_ImGui_SetOnClick("btn_b_seed",  "_OnSeedBOpen")
_ImGui_SetOnClick("btn_quit",    "_OnQuit")
; The pin handler runs every 16 ms ; it only acts while the checkbox is on.
_ImGui_SetOnTick("_OnPinTick", 16)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnForceOpenA($sId)
    _ImGui_SetNextItemOpen("tn_a", True, $ImGuiCond_Always)
EndFunc

Func _OnForceCloseA($sId)
    _ImGui_SetNextItemOpen("tn_a", False, $ImGuiCond_Always)
EndFunc

Func _OnSeedBOpen($sId)
    ; Cond_Once : seeded the first time, then ImGui keeps the user's
    ; current state on every subsequent call. Click twice and the
    ; second click is a no-op (assuming you toggled in between).
    _ImGui_SetNextItemOpen("ch_b", True, $ImGuiCond_Once)
EndFunc

Func _OnPinTick()
    ; Re-apply force-open EVERY tick while the checkbox is on. The user
    ; cannot collapse tn_a as long as this fires -- they can click the
    ; arrow but the next render frame overwrites the toggle.
    If _ImGui_GetValueBool("cb_pin") Then
        _ImGui_SetNextItemOpen("tn_a", True, $ImGuiCond_Always)
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
