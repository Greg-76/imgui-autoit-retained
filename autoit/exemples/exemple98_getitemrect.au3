#cs
================================================================================
 Example 98 : _ImGui_GetItemRectMin / Max / Size
================================================================================
 Covers 3 exports of imgui_autoit.dll (inseparable cluster -- the natural
 demo shows all three together because they are derived from the same
 underlying rect) :

   _ImGui_GetItemRectMin   Top-left corner of the widget's bounding box
   _ImGui_GetItemRectMax   Bottom-right corner of the widget's bounding box
   _ImGui_GetItemRectSize  Width / height (= Max - Min, computed on the DLL side)

 All three return a 2-element AutoIt array [x, y] in ImGui
 screen-space pixels (same origin as the host window's client area).
 Coordinates change when the user resizes / moves the ImGui window.

 PERSISTENT state -- polling at 50 ms is reliable. Unknown widget id
 returns 0 + @error = 3 (not silent like the Is* queries).

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple98_getitemrect.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple98_getitemrect.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 98 : _ImGui_GetItemRect*", 660, 540) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_GetItemRectMin / Max / Size  --  doc block
; ==============================================================================
; Signatures :
;   _ImGui_GetItemRectMin($sId)   -> [x, y] top-left  (screen-space)
;   _ImGui_GetItemRectMax($sId)   -> [x, y] bot-right (screen-space)
;   _ImGui_GetItemRectSize($sId)  -> [w, h] (= Max - Min)
;
;   All three return an AutoIt array[2] on success, or 0 with @error
;   set on failure :
;     @error = 1 : DLL not loaded
;              2 : DllCall failed
;              3 : unknown widget id (does NOT silently return zeros)
;
;   Coordinates : screen-space pixels relative to the host window's
;   client area. They change when the ImGui window is moved or
;   resized. They do NOT include the widget's outer margin spacing
;   (ItemSpacing) -- only the widget's own bounding rect.


; ==============================================================================
; Demo widgets  --  three target widget types side by side, live geometry
;                  readout updated every 50 ms.
; ==============================================================================
_ImGui_CreateText("t_title", "GetItemRect* demo  --  live screen-space bounding boxes of three widgets")
_ImGui_CreateText("t_hint",  "Resize the window or scroll. The coordinates below update each tick.")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_targets_hdr", "Targets :")
_ImGui_CreateButton("tg_btn", "Target A : a Button")
_ImGui_CreateInputText("tg_in", "Target B : an InputText with a custom width set next", "type here", 64, 0)
_ImGui_CreateCheckbox("tg_cb", "Target C : a Checkbox", True)
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_panel_hdr",  "Geometry panel (~20 Hz poll) :")
_ImGui_CreateText("t_a_min",      "  A.Min  : (0, 0)")
_ImGui_CreateText("t_a_max",      "  A.Max  : (0, 0)")
_ImGui_CreateText("t_a_size",     "  A.Size : (0, 0)")
_ImGui_CreateText("t_a_check",    "  A.Max - A.Min vs A.Size : equal (sanity check)")
_ImGui_CreateSeparator("sep3")
_ImGui_CreateText("t_b_min",      "  B.Min  : (0, 0)")
_ImGui_CreateText("t_b_max",      "  B.Max  : (0, 0)")
_ImGui_CreateText("t_b_size",     "  B.Size : (0, 0)")
_ImGui_CreateSeparator("sep4")
_ImGui_CreateText("t_c_min",      "  C.Min  : (0, 0)")
_ImGui_CreateText("t_c_max",      "  C.Max  : (0, 0)")
_ImGui_CreateText("t_c_size",     "  C.Size : (0, 0)")
_ImGui_CreateSeparator("sep5")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick ("_OnPollGeometry", 50)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollGeometry()
    _UpdateOne("tg_btn", "t_a_min", "t_a_max", "t_a_size")
    ; Extra sanity check for A : (Max - Min) should match Size exactly.
    Local $aMinA = _ImGui_GetItemRectMin("tg_btn")
    Local $aMaxA = _ImGui_GetItemRectMax("tg_btn")
    Local $aSzA  = _ImGui_GetItemRectSize("tg_btn")
    If IsArray($aMinA) And IsArray($aMaxA) And IsArray($aSzA) Then
        Local $bMatch = (($aMaxA[0] - $aMinA[0]) = $aSzA[0]) And (($aMaxA[1] - $aMinA[1]) = $aSzA[1])
        _ImGui_SetText("t_a_check", "  A.Max - A.Min vs A.Size : " & ($bMatch ? "equal (sanity OK)" : "MISMATCH"))
    EndIf

    _UpdateOne("tg_in", "t_b_min", "t_b_max", "t_b_size")
    _UpdateOne("tg_cb", "t_c_min", "t_c_max", "t_c_size")
EndFunc

Func _UpdateOne($sWidgetId, $sIdMin, $sIdMax, $sIdSize)
    Local $aMin = _ImGui_GetItemRectMin($sWidgetId)
    Local $aMax = _ImGui_GetItemRectMax($sWidgetId)
    Local $aSz  = _ImGui_GetItemRectSize($sWidgetId)
    If IsArray($aMin) Then
        _ImGui_SetText($sIdMin, StringFormat("  %s.Min  : (%.0f, %.0f)", $sIdMin, $aMin[0], $aMin[1]))
    EndIf
    If IsArray($aMax) Then
        _ImGui_SetText($sIdMax, StringFormat("  %s.Max  : (%.0f, %.0f)", $sIdMax, $aMax[0], $aMax[1]))
    EndIf
    If IsArray($aSz) Then
        _ImGui_SetText($sIdSize, StringFormat("  %s.Size : (%.0f, %.0f) px", $sIdSize, $aSz[0], $aSz[1]))
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
