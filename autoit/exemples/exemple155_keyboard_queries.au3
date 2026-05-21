#cs
================================================================================
 Example 155 : Keyboard queries (5-export cluster)
================================================================================
 Covers 5 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_IsKeyDown            persistent : key currently held ?
   _ImGui_IsKeyPressed         edge-frame : key just pressed ?
                               ($bRepeat default True = repeats fire
                                at io.KeyRepeatDelay / Rate)
   _ImGui_IsKeyReleased        edge-frame : key just released ?
   _ImGui_GetKeyPressedAmount  count of press events this frame at
                               given delay / rate (>= 1 on key down,
                               more on long press depending on rate)
   _ImGui_GetKeyName           "A", "Space", "F1", ... for any key code

 Cluster bundling : the five exports are inseparable for a working
 demo -- you need a key code, the name for display, plus the family
 of "down / pressed / released / amount" queries that drive UX
 reactions to a key.

 ImGui-side queries vs AutoIt _IsPressed :
   * IsKey* only return True while OUR window has focus AND the key
     is not consumed by a widget (e.g. an active InputText eats most
     keystrokes).
   * For a hotkey that fires globally (regardless of focus), use
     AutoIt's HotKeySet() instead.

 EDGE-FRAME : IsKeyPressed (when $bRepeat=False) and IsKeyReleased
 are True for ONE frame. Poll at 16 ms here. The default
 $bRepeat=True for IsKeyPressed makes it ALSO fire at the OS repeat
 rate while held -- still edge-frame per repeat event.

 Demo : the four WASD keys side by side, plus the canonical
 GetKeyName lookup.

 Borrowed widgets : Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple155_keyboard_queries.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple155_keyboard_queries.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 155 : Keyboard queries (W/A/S/D)", 760, 580) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 5-export cluster
; ==============================================================================
; All take an $iKey parameter (or no arg for GetKeyName, which itself
; takes the key code).
;
;   IsKeyDown($iKey)                         -> True while held
;   IsKeyPressed($iKey, $bRepeat = True)     -> True on press edge
;                                                + repeats while held
;                                                if $bRepeat
;   IsKeyReleased($iKey)                     -> True on release edge
;   GetKeyPressedAmount($iKey, $fDelay, $fRate)
;                                            -> int >= 0 ; press
;                                                events fired this
;                                                frame at the given
;                                                ($fDelay, $fRate)
;   GetKeyName($iKey, $iBufSize = 32)        -> e.g. "A", "Space", "F1"


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "Keyboard queries  --  WASD demo, all 5 exports polled at 16 ms")
_ImGui_CreateText("t_hint",  "Click anywhere in the empty area to give the host window focus, then hold WASD keys.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Per-key status block (4 keys ; 5 lines each + a section header)
; ==============================================================================
_ImGui_CreateText("t_w_hdr",  "W  (forward)  --  GetKeyName : 'W'")
_ImGui_CreateText("t_w_down", "  IsKeyDown      : False")
_ImGui_CreateText("t_w_prss", "  IsKeyPressed   : 0 events (with repeat)")
_ImGui_CreateText("t_w_rels", "  IsKeyReleased  : 0 events")
_ImGui_CreateText("t_w_amt",  "  GetKeyPressedAmount(delay 0.30, rate 0.05) frame total : 0")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_a_hdr",  "A  (left)     --  GetKeyName : 'A'")
_ImGui_CreateText("t_a_down", "  IsKeyDown      : False")
_ImGui_CreateText("t_a_prss", "  IsKeyPressed   : 0 events (with repeat)")
_ImGui_CreateText("t_a_rels", "  IsKeyReleased  : 0 events")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_s_hdr",  "S  (back)     --  GetKeyName : 'S'")
_ImGui_CreateText("t_s_down", "  IsKeyDown      : False")
_ImGui_CreateText("t_s_prss", "  IsKeyPressed   : 0 events (NO repeat ; press edge only)")
_ImGui_CreateText("t_s_rels", "  IsKeyReleased  : 0 events")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_d_hdr",  "D  (right)    --  GetKeyName : 'D'")
_ImGui_CreateText("t_d_down", "  IsKeyDown      : False")
_ImGui_CreateText("t_d_prss", "  IsKeyPressed   : 0 events (with repeat)")
_ImGui_CreateText("t_d_rels", "  IsKeyReleased  : 0 events")
_ImGui_CreateSeparator("sep4")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters (edge-frame events) -------------------------------------------
Global $g_iPrssW = 0, $g_iRelsW = 0, $g_iAmtW = 0
Global $g_iPrssA = 0, $g_iRelsA = 0
Global $g_iPrssS = 0, $g_iRelsS = 0
Global $g_iPrssD = 0, $g_iRelsD = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPoll", 16)
; Seed the GetKeyName labels once on startup -- not needed every tick.
_RefreshKeyNames()


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPoll()
    ; W ----------------------------------------------------------------------
    If _ImGui_IsKeyPressed($ImGuiKey_W, True)   Then $g_iPrssW += 1
    If _ImGui_IsKeyReleased($ImGuiKey_W)        Then $g_iRelsW += 1
    $g_iAmtW += _ImGui_GetKeyPressedAmount($ImGuiKey_W, 0.30, 0.05)

    _ImGui_SetText("t_w_down", "  IsKeyDown      : " & (_ImGui_IsKeyDown($ImGuiKey_W) ? "True " : "False"))
    _ImGui_SetText("t_w_prss", "  IsKeyPressed   : " & $g_iPrssW & " events (with repeat)")
    _ImGui_SetText("t_w_rels", "  IsKeyReleased  : " & $g_iRelsW & " events")
    _ImGui_SetText("t_w_amt",  "  GetKeyPressedAmount(delay 0.30, rate 0.05) frame total : " & $g_iAmtW)

    ; A ----------------------------------------------------------------------
    If _ImGui_IsKeyPressed($ImGuiKey_A, True)   Then $g_iPrssA += 1
    If _ImGui_IsKeyReleased($ImGuiKey_A)        Then $g_iRelsA += 1
    _ImGui_SetText("t_a_down", "  IsKeyDown      : " & (_ImGui_IsKeyDown($ImGuiKey_A) ? "True " : "False"))
    _ImGui_SetText("t_a_prss", "  IsKeyPressed   : " & $g_iPrssA & " events (with repeat)")
    _ImGui_SetText("t_a_rels", "  IsKeyReleased  : " & $g_iRelsA & " events")

    ; S  (NO repeat -- $bRepeat = False ; press-edge only) -------------------
    If _ImGui_IsKeyPressed($ImGuiKey_S, False)  Then $g_iPrssS += 1
    If _ImGui_IsKeyReleased($ImGuiKey_S)        Then $g_iRelsS += 1
    _ImGui_SetText("t_s_down", "  IsKeyDown      : " & (_ImGui_IsKeyDown($ImGuiKey_S) ? "True " : "False"))
    _ImGui_SetText("t_s_prss", "  IsKeyPressed   : " & $g_iPrssS & " events (NO repeat ; press edge only)")
    _ImGui_SetText("t_s_rels", "  IsKeyReleased  : " & $g_iRelsS & " events")

    ; D ----------------------------------------------------------------------
    If _ImGui_IsKeyPressed($ImGuiKey_D, True)   Then $g_iPrssD += 1
    If _ImGui_IsKeyReleased($ImGuiKey_D)        Then $g_iRelsD += 1
    _ImGui_SetText("t_d_down", "  IsKeyDown      : " & (_ImGui_IsKeyDown($ImGuiKey_D) ? "True " : "False"))
    _ImGui_SetText("t_d_prss", "  IsKeyPressed   : " & $g_iPrssD & " events (with repeat)")
    _ImGui_SetText("t_d_rels", "  IsKeyReleased  : " & $g_iRelsD & " events")
EndFunc

Func _RefreshKeyNames()
    ; GetKeyName : runs once at startup -- the names are stable.
    _ImGui_SetText("t_w_hdr", "W  (forward)  --  GetKeyName : '" & _ImGui_GetKeyName($ImGuiKey_W) & "'")
    _ImGui_SetText("t_a_hdr", "A  (left)     --  GetKeyName : '" & _ImGui_GetKeyName($ImGuiKey_A) & "'")
    _ImGui_SetText("t_s_hdr", "S  (back)     --  GetKeyName : '" & _ImGui_GetKeyName($ImGuiKey_S) & "'")
    _ImGui_SetText("t_d_hdr", "D  (right)    --  GetKeyName : '" & _ImGui_GetKeyName($ImGuiKey_D) & "'")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
