#cs
================================================================================
 Example 134 : _ImGui_CreateTreeNode  (+ _ImGui_IsToggledOpen)
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_CreateTreeNode    Hierarchical expandable node with an arrow
   _ImGui_IsToggledOpen     Edge-frame query : True for ONE frame
                            when the user clicked the arrow to open
                            or close the node

 IsToggledOpen is exclusively a TreeNode / CollapsingHeader signal --
 no other widget raises it -- so it lives in the same file as
 TreeNode for completeness (same bundling rule as exemple89
 IsItemHoveredEx + GetItemHoveredEx).

 TreeNode is a CONTAINER : children added with _ImGui_SetParent
 render INSIDE the node's body, visible only when the node is open.
 Nested TreeNodes (sub-nodes) follow the same pattern recursively.

 EDGE-FRAME query (see Decisions log 2026-05-21) : IsToggledOpen is
 True for exactly one render frame (~16 ms at 60 fps). Polling at
 the default 50 ms WILL miss most events. The canonical workaround
 is _ImGui_SetOnTick at 16 ms (used here) ; rare misses still happen
 if Render outruns the tick but accuracy is good enough for a
 counter.

 Flags exercised :
   None                                     baseline
   DefaultOpen                              starts open at first display
   Leaf | NoTreePushOnOpen                  no arrow, no body
   SpanAvailWidth + OpenOnArrow             hover area extends across
                                            the row ; only the arrow
                                            toggles open

 Borrowed widgets : Text, Button, Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple134_treenode.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple134_treenode.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 134 : _ImGui_CreateTreeNode", 760, 640) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_CreateTreeNode  --  doc block
; ==============================================================================
; Signature : _ImGui_CreateTreeNode($sId, $sLabel = "", $iFlags = 0)
;
;   $iFlags : bitmask of $ImGuiTreeNodeFlags_*. Useful values :
;     0       = None
;     1       = Selected             draw as if selected
;     2       = Framed                bg frame around label (used by
;                                     CollapsingHeader)
;     4       = AllowOverlap          let later widgets overlap
;     8       = NoTreePushOnOpen      skip TreePush (no children)
;     32      = DefaultOpen           open at first display
;     64      = OpenOnDoubleClick
;     128     = OpenOnArrow           only the arrow toggles, not label
;     256     = Leaf                  no arrow, always "open"
;     512     = Bullet                bullet glyph instead of arrow
;     1024    = FramePadding          vertical-align label to widget baseline
;     2048    = SpanAvailWidth        hitbox extends to right edge
;     4096    = SpanFullWidth         hitbox spans full row
;     262144  = DrawLinesNone         no parent-child lines
;     524288  = DrawLinesFull         draw parent-child lines (1.92+)
;
;   Children : reparent any widget via _ImGui_SetParent ; they render
;              inside the node body and are visible only while the node
;              is open. Nested TreeNodes work the same way.
;
;   Return : True on success, False on failure (@error = 1=DLL not loaded,
;            2=DllCall failed).

; ==============================================================================
; _ImGui_IsToggledOpen  --  doc block
; ==============================================================================
; Signature : _ImGui_IsToggledOpen($sId)
;
;   Returns True for exactly ONE render frame when the user clicked
;   the arrow to open or close the node. Edge-frame -- polling at
;   the default 50 ms tick misses most events ; poll at 16 ms via
;   _ImGui_SetOnTick (demonstrated below).
;
;   Distinct from _ImGui_HasChanged, which does not apply to non-
;   valued widgets like TreeNode / CollapsingHeader. Returns False
;   silently for any other widget id.


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "CreateTreeNode demo  --  expandable nodes + flags + IsToggledOpen")
_ImGui_CreateText("t_hint",  "Click the arrows to expand / collapse. The IsToggledOpen counters poll at 16 ms.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; 1) Basic TreeNode (no flags ; collapsed at start)
; ==============================================================================
_ImGui_CreateTreeNode("tn_basic", "1) Basic  --  no flags, collapsed at start")
_ImGui_CreateText("tn_b_t1", "  Child text A")
_ImGui_CreateText("tn_b_t2", "  Child text B")
_ImGui_SetParent("tn_b_t1", "tn_basic")
_ImGui_SetParent("tn_b_t2", "tn_basic")


; ==============================================================================
; 2) DefaultOpen  --  starts open
; ==============================================================================
_ImGui_CreateTreeNode("tn_def", "2) DefaultOpen  --  starts open at first display", _
                       $ImGuiTreeNodeFlags_DefaultOpen)
_ImGui_CreateText  ("tn_d_t1",  "  Child text")
_ImGui_CreateButton("tn_d_btn", "  Child button (click me)")
_ImGui_SetParent("tn_d_t1",  "tn_def")
_ImGui_SetParent("tn_d_btn", "tn_def")


; ==============================================================================
; 3) Leaf | NoTreePushOnOpen  --  no arrow, no body
; ==============================================================================
_ImGui_CreateTreeNode("tn_leaf", "3) Leaf | NoTreePushOnOpen  --  no arrow, no body", _
                       BitOR($ImGuiTreeNodeFlags_Leaf, $ImGuiTreeNodeFlags_NoTreePushOnOpen))


; ==============================================================================
; 4) SpanAvailWidth + OpenOnArrow
; ==============================================================================
_ImGui_CreateTreeNode("tn_span", "4) SpanAvailWidth + OpenOnArrow  --  hitbox to right edge, only arrow toggles", _
                       BitOR($ImGuiTreeNodeFlags_SpanAvailWidth, $ImGuiTreeNodeFlags_OpenOnArrow))
_ImGui_CreateText("tn_s_t1", "  Inside the span-avail node. Hover the right margin -- it highlights as part of the row.")
_ImGui_CreateText("tn_s_t2", "  Clicking the label does NOTHING (OpenOnArrow). Only the arrow toggles.")
_ImGui_SetParent("tn_s_t1", "tn_span")
_ImGui_SetParent("tn_s_t2", "tn_span")


; ==============================================================================
; 5) Nested 3 levels deep
; ==============================================================================
_ImGui_CreateTreeNode("tn_root", "5) Nested  --  3 levels deep (DefaultOpen on the first two)", _
                       $ImGuiTreeNodeFlags_DefaultOpen)
_ImGui_CreateText    ("tn_r_t",  "  level 1 text")
_ImGui_CreateTreeNode("tn_mid",  "level 2 node", $ImGuiTreeNodeFlags_DefaultOpen)
_ImGui_CreateText    ("tn_m_t",  "  level 2 text")
_ImGui_CreateTreeNode("tn_leaf3","level 3 node")
_ImGui_CreateText    ("tn_l3_t", "  level 3 text (inside level 3 node)")
_ImGui_SetParent("tn_r_t",   "tn_root")
_ImGui_SetParent("tn_mid",   "tn_root")
_ImGui_SetParent("tn_m_t",   "tn_mid")
_ImGui_SetParent("tn_leaf3", "tn_mid")
_ImGui_SetParent("tn_l3_t",  "tn_leaf3")


; ==============================================================================
; Status footer
; ==============================================================================
_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_tog_hdr",  "IsToggledOpen counters (polled at 16 ms) :")
_ImGui_CreateText("t_counters", "  tn_basic: 0   tn_def: 0   tn_span: 0   tn_root: 0   tn_mid: 0   tn_leaf3: 0")
_ImGui_CreateText("t_flash",    "(awaiting toggle...)")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Counters ---------------------------------------------------------------
Global $g_iTogBasic = 0
Global $g_iTogDef   = 0
Global $g_iTogSpan  = 0
Global $g_iTogRoot  = 0
Global $g_iTogMid   = 0
Global $g_iTogLeaf3 = 0


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
; Poll IsToggledOpen on every expandable node every 16 ms (edge-frame query).
_ImGui_SetOnTick("_OnPollToggles", 16)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollToggles()
    Local $bBasic = _ImGui_IsToggledOpen("tn_basic")
    Local $bDef   = _ImGui_IsToggledOpen("tn_def")
    Local $bSpan  = _ImGui_IsToggledOpen("tn_span")
    Local $bRoot  = _ImGui_IsToggledOpen("tn_root")
    Local $bMid   = _ImGui_IsToggledOpen("tn_mid")
    Local $bLeaf3 = _ImGui_IsToggledOpen("tn_leaf3")
    If $bBasic Then $g_iTogBasic += 1
    If $bDef   Then $g_iTogDef   += 1
    If $bSpan  Then $g_iTogSpan  += 1
    If $bRoot  Then $g_iTogRoot  += 1
    If $bMid   Then $g_iTogMid   += 1
    If $bLeaf3 Then $g_iTogLeaf3 += 1

    _ImGui_SetText("t_counters", StringFormat( _
        "  tn_basic: %d   tn_def: %d   tn_span: %d   tn_root: %d   tn_mid: %d   tn_leaf3: %d", _
        $g_iTogBasic, $g_iTogDef, $g_iTogSpan, $g_iTogRoot, $g_iTogMid, $g_iTogLeaf3))

    Local $bAny = ($bBasic Or $bDef Or $bSpan Or $bRoot Or $bMid Or $bLeaf3)
    _ImGui_SetText("t_flash", $bAny ? ">>> TOGGLED THIS TICK <<<" : "(awaiting toggle...)")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
