#cs
================================================================================
 Example 196 : _ImGui_CreateGroup
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_CreateGroup   Layout container that treats its children as a
                        SINGLE item for ImGui's "last item" queries

 ImGui::BeginGroup() / EndGroup() defines a rectangular block whose
 bounding rect is the union of all enclosed widgets. The key property
 is that AFTER the Group, every Item-query function (IsItemHovered,
 IsItemActive, GetItemRectMin / Max / Size, ...) refers to the GROUP
 as a whole -- as if it were one widget -- not to the last child.

 Use cases :
   * Wrap a (icon + label + value) cluster to make ItemTooltip /
     ContextPopup apply to the whole cluster, not just the last child.
   * Treat a paragraph of Text + small Buttons as one rectangle for
     hover detection.
   * Build a custom widget out of primitives and have it behave as
     one unit for layout (SameLine, AlignTextToFramePadding, ...).

 Children attach via `_ImGui_SetParent($childId, $groupId)`, like
 Window / TabItem / Popup. The Group is a CONTAINER (parent context),
 NOT a cell-style marker -- so the "Cells are NOT containers" trap
 (Tables family, exemple158) does NOT apply here.

 Demo layout :
   Section A  -- the same children laid out as plain siblings ; each
                 reports its own hover state.
   Section B  -- the same children inside a Group ; hovering ANY child
                 (or the empty space inside the group rect) lights up
                 the Group as a single item.
   Counters at the bottom : Group hovered count vs sum of child hovered
   counts. The group fires once per hover frame ; the individual
   children fire only on themselves.

 Borrowed widgets : Text + Separator, Button, SliderFloat, IsHovered
 (exemple88), IsItemHoveredEx (exemple89) -- both pollable.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple196_creategroup.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple196_creategroup.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 196 : CreateGroup", 780, 640) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateGroup  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateGroup($sId, $sLabel = "")
;
;   $sId    : stable widget identifier.
;   $sLabel : optional label (empty falls back to $sId). The Group
;             itself has no visible label or chrome -- it's a layout
;             container ; the label is mainly an internal identifier.
;
;   Return : True on success, False on failure (@error = 1, 2).
;
;   Attach children via _ImGui_SetParent($child, $groupId).
;   After the Group, IsItemHovered / IsItemActive / GetItemRect* on
;   the GROUP id refer to the whole cluster.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateGroup demo  --  cluster widgets, treat them as ONE item for hover queries")
_ImGui_CreateText("t_hint",  "Hover the two sections below ; counters at the bottom track hover frames.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Section A  --  plain siblings (no group)
; ==============================================================================
_ImGui_CreateText("t_a_hdr", "Section A  --  plain siblings (no Group) :")
_ImGui_CreateText("t_a1", "  Icon-A (Text)")
_ImGui_CreateButton("btn_a", "Button A")
_ImGui_CreateSliderFloat("sl_a", "Slider A", 0.0, 1.0, 0.5, "%.2f")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Section B  --  same children inside a Group
; ==============================================================================
_ImGui_CreateText("t_b_hdr", "Section B  --  same widgets inside a Group :")
_ImGui_CreateGroup("grp_b", "##group_b")
_ImGui_CreateText("t_b1", "  Icon-B (Text)")
_ImGui_SetParent("t_b1", "grp_b")
_ImGui_CreateButton("btn_b", "Button B")
_ImGui_SetParent("btn_b", "grp_b")
_ImGui_CreateSliderFloat("sl_b", "Slider B", 0.0, 1.0, 0.5, "%.2f")
_ImGui_SetParent("sl_b", "grp_b")
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Hover counters
; ==============================================================================
_ImGui_CreateText("t_count_hdr", "Hover counters (polled at 100 ms) :")
_ImGui_CreateText("t_a_counts", "  Section A  --  text: 0   button: 0   slider: 0   sum: 0")
_ImGui_CreateText("t_b_counts", "  Section B  --  text: 0   button: 0   slider: 0   sum: 0   GROUP: 0")
_ImGui_CreateText("t_observation", "  Observation : Group counter ticks once per frame for ANY child or the empty space inside the rect.")
_ImGui_CreateSeparator("sep3")


_ImGui_CreateButton("btn_quit", "Quit")


; --- Globals (counters) ------------------------------------------------------
Global $g_iA_t = 0, $g_iA_b = 0, $g_iA_s = 0
Global $g_iB_t = 0, $g_iB_b = 0, $g_iB_s = 0
Global $g_iB_group = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnHoverTick", 100)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnHoverTick()
    If _ImGui_IsHovered("t_a1")   Then $g_iA_t += 1
    If _ImGui_IsHovered("btn_a")  Then $g_iA_b += 1
    If _ImGui_IsHovered("sl_a")   Then $g_iA_s += 1
    If _ImGui_IsHovered("t_b1")   Then $g_iB_t += 1
    If _ImGui_IsHovered("btn_b")  Then $g_iB_b += 1
    If _ImGui_IsHovered("sl_b")   Then $g_iB_s += 1
    If _ImGui_IsHovered("grp_b")  Then $g_iB_group += 1
    Local $iASum = $g_iA_t + $g_iA_b + $g_iA_s
    Local $iBSum = $g_iB_t + $g_iB_b + $g_iB_s
    _ImGui_SetText("t_a_counts", StringFormat( _
        "  Section A  --  text: %d   button: %d   slider: %d   sum: %d", _
        $g_iA_t, $g_iA_b, $g_iA_s, $iASum))
    _ImGui_SetText("t_b_counts", StringFormat( _
        "  Section B  --  text: %d   button: %d   slider: %d   sum: %d   GROUP: %d", _
        $g_iB_t, $g_iB_b, $g_iB_s, $iBSum, $g_iB_group))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
