#include-once
#include "imgui_generated.au3"

Global $__g_hImGuiDll = -1
Global $__g_sImGuiDllPath = ""   ; override before _ImGui_Init() to force a path

; Event-subscription state ; consumed by _ImGui_SetOnClick / _ImGui_SetOnChange
; / _ImGui_SetOnDoubleClick. The pump is registered lazily on the first Set*
; call and unregistered by _ImGui_Shutdown ; scripts never see the
; AdlibRegister underneath.
Global $__g_aOnClick[16][2]         ; [id, funcname]
Global $__g_aOnChange[16][2]
Global $__g_aOnDoubleClick[16][2]
Global $__g_iOnClickCount        = 0
Global $__g_iOnChangeCount       = 0
Global $__g_iOnDoubleClickCount  = 0
Global $__g_bEventPumpActive = False
Global Const $__g_iEventPumpRateMs = 50

; --- ImGuiCol_ (PushStyleColor) ----------------------------------------------
; Sequential 0-based enum positions in imgui-docking/imgui.h.
Global Const $ImGuiCol_Text                       = 0
Global Const $ImGuiCol_TextDisabled               = 1
Global Const $ImGuiCol_WindowBg                   = 2
Global Const $ImGuiCol_ChildBg                    = 3
Global Const $ImGuiCol_PopupBg                    = 4
Global Const $ImGuiCol_Border                     = 5
Global Const $ImGuiCol_BorderShadow               = 6
Global Const $ImGuiCol_FrameBg                    = 7
Global Const $ImGuiCol_FrameBgHovered             = 8
Global Const $ImGuiCol_FrameBgActive              = 9
Global Const $ImGuiCol_TitleBg                    = 10
Global Const $ImGuiCol_TitleBgActive              = 11
Global Const $ImGuiCol_TitleBgCollapsed           = 12
Global Const $ImGuiCol_MenuBarBg                  = 13
Global Const $ImGuiCol_ScrollbarBg                = 14
Global Const $ImGuiCol_ScrollbarGrab              = 15
Global Const $ImGuiCol_ScrollbarGrabHovered       = 16
Global Const $ImGuiCol_ScrollbarGrabActive        = 17
Global Const $ImGuiCol_CheckMark                  = 18
Global Const $ImGuiCol_CheckboxSelectedBg         = 19
Global Const $ImGuiCol_SliderGrab                 = 20
Global Const $ImGuiCol_SliderGrabActive           = 21
Global Const $ImGuiCol_Button                     = 22
Global Const $ImGuiCol_ButtonHovered              = 23
Global Const $ImGuiCol_ButtonActive               = 24
Global Const $ImGuiCol_Header                     = 25
Global Const $ImGuiCol_HeaderHovered              = 26
Global Const $ImGuiCol_HeaderActive               = 27
Global Const $ImGuiCol_Separator                  = 28
Global Const $ImGuiCol_SeparatorHovered           = 29
Global Const $ImGuiCol_SeparatorActive            = 30
Global Const $ImGuiCol_ResizeGrip                 = 31
Global Const $ImGuiCol_ResizeGripHovered          = 32
Global Const $ImGuiCol_ResizeGripActive           = 33
Global Const $ImGuiCol_InputTextCursor            = 34
Global Const $ImGuiCol_TabHovered                 = 35
Global Const $ImGuiCol_Tab                        = 36
Global Const $ImGuiCol_TabSelected                = 37
Global Const $ImGuiCol_TabSelectedOverline        = 38
Global Const $ImGuiCol_TabDimmed                  = 39
Global Const $ImGuiCol_TabDimmedSelected          = 40
Global Const $ImGuiCol_TabDimmedSelectedOverline  = 41
Global Const $ImGuiCol_DockingPreview             = 42
Global Const $ImGuiCol_DockingEmptyBg             = 43
Global Const $ImGuiCol_PlotLines                  = 44
Global Const $ImGuiCol_PlotLinesHovered           = 45
Global Const $ImGuiCol_PlotHistogram              = 46
Global Const $ImGuiCol_PlotHistogramHovered       = 47
Global Const $ImGuiCol_TableHeaderBg              = 48
Global Const $ImGuiCol_TableBorderStrong          = 49
Global Const $ImGuiCol_TableBorderLight           = 50
Global Const $ImGuiCol_TableRowBg                 = 51
Global Const $ImGuiCol_TableRowBgAlt              = 52
Global Const $ImGuiCol_TextLink                   = 53
Global Const $ImGuiCol_TextSelectedBg             = 54
Global Const $ImGuiCol_TreeLines                  = 55
Global Const $ImGuiCol_DragDropTarget             = 56
Global Const $ImGuiCol_DragDropTargetBg           = 57
Global Const $ImGuiCol_UnsavedMarker              = 58
Global Const $ImGuiCol_NavCursor                  = 59
Global Const $ImGuiCol_NavWindowingHighlight      = 60
Global Const $ImGuiCol_NavWindowingDimBg          = 61
Global Const $ImGuiCol_ModalWindowDimBg           = 62
Global Const $ImGuiCol_COUNT                      = 63   ; sentinel — not a valid slot

; --- ImGuiStyleVar_ (PushStyleVarFloat / PushStyleVarVec2 / X / Y) -----------
; Comment indicates the type. PushStyleVarFloat for float entries,
; PushStyleVarVec2 for ImVec2 entries, PushStyleVarX/Y for single-component
; tweaks of an ImVec2 entry.
Global Const $ImGuiStyleVar_Alpha                       = 0   ; float
Global Const $ImGuiStyleVar_DisabledAlpha               = 1   ; float
Global Const $ImGuiStyleVar_WindowPadding               = 2   ; Vec2
Global Const $ImGuiStyleVar_WindowRounding              = 3   ; float
Global Const $ImGuiStyleVar_WindowBorderSize            = 4   ; float
Global Const $ImGuiStyleVar_WindowMinSize               = 5   ; Vec2
Global Const $ImGuiStyleVar_WindowTitleAlign            = 6   ; Vec2
Global Const $ImGuiStyleVar_ChildRounding               = 7   ; float
Global Const $ImGuiStyleVar_ChildBorderSize             = 8   ; float
Global Const $ImGuiStyleVar_PopupRounding               = 9   ; float
Global Const $ImGuiStyleVar_PopupBorderSize             = 10  ; float
Global Const $ImGuiStyleVar_FramePadding                = 11  ; Vec2
Global Const $ImGuiStyleVar_FrameRounding               = 12  ; float
Global Const $ImGuiStyleVar_FrameBorderSize             = 13  ; float
Global Const $ImGuiStyleVar_ItemSpacing                 = 14  ; Vec2
Global Const $ImGuiStyleVar_ItemInnerSpacing            = 15  ; Vec2
Global Const $ImGuiStyleVar_IndentSpacing               = 16  ; float
Global Const $ImGuiStyleVar_CellPadding                 = 17  ; Vec2
Global Const $ImGuiStyleVar_ScrollbarSize               = 18  ; float
Global Const $ImGuiStyleVar_ScrollbarRounding           = 19  ; float
Global Const $ImGuiStyleVar_ScrollbarPadding            = 20  ; float
Global Const $ImGuiStyleVar_GrabMinSize                 = 21  ; float
Global Const $ImGuiStyleVar_GrabRounding                = 22  ; float
Global Const $ImGuiStyleVar_ImageRounding               = 23  ; float
Global Const $ImGuiStyleVar_ImageBorderSize             = 24  ; float
Global Const $ImGuiStyleVar_TabRounding                 = 25  ; float
Global Const $ImGuiStyleVar_TabBorderSize               = 26  ; float
Global Const $ImGuiStyleVar_TabMinWidthBase             = 27  ; float
Global Const $ImGuiStyleVar_TabMinWidthShrink           = 28  ; float
Global Const $ImGuiStyleVar_TabBarBorderSize            = 29  ; float
Global Const $ImGuiStyleVar_TabBarOverlineSize          = 30  ; float
Global Const $ImGuiStyleVar_TableAngledHeadersAngle     = 31  ; float
Global Const $ImGuiStyleVar_TableAngledHeadersTextAlign = 32  ; Vec2
Global Const $ImGuiStyleVar_TreeLinesSize               = 33  ; float
Global Const $ImGuiStyleVar_TreeLinesRounding           = 34  ; float
Global Const $ImGuiStyleVar_DragDropTargetRounding      = 35  ; float
Global Const $ImGuiStyleVar_ButtonTextAlign             = 36  ; Vec2
Global Const $ImGuiStyleVar_SelectableTextAlign         = 37  ; Vec2
Global Const $ImGuiStyleVar_SeparatorSize               = 38  ; float
Global Const $ImGuiStyleVar_SeparatorTextBorderSize     = 39  ; float
Global Const $ImGuiStyleVar_SeparatorTextAlign          = 40  ; Vec2
Global Const $ImGuiStyleVar_SeparatorTextPadding        = 41  ; Vec2
Global Const $ImGuiStyleVar_DockingSeparatorSize        = 42  ; float

; --- ImGuiConfigFlags_ (SetConfigFlags) --------------------------------------
; Non-contiguous bitflags — values from imgui-docking/imgui.h.
Global Const $ImGuiConfigFlags_None              = 0
Global Const $ImGuiConfigFlags_NavEnableKeyboard = 1   ; 1 << 0
Global Const $ImGuiConfigFlags_NavEnableGamepad  = 2   ; 1 << 1
Global Const $ImGuiConfigFlags_NoMouse           = 16  ; 1 << 4
Global Const $ImGuiConfigFlags_NoMouseCursorChange = 32 ; 1 << 5
Global Const $ImGuiConfigFlags_NoKeyboard        = 64  ; 1 << 6

; --- ImGuiWindowFlags_ (CreateWindow) ----------------------------------------
; Bitflags — combine with BitOR(). E.g. NoResize+NoMove = 6.
Global Const $ImGuiWindowFlags_None                  = 0
Global Const $ImGuiWindowFlags_NoTitleBar            = 1     ; 1 << 0
Global Const $ImGuiWindowFlags_NoResize              = 2     ; 1 << 1
Global Const $ImGuiWindowFlags_NoMove                = 4     ; 1 << 2
Global Const $ImGuiWindowFlags_NoScrollbar           = 8     ; 1 << 3
Global Const $ImGuiWindowFlags_NoScrollWithMouse     = 16    ; 1 << 4
Global Const $ImGuiWindowFlags_NoCollapse            = 32    ; 1 << 5
Global Const $ImGuiWindowFlags_AlwaysAutoResize      = 64    ; 1 << 6
Global Const $ImGuiWindowFlags_NoBackground          = 128   ; 1 << 7
Global Const $ImGuiWindowFlags_NoSavedSettings       = 256   ; 1 << 8
Global Const $ImGuiWindowFlags_NoMouseInputs         = 512   ; 1 << 9
Global Const $ImGuiWindowFlags_MenuBar               = 1024  ; 1 << 10  — required for BeginMenuBar
Global Const $ImGuiWindowFlags_HorizontalScrollbar   = 2048  ; 1 << 11
Global Const $ImGuiWindowFlags_NoFocusOnAppearing    = 4096  ; 1 << 12
Global Const $ImGuiWindowFlags_NoBringToFrontOnFocus = 8192  ; 1 << 13
Global Const $ImGuiWindowFlags_AlwaysVerticalScrollbar   = 16384  ; 1 << 14
Global Const $ImGuiWindowFlags_AlwaysHorizontalScrollbar = 32768  ; 1 << 15
Global Const $ImGuiWindowFlags_NoNavInputs           = 65536 ; 1 << 16
Global Const $ImGuiWindowFlags_NoNavFocus            = 131072 ; 1 << 17
; Composites (defined as OR-combinations inside imgui.h)
Global Const $ImGuiWindowFlags_NoNav                 = 196608  ; NoNavInputs | NoNavFocus
Global Const $ImGuiWindowFlags_NoDecoration          = 43      ; NoTitleBar | NoResize | NoScrollbar | NoCollapse
Global Const $ImGuiWindowFlags_NoInputs              = 197120  ; NoMouseInputs | NoNavInputs | NoNavFocus

; --- ImGuiChildFlags_ (CreateChild, F.3) -------------------------------------
; $bBorder=True in _ImGui_CreateChild is just shorthand for ImGuiChildFlags_Borders.
; Other flags are not currently exposed by the wrapper but the C-ABI accepts
; them if you bypass the helper (or future _ImGui_CreateChildEx).
Global Const $ImGuiChildFlags_None                   = 0
Global Const $ImGuiChildFlags_Borders                = 1     ; 1 << 0
Global Const $ImGuiChildFlags_AlwaysUseWindowPadding = 2     ; 1 << 1
Global Const $ImGuiChildFlags_ResizeX                = 4     ; 1 << 2
Global Const $ImGuiChildFlags_ResizeY                = 8     ; 1 << 3
Global Const $ImGuiChildFlags_AutoResizeX            = 16    ; 1 << 4
Global Const $ImGuiChildFlags_AutoResizeY            = 32    ; 1 << 5
Global Const $ImGuiChildFlags_AlwaysAutoResize       = 64    ; 1 << 6
Global Const $ImGuiChildFlags_FrameStyle             = 128   ; 1 << 7
Global Const $ImGuiChildFlags_NavFlattened           = 256   ; 1 << 8

; --- ImGuiItemFlags_ (PushItemFlag, F.1) -------------------------------------
; Shared item-level behaviors pushed onto a stack. Combine with BitOR().
Global Const $ImGuiItemFlags_None                = 0
Global Const $ImGuiItemFlags_NoTabStop           = 1     ; 1 << 0 — disable keyboard tabbing
Global Const $ImGuiItemFlags_NoNav               = 2     ; 1 << 1 — disable focus (kbd/gamepad/SetKeyboardFocusHere)
Global Const $ImGuiItemFlags_NoNavDefaultFocus   = 4     ; 1 << 2
Global Const $ImGuiItemFlags_ButtonRepeat        = 8     ; 1 << 3 — buttons auto-repeat while held
Global Const $ImGuiItemFlags_AutoClosePopups     = 16    ; 1 << 4 — MenuItem/Selectable close parent popup
Global Const $ImGuiItemFlags_AllowDuplicateId    = 32    ; 1 << 5

; --- ImGuiHoveredFlags_ (passed to IsItemHovered / IsWindowHovered) ----------
; These aren't directly consumed by our current C-ABI surface (we expose
; `_ImGui_IsHovered` with default flags only), but listed for future extension
; and for users who compose their own scripts on top of helpers.
Global Const $ImGuiHoveredFlags_None                         = 0
Global Const $ImGuiHoveredFlags_ChildWindows                 = 1     ; 1 << 0
Global Const $ImGuiHoveredFlags_RootWindow                   = 2     ; 1 << 1
Global Const $ImGuiHoveredFlags_AnyWindow                    = 4     ; 1 << 2
Global Const $ImGuiHoveredFlags_NoPopupHierarchy             = 8     ; 1 << 3
Global Const $ImGuiHoveredFlags_DockHierarchy                = 16    ; 1 << 4
Global Const $ImGuiHoveredFlags_AllowWhenBlockedByPopup      = 32    ; 1 << 5
Global Const $ImGuiHoveredFlags_AllowWhenBlockedByActiveItem = 128   ; 1 << 7
Global Const $ImGuiHoveredFlags_AllowWhenOverlappedByItem    = 256   ; 1 << 8
Global Const $ImGuiHoveredFlags_AllowWhenOverlappedByWindow  = 512   ; 1 << 9
Global Const $ImGuiHoveredFlags_AllowWhenDisabled            = 1024  ; 1 << 10
Global Const $ImGuiHoveredFlags_NoNavOverride                = 2048  ; 1 << 11
Global Const $ImGuiHoveredFlags_ForTooltip                   = 4096  ; 1 << 12
Global Const $ImGuiHoveredFlags_Stationary                   = 8192  ; 1 << 13
Global Const $ImGuiHoveredFlags_DelayNone                    = 16384 ; 1 << 14
Global Const $ImGuiHoveredFlags_DelayShort                   = 32768 ; 1 << 15
Global Const $ImGuiHoveredFlags_DelayNormal                  = 65536 ; 1 << 16
Global Const $ImGuiHoveredFlags_NoSharedDelay                = 131072 ; 1 << 17

; --- ImGuiFocusedFlags_ (passed to IsItemFocused / IsWindowFocused) ----------
Global Const $ImGuiFocusedFlags_None                = 0
Global Const $ImGuiFocusedFlags_ChildWindows        = 1     ; 1 << 0
Global Const $ImGuiFocusedFlags_RootWindow          = 2     ; 1 << 1
Global Const $ImGuiFocusedFlags_AnyWindow           = 4     ; 1 << 2
Global Const $ImGuiFocusedFlags_NoPopupHierarchy    = 8     ; 1 << 3
Global Const $ImGuiFocusedFlags_DockHierarchy       = 16    ; 1 << 4
Global Const $ImGuiFocusedFlags_RootAndChildWindows = 3     ; RootWindow | ChildWindows

; --- ImGuiMouseCursor_ (anticipation : pas de SetMouseCursor encore exposé) --
; Liste pour usage futur si on ajoute un setter.
Global Const $ImGuiMouseCursor_None       = -1
Global Const $ImGuiMouseCursor_Arrow      = 0
Global Const $ImGuiMouseCursor_TextInput  = 1
Global Const $ImGuiMouseCursor_ResizeAll  = 2
Global Const $ImGuiMouseCursor_ResizeNS   = 3
Global Const $ImGuiMouseCursor_ResizeEW   = 4
Global Const $ImGuiMouseCursor_ResizeNESW = 5
Global Const $ImGuiMouseCursor_ResizeNWSE = 6
Global Const $ImGuiMouseCursor_Hand       = 7
Global Const $ImGuiMouseCursor_Wait       = 8
Global Const $ImGuiMouseCursor_Progress   = 9
Global Const $ImGuiMouseCursor_NotAllowed = 10

; --- ImGuiStyleTheme (helper for _ImGui_SetStyleTheme, F.2) ------------------
; Pure convention — not an ImGui enum. Pass to _ImGui_SetStyleTheme.
Global Const $ImGuiStyleTheme_Dark    = 0
Global Const $ImGuiStyleTheme_Light   = 1
Global Const $ImGuiStyleTheme_Classic = 2

; --- ImGuiCond_ (SetWindowPos/Size/Collapsed cond param, D.3) ----------------
; Cond gates whether the setter actually overwrites. ImGui treats None and
; Always identically (= no gating, always overwrite). Use Once to seed once,
; or FirstUseEver to seed only when no .ini state exists (= user-friendly
; initial pos that the user can then drag/resize freely).
Global Const $ImGuiCond_None         = 0      ; functionally identical to Always
Global Const $ImGuiCond_Always       = 1      ; 1 << 0
Global Const $ImGuiCond_Once         = 2      ; 1 << 1
Global Const $ImGuiCond_FirstUseEver = 4      ; 1 << 2
Global Const $ImGuiCond_Appearing    = 8      ; 1 << 3

; --- ImGuiInputTextFlags_ (CreateInputText, CreateInputTextMultiline) --------
; Values from imgui-1.92.8/imgui.h, lines 1254-1295. Bitflags — combine with
; BitOR(). Callback-related flags (CallbackCompletion..CallbackEdit) are
; listed for completeness but require a C++ callback NOT exposed via this DLL ;
; setting them without registering a callback does nothing useful.
Global Const $ImGuiInputTextFlags_None                = 0
Global Const $ImGuiInputTextFlags_CharsDecimal        = 1       ; 1 << 0  — 0123456789.+-*/
Global Const $ImGuiInputTextFlags_CharsHexadecimal    = 2       ; 1 << 1  — 0123456789ABCDEFabcdef
Global Const $ImGuiInputTextFlags_CharsScientific     = 4       ; 1 << 2  — 0123456789.+-*/eE
Global Const $ImGuiInputTextFlags_CharsUppercase      = 8       ; 1 << 3  — turn a..z into A..Z
Global Const $ImGuiInputTextFlags_CharsNoBlank        = 16      ; 1 << 4  — filter spaces/tabs
Global Const $ImGuiInputTextFlags_AllowTabInput       = 32      ; 1 << 5  — TAB inputs '\t'
Global Const $ImGuiInputTextFlags_EnterReturnsTrue    = 64      ; 1 << 6  — return true on Enter only
Global Const $ImGuiInputTextFlags_EscapeClearsAll     = 128     ; 1 << 7  — Esc clears if non-empty
Global Const $ImGuiInputTextFlags_CtrlEnterForNewLine = 256     ; 1 << 8  — multiline: Enter validates
Global Const $ImGuiInputTextFlags_ReadOnly            = 512     ; 1 << 9
Global Const $ImGuiInputTextFlags_Password            = 1024    ; 1 << 10 — display as '*', no copy
Global Const $ImGuiInputTextFlags_AlwaysOverwrite     = 2048    ; 1 << 11
Global Const $ImGuiInputTextFlags_AutoSelectAll       = 4096    ; 1 << 12
Global Const $ImGuiInputTextFlags_ParseEmptyRefVal    = 8192    ; 1 << 13 — InputFloat/Int only
Global Const $ImGuiInputTextFlags_DisplayEmptyRefVal  = 16384   ; 1 << 14 — InputFloat/Int only
Global Const $ImGuiInputTextFlags_NoHorizontalScroll  = 32768   ; 1 << 15
Global Const $ImGuiInputTextFlags_NoUndoRedo          = 65536   ; 1 << 16
Global Const $ImGuiInputTextFlags_ElideLeft           = 131072  ; 1 << 17 — single-line only
Global Const $ImGuiInputTextFlags_CallbackCompletion  = 262144  ; 1 << 18 — needs C++ callback (unused here)
Global Const $ImGuiInputTextFlags_CallbackHistory     = 524288  ; 1 << 19 — needs C++ callback
Global Const $ImGuiInputTextFlags_CallbackAlways      = 1048576 ; 1 << 20 — needs C++ callback
Global Const $ImGuiInputTextFlags_CallbackCharFilter  = 2097152 ; 1 << 21 — needs C++ callback
Global Const $ImGuiInputTextFlags_CallbackResize      = 4194304 ; 1 << 22 — needs C++ callback (buffer grow)
Global Const $ImGuiInputTextFlags_CallbackEdit        = 8388608 ; 1 << 23 — needs C++ callback
Global Const $ImGuiInputTextFlags_WordWrap            = 16777216 ; 1 << 24 — InputTextMultiline only

; --- ImGuiComboFlags_ (CreateCombo) ------------------------------------------
; Values from imgui-1.92.8/imgui.h, lines 1380-1389. Bitflags — combine with
; BitOR(). Height* are mutually exclusive (mask = 30).
Global Const $ImGuiComboFlags_None             = 0
Global Const $ImGuiComboFlags_PopupAlignLeft   = 1     ; 1 << 0 — popup leans left
Global Const $ImGuiComboFlags_HeightSmall      = 2     ; 1 << 1 — max ~4 items visible
Global Const $ImGuiComboFlags_HeightRegular    = 4     ; 1 << 2 — max ~8 items (default)
Global Const $ImGuiComboFlags_HeightLarge      = 8     ; 1 << 3 — max ~20 items
Global Const $ImGuiComboFlags_HeightLargest    = 16    ; 1 << 4 — as many as fit
Global Const $ImGuiComboFlags_NoArrowButton    = 32    ; 1 << 5 — no square arrow on the right
Global Const $ImGuiComboFlags_NoPreview        = 64    ; 1 << 6 — only the square arrow, no preview text
Global Const $ImGuiComboFlags_WidthFitPreview  = 128   ; 1 << 7 — width follows preview contents

; --- ImGuiSelectableFlags_ (CreateSelectable) --------------------------------
; Values from imgui-1.92.8/imgui.h, lines 1362-1369.
Global Const $ImGuiSelectableFlags_None             = 0
Global Const $ImGuiSelectableFlags_NoAutoClosePopups = 1   ; 1 << 0 — don't close parent popup on click
Global Const $ImGuiSelectableFlags_SpanAllColumns   = 2    ; 1 << 1 — span all table columns
Global Const $ImGuiSelectableFlags_AllowDoubleClick = 4    ; 1 << 2 — also fires on double-click
Global Const $ImGuiSelectableFlags_Disabled         = 8    ; 1 << 3 — grayed, not selectable
Global Const $ImGuiSelectableFlags_AllowOverlap     = 16   ; 1 << 4 — let later widgets overlap
Global Const $ImGuiSelectableFlags_Highlight        = 32   ; 1 << 5 — render as if hovered
Global Const $ImGuiSelectableFlags_SelectOnNav      = 64   ; 1 << 6 — auto-select on nav

; --- ImGuiColorEditFlags_ (Create{ColorEdit3,ColorEdit4,ColorPicker3,ColorPicker4}) ---
; Values from imgui-1.92.8/imgui.h, lines 1882-1914. Bitflags — combine with BitOR().
Global Const $ImGuiColorEditFlags_None             = 0
Global Const $ImGuiColorEditFlags_NoAlpha          = 2        ; 1 << 1  — ignore alpha component
Global Const $ImGuiColorEditFlags_NoPicker         = 4        ; 1 << 2  — ColorEdit: no picker on click
Global Const $ImGuiColorEditFlags_NoOptions        = 8        ; 1 << 3  — no right-click options menu
Global Const $ImGuiColorEditFlags_NoSmallPreview   = 16       ; 1 << 4
Global Const $ImGuiColorEditFlags_NoInputs         = 32       ; 1 << 5
Global Const $ImGuiColorEditFlags_NoTooltip        = 64       ; 1 << 6
Global Const $ImGuiColorEditFlags_NoLabel          = 128      ; 1 << 7
Global Const $ImGuiColorEditFlags_NoSidePreview   = 256       ; 1 << 8  — ColorPicker only
Global Const $ImGuiColorEditFlags_NoDragDrop       = 512      ; 1 << 9
Global Const $ImGuiColorEditFlags_NoBorder         = 1024     ; 1 << 10 — ColorButton only
Global Const $ImGuiColorEditFlags_AlphaOpaque      = 4096     ; 1 << 12
Global Const $ImGuiColorEditFlags_AlphaNoBg        = 8192     ; 1 << 13
Global Const $ImGuiColorEditFlags_AlphaPreviewHalf = 16384    ; 1 << 14
Global Const $ImGuiColorEditFlags_AlphaBar         = 262144   ; 1 << 18
Global Const $ImGuiColorEditFlags_HDR              = 524288   ; 1 << 19
Global Const $ImGuiColorEditFlags_DisplayRGB       = 1048576  ; 1 << 20
Global Const $ImGuiColorEditFlags_DisplayHSV       = 2097152  ; 1 << 21
Global Const $ImGuiColorEditFlags_DisplayHex       = 4194304  ; 1 << 22
Global Const $ImGuiColorEditFlags_Uint8            = 8388608  ; 1 << 23
Global Const $ImGuiColorEditFlags_Float            = 16777216 ; 1 << 24
Global Const $ImGuiColorEditFlags_PickerHueBar     = 33554432 ; 1 << 25
Global Const $ImGuiColorEditFlags_PickerHueWheel   = 67108864 ; 1 << 26
Global Const $ImGuiColorEditFlags_InputRGB         = 134217728  ; 1 << 27
Global Const $ImGuiColorEditFlags_InputHSV         = 268435456  ; 1 << 28

; --- ImGuiTreeNodeFlags_ (CreateTreeNode, CreateCollapsingHeader, D.6) --------
; Values from imgui-docking/imgui.h, lines 1349-1380. Bitflags — combine with
; BitOR(). Common combos that I'd reach for in a bot panel : DefaultOpen on
; the top-level node, Leaf (with NoTreePushOnOpen) for a row that mustn't
; collapse further, SpanAvailWidth to make the whole row clickable.
Global Const $ImGuiTreeNodeFlags_None                 = 0
Global Const $ImGuiTreeNodeFlags_Selected             = 1        ; 1 << 0   — draw as selected
Global Const $ImGuiTreeNodeFlags_Framed               = 2        ; 1 << 1   — frame with bg (used by CollapsingHeader)
Global Const $ImGuiTreeNodeFlags_AllowOverlap         = 4        ; 1 << 2   — let subsequent widgets overlap
Global Const $ImGuiTreeNodeFlags_NoTreePushOnOpen     = 8        ; 1 << 3   — skip TreePush (also implies no TreePop)
Global Const $ImGuiTreeNodeFlags_NoAutoOpenOnLog      = 16       ; 1 << 4
Global Const $ImGuiTreeNodeFlags_DefaultOpen          = 32       ; 1 << 5   — open at first display
Global Const $ImGuiTreeNodeFlags_OpenOnDoubleClick    = 64       ; 1 << 6
Global Const $ImGuiTreeNodeFlags_OpenOnArrow          = 128      ; 1 << 7   — only the arrow toggles open, not the label
Global Const $ImGuiTreeNodeFlags_Leaf                 = 256      ; 1 << 8   — no arrow, no collapse (always "open")
Global Const $ImGuiTreeNodeFlags_Bullet               = 512      ; 1 << 9   — bullet instead of arrow
Global Const $ImGuiTreeNodeFlags_FramePadding         = 1024     ; 1 << 10  — vertical-align label to widget baseline
Global Const $ImGuiTreeNodeFlags_SpanAvailWidth       = 2048     ; 1 << 11  — hitbox extends to right edge
Global Const $ImGuiTreeNodeFlags_SpanFullWidth        = 4096     ; 1 << 12  — hitbox spans both left and right edges
Global Const $ImGuiTreeNodeFlags_SpanLabelWidth      = 8192     ; 1 << 13  — narrow hitbox (label only)
Global Const $ImGuiTreeNodeFlags_SpanAllColumns       = 16384    ; 1 << 14  — table mode
Global Const $ImGuiTreeNodeFlags_LabelSpanAllColumns  = 32768    ; 1 << 15  — table mode
Global Const $ImGuiTreeNodeFlags_NavLeftJumpsToParent = 131072   ; 1 << 17  — keyboard nav
Global Const $ImGuiTreeNodeFlags_DrawLinesNone        = 262144   ; 1 << 18
Global Const $ImGuiTreeNodeFlags_DrawLinesFull        = 524288   ; 1 << 19
Global Const $ImGuiTreeNodeFlags_DrawLinesToNodes     = 1048576  ; 1 << 20
; Convenience alias used internally by ImGui to implement CollapsingHeader =
; Framed | NoTreePushOnOpen | NoAutoOpenOnLog = 2 | 8 | 16 = 26. Exposed for
; symmetry, but you don't normally need to set it explicitly — pass these flags
; through _ImGui_CreateCollapsingHeader's $iFlags param if you want a custom mix.
Global Const $ImGuiTreeNodeFlags_CollapsingHeader     = 26

; --- ImGuiTabBarFlags_ (CreateTabBar, D.7) -----------------------------------
; Values from imgui-docking/imgui.h, lines 1440-1456. Bitflags — combine with
; BitOR(). FittingPolicy* are mutually exclusive (Mixed is default).
Global Const $ImGuiTabBarFlags_None                         = 0
Global Const $ImGuiTabBarFlags_Reorderable                  = 1     ; 1 << 0  — drag tabs to reorder
Global Const $ImGuiTabBarFlags_AutoSelectNewTabs            = 2     ; 1 << 1  — select new tabs on appearance
Global Const $ImGuiTabBarFlags_TabListPopupButton           = 4     ; 1 << 2
Global Const $ImGuiTabBarFlags_NoCloseWithMiddleMouseButton = 8     ; 1 << 3
Global Const $ImGuiTabBarFlags_NoTabListScrollingButtons    = 16    ; 1 << 4
Global Const $ImGuiTabBarFlags_NoTooltip                    = 32    ; 1 << 5
Global Const $ImGuiTabBarFlags_DrawSelectedOverline         = 64    ; 1 << 6
Global Const $ImGuiTabBarFlags_FittingPolicyMixed           = 128   ; 1 << 7  — default
Global Const $ImGuiTabBarFlags_FittingPolicyShrink          = 256   ; 1 << 8
Global Const $ImGuiTabBarFlags_FittingPolicyScroll          = 512   ; 1 << 9

; --- ImGuiTabItemFlags_ (CreateTabItem, CreateTabItemButton, D.7) ------------
; Values from imgui-docking/imgui.h, lines 1466-1475. Bitflags — combine with
; BitOR(). Leading/Trailing pin a tab to either side of the bar (useful for
; TabItemButton "+" / "≡").
Global Const $ImGuiTabItemFlags_None                         = 0
Global Const $ImGuiTabItemFlags_UnsavedDocument              = 1   ; 1 << 0  — dot next to title + NoAssumedClosure
Global Const $ImGuiTabItemFlags_SetSelected                  = 2   ; 1 << 1  — force selected on next BeginTabItem
Global Const $ImGuiTabItemFlags_NoCloseWithMiddleMouseButton = 4   ; 1 << 2
Global Const $ImGuiTabItemFlags_NoPushId                     = 8   ; 1 << 3
Global Const $ImGuiTabItemFlags_NoTooltip                    = 16  ; 1 << 4
Global Const $ImGuiTabItemFlags_NoReorder                    = 32  ; 1 << 5
Global Const $ImGuiTabItemFlags_Leading                      = 64  ; 1 << 6  — pin to left side
Global Const $ImGuiTabItemFlags_Trailing                     = 128 ; 1 << 7  — pin to right side
Global Const $ImGuiTabItemFlags_NoAssumedClosure             = 256 ; 1 << 8

; --- ImGuiPopupFlags_ (OpenPopup, ClosePopup, IsPopupOpen, E.1) --------------
; Values from imgui-docking/imgui.h, lines 1388-1403. Used in two contexts :
;  - On _ImGui_OpenPopup / _ImGui_ClosePopup : only NoReopen / NoOpenOver* apply.
;    (We don't accept a flags arg on these wrappers yet — wire it via $iFlags
;    on the Create call if you need NoReopen.)
;  - On _ImGui_IsPopupOpen : AnyPopupId / AnyPopupLevel control the search.
;  - MouseButton* are for BeginPopupContext* helpers (not in scope for E.1 ;
;    compose right-click manually via _ImGui_IsClicked + _ImGui_OpenPopup).
Global Const $ImGuiPopupFlags_None                    = 0
Global Const $ImGuiPopupFlags_MouseButtonLeft         = 4    ; 1 << 2
Global Const $ImGuiPopupFlags_MouseButtonRight        = 8    ; 2 << 2  — default for BeginPopupContext*
Global Const $ImGuiPopupFlags_MouseButtonMiddle       = 12   ; 3 << 2
Global Const $ImGuiPopupFlags_NoReopen                = 32   ; 1 << 5
Global Const $ImGuiPopupFlags_NoOpenOverExistingPopup = 128  ; 1 << 7
Global Const $ImGuiPopupFlags_NoOpenOverItems         = 256  ; 1 << 8
Global Const $ImGuiPopupFlags_AnyPopupId              = 1024 ; 1 << 10
Global Const $ImGuiPopupFlags_AnyPopupLevel           = 2048 ; 1 << 11
Global Const $ImGuiPopupFlags_AnyPopup                = 3072 ; AnyPopupId | AnyPopupLevel

; --- ImGuiSliderFlags_ (DragFloat/Int, SliderFloat/Int, VSlider, Range2, E.2) -
; Values from imgui-docking/imgui.h, lines 2023-2036. Shared by all Drag*,
; Slider* and Range2 calls — same flags apply since the features are aligned.
Global Const $ImGuiSliderFlags_None             = 0
Global Const $ImGuiSliderFlags_Logarithmic      = 32   ; 1 << 5   — logarithmic ramp (pair with NoRoundToFormat for low-digit formats)
Global Const $ImGuiSliderFlags_NoRoundToFormat  = 64   ; 1 << 6   — don't round value to %.Nf precision
Global Const $ImGuiSliderFlags_NoInput          = 128  ; 1 << 7   — disable Ctrl+Click text input
Global Const $ImGuiSliderFlags_WrapAround       = 256  ; 1 << 8   — Drag only : wrap min↔max
Global Const $ImGuiSliderFlags_ClampOnInput     = 512  ; 1 << 9   — Ctrl+Click input is clamped to [v_min, v_max]
Global Const $ImGuiSliderFlags_ClampZeroRange   = 1024 ; 1 << 10  — also clamp when min==max==0 (Drag legacy quirk)
Global Const $ImGuiSliderFlags_NoSpeedTweaks    = 2048 ; 1 << 11  — disable Shift/Alt drag speed modifiers
Global Const $ImGuiSliderFlags_AlwaysClamp      = 1536 ; ClampOnInput | ClampZeroRange

; --- ImGuiMouseButton_ (GetMouseDragDelta, $ImGuiPopupFlags_MouseButton*, E.3) ---
; Values from imgui-docking/imgui.h:2040 — stable, guaranteed by ImGui contract.
Global Const $ImGuiMouseButton_Left   = 0
Global Const $ImGuiMouseButton_Right  = 1
Global Const $ImGuiMouseButton_Middle = 2

; --- ImGuiKey_ (IsKeyDown/Pressed/Released — G.3) -----------------------------
; Values from imgui-docking/imgui.h:1626 — ImGuiKey is a fixed enum starting at
; 512 ($ImGuiKey_NamedKey_BEGIN, where ImGuiKey_None=0 is the only "before" value).
; Sequential ordering inside the enum is part of ImGui's API contract. Listed
; in the same order as imgui.h so the offsets remain auditable.

Global Const $ImGuiKey_None          = 0
Global Const $ImGuiKey_NamedKey_BEGIN = 512

Global Const $ImGuiKey_Tab           = 512
Global Const $ImGuiKey_LeftArrow     = 513
Global Const $ImGuiKey_RightArrow    = 514
Global Const $ImGuiKey_UpArrow       = 515
Global Const $ImGuiKey_DownArrow     = 516
Global Const $ImGuiKey_PageUp        = 517
Global Const $ImGuiKey_PageDown      = 518
Global Const $ImGuiKey_Home          = 519
Global Const $ImGuiKey_End           = 520
Global Const $ImGuiKey_Insert        = 521
Global Const $ImGuiKey_Delete        = 522
Global Const $ImGuiKey_Backspace     = 523
Global Const $ImGuiKey_Space         = 524
Global Const $ImGuiKey_Enter         = 525
Global Const $ImGuiKey_Escape        = 526
Global Const $ImGuiKey_LeftCtrl      = 527
Global Const $ImGuiKey_LeftShift     = 528
Global Const $ImGuiKey_LeftAlt       = 529
Global Const $ImGuiKey_LeftSuper     = 530
Global Const $ImGuiKey_RightCtrl     = 531
Global Const $ImGuiKey_RightShift    = 532
Global Const $ImGuiKey_RightAlt      = 533
Global Const $ImGuiKey_RightSuper    = 534
Global Const $ImGuiKey_Menu          = 535
Global Const $ImGuiKey_0             = 536
Global Const $ImGuiKey_1             = 537
Global Const $ImGuiKey_2             = 538
Global Const $ImGuiKey_3             = 539
Global Const $ImGuiKey_4             = 540
Global Const $ImGuiKey_5             = 541
Global Const $ImGuiKey_6             = 542
Global Const $ImGuiKey_7             = 543
Global Const $ImGuiKey_8             = 544
Global Const $ImGuiKey_9             = 545
Global Const $ImGuiKey_A             = 546
Global Const $ImGuiKey_B             = 547
Global Const $ImGuiKey_C             = 548
Global Const $ImGuiKey_D             = 549
Global Const $ImGuiKey_E             = 550
Global Const $ImGuiKey_F             = 551
Global Const $ImGuiKey_G             = 552
Global Const $ImGuiKey_H             = 553
Global Const $ImGuiKey_I             = 554
Global Const $ImGuiKey_J             = 555
Global Const $ImGuiKey_K             = 556
Global Const $ImGuiKey_L             = 557
Global Const $ImGuiKey_M             = 558
Global Const $ImGuiKey_N             = 559
Global Const $ImGuiKey_O             = 560
Global Const $ImGuiKey_P             = 561
Global Const $ImGuiKey_Q             = 562
Global Const $ImGuiKey_R             = 563
Global Const $ImGuiKey_S             = 564
Global Const $ImGuiKey_T             = 565
Global Const $ImGuiKey_U             = 566
Global Const $ImGuiKey_V             = 567
Global Const $ImGuiKey_W             = 568
Global Const $ImGuiKey_X             = 569
Global Const $ImGuiKey_Y             = 570
Global Const $ImGuiKey_Z             = 571
Global Const $ImGuiKey_F1            = 572
Global Const $ImGuiKey_F2            = 573
Global Const $ImGuiKey_F3            = 574
Global Const $ImGuiKey_F4            = 575
Global Const $ImGuiKey_F5            = 576
Global Const $ImGuiKey_F6            = 577
Global Const $ImGuiKey_F7            = 578
Global Const $ImGuiKey_F8            = 579
Global Const $ImGuiKey_F9            = 580
Global Const $ImGuiKey_F10           = 581
Global Const $ImGuiKey_F11           = 582
Global Const $ImGuiKey_F12           = 583
Global Const $ImGuiKey_F13           = 584
Global Const $ImGuiKey_F14           = 585
Global Const $ImGuiKey_F15           = 586
Global Const $ImGuiKey_F16           = 587
Global Const $ImGuiKey_F17           = 588
Global Const $ImGuiKey_F18           = 589
Global Const $ImGuiKey_F19           = 590
Global Const $ImGuiKey_F20           = 591
Global Const $ImGuiKey_F21           = 592
Global Const $ImGuiKey_F22           = 593
Global Const $ImGuiKey_F23           = 594
Global Const $ImGuiKey_F24           = 595
Global Const $ImGuiKey_Apostrophe    = 596
Global Const $ImGuiKey_Comma         = 597
Global Const $ImGuiKey_Minus         = 598
Global Const $ImGuiKey_Period        = 599
Global Const $ImGuiKey_Slash         = 600
Global Const $ImGuiKey_Semicolon     = 601
Global Const $ImGuiKey_Equal         = 602
Global Const $ImGuiKey_LeftBracket   = 603
Global Const $ImGuiKey_Backslash     = 604
Global Const $ImGuiKey_RightBracket  = 605
Global Const $ImGuiKey_GraveAccent   = 606
Global Const $ImGuiKey_CapsLock      = 607
Global Const $ImGuiKey_ScrollLock    = 608
Global Const $ImGuiKey_NumLock       = 609
Global Const $ImGuiKey_PrintScreen   = 610
Global Const $ImGuiKey_Pause         = 611
Global Const $ImGuiKey_Keypad0       = 612
Global Const $ImGuiKey_Keypad1       = 613
Global Const $ImGuiKey_Keypad2       = 614
Global Const $ImGuiKey_Keypad3       = 615
Global Const $ImGuiKey_Keypad4       = 616
Global Const $ImGuiKey_Keypad5       = 617
Global Const $ImGuiKey_Keypad6       = 618
Global Const $ImGuiKey_Keypad7       = 619
Global Const $ImGuiKey_Keypad8       = 620
Global Const $ImGuiKey_Keypad9       = 621
Global Const $ImGuiKey_KeypadDecimal = 622
Global Const $ImGuiKey_KeypadDivide  = 623
Global Const $ImGuiKey_KeypadMultiply = 624
Global Const $ImGuiKey_KeypadSubtract = 625
Global Const $ImGuiKey_KeypadAdd     = 626
Global Const $ImGuiKey_KeypadEnter   = 627
Global Const $ImGuiKey_KeypadEqual   = 628
Global Const $ImGuiKey_AppBack       = 629
Global Const $ImGuiKey_AppForward    = 630
Global Const $ImGuiKey_Oem102        = 631

; Keyboard modifier chord bits — OR with a regular ImGuiKey to form a chord
; (e.g. $ImGuiMod_Ctrl + $ImGuiKey_S for Ctrl+S). Used with Shortcut() if/when
; we expose it ; IsKeyPressed/Down/Released accept either chord or plain keys.
Global Const $ImGuiMod_None  = 0
Global Const $ImGuiMod_Ctrl  = 0x1000
Global Const $ImGuiMod_Shift = 0x2000
Global Const $ImGuiMod_Alt   = 0x4000
Global Const $ImGuiMod_Super = 0x8000

; --- ImGuiTableFlags_ (CreateTable, Phase I) ---------------------------------
; Values from imgui-docking/imgui.h:2120 (1.92.9 WIP). Bit positions stable.
Global Const $ImGuiTableFlags_None                       = 0
Global Const $ImGuiTableFlags_Resizable                  = 0x1        ; 1 << 0
Global Const $ImGuiTableFlags_Reorderable                = 0x2        ; 1 << 1
Global Const $ImGuiTableFlags_Hideable                   = 0x4        ; 1 << 2
Global Const $ImGuiTableFlags_Sortable                   = 0x8        ; 1 << 3
Global Const $ImGuiTableFlags_NoSavedSettings            = 0x10       ; 1 << 4
Global Const $ImGuiTableFlags_ContextMenuInBody          = 0x20       ; 1 << 5
Global Const $ImGuiTableFlags_RowBg                      = 0x40       ; 1 << 6
Global Const $ImGuiTableFlags_BordersInnerH              = 0x80       ; 1 << 7
Global Const $ImGuiTableFlags_BordersOuterH              = 0x100      ; 1 << 8
Global Const $ImGuiTableFlags_BordersInnerV              = 0x200      ; 1 << 9
Global Const $ImGuiTableFlags_BordersOuterV              = 0x400      ; 1 << 10
Global Const $ImGuiTableFlags_BordersH                   = 0x180      ; InnerH | OuterH
Global Const $ImGuiTableFlags_BordersV                   = 0x600      ; InnerV | OuterV
Global Const $ImGuiTableFlags_BordersInner               = 0x280      ; InnerV | InnerH
Global Const $ImGuiTableFlags_BordersOuter               = 0x500      ; OuterV | OuterH
Global Const $ImGuiTableFlags_Borders                    = 0x780      ; BordersInner | BordersOuter
Global Const $ImGuiTableFlags_NoBordersInBody            = 0x800      ; 1 << 11
Global Const $ImGuiTableFlags_NoBordersInBodyUntilResize = 0x1000     ; 1 << 12
Global Const $ImGuiTableFlags_SizingFixedFit             = 0x2000     ; 1 << 13
Global Const $ImGuiTableFlags_SizingFixedSame            = 0x4000     ; 2 << 13
Global Const $ImGuiTableFlags_SizingStretchProp          = 0x6000     ; 3 << 13
Global Const $ImGuiTableFlags_SizingStretchSame          = 0x8000     ; 4 << 13
Global Const $ImGuiTableFlags_NoHostExtendX              = 0x10000    ; 1 << 16
Global Const $ImGuiTableFlags_NoHostExtendY              = 0x20000    ; 1 << 17
Global Const $ImGuiTableFlags_NoKeepColumnsVisible       = 0x40000    ; 1 << 18
Global Const $ImGuiTableFlags_PreciseWidths              = 0x80000    ; 1 << 19
Global Const $ImGuiTableFlags_NoClip                     = 0x100000   ; 1 << 20
Global Const $ImGuiTableFlags_PadOuterX                  = 0x200000   ; 1 << 21
Global Const $ImGuiTableFlags_NoPadOuterX                = 0x400000   ; 1 << 22
Global Const $ImGuiTableFlags_NoPadInnerX                = 0x800000   ; 1 << 23
Global Const $ImGuiTableFlags_ScrollX                    = 0x1000000  ; 1 << 24
Global Const $ImGuiTableFlags_ScrollY                    = 0x2000000  ; 1 << 25
Global Const $ImGuiTableFlags_SortMulti                  = 0x4000000  ; 1 << 26
Global Const $ImGuiTableFlags_SortTristate               = 0x8000000  ; 1 << 27
Global Const $ImGuiTableFlags_HighlightHoveredColumn     = 0x10000000 ; 1 << 28

; --- ImGuiTableColumnFlags_ (TableSetupColumn, Phase I) ----------------------
; Values from imgui-docking/imgui.h:2173.
Global Const $ImGuiTableColumnFlags_None                 = 0
Global Const $ImGuiTableColumnFlags_Disabled             = 0x1     ; 1 << 0
Global Const $ImGuiTableColumnFlags_DefaultHide          = 0x2     ; 1 << 1
Global Const $ImGuiTableColumnFlags_DefaultSort          = 0x4     ; 1 << 2
Global Const $ImGuiTableColumnFlags_WidthStretch         = 0x8     ; 1 << 3
Global Const $ImGuiTableColumnFlags_WidthFixed           = 0x10    ; 1 << 4
Global Const $ImGuiTableColumnFlags_NoResize             = 0x20    ; 1 << 5
Global Const $ImGuiTableColumnFlags_NoReorder            = 0x40    ; 1 << 6
Global Const $ImGuiTableColumnFlags_NoHide               = 0x80    ; 1 << 7
Global Const $ImGuiTableColumnFlags_NoClip               = 0x100   ; 1 << 8
Global Const $ImGuiTableColumnFlags_NoSort               = 0x200   ; 1 << 9
Global Const $ImGuiTableColumnFlags_NoSortAscending      = 0x400   ; 1 << 10
Global Const $ImGuiTableColumnFlags_NoSortDescending     = 0x800   ; 1 << 11
Global Const $ImGuiTableColumnFlags_NoHeaderLabel        = 0x1000  ; 1 << 12
Global Const $ImGuiTableColumnFlags_NoHeaderWidth        = 0x2000  ; 1 << 13
Global Const $ImGuiTableColumnFlags_PreferSortAscending  = 0x4000  ; 1 << 14
Global Const $ImGuiTableColumnFlags_PreferSortDescending = 0x8000  ; 1 << 15
Global Const $ImGuiTableColumnFlags_IndentEnable         = 0x10000 ; 1 << 16
Global Const $ImGuiTableColumnFlags_IndentDisable        = 0x20000 ; 1 << 17
Global Const $ImGuiTableColumnFlags_AngledHeader         = 0x40000 ; 1 << 18

; --- ImGuiTableRowFlags_ (TableNextRow, Phase I) -----------------------------
Global Const $ImGuiTableRowFlags_None    = 0
Global Const $ImGuiTableRowFlags_Headers = 0x1   ; 1 << 0

; --- ImGuiSortDirection_ (TableGetSortSpecs return values, Phase I) ----------
Global Const $ImGuiSortDirection_None       = 0
Global Const $ImGuiSortDirection_Ascending  = 1
Global Const $ImGuiSortDirection_Descending = 2

; --- ImGuiTableBgTarget_ (TableSetBgColor target, Phase J.5) -----------------
; RowBg0 = base zebra row color (applied first), RowBg1 = additional row
; color (mixed over RowBg0), CellBg = a single cell (target with $iColumnN).
Global Const $ImGuiTableBgTarget_None  = 0
Global Const $ImGuiTableBgTarget_RowBg0 = 1
Global Const $ImGuiTableBgTarget_RowBg1 = 2
Global Const $ImGuiTableBgTarget_CellBg = 3

; Note : $ImGuiHoveredFlags_* are declared further up (F.3 constants audit).
; Combos `AllowWhenOverlapped` / `RectOnly` / `RootAndChildWindows` are
; composable via BitOR from the individual flag constants if needed.

; --- ImGuiFontGlyphRange_ (Phase K.3 LoadFontEx glyph_range param) ----------
; Wrapper-side enum that maps to io.Fonts->GetGlyphRanges*() at DLL level.
Global Const $ImGuiFontGlyphRange_Default                = 0   ; Latin (no extra range)
Global Const $ImGuiFontGlyphRange_Vietnamese             = 1
Global Const $ImGuiFontGlyphRange_Cyrillic               = 2
Global Const $ImGuiFontGlyphRange_Greek                  = 3
Global Const $ImGuiFontGlyphRange_ChineseFull            = 4
Global Const $ImGuiFontGlyphRange_ChineseSimplifiedCommon = 5
Global Const $ImGuiFontGlyphRange_Japanese               = 6
Global Const $ImGuiFontGlyphRange_Korean                 = 7
Global Const $ImGuiFontGlyphRange_Thai                   = 8

; #FUNCTION# ====================================================================================================================
; Name...........: __ImGui_Arch
; Description ...: Return the AutoIt host architecture as a short string
; Syntax.........: __ImGui_Arch()
; Parameters ....: None
; Return values .: Returns "x64" when running under 64-bit AutoIt, "x86" otherwise
; Information ...: Internal helper. Consumed by __ImGui_ResolveDll to pick the matching binary directory.
; ===============================================================================================================================
Func __ImGui_Arch()
    Return @AutoItX64 ? "x64" : "x86"
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: __ImGui_ResolveDll
; Description ...: Resolve the absolute path to imgui_autoit.dll by probing standard locations
; Syntax.........: __ImGui_ResolveDll()
; Parameters ....: None
; Return values .: Returns the absolute DLL path on success. Empty string if no candidate exists.
; Information ...: Honors $__g_sImGuiDllPath when explicitly set ; otherwise scans @ScriptDir, @ScriptDir\<arch>\,
;                  @ScriptDir\bin\<arch>\, ..\dll\bin\<arch>\ (when run from autoit\),
;                  ..\..\dll\bin\<arch>\ (when run from autoit\tests or autoit\exemples),
;                  and ..\imgui-autoit-retained\dll\bin\<arch>\.
; ===============================================================================================================================
Func __ImGui_ResolveDll()
    If $__g_sImGuiDllPath <> "" And FileExists($__g_sImGuiDllPath) Then Return $__g_sImGuiDllPath
    Local $sArch = __ImGui_Arch()
    Local $aCandidates[6] = [ _
        @ScriptDir & "\imgui_autoit.dll", _
        @ScriptDir & "\" & $sArch & "\imgui_autoit.dll", _
        @ScriptDir & "\bin\" & $sArch & "\imgui_autoit.dll", _
        @ScriptDir & "\..\dll\bin\" & $sArch & "\imgui_autoit.dll", _
        @ScriptDir & "\..\..\dll\bin\" & $sArch & "\imgui_autoit.dll", _
        @ScriptDir & "\..\imgui-autoit-retained\dll\bin\" & $sArch & "\imgui_autoit.dll" _
    ]
    For $i = 0 To UBound($aCandidates) - 1
        If FileExists($aCandidates[$i]) Then Return $aCandidates[$i]
    Next
    Return ""
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_Init
; Description ...: Load the DLL and create the ImGui main window
; Syntax.........: _ImGui_Init($sTitle[, $iW = 800, $iH = 600])
; Parameters ....: $sTitle      - Window title (UTF-8)
;                  $iW          - Initial window width in pixels
;                  $iH          - Initial window height in pixels
; Return values .: Success - True. Failure - False (@error = 1=already initialized, 2=DLL not found,
;                  3=DllOpen failed, 4=DllCall failed, 5=ImGui_Init returned non-zero)
; Information ...: Registers _ImGui_Shutdown via OnAutoItExitRegister so resources are released automatically.
; ===============================================================================================================================
Func _ImGui_Init($sTitle, $iW = 800, $iH = 600)
    If $__g_hImGuiDll <> -1 Then Return SetError(1, 0, False)
    Local $sPath = __ImGui_ResolveDll()
    If $sPath = "" Then Return SetError(2, 0, False)
    $__g_hImGuiDll = DllOpen($sPath)
    If $__g_hImGuiDll = -1 Then Return SetError(3, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_Init", "wstr", $sTitle, "int", $iW, "int", $iH)
    If @error Then Return SetError(4, @error, False)
    If $aRet[0] <> 0 Then Return SetError(5, $aRet[0], False)
    OnAutoItExitRegister("_ImGui_Shutdown")
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_Shutdown
; Description ...: Tear down the ImGui context and unload the DLL
; Syntax.........: _ImGui_Shutdown()
; Parameters ....: None
; Return values .: None (idempotent, no error reporting)
; Information ...: Safe to call multiple times. Registered as an OnAutoItExit handler by _ImGui_Init,
;                  so the script does not need to invoke it explicitly under normal shutdown.
; ===============================================================================================================================
Func _ImGui_Shutdown()
    If $__g_hImGuiDll = -1 Then Return
    If $__g_bEventPumpActive Then
        AdlibUnRegister("__ImGui_PumpEvents")
        $__g_bEventPumpActive = False
    EndIf
    $__g_iOnClickCount       = 0
    $__g_iOnChangeCount      = 0
    $__g_iOnDoubleClickCount = 0
    DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_Shutdown")
    DllClose($__g_hImGuiDll)
    $__g_hImGuiDll = -1
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsRunning
; Description ...: Report whether the ImGui main loop is still running
; Syntax.........: _ImGui_IsRunning()
; Parameters ....: None
; Return values .: Returns True while the window is open and processing frames. False once closed or before _ImGui_Init.
; Information ...: Typical use is the main loop predicate : While _ImGui_IsRunning() ... WEnd.
; ===============================================================================================================================
Func _ImGui_IsRunning()
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsRunning")
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_WasClicked
; Description ...: Consume the "user just clicked this widget" edge for a clickable
; Syntax.........: _ImGui_WasClicked($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True exactly once per user click, then re-arms. False on missing widget or DLL not loaded.
; Information ...: Consume-and-reset semantics : reading the flag clears it. Only user interaction in Render()
;                  latches the flag ; programmatic actions never do (see [[imgui_retained_strict_changed]]).
; ===============================================================================================================================
Func _ImGui_WasClicked($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_WasClicked", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_WasDoubleClicked
; Description ...: Consume the "user just double-clicked this widget" edge
; Syntax.........: _ImGui_WasDoubleClicked($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True exactly once per detected double-click, then re-arms. False on missing widget or DLL not loaded.
; Information ...: Companion to _ImGui_WasClicked. Detection is performed by the render thread at the exact frame of the
;                  press event (via ImGui::IsMouseDoubleClicked), so the result is reliable regardless of the AutoIt-side
;                  polling cadence. Only widgets whose Render() opts in (today : Selectable with AllowDoubleClick) actually
;                  raise this flag ; others always return False here.
; ===============================================================================================================================
Func _ImGui_WasDoubleClicked($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_WasDoubleClicked", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; --- Event subscriptions (OnEvent-style API) ---------------------------------
; Mimic AutoIt's native `Opt("GUIOnEventMode", 1) + GUICtrlSetOnEvent` for
; ImGui widgets. The script binds a function to a widget id ; the wrapper
; calls it (with $sId as the only argument) every time the matching latched
; flag fires.
;
; The script's main loop stays minimal :
;     While _ImGui_IsRunning()
;         Sleep(50)
;     WEnd
;
; Internally a single AdlibRegister polls the latched WasClicked / HasChanged
; flags and dispatches to the registered user functions. It is started
; lazily on the first Set* call and unregistered by _ImGui_Shutdown.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetOnClick
; Description ...: Bind a function to be invoked when the widget reports a click
; Syntax.........: _ImGui_SetOnClick($sId, $sFuncName)
; Parameters ....: $sId         - Stable widget identifier
;                  $sFuncName   - Name of an AutoIt Func ; pass "" to unbind
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=$sId empty)
; Information ...: The handler receives $sId as its only argument :
;                      Func _OnButtonClicked($sId)
;                          MsgBox(0, "Click", "Widget " & $sId & " was clicked.")
;                      EndFunc
;                      _ImGui_SetOnClick("btn_quit", "_OnButtonClicked")
;                  Re-binding the same id replaces the previous handler.
; ===============================================================================================================================
Func _ImGui_SetOnClick($sId, $sFuncName)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sId = "" Then Return SetError(2, 0, False)
    Local $iIdx = -1, $i
    For $i = 0 To $__g_iOnClickCount - 1
        If $__g_aOnClick[$i][0] = $sId Then
            $iIdx = $i
            ExitLoop
        EndIf
    Next
    If $sFuncName = "" Then
        ; Unbind. Shift remaining entries down.
        If $iIdx = -1 Then Return True
        For $i = $iIdx To $__g_iOnClickCount - 2
            $__g_aOnClick[$i][0] = $__g_aOnClick[$i + 1][0]
            $__g_aOnClick[$i][1] = $__g_aOnClick[$i + 1][1]
        Next
        $__g_iOnClickCount -= 1
        Return True
    EndIf
    If $iIdx = -1 Then
        If $__g_iOnClickCount >= UBound($__g_aOnClick) Then
            ReDim $__g_aOnClick[$__g_iOnClickCount + 16][2]
        EndIf
        $__g_aOnClick[$__g_iOnClickCount][0] = $sId
        $__g_aOnClick[$__g_iOnClickCount][1] = $sFuncName
        $__g_iOnClickCount += 1
    Else
        $__g_aOnClick[$iIdx][1] = $sFuncName
    EndIf
    __ImGui_StartEventPump()
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetOnChange
; Description ...: Bind a function to be invoked when the widget value changes
; Syntax.........: _ImGui_SetOnChange($sId, $sFuncName)
; Parameters ....: $sId         - Stable widget identifier
;                  $sFuncName   - Name of an AutoIt Func ; pass "" to unbind
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=$sId empty)
; Information ...: Same pattern as _ImGui_SetOnClick but driven by HasChanged.
;                  Strict semantics : programmatic Set* never fire OnChange ;
;                  only user interaction in Render() does.
; ===============================================================================================================================
Func _ImGui_SetOnChange($sId, $sFuncName)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sId = "" Then Return SetError(2, 0, False)
    Local $iIdx = -1, $i
    For $i = 0 To $__g_iOnChangeCount - 1
        If $__g_aOnChange[$i][0] = $sId Then
            $iIdx = $i
            ExitLoop
        EndIf
    Next
    If $sFuncName = "" Then
        If $iIdx = -1 Then Return True
        For $i = $iIdx To $__g_iOnChangeCount - 2
            $__g_aOnChange[$i][0] = $__g_aOnChange[$i + 1][0]
            $__g_aOnChange[$i][1] = $__g_aOnChange[$i + 1][1]
        Next
        $__g_iOnChangeCount -= 1
        Return True
    EndIf
    If $iIdx = -1 Then
        If $__g_iOnChangeCount >= UBound($__g_aOnChange) Then
            ReDim $__g_aOnChange[$__g_iOnChangeCount + 16][2]
        EndIf
        $__g_aOnChange[$__g_iOnChangeCount][0] = $sId
        $__g_aOnChange[$__g_iOnChangeCount][1] = $sFuncName
        $__g_iOnChangeCount += 1
    Else
        $__g_aOnChange[$iIdx][1] = $sFuncName
    EndIf
    __ImGui_StartEventPump()
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetOnDoubleClick
; Description ...: Bind a function to be invoked when the widget reports a double-click
; Syntax.........: _ImGui_SetOnDoubleClick($sId, $sFuncName)
; Parameters ....: $sId         - Stable widget identifier
;                  $sFuncName   - Name of an AutoIt Func ; pass "" to unbind
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=$sId empty)
; Information ...: Companion to _ImGui_SetOnClick : fires only on detected double-clicks (typically Selectable
;                  with $ImGuiSelectableFlags_AllowDoubleClick). Detection happens on the render thread at the
;                  exact frame of the press, so it works reliably regardless of polling cadence. Binding both
;                  OnClick and OnDoubleClick on the same widget is supported : both will fire when a double-click
;                  happens (OnClick from the first click of the burst, OnDoubleClick from the second).
; ===============================================================================================================================
Func _ImGui_SetOnDoubleClick($sId, $sFuncName)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sId = "" Then Return SetError(2, 0, False)
    Local $iIdx = -1, $i
    For $i = 0 To $__g_iOnDoubleClickCount - 1
        If $__g_aOnDoubleClick[$i][0] = $sId Then
            $iIdx = $i
            ExitLoop
        EndIf
    Next
    If $sFuncName = "" Then
        If $iIdx = -1 Then Return True
        For $i = $iIdx To $__g_iOnDoubleClickCount - 2
            $__g_aOnDoubleClick[$i][0] = $__g_aOnDoubleClick[$i + 1][0]
            $__g_aOnDoubleClick[$i][1] = $__g_aOnDoubleClick[$i + 1][1]
        Next
        $__g_iOnDoubleClickCount -= 1
        Return True
    EndIf
    If $iIdx = -1 Then
        If $__g_iOnDoubleClickCount >= UBound($__g_aOnDoubleClick) Then
            ReDim $__g_aOnDoubleClick[$__g_iOnDoubleClickCount + 16][2]
        EndIf
        $__g_aOnDoubleClick[$__g_iOnDoubleClickCount][0] = $sId
        $__g_aOnDoubleClick[$__g_iOnDoubleClickCount][1] = $sFuncName
        $__g_iOnDoubleClickCount += 1
    Else
        $__g_aOnDoubleClick[$iIdx][1] = $sFuncName
    EndIf
    __ImGui_StartEventPump()
    Return True
EndFunc

; Internal : start the periodic poll the first time someone subscribes.
; Idempotent.
Func __ImGui_StartEventPump()
    If $__g_bEventPumpActive Then Return
    AdlibRegister("__ImGui_PumpEvents", $__g_iEventPumpRateMs)
    $__g_bEventPumpActive = True
EndFunc

; Internal : called by AdlibRegister every $__g_iEventPumpRateMs ms on the
; AutoIt main thread. Consumes the latched flags and dispatches to user funcs.
Func __ImGui_PumpEvents()
    If $__g_hImGuiDll = -1 Then Return
    Local $i
    For $i = 0 To $__g_iOnClickCount - 1
        If _ImGui_WasClicked($__g_aOnClick[$i][0]) Then
            Call($__g_aOnClick[$i][1], $__g_aOnClick[$i][0])
        EndIf
    Next
    For $i = 0 To $__g_iOnChangeCount - 1
        If _ImGui_HasChanged($__g_aOnChange[$i][0]) Then
            Call($__g_aOnChange[$i][1], $__g_aOnChange[$i][0])
        EndIf
    Next
    For $i = 0 To $__g_iOnDoubleClickCount - 1
        If _ImGui_WasDoubleClicked($__g_aOnDoubleClick[$i][0]) Then
            Call($__g_aOnDoubleClick[$i][1], $__g_aOnDoubleClick[$i][0])
        EndIf
    Next
EndFunc

; --- Item queries ------------------------------------------------------------
; Latched at the end of each frame by the render thread (Widget::RenderAndQueryState).
; Reflect the user's interaction state with the widget : hovered = pointer is
; over it, active = held/dragged, focused = keyboard focus.
; Hidden widgets always report False — querying a non-existent id returns
; False silently (no @error).

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsHovered
; Description ...: Report whether the mouse pointer is currently over the widget
; Syntax.........: _ImGui_IsHovered($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True while hovered. False on hidden/unknown widget or DLL not loaded (no @error).
; Information ...: Read-only — does not consume the flag. Latched at the end of each frame.
; ===============================================================================================================================
Func _ImGui_IsHovered($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsHovered", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsActive
; Description ...: Report whether the widget is currently active (held/dragged/edited)
; Syntax.........: _ImGui_IsActive($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True while active. False on hidden/unknown widget or DLL not loaded (no @error).
; Information ...: Read-only ; persists across frames as long as the user holds the widget.
; ===============================================================================================================================
Func _ImGui_IsActive($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsActive", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsFocused
; Description ...: Report whether the widget owns the keyboard focus
; Syntax.........: _ImGui_IsFocused($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True while focused. False on hidden/unknown widget or DLL not loaded (no @error).
; Information ...: Read-only ; only one widget can be focused at a time.
; ===============================================================================================================================
Func _ImGui_IsFocused($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsFocused", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; Extended frame-state item queries (D.1). All read-only — they reflect the
; widget's interaction state during the LAST frame it rendered, without
; consuming the value (unlike _ImGui_WasClicked / _ImGui_HasChanged which
; consume-and-reset). Hidden widgets and unknown ids always return False.
;
; _ImGui_IsClicked      — left mouse button just clicked the widget this frame.
;                         Differs from WasClicked: not consumed, refreshes
;                         every frame, frame-state only.
; _ImGui_IsEdited       — the widget's value changed this frame (frame-state,
;                         not consumed — different from HasChanged).
; _ImGui_IsActivated    — edge frame: widget became active (e.g. mouse down).
; _ImGui_IsDeactivated  — edge frame: widget stopped being active.
; _ImGui_IsDeactivatedAfterEdit — edge frame on deactivation IF the value
;                         actually changed during the interaction.
; _ImGui_IsVisible      — widget is currently rendered (not clipped).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsClicked
; Description ...: Report whether the left mouse button just clicked the widget this frame
; Syntax.........: _ImGui_IsClicked($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True only on the click frame. False on hidden/unknown widget or DLL not loaded.
; Information ...: Read-only frame-state — refreshes every frame, not consumed. Use _ImGui_WasClicked
;                  if you want consume-and-reset semantics across polling cycles.
; ===============================================================================================================================
Func _ImGui_IsClicked($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsClicked", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsEdited
; Description ...: Report whether the widget's value changed this frame
; Syntax.........: _ImGui_IsEdited($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True only on the change frame. False on hidden/unknown widget or DLL not loaded.
; Information ...: Read-only frame-state ; differs from _ImGui_HasChanged which is consume-and-reset.
; ===============================================================================================================================
Func _ImGui_IsEdited($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsEdited", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsActivated
; Description ...: Report whether the widget just transitioned to the active state this frame
; Syntax.........: _ImGui_IsActivated($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True only on the activation edge frame. False otherwise.
; Information ...: Edge frame ; pairs with _ImGui_IsDeactivated to detect interaction boundaries.
; ===============================================================================================================================
Func _ImGui_IsActivated($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsActivated", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsDeactivated
; Description ...: Report whether the widget just transitioned out of the active state this frame
; Syntax.........: _ImGui_IsDeactivated($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True only on the deactivation edge frame. False otherwise.
; Information ...: Edge frame ; fires even when the value did not change. Use _ImGui_IsDeactivatedAfterEdit to filter.
; ===============================================================================================================================
Func _ImGui_IsDeactivated($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsDeactivated", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsDeactivatedAfterEdit
; Description ...: Report deactivation only when the value actually changed during the interaction
; Syntax.........: _ImGui_IsDeactivatedAfterEdit($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True on the deactivation edge frame iff the user changed the value. False otherwise.
; Information ...: Edge frame ; ideal trigger for "commit on lose focus" semantics (e.g. input field validation).
; ===============================================================================================================================
Func _ImGui_IsDeactivatedAfterEdit($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsDeactivatedAfterEdit", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsVisible
; Description ...: Report whether the widget is currently rendered (not clipped or hidden)
; Syntax.........: _ImGui_IsVisible($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True if the widget produced draw output this frame. False if clipped or hidden.
; Information ...: Useful before reading geometry or skipping expensive per-widget logic for off-screen items.
; ===============================================================================================================================
Func _ImGui_IsVisible($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsVisible", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; Bounding rect of the last rendered item. Returns a 2-element array [x, y]
; in ImGui screen-space (same origin as the host window's client area).
; SetError(3) on unknown id. _ImGui_GetItemRectSize is derived (max - min)
; by the DLL, identical to ImGui::GetItemRectSize().
; #FUNCTION# ====================================================================================================================
; Name...........: __ImGui_GetRectInternal
; Description ...: Shared backend for the GetItemRectMin/Max/Size accessors
; Syntax.........: __ImGui_GetRectInternal($sId, $sExport)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sExport     - DLL export name ("ImGui_GetItemRectMin"/"Max"/"Size")
; Return values .: Returns array[2] = [x, y] in ImGui screen-space on success.
;                  0 with @error set (1=DLL not loaded, 2=DllCall failed, 3=unknown widget id).
; Information ...: Internal helper. Use the public _ImGui_GetItemRect* wrappers from user code.
; ===============================================================================================================================
Func __ImGui_GetRectInternal($sId, $sExport)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $tBuf = DllStructCreate("float buf[2]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", $sExport, _
        "wstr", $sId, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Local $aOut[2] = [DllStructGetData($tBuf, "buf", 1), DllStructGetData($tBuf, "buf", 2)]
    Return $aOut
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetItemRectMin
; Description ...: Return the top-left corner of the widget's bounding rect in ImGui screen-space
; Syntax.........: _ImGui_GetItemRectMin($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns array[2] = [x, y] on success. 0 with @error set (3=unknown widget id).
; ===============================================================================================================================
Func _ImGui_GetItemRectMin($sId)
    Return __ImGui_GetRectInternal($sId, "ImGui_GetItemRectMin")
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetItemRectMax
; Description ...: Return the bottom-right corner of the widget's bounding rect in ImGui screen-space
; Syntax.........: _ImGui_GetItemRectMax($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns array[2] = [x, y] on success. 0 with @error set (3=unknown widget id).
; ===============================================================================================================================
Func _ImGui_GetItemRectMax($sId)
    Return __ImGui_GetRectInternal($sId, "ImGui_GetItemRectMax")
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetItemRectSize
; Description ...: Return the size (width, height) of the widget's bounding rect
; Syntax.........: _ImGui_GetItemRectSize($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns array[2] = [width, height] on success. 0 with @error set (3=unknown widget id).
; ===============================================================================================================================
Func _ImGui_GetItemRectSize($sId)
    Return __ImGui_GetRectInternal($sId, "ImGui_GetItemRectSize")
EndFunc

; Global "any item" queries — True if at least one widget in the tree
; matches the predicate, across both render passes (host area + top-level
; Windows). Useful for "is the user currently interacting with the panel
; at all?" checks before passing the click through to the bot logic.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsAnyItemHovered
; Description ...: Report whether at least one widget in the tree is currently hovered
; Syntax.........: _ImGui_IsAnyItemHovered()
; Parameters ....: None
; Return values .: Returns True if any widget is hovered this frame. False otherwise or DLL not loaded (no @error).
; Information ...: Spans both render passes (host area + top-level Windows). Useful as a "panel-claims-the-click"
;                  gate before forwarding mouse events to bot logic.
; ===============================================================================================================================
Func _ImGui_IsAnyItemHovered()
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsAnyItemHovered")
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsAnyItemActive
; Description ...: Report whether at least one widget in the tree is currently active
; Syntax.........: _ImGui_IsAnyItemActive()
; Parameters ....: None
; Return values .: Returns True if any widget is held/dragged/edited this frame. False otherwise (no @error).
; ===============================================================================================================================
Func _ImGui_IsAnyItemActive()
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsAnyItemActive")
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsAnyItemFocused
; Description ...: Report whether at least one widget in the tree owns the keyboard focus
; Syntax.........: _ImGui_IsAnyItemFocused()
; Parameters ....: None
; Return values .: Returns True if any widget has focus this frame. False otherwise (no @error).
; ===============================================================================================================================
Func _ImGui_IsAnyItemFocused()
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsAnyItemFocused")
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; Set a tooltip that appears when the widget is hovered. Empty string clears it.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetTooltip
; Description ...: Attach a tooltip that appears when the widget is hovered
; Syntax.........: _ImGui_SetTooltip($sId, $sText)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sText       - Tooltip text (UTF-8). Empty string clears the tooltip.
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; ===============================================================================================================================
Func _ImGui_SetTooltip($sId, $sText)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetTooltip", "wstr", $sId, "wstr", $sText)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Returns True/False for any BoolValueWidget. SetError(3) if the widget id
; doesn't exist OR isn't bool-valued (the DLL returns -1 in both cases).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetValueBool
; Description ...: Read the current boolean value of any bool-valued widget
; Syntax.........: _ImGui_GetValueBool($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True/False on success. False with @error set (1=DLL not loaded, 2=DllCall failed,
;                  3=unknown widget id or not bool-valued).
; ===============================================================================================================================
Func _ImGui_GetValueBool($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetValueBool", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] = -1 Then Return SetError(3, 0, False)
    Return ($aRet[0] = 1)
EndFunc

; Programmatic write — does NOT latch `changed` (mirrors WasClicked: the bot
; doesn't see its own writes as notifications).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetValueBool
; Description ...: Programmatically write a boolean value into a bool-valued widget
; Syntax.........: _ImGui_SetValueBool($sId, $bValue)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $bValue      - New boolean state to apply
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Programmatic writes never latch the changed/clicked flag — see [[imgui_retained_strict_changed]].
; ===============================================================================================================================
Func _ImGui_SetValueBool($sId, $bValue)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iVal = $bValue ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetValueBool", "wstr", $sId, "int", $iVal)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Returns the float value of any FloatValueWidget. SetError(3) with @extended
; carrying the DLL status (2=unknown id, 3=type mismatch) if the widget can't
; provide a float — the user can distinguish if they want, otherwise treat any
; @error as failure.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetValueFloat
; Description ...: Read the current float value of any float-valued widget
; Syntax.........: _ImGui_GetValueFloat($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns the float value on success. 0.0 with @error set (1=DLL not loaded, 2=DllCall failed,
;                  3=unknown widget id or not float-valued — @extended carries the DLL status).
; ===============================================================================================================================
Func _ImGui_GetValueFloat($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0.0)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetValueFloat", "wstr", $sId, "float*", 0.0)
    If @error Then Return SetError(2, @error, 0.0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0.0)
    Return $aRet[2]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetValueFloat
; Description ...: Programmatically write a float value into a float-valued widget
; Syntax.........: _ImGui_SetValueFloat($sId, $fValue)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fValue      - New float value to apply
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Programmatic writes never latch the changed flag — see [[imgui_retained_strict_changed]].
; ===============================================================================================================================
Func _ImGui_SetValueFloat($sId, $fValue)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetValueFloat", "wstr", $sId, "float", $fValue)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetValueInt
; Description ...: Read the current integer value of any int-valued widget
; Syntax.........: _ImGui_GetValueInt($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns the integer value on success. 0 with @error set (1=DLL not loaded, 2=DllCall failed,
;                  3=unknown widget id or not int-valued).
; ===============================================================================================================================
Func _ImGui_GetValueInt($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetValueInt", "wstr", $sId, "int*", 0)
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Return $aRet[2]
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetValueInt
; Description ...: Programmatically write an integer value into an int-valued widget
; Syntax.........: _ImGui_SetValueInt($sId, $iValue)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iValue      - New integer value to apply
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Programmatic writes never latch the changed flag — see [[imgui_retained_strict_changed]].
; ===============================================================================================================================
Func _ImGui_SetValueInt($sId, $iValue)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetValueInt", "wstr", $sId, "int", $iValue)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Vector value accessors --------------------------------------------------
; For SliderFloat2/3/4, DragInt3, InputFloat4, etc. Get returns a 1D array of
; N floats/ints (the widget's arity) ; Set takes a 1D array of N values that
; must match the widget's arity exactly (no truncation).

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetValueFloatN
; Description ...: Read the float vector value of a vector-valued widget (SliderFloat2/3/4, InputFloat4, ...)
; Syntax.........: _ImGui_GetValueFloatN($sId[, $iMaxN = 4])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iMaxN       - Maximum component count to read (1..4 typical)
; Return values .: Returns a 1D float array sized to the widget's arity (N) on success.
;                  0 with @error set (1=DLL not loaded, 2=DllCall failed, 3=unknown/non-vector widget).
; ===============================================================================================================================
Func _ImGui_GetValueFloatN($sId, $iMaxN = 4)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    If $iMaxN < 1 Then $iMaxN = 1
    Local $tBuf = DllStructCreate("float buf[" & $iMaxN & "]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetValueFloatN", _
        "wstr", $sId, "ptr", DllStructGetPtr($tBuf), "int", $iMaxN)
    If @error Then Return SetError(2, @error, 0)
    Local $iN = $aRet[0]
    If $iN <= 0 Then Return SetError(3, 0, 0)
    Local $aOut[$iN]
    For $i = 0 To $iN - 1
        $aOut[$i] = DllStructGetData($tBuf, "buf", $i + 1)
    Next
    Return $aOut
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetValueFloatN
; Description ...: Programmatically write a float vector into a vector-valued widget
; Syntax.........: _ImGui_SetValueFloatN($sId, $aValues)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $aValues     - 1D float array, size must match the widget arity exactly (no truncation)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=arity mismatch, 5=$aValues is not an array or is empty)
; Information ...: Programmatic writes never latch the changed flag — see [[imgui_retained_strict_changed]].
; ===============================================================================================================================
Func _ImGui_SetValueFloatN($sId, $aValues)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If Not IsArray($aValues) Then Return SetError(5, 0, False)
    Local $iN = UBound($aValues)
    If $iN < 1 Then Return SetError(5, 0, False)
    Local $tBuf = DllStructCreate("float buf[" & $iN & "]")
    For $i = 0 To $iN - 1
        DllStructSetData($tBuf, "buf", $aValues[$i], $i + 1)
    Next
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetValueFloatN", _
        "wstr", $sId, "ptr", DllStructGetPtr($tBuf), "int", $iN)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetValueIntN
; Description ...: Read the integer vector value of a vector-valued widget (SliderInt2/3/4, InputInt4, ...)
; Syntax.........: _ImGui_GetValueIntN($sId[, $iMaxN = 4])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iMaxN       - Maximum component count to read (1..4 typical)
; Return values .: Returns a 1D int array sized to the widget's arity (N) on success.
;                  0 with @error set (1=DLL not loaded, 2=DllCall failed, 3=unknown/non-vector widget).
; ===============================================================================================================================
Func _ImGui_GetValueIntN($sId, $iMaxN = 4)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    If $iMaxN < 1 Then $iMaxN = 1
    Local $tBuf = DllStructCreate("int buf[" & $iMaxN & "]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetValueIntN", _
        "wstr", $sId, "ptr", DllStructGetPtr($tBuf), "int", $iMaxN)
    If @error Then Return SetError(2, @error, 0)
    Local $iN = $aRet[0]
    If $iN <= 0 Then Return SetError(3, 0, 0)
    Local $aOut[$iN]
    For $i = 0 To $iN - 1
        $aOut[$i] = DllStructGetData($tBuf, "buf", $i + 1)
    Next
    Return $aOut
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetValueIntN
; Description ...: Programmatically write an integer vector into a vector-valued widget
; Syntax.........: _ImGui_SetValueIntN($sId, $aValues)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $aValues     - 1D int array, size must match the widget arity exactly (no truncation)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=arity mismatch, 5=$aValues is not an array or is empty)
; Information ...: Programmatic writes never latch the changed flag — see [[imgui_retained_strict_changed]].
; ===============================================================================================================================
Func _ImGui_SetValueIntN($sId, $aValues)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If Not IsArray($aValues) Then Return SetError(5, 0, False)
    Local $iN = UBound($aValues)
    If $iN < 1 Then Return SetError(5, 0, False)
    Local $tBuf = DllStructCreate("int buf[" & $iN & "]")
    For $i = 0 To $iN - 1
        DllStructSetData($tBuf, "buf", $aValues[$i], $i + 1)
    Next
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetValueIntN", _
        "wstr", $sId, "ptr", DllStructGetPtr($tBuf), "int", $iN)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; True exactly once per user-driven change, then re-arms.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_HasChanged
; Description ...: Consume the "user just changed this widget's value" edge
; Syntax.........: _ImGui_HasChanged($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True exactly once per user-driven change, then re-arms. False on hidden/unknown widget.
; Information ...: Consume-and-reset semantics. Only user interaction in Render() latches the flag ;
;                  programmatic Set* writes never do — see [[imgui_retained_strict_changed]].
; ===============================================================================================================================
Func _ImGui_HasChanged($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_HasChanged", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateText
; Description ...: Create a Text widget (static label with no interaction)
; Syntax.........: _ImGui_CreateText($sId[, $sText = ""])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sText       - Text content (UTF-8) ; empty allowed
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Use _ImGui_SetText to update the displayed string at runtime.
; ===============================================================================================================================
Func _ImGui_CreateText($sId, $sText = "")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateText", "wstr", $sId, "wstr", $sText)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetText
; Description ...: Update the text content of an existing Text widget
; Syntax.........: _ImGui_SetText($sId, $sText)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sText       - New text content (UTF-8) ; empty clears the label
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; ===============================================================================================================================
Func _ImGui_SetText($sId, $sText)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetText", "wstr", $sId, "wstr", $sText)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Global config setters (post-Init) ---------------------------------------
; Apply to ImGui::GetIO() under the same lock the render thread uses around
; NewFrame → Render → Present. Picked up at the start of the next frame.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetConfigFlags
; Description ...: Apply a new ImGuiIO::ConfigFlags bitmask at runtime
; Syntax.........: _ImGui_SetConfigFlags($iFlags)
; Parameters ....: $iFlags      - Bitmask of $ImGuiConfigFlags_* values
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Applied under the render-thread lock and picked up at the start of the next frame.
;                  Viewports are enabled by default ; never enable DockingEnable without asking.
; ===============================================================================================================================
Func _ImGui_SetConfigFlags($iFlags)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetConfigFlags", "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetFontGlobalScale
; Description ...: Set the global font scale factor applied to all rendered text
; Syntax.........: _ImGui_SetFontGlobalScale($fScale)
; Parameters ....: $fScale      - Multiplier applied to font sizes (1.0 = default)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Applied at the start of the next frame.
; ===============================================================================================================================
Func _ImGui_SetFontGlobalScale($fScale)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetFontGlobalScale", "float", $fScale)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Focus-aware frame rate limiter ------------------------------------------
; Sets the FPS cap used when the ImGui window doesn't have focus. Range [1, 60]
; (clamped DLL-side). Default 20 fps. Focused windows always render at vsync
; (~60 fps). Critical for multi-bot setups : with 8 bot panels running, each
; would consume ~12% of a typical iGPU at 60 fps blur ; at 20 fps the budget
; drops to ~4%.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetUnfocusedFps
; Description ...: Set the FPS cap used when the ImGui window does not have focus
; Syntax.........: _ImGui_SetUnfocusedFps($iFps)
; Parameters ....: $iFps        - Target FPS in [1, 60] (clamped DLL-side, default 20)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Focused windows always render at vsync (~60 fps). Critical for multi-panel setups
;                  where idle blur cost adds up across instances.
; ===============================================================================================================================
Func _ImGui_SetUnfocusedFps($iFps)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetUnfocusedFps", "int", $iFps)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Debug-window toggles (D.2) ---------------------------------------------
; Each pair toggles one of ImGui's built-in debug windows :
;   - Demo : exhaustive widget gallery (huge ImGui sample)
;   - Metrics : per-frame stats, draw lists, performance counters
;   - DebugLog : ImGui-internal debug log
;   - IDStackTool : helps diagnose ID collisions in the widget tree
;   - About : ImGui version + build info
; The X close button on each window writes False back to the atomic, so
; _ImGui_IsShowing*() reflects manual closes — useful for keeping menu
; checkmarks in sync with the actual window state.
; #FUNCTION# ====================================================================================================================
; Name...........: __ImGui_ShowDebugWindow
; Description ...: Shared backend that toggles one of ImGui's built-in debug windows
; Syntax.........: __ImGui_ShowDebugWindow($sExport, $bShow)
; Parameters ....: $sExport     - DLL export name (e.g. "ImGui_ShowDemoWindow")
;                  $bShow       - True to show, False to hide
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Internal helper. Use the public _ImGui_Show*Window wrappers from user code.
; ===============================================================================================================================
Func __ImGui_ShowDebugWindow($sExport, $bShow)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iVal = $bShow ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", $sExport, "int", $iVal)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: __ImGui_IsShowingDebugWindow
; Description ...: Shared backend that reads the visibility of one of ImGui's built-in debug windows
; Syntax.........: __ImGui_IsShowingDebugWindow($sExport)
; Parameters ....: $sExport     - DLL export name (e.g. "ImGui_IsShowingDemoWindow")
; Return values .: Returns True while the window is shown. False otherwise or on DLL error (no @error).
; Information ...: Internal helper. Use the public _ImGui_IsShowing*Window wrappers from user code.
; ===============================================================================================================================
Func __ImGui_IsShowingDebugWindow($sExport)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", $sExport)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_ShowDemoWindow
; Description ...: Show or hide ImGui's built-in Demo window (exhaustive widget gallery)
; Syntax.........: _ImGui_ShowDemoWindow([$bShow = True])
; Parameters ....: $bShow       - True to show, False to hide
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: The window's X close button writes False back, so _ImGui_IsShowingDemoWindow stays in sync.
; ===============================================================================================================================
Func _ImGui_ShowDemoWindow($bShow = True)
    Return __ImGui_ShowDebugWindow("ImGui_ShowDemoWindow", $bShow)
EndFunc
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_ShowMetricsWindow
; Description ...: Show or hide ImGui's Metrics window (per-frame stats, draw lists, perf counters)
; Syntax.........: _ImGui_ShowMetricsWindow([$bShow = True])
; Parameters ....: $bShow       - True to show, False to hide
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; ===============================================================================================================================
Func _ImGui_ShowMetricsWindow($bShow = True)
    Return __ImGui_ShowDebugWindow("ImGui_ShowMetricsWindow", $bShow)
EndFunc
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_ShowDebugLogWindow
; Description ...: Show or hide ImGui's internal Debug Log window
; Syntax.........: _ImGui_ShowDebugLogWindow([$bShow = True])
; Parameters ....: $bShow       - True to show, False to hide
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; ===============================================================================================================================
Func _ImGui_ShowDebugLogWindow($bShow = True)
    Return __ImGui_ShowDebugWindow("ImGui_ShowDebugLogWindow", $bShow)
EndFunc
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_ShowIDStackToolWindow
; Description ...: Show or hide ImGui's ID Stack Tool window (helps diagnose ID collisions)
; Syntax.........: _ImGui_ShowIDStackToolWindow([$bShow = True])
; Parameters ....: $bShow       - True to show, False to hide
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; ===============================================================================================================================
Func _ImGui_ShowIDStackToolWindow($bShow = True)
    Return __ImGui_ShowDebugWindow("ImGui_ShowIDStackToolWindow", $bShow)
EndFunc
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_ShowAboutWindow
; Description ...: Show or hide ImGui's About window (version + build info)
; Syntax.........: _ImGui_ShowAboutWindow([$bShow = True])
; Parameters ....: $bShow       - True to show, False to hide
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; ===============================================================================================================================
Func _ImGui_ShowAboutWindow($bShow = True)
    Return __ImGui_ShowDebugWindow("ImGui_ShowAboutWindow", $bShow)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsShowingDemoWindow
; Description ...: Report whether ImGui's Demo window is currently shown
; Syntax.........: _ImGui_IsShowingDemoWindow()
; Parameters ....: None
; Return values .: Returns True while the Demo window is shown. False otherwise or DLL not loaded.
; Information ...: Reflects manual closes (X button) too — handy for keeping menu checkmarks in sync.
; ===============================================================================================================================
Func _ImGui_IsShowingDemoWindow()
    Return __ImGui_IsShowingDebugWindow("ImGui_IsShowingDemoWindow")
EndFunc
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsShowingMetricsWindow
; Description ...: Report whether ImGui's Metrics window is currently shown
; Syntax.........: _ImGui_IsShowingMetricsWindow()
; Parameters ....: None
; Return values .: Returns True while the Metrics window is shown. False otherwise or DLL not loaded.
; ===============================================================================================================================
Func _ImGui_IsShowingMetricsWindow()
    Return __ImGui_IsShowingDebugWindow("ImGui_IsShowingMetricsWindow")
EndFunc
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsShowingDebugLogWindow
; Description ...: Report whether ImGui's Debug Log window is currently shown
; Syntax.........: _ImGui_IsShowingDebugLogWindow()
; Parameters ....: None
; Return values .: Returns True while the Debug Log window is shown. False otherwise or DLL not loaded.
; ===============================================================================================================================
Func _ImGui_IsShowingDebugLogWindow()
    Return __ImGui_IsShowingDebugWindow("ImGui_IsShowingDebugLogWindow")
EndFunc
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsShowingIDStackToolWindow
; Description ...: Report whether ImGui's ID Stack Tool window is currently shown
; Syntax.........: _ImGui_IsShowingIDStackToolWindow()
; Parameters ....: None
; Return values .: Returns True while the ID Stack Tool window is shown. False otherwise or DLL not loaded.
; ===============================================================================================================================
Func _ImGui_IsShowingIDStackToolWindow()
    Return __ImGui_IsShowingDebugWindow("ImGui_IsShowingIDStackToolWindow")
EndFunc
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsShowingAboutWindow
; Description ...: Report whether ImGui's About window is currently shown
; Syntax.........: _ImGui_IsShowingAboutWindow()
; Parameters ....: None
; Return values .: Returns True while the About window is shown. False otherwise or DLL not loaded.
; ===============================================================================================================================
Func _ImGui_IsShowingAboutWindow()
    Return __ImGui_IsShowingDebugWindow("ImGui_IsShowingAboutWindow")
EndFunc

; --- Settings persistence (D.4, opt-in) -------------------------------------
; Save / restore ImGui's window state (top-level WindowWidget positions, sizes,
; collapsed flags) to/from an .ini file. Opt-in : `io.IniFilename = nullptr`
; in the DLL init disables auto-save, so the bot doesn't litter random .ini
; files next to scripts. Choose your own path here.
;
; Canonical pattern :
;   _ImGui_Init(...)
;   _ImGui_LoadSettings(@ScriptDir & "\my_bot.ini")    ; populate cache BEFORE
;   _ImGui_CreateWindow("debug", ...)                  ; first Begin() applies
;   ; ... user moves/resizes windows during use ...
;   OnAutoItExitRegister(SaveOnExit)                   ; or call on a Save button
;
; Loading AFTER creating windows does NOT retroactively move them — ImGui only
; applies cached state on a window's first appearance. Use _ImGui_SetWindowPos
; etc. for that case.
;
; Returns True on success. SetError(2)/@extended = 2 means "path is empty",
; SetError(3) means "DLL not initialized". Missing file on Load is a silent
; no-op (returns True).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_LoadSettings
; Description ...: Load ImGui window state (positions, sizes, collapsed flags) from an .ini file
; Syntax.........: _ImGui_LoadSettings($sPath)
; Parameters ....: $sPath       - Path to the .ini file (UTF-8). Missing file is a silent no-op.
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed or empty path,
;                  3=DLL not initialized)
; Information ...: Cached state is applied at each window's first Begin() — call BEFORE _ImGui_CreateWindow.
;                  Loading after window creation does NOT retroactively move them ; use _ImGui_SetWindowPos for that.
; ===============================================================================================================================
Func _ImGui_LoadSettings($sPath)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_LoadSettings", "wstr", $sPath)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] = 1 Then Return SetError(3, 1, False)
    If $aRet[0] = 2 Then Return SetError(2, 2, False)
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SaveSettings
; Description ...: Save the current ImGui window state to an .ini file
; Syntax.........: _ImGui_SaveSettings($sPath)
; Parameters ....: $sPath       - Path to the .ini file (UTF-8) ; overwritten if it exists
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed or empty path,
;                  3=DLL not initialized)
; Information ...: Auto-save is disabled by the DLL ($io.IniFilename = nullptr) ; call this explicitly on a
;                  Save button or via OnAutoItExitRegister to persist the user's layout.
; ===============================================================================================================================
Func _ImGui_SaveSettings($sPath)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SaveSettings", "wstr", $sPath)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] = 1 Then Return SetError(3, 1, False)
    If $aRet[0] = 2 Then Return SetError(2, 2, False)
    Return True
EndFunc

; --- Settings memory variants (J.4) ------------------------------------------
; Same payload format as the on-disk variants, but the caller owns the buffer.
; Typical usage : carry settings inside a larger user-defined save file (game
; profile, encrypted vault, etc.) without hitting a temporary .ini.

; Apply an ini blob produced earlier by _ImGui_SaveSettingsToMemory or by reading
; an .ini file. Same caveat as _ImGui_LoadSettings : only takes effect on each
; window's first Begin().
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_LoadSettingsFromMemory
; Description ...: Apply an in-memory ini blob produced by _ImGui_SaveSettingsToMemory
; Syntax.........: _ImGui_LoadSettingsFromMemory($sIniData)
; Parameters ....: $sIniData    - Ini-format string (UTF-8)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Same caveat as _ImGui_LoadSettings : only takes effect at each window's first Begin().
;                  Use to carry settings inside a larger user-defined save file without a temp .ini.
; ===============================================================================================================================
Func _ImGui_LoadSettingsFromMemory($sIniData)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_LoadSettingsFromMemory", _
        "wstr", $sIniData)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Snapshot the current settings to a string. $iBufSize caps the result (in
; wchar) ; raise it if you have many windows. Status 4 = truncated (the result
; is still valid up to capacity-1, but downstream Load would miss late entries).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SaveSettingsToMemory
; Description ...: Snapshot the current ImGui settings to a string buffer
; Syntax.........: _ImGui_SaveSettingsToMemory([$iBufSize = 8192])
; Parameters ....: $iBufSize    - Output buffer capacity in wchars (raise for many windows)
; Return values .: Returns the settings ini blob on success. Empty string with @error set
;                  (1=DLL not loaded, 2=DllCall failed, 3=DLL status non-zero and non-truncation).
; Information ...: Status 4 means the buffer was truncated ; bump $iBufSize and retry.
; ===============================================================================================================================
Func _ImGui_SaveSettingsToMemory($iBufSize = 8192)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, "")
    Local $tBuf = DllStructCreate("wchar buf[" & $iBufSize & "]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SaveSettingsToMemory", _
        "ptr", DllStructGetPtr($tBuf), "int", $iBufSize)
    If @error Then Return SetError(2, @error, "")
    If $aRet[0] <> 0 And $aRet[0] <> 4 Then Return SetError(3, $aRet[0], "")
    Return DllStructGetData($tBuf, "buf")
EndFunc

; Returns the embedded ImGui version string (e.g. "1.92.8"). Empty string
; on error. The DLL writes UTF-16 into a 32-wchar buffer — plenty for any
; conceivable version string.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetVersion
; Description ...: Return the embedded ImGui version string (e.g. "1.92.8")
; Syntax.........: _ImGui_GetVersion()
; Parameters ....: None
; Return values .: Returns the version string on success. Empty string with @error set
;                  (1=DLL not loaded, 2=DllCall failed, 3=DLL status non-zero and non-truncation).
; ===============================================================================================================================
Func _ImGui_GetVersion()
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, "")
    Local $tBuf = DllStructCreate("wchar buf[32]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetVersion", _
        "ptr", DllStructGetPtr($tBuf), "int", 32)
    If @error Then Return SetError(2, @error, "")
    ; status 0 = ok, 4 = truncated (still usable string up to cap-1)
    If $aRet[0] <> 0 And $aRet[0] <> 4 Then Return SetError(3, $aRet[0], "")
    Return DllStructGetData($tBuf, "buf")
EndFunc

; Show/hide a widget — also hides its whole subtree if it's a container.
; Useful to re-show a Window after the user clicked its X (which sets
; visible=false on the widget).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetVisible
; Description ...: Show or hide a widget (and its whole subtree if it is a container)
; Syntax.........: _ImGui_SetVisible($sId, $bVisible)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $bVisible    - True to show, False to hide
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Use to re-show a Window after the user clicked its X (which sets visible=false on the widget).
; ===============================================================================================================================
Func _ImGui_SetVisible($sId, $bVisible)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iVal = $bVisible ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetVisible", "wstr", $sId, "int", $iVal)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetVisible
; Description ...: Report the current visibility flag of a widget
; Syntax.........: _ImGui_GetVisible($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True when visible. False when hidden, unknown, or DLL not loaded (no @error).
; ===============================================================================================================================
Func _ImGui_GetVisible($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetVisible", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; --- WindowWidget (hand-written, used to live in imgui_generated.au3 before
; Phase D.3 moved it back here to support pending-state setters + window-level
; latched queries). Same signature as before, scripts don't need to change.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateWindow
; Description ...: Create a top-level Window widget (Begin/End scope, draggable and resizable)
; Syntax.........: _ImGui_CreateWindow($sId[, $sTitle = "", $bClosable = True, $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sTitle      - Displayed title (empty = falls back to $sId)
;                  $bClosable   - True = add an X close button
;                  $iFlags      - Bitmask of $ImGuiWindowFlags_*
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Exposes window-level latched queries (_ImGui_IsWindow*) and pending-state setters (D.3).
; ===============================================================================================================================
Func _ImGui_CreateWindow($sId, $sTitle = "", $bClosable = True, $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sTitle = "" Then $sTitle = $sId
    Local $iClos = $bClosable ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateWindow", _
        "wstr", $sId, "wstr", $sTitle, "int", $iClos, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Window manipulation (D.3) ----------------------------------------------
; Each setter queues a one-shot ImGui::SetNextWindow*() call to apply at the
; next Render(). Strict semantics : these never latch any user-facing flag.
;
; $iCond is one of $ImGuiCond_* (0 = Always by default — sets every frame).
; Use $ImGuiCond_Once or $ImGuiCond_FirstUseEver to seed a position once and
; let the user move it freely afterwards.
;
; Return codes (all setters) : True on success ; SetError with @extended
; carrying the DLL status (2=unknown id, 3=not a window) on failure.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetWindowPos
; Description ...: Queue a one-shot ImGui::SetNextWindowPos for the next Render
; Syntax.........: _ImGui_SetWindowPos($sId, $fX, $fY[, $iCond = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fX / $fY    - X / Y coordinate in pixels
;                  $iCond       - Condition flag ($ImGuiCond_Always/Once/FirstUseEver/Appearing)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a window — @extended carries the DLL status)
; Information ...: Use $ImGuiCond_Once or _FirstUseEver to seed a position once and let the user move it freely.
; ===============================================================================================================================
Func _ImGui_SetWindowPos($sId, $fX, $fY, $iCond = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetWindowPos", _
        "wstr", $sId, "float", $fX, "float", $fY, "int", $iCond)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetWindowSize
; Description ...: Queue a one-shot ImGui::SetNextWindowSize for the next Render
; Syntax.........: _ImGui_SetWindowSize($sId, $fW, $fH[, $iCond = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fW          - Width in pixels (0 = auto)
;                  $fH          - Height in pixels (0 = auto)
;                  $iCond       - Condition flag ($ImGuiCond_Always/Once/FirstUseEver/Appearing)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a window)
; ===============================================================================================================================
Func _ImGui_SetWindowSize($sId, $fW, $fH, $iCond = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetWindowSize", _
        "wstr", $sId, "float", $fW, "float", $fH, "int", $iCond)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetWindowCollapsed
; Description ...: Queue a one-shot ImGui::SetNextWindowCollapsed for the next Render
; Syntax.........: _ImGui_SetWindowCollapsed($sId, $bCollapsed[, $iCond = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $bCollapsed  - True = collapse to title bar, False = expand
;                  $iCond       - Condition flag ($ImGuiCond_Always/Once/FirstUseEver/Appearing)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a window)
; ===============================================================================================================================
Func _ImGui_SetWindowCollapsed($sId, $bCollapsed, $iCond = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iVal = $bCollapsed ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetWindowCollapsed", _
        "wstr", $sId, "int", $iVal, "int", $iCond)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; One-shot focus — calls ImGui::SetNextWindowFocus at the next Render. The
; window will be brought to front and gain keyboard focus.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetWindowFocus
; Description ...: Bring the window to the front and give it keyboard focus
; Syntax.........: _ImGui_SetWindowFocus($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a window)
; Information ...: One-shot — applied at the next Render via ImGui::SetNextWindowFocus.
; ===============================================================================================================================
Func _ImGui_SetWindowFocus($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetWindowFocus", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; Background alpha [0.0 = fully transparent, 1.0 = opaque]. Clamped DLL-side.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetWindowBgAlpha
; Description ...: Set the background alpha of the window for the next Render
; Syntax.........: _ImGui_SetWindowBgAlpha($sId, $fAlpha)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fAlpha      - Alpha value [0.0 - 1.0] (clamped DLL-side)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a window)
; ===============================================================================================================================
Func _ImGui_SetWindowBgAlpha($sId, $fAlpha)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetWindowBgAlpha", _
        "wstr", $sId, "float", $fAlpha)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; Min / max size for user resize. Pass 0 (or any non-positive value) for
; max_w/max_h to mean "no limit" (DLL maps to FLT_MAX).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetWindowSizeConstraints
; Description ...: Constrain the user-resize range of the window
; Syntax.........: _ImGui_SetWindowSizeConstraints($sId, $fMinW, $fMinH[, $fMaxW = 0, $fMaxH = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fMinW       - Minimum width in pixels
;                  $fMinH       - Minimum height in pixels
;                  $fMaxW       - Maximum width in pixels (0 or any non-positive = no limit, mapped to FLT_MAX)
;                  $fMaxH       - Maximum height in pixels (0 or any non-positive = no limit, mapped to FLT_MAX)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a window)
; ===============================================================================================================================
Func _ImGui_SetWindowSizeConstraints($sId, $fMinW, $fMinH, $fMaxW = 0, $fMaxH = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetWindowSizeConstraints", _
        "wstr", $sId, "float", $fMinW, "float", $fMinH, "float", $fMaxW, "float", $fMaxH)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; --- Window content size & next-frame scroll (J.3) ---------------------------
; SetWindowContentSize pins the content area used to compute scrollbar extents
; when ScrollX/Y is active. Pass 0 on an axis to let ImGui auto-fit. Re-call
; each frame to keep the override active (matches ImGui's SetNextWindow* shape).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetWindowContentSize
; Description ...: Pin the content area used to compute scrollbar extents when ScrollX/Y is active
; Syntax.........: _ImGui_SetWindowContentSize($sId, $fW, $fH)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fW          - Content width in pixels (0 = auto-fit on this axis)
;                  $fH          - Content height in pixels (0 = auto-fit on this axis)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a window)
; Information ...: Re-call each frame to keep the override active (matches ImGui's SetNextWindow* shape).
; ===============================================================================================================================
Func _ImGui_SetWindowContentSize($sId, $fW, $fH)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetWindowContentSize", _
        "wstr", $sId, "float", $fW, "float", $fH)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; Set scroll BEFORE the window's next Begin (one-shot SetNextWindowScroll). This
; is the right call to restore a saved scroll position when the window opens.
; Distinct from _ImGui_SetScrollX/Y (H.1) which fires AFTER children render and
; gives the "scroll to bottom" semantics for a log panel.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetWindowScroll
; Description ...: Set the window scroll position BEFORE its next Begin (one-shot SetNextWindowScroll)
; Syntax.........: _ImGui_SetWindowScroll($sId, $fX, $fY)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fX / $fY    - Target scroll offset in pixels
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a window)
; Information ...: Use to restore a saved scroll position when the window opens. Distinct from
;                  _ImGui_SetScrollX/Y (H.1) which fires AFTER children render ("scroll to bottom" semantics).
; ===============================================================================================================================
Func _ImGui_SetWindowScroll($sId, $fX, $fY)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetWindowScroll", _
        "wstr", $sId, "float", $fX, "float", $fY)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; Window-level latched queries — distinct from _ImGui_IsHovered / IsFocused
; which are ImGui::IsItem*() (the window as the last-rendered item).
; IsWindow* checks the window as an entity, including its child contents.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsWindowAppearing
; Description ...: Report whether the window is on its first frame after becoming visible
; Syntax.........: _ImGui_IsWindowAppearing($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True on the first frame the window appears. False otherwise.
; Information ...: Ideal trigger for "open dialog → initialize input fields" one-shot logic.
; ===============================================================================================================================
Func _ImGui_IsWindowAppearing($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsWindowAppearing", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsWindowCollapsed
; Description ...: Report whether the window is currently collapsed (title bar only)
; Syntax.........: _ImGui_IsWindowCollapsed($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True while collapsed. False otherwise or DLL not loaded (no @error).
; ===============================================================================================================================
Func _ImGui_IsWindowCollapsed($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsWindowCollapsed", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsWindowFocused
; Description ...: Report whether the window (as an entity, including children) owns focus
; Syntax.........: _ImGui_IsWindowFocused($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True while focused. False otherwise or DLL not loaded (no @error).
; Information ...: Distinct from _ImGui_IsFocused (item-level) — IsWindow* checks the window as an entity.
; ===============================================================================================================================
Func _ImGui_IsWindowFocused($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsWindowFocused", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsWindowHovered
; Description ...: Report whether the window (as an entity, including children) is currently hovered
; Syntax.........: _ImGui_IsWindowHovered($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns True while hovered. False otherwise or DLL not loaded (no @error).
; Information ...: Use _ImGui_IsWindowHoveredEx (K.1) for the variant that honors HoveredFlags.
; ===============================================================================================================================
Func _ImGui_IsWindowHovered($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsWindowHovered", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; Returns array[2] = (x, y) ; SetError(3) on unknown id / not a window.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetWindowPos
; Description ...: Read the current window position in ImGui screen-space
; Syntax.........: _ImGui_GetWindowPos($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns array[2] = [x, y] on success. 0 with @error set (1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a window).
; ===============================================================================================================================
Func _ImGui_GetWindowPos($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $tBuf = DllStructCreate("float buf[2]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetWindowPos", _
        "wstr", $sId, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Local $aOut[2] = [DllStructGetData($tBuf, "buf", 1), DllStructGetData($tBuf, "buf", 2)]
    Return $aOut
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetWindowSize
; Description ...: Read the current window size in pixels
; Syntax.........: _ImGui_GetWindowSize($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns array[2] = [width, height] on success. 0 with @error set (1=DLL not loaded,
;                  2=DllCall failed, 3=unknown id or not a window).
; ===============================================================================================================================
Func _ImGui_GetWindowSize($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $tBuf = DllStructCreate("float buf[2]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetWindowSize", _
        "wstr", $sId, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Local $aOut[2] = [DllStructGetData($tBuf, "buf", 1), DllStructGetData($tBuf, "buf", 2)]
    Return $aOut
EndFunc

; --- ChildWidget + Scroll helpers (hand-written, H.1) ------------------------
; ChildWidget used to be generator-emitted ; H.1 extracted it to expose a
; ScrollableState (latched scroll position + pending Set* one-shots). The
; signature is unchanged so old callers (4-arg, no $sLabel) keep working.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateChild
; Description ...: Create a Child widget (scrollable sub-region inside a window)
; Syntax.........: _ImGui_CreateChild($sId[, $sLabel = "", $fW = 0, $fH = 0, $bBorder = False])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Optional displayed label (empty for unlabeled child)
;                  $fW          - Width in pixels (0 = auto)
;                  $fH          - Height in pixels (0 = auto)
;                  $bBorder     - True to render a 1-pixel border around the child region
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Exposes ScrollableState — combine with _ImGui_GetScroll* / _ImGui_SetScroll* for log panels.
; ===============================================================================================================================
Func _ImGui_CreateChild($sId, $sLabel = "", $fW = 0, $fH = 0, $bBorder = False)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iBorder = $bBorder ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateChild", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fW, "float", $fH, "int", $iBorder)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Read latched scroll state. Works on Window and Child widgets.
; @extended carries the DLL status on failure (2=unknown id, 3=widget not scrollable).
; Returns 0.0 on error.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetScrollX
; Description ...: Read the current horizontal scroll offset of a Window or Child widget
; Syntax.........: _ImGui_GetScrollX($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns the scroll offset in pixels on success. 0.0 with @error set (1=DLL not loaded,
;                  2=DllCall failed, 3=widget not scrollable — @extended carries the DLL status).
; ===============================================================================================================================
Func _ImGui_GetScrollX($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0.0)
    Local $tBuf = DllStructCreate("float v")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetScrollX", _
        "wstr", $sId, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0.0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0.0)
    Return DllStructGetData($tBuf, "v")
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetScrollY
; Description ...: Read the current vertical scroll offset of a Window or Child widget
; Syntax.........: _ImGui_GetScrollY($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns the scroll offset in pixels on success. 0.0 with @error set (1=DLL not loaded,
;                  2=DllCall failed, 3=widget not scrollable).
; ===============================================================================================================================
Func _ImGui_GetScrollY($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0.0)
    Local $tBuf = DllStructCreate("float v")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetScrollY", _
        "wstr", $sId, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0.0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0.0)
    Return DllStructGetData($tBuf, "v")
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetScrollMaxX
; Description ...: Read the maximum horizontal scroll offset of a Window or Child widget
; Syntax.........: _ImGui_GetScrollMaxX($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns the max scroll offset in pixels on success. 0.0 with @error set
;                  (1=DLL not loaded, 2=DllCall failed, 3=widget not scrollable).
; Information ...: Use (scroll == max) to detect "scrolled to the end" for stickiness logic.
; ===============================================================================================================================
Func _ImGui_GetScrollMaxX($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0.0)
    Local $tBuf = DllStructCreate("float v")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetScrollMaxX", _
        "wstr", $sId, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0.0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0.0)
    Return DllStructGetData($tBuf, "v")
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetScrollMaxY
; Description ...: Read the maximum vertical scroll offset of a Window or Child widget
; Syntax.........: _ImGui_GetScrollMaxY($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns the max scroll offset in pixels on success. 0.0 with @error set
;                  (1=DLL not loaded, 2=DllCall failed, 3=widget not scrollable).
; ===============================================================================================================================
Func _ImGui_GetScrollMaxY($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0.0)
    Local $tBuf = DllStructCreate("float v")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetScrollMaxY", _
        "wstr", $sId, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0.0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0.0)
    Return DllStructGetData($tBuf, "v")
EndFunc

; One-shot scroll setters. Consumed at the END of the target widget's next
; Render (after children, before End/EndChild) so SetScrollHere uses the
; cursor's final position — canonical "scroll to bottom" of a log panel.
; All never latch the widget's `changed` flag (strict semantics).

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetScrollX
; Description ...: Queue a one-shot horizontal scroll position for the next Render
; Syntax.........: _ImGui_SetScrollX($sId, $fScroll)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fScroll     - Target scroll offset in pixels
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Consumed AFTER children render (end of the widget's Render pass). Does not latch
;                  any user-facing flag — see [[imgui_retained_strict_changed]].
; ===============================================================================================================================
Func _ImGui_SetScrollX($sId, $fScroll)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetScrollX", _
        "wstr", $sId, "float", $fScroll)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetScrollY
; Description ...: Queue a one-shot vertical scroll position for the next Render
; Syntax.........: _ImGui_SetScrollY($sId, $fScroll)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fScroll     - Target scroll offset in pixels
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; ===============================================================================================================================
Func _ImGui_SetScrollY($sId, $fScroll)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetScrollY", _
        "wstr", $sId, "float", $fScroll)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; $fCenterRatio : 0.0 = top/left, 0.5 = center (default), 1.0 = bottom/right.
; Typical usage : SetScrollHereY(1.0) right after appending a log line to
; follow the bottom of the panel.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetScrollHereX
; Description ...: Scroll horizontally so the current cursor position lands at $fCenterRatio of the viewport
; Syntax.........: _ImGui_SetScrollHereX($sId[, $fCenterRatio = 0.5])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fCenterRatio - 0.0 = left, 0.5 = center, 1.0 = right
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Consumed at the END of the target widget's Render (uses cursor's final position).
; ===============================================================================================================================
Func _ImGui_SetScrollHereX($sId, $fCenterRatio = 0.5)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetScrollHereX", _
        "wstr", $sId, "float", $fCenterRatio)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetScrollHereY
; Description ...: Scroll vertically so the current cursor position lands at $fCenterRatio of the viewport
; Syntax.........: _ImGui_SetScrollHereY($sId[, $fCenterRatio = 0.5])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fCenterRatio - 0.0 = top, 0.5 = center, 1.0 = bottom
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Canonical pattern : call SetScrollHereY(1.0) right after appending a log line to follow the bottom.
; ===============================================================================================================================
Func _ImGui_SetScrollHereY($sId, $fCenterRatio = 0.5)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetScrollHereY", _
        "wstr", $sId, "float", $fCenterRatio)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Scroll so that the window-local pixel position $fLocalPos lands at
; $fCenterRatio of the visible region. Niche but bien défini : "scroll so that
; the row at y=420px is shown 25% from the top" → SetScrollFromPosY(420, 0.25).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetScrollFromPosX
; Description ...: Scroll horizontally so a window-local X position lands at $fCenterRatio of the viewport
; Syntax.........: _ImGui_SetScrollFromPosX($sId, $fLocalPos[, $fCenterRatio = 0.5])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fLocalPos   - Target X position in window-local pixels
;                  $fCenterRatio - 0.0 = left, 0.5 = center, 1.0 = right
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; ===============================================================================================================================
Func _ImGui_SetScrollFromPosX($sId, $fLocalPos, $fCenterRatio = 0.5)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetScrollFromPosX", _
        "wstr", $sId, "float", $fLocalPos, "float", $fCenterRatio)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetScrollFromPosY
; Description ...: Scroll vertically so a window-local Y position lands at $fCenterRatio of the viewport
; Syntax.........: _ImGui_SetScrollFromPosY($sId, $fLocalPos[, $fCenterRatio = 0.5])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fLocalPos   - Target Y position in window-local pixels
;                  $fCenterRatio - 0.0 = top, 0.5 = center, 1.0 = bottom
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: e.g. "scroll so the row at y=420px is shown 25% from the top" → SetScrollFromPosY($sId, 420, 0.25).
; ===============================================================================================================================
Func _ImGui_SetScrollFromPosY($sId, $fLocalPos, $fCenterRatio = 0.5)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetScrollFromPosY", _
        "wstr", $sId, "float", $fLocalPos, "float", $fCenterRatio)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Tables (hand-written, Phase I) ------------------------------------------
; Container : create the table, declare columns via _ImGui_TableSetupColumn,
; optionally lock leading rows/cols with _ImGui_TableSetupScrollFreeze, then
; add row + cell markers + content widgets as children (in tree order). At
; each frame, the DLL emits the right BeginTable / TableSetupColumn / Headers
; / NextRow / NextColumn / EndTable sequence.
;
; Cells are NOT containers — content widgets (Text, Button, …) are siblings
; AFTER the matching TableNextColumn marker, at the parent table's children
; level. Mirrors how ImGui's table API actually behaves.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTable
; Description ...: Create a Table container widget (BeginTable scope)
; Syntax.........: _ImGui_CreateTable($sId, $iColumns[, $iFlags = 0, $fOuterW = 0, $fOuterH = 0, $fInnerW = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iColumns    - Number of columns
;                  $iFlags      - Bitmask of $ImGuiTableFlags_*
;                  $fOuterW     - Outer width in pixels (0 = use available)
;                  $fOuterH     - Outer height in pixels (0 = auto)
;                  $fInnerW     - Inner width override in pixels (0 = auto)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Add columns via _ImGui_TableSetupColumn BEFORE any row, then attach row/cell markers
;                  + content widgets as children in tree order.
; ===============================================================================================================================
Func _ImGui_CreateTable($sId, $iColumns, $iFlags = 0, $fOuterW = 0, $fOuterH = 0, $fInnerW = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTable", _
        "wstr", $sId, "int", $iColumns, "int", $iFlags, _
        "float", $fOuterW, "float", $fOuterH, "float", $fInnerW)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Append a column config to the table. MUST be called after _ImGui_CreateTable
; but BEFORE adding rows. Order matters — columns are emitted in call order.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_TableSetupColumn
; Description ...: Append a column configuration to a table (label, flags, sizing)
; Syntax.........: _ImGui_TableSetupColumn($sTableId, $sLabel[, $iFlags = 0, $fWidthOrWeight = 0.0])
; Parameters ....: $sTableId    - Parent table identifier
;                  $sLabel      - Column header label (UTF-8)
;                  $iFlags      - Bitmask of $ImGuiTableColumnFlags_*
;                  $fWidthOrWeight - Initial fixed width in pixels, or weight if Stretch is set
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a table)
; Information ...: MUST be called after _ImGui_CreateTable and BEFORE adding any row. Call order = column order.
; ===============================================================================================================================
Func _ImGui_TableSetupColumn($sTableId, $sLabel, $iFlags = 0, $fWidthOrWeight = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_TableSetupColumn", _
        "wstr", $sTableId, "wstr", $sLabel, _
        "int", $iFlags, "float", $fWidthOrWeight)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; Lock the leading $iCols columns + $iRows rows so they stay visible during
; ScrollX/ScrollY. Set ONCE after Create — sticky for the lifetime of the table.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_TableSetupScrollFreeze
; Description ...: Lock leading columns and/or rows so they stay visible during ScrollX/ScrollY
; Syntax.........: _ImGui_TableSetupScrollFreeze($sTableId, $iCols, $iRows)
; Parameters ....: $sTableId    - Parent table identifier
;                  $iCols       - Number of leading columns to freeze
;                  $iRows       - Number of leading rows to freeze
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a table)
; Information ...: Set ONCE after _ImGui_CreateTable — sticky for the lifetime of the table.
; ===============================================================================================================================
Func _ImGui_TableSetupScrollFreeze($sTableId, $iCols, $iRows)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_TableSetupScrollFreeze", _
        "wstr", $sTableId, "int", $iCols, "int", $iRows)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; Read the latched sort spec : returns array[2] = [col_index, direction].
; col_index = -1 when no sort active (table not Sortable, or SortTristate with
; no column selected). direction = 0=None / 1=Asc / 2=Desc.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_TableGetSortSpecs
; Description ...: Read the active single-column sort spec of a sortable table
; Syntax.........: _ImGui_TableGetSortSpecs($sTableId)
; Parameters ....: $sTableId    - Parent table identifier
; Return values .: Returns array[2] = [col_index, direction] on success. 0 with @error set on failure.
;                  col_index = -1 when no sort active. direction = 0=None / 1=Asc / 2=Desc.
; Information ...: For SortMulti tables (multi-column sort) use _ImGui_TableGetSortSpecsN instead.
; ===============================================================================================================================
Func _ImGui_TableGetSortSpecs($sTableId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $tBuf = DllStructCreate("int spec[2]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_TableGetSortSpecs", _
        "wstr", $sTableId, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Local $aOut[2] = [DllStructGetData($tBuf, "spec", 1), DllStructGetData($tBuf, "spec", 2)]
    Return $aOut
EndFunc

; Marker widgets — place them in the table's children list, intermixed with
; content widgets. Tree order matters : a TableNextColumn must come BEFORE
; the widgets that should render into that cell.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTableHeadersRow
; Description ...: Emit the standard TableHeadersRow marker (one header per column with labels)
; Syntax.........: _ImGui_CreateTableHeadersRow($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Place as a child of the table BEFORE any row marker. Use _ImGui_CreateTableHeader
;                  for per-cell custom layouts (icon + text, etc.).
; ===============================================================================================================================
Func _ImGui_CreateTableHeadersRow($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTableHeadersRow", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTableNextRow
; Description ...: Emit a TableNextRow marker that advances to a new row
; Syntax.........: _ImGui_CreateTableNextRow($sId[, $iRowFlags = 0, $fMinHeight = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iRowFlags   - Bitmask of $ImGuiTableRowFlags_* (Headers, etc.)
;                  $fMinHeight  - Minimum row height in pixels (0 = default)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Tree order matters : must come BEFORE the TableNextColumn markers + content of that row.
; ===============================================================================================================================
Func _ImGui_CreateTableNextRow($sId, $iRowFlags = 0, $fMinHeight = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTableNextRow", _
        "wstr", $sId, "int", $iRowFlags, "float", $fMinHeight)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTableNextColumn
; Description ...: Emit a TableNextColumn marker that advances to the next cell
; Syntax.........: _ImGui_CreateTableNextColumn($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Place AFTER TableNextRow, BEFORE the widget(s) that should render in this cell.
; ===============================================================================================================================
Func _ImGui_CreateTableNextColumn($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTableNextColumn", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTableSetColumnIndex
; Description ...: Emit a TableSetColumnIndex marker that jumps to a specific column
; Syntax.........: _ImGui_CreateTableSetColumnIndex($sId, $iColumnIndex)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iColumnIndex - 0-based column index to switch to
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateTableSetColumnIndex($sId, $iColumnIndex)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTableSetColumnIndex", _
        "wstr", $sId, "int", $iColumnIndex)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Tables runtime extras (J.5) --------------------------------------------

; Toggle a column's enabled state at runtime (column visibility — the user can
; also do this via the table context menu when the Hideable flag is set). The
; toggle is queued and applied at the next BeginTable() scope. Successive
; toggles on the same column coalesce.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_TableSetColumnEnabled
; Description ...: Toggle a column's enabled state at runtime
; Syntax.........: _ImGui_TableSetColumnEnabled($sTableId, $iColumn, $bEnabled)
; Parameters ....: $sTableId    - Parent table identifier
;                  $iColumn     - 0-based column index
;                  $bEnabled    - True to enable (visible), False to hide
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or invalid column)
; Information ...: Queued and applied at the next BeginTable() scope. Successive toggles on the same column coalesce.
; ===============================================================================================================================
Func _ImGui_TableSetColumnEnabled($sTableId, $iColumn, $bEnabled)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iVal = $bEnabled ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_TableSetColumnEnabled", _
        "wstr", $sTableId, "int", $iColumn, "int", $iVal)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; Marker widget — set the background color of a row or cell. Place as a sibling
; of TableNextRow/TableNextColumn, AFTER the marker that targets the row/cell.
; $iTarget : $ImGuiTableBgTarget_RowBg0 / _RowBg1 / _CellBg.
; $iU32Color : packed ImU32 (use _ImGui_ColorFloat4ToU32 to build).
; $iColumnN : -1 = current cell (CellBg) / current row (RowBg* — ignored).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTableSetBgColor
; Description ...: Emit a marker that sets the background color of a row or cell
; Syntax.........: _ImGui_CreateTableSetBgColor($sId, $iTarget, $iU32Color[, $iColumnN = -1])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iTarget     - $ImGuiTableBgTarget_RowBg0 / _RowBg1 / _CellBg
;                  $iU32Color   - Packed ImU32 color (use _ImGui_ColorFloat4ToU32 to build)
;                  $iColumnN    - -1 = current cell (CellBg) or current row (RowBg* — ignored)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Place as a sibling of TableNextRow/TableNextColumn, AFTER the marker targeting the row/cell.
; ===============================================================================================================================
Func _ImGui_CreateTableSetBgColor($sId, $iTarget, $iU32Color, $iColumnN = -1)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTableSetBgColor", _
        "wstr", $sId, "int", $iTarget, "uint", $iU32Color, "int", $iColumnN)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Single-cell header. Place AFTER a TableNextRow($ImGuiTableRowFlags_Headers)
; and a TableNextColumn / TableSetColumnIndex marker. Use this when you need
; custom layout per header cell (icon + text, two-line headers, …) ; for the
; standard case use _ImGui_CreateTableHeadersRow instead.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTableHeader
; Description ...: Emit a single-cell custom header (use instead of CreateTableHeadersRow for per-cell layouts)
; Syntax.........: _ImGui_CreateTableHeader($sId, $sLabel)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Header text (UTF-8)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Place AFTER a TableNextRow($ImGuiTableRowFlags_Headers) + TableNextColumn / TableSetColumnIndex marker.
; ===============================================================================================================================
Func _ImGui_CreateTableHeader($sId, $sLabel)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTableHeader", _
        "wstr", $sId, "wstr", $sLabel)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Marker that emits an angled headers row. Requires at least one column with
; $ImGuiTableColumnFlags_AngledHeader. Useful when many columns need long
; labels — diagonal text saves horizontal space.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTableAngledHeadersRow
; Description ...: Emit a marker that renders angled (diagonal) text headers
; Syntax.........: _ImGui_CreateTableAngledHeadersRow($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Requires at least one column flagged with $ImGuiTableColumnFlags_AngledHeader.
;                  Useful when many columns need long labels — diagonals save horizontal space.
; ===============================================================================================================================
Func _ImGui_CreateTableAngledHeadersRow($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTableAngledHeadersRow", _
        "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Tables multi-column sort spec query (J.6) ------------------------------
; Read the FULL sort spec list from a table flagged with $ImGuiTableFlags_SortMulti.
; Returns a 2D AutoIt array $aOut[N][2] where each row is (col_index, direction)
; in priority order ; N is the actual number of active sort specs (0 = no sort,
; >=1 means a sort is active). $iMaxSpecs caps the result (default 4 — plenty
; for any practical table).
;
; On error : returns an empty array $aRet[0][2] and sets @error / @extended.
; Error codes (negative DLL return) : -1 = bad args, -2 = unknown id, -3 = not
; a table.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_TableGetSortSpecsN
; Description ...: Read the full multi-column sort spec list of a SortMulti-flagged table
; Syntax.........: _ImGui_TableGetSortSpecsN($sTableId[, $iMaxSpecs = 4])
; Parameters ....: $sTableId    - Parent table identifier
;                  $iMaxSpecs   - Maximum number of specs to return (caps the result)
; Return values .: Returns 2D array $aOut[N][2] where each row is (col_index, direction) in priority order.
;                  Empty array $aOut[0][2] when no sort active. Sets @error on failure (3=table error,
;                  @extended carries the C-side code : 1=bad args, 2=unknown id, 3=not a table).
; ===============================================================================================================================
Func _ImGui_TableGetSortSpecsN($sTableId, $iMaxSpecs = 4)
    Local $aOut[1][2] = [[-1, 0]]
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, $aOut)
    If $iMaxSpecs < 1 Then $iMaxSpecs = 1
    Local $tBuf = DllStructCreate("int pairs[" & ($iMaxSpecs * 2) & "]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_TableGetSortSpecsN", _
        "wstr", $sTableId, "ptr", DllStructGetPtr($tBuf), "int", $iMaxSpecs)
    If @error Then Return SetError(2, @error, $aOut)
    Local $n = $aRet[0]
    If $n < 0 Then Return SetError(3, -$n, $aOut)
    If $n = 0 Then
        Local $aEmpty[0][2]
        Return $aEmpty
    EndIf
    Local $aSpecs[$n][2]
    For $i = 0 To $n - 1
        $aSpecs[$i][0] = DllStructGetData($tBuf, "pairs", $i * 2 + 1)
        $aSpecs[$i][1] = DllStructGetData($tBuf, "pairs", $i * 2 + 2)
    Next
    Return $aSpecs
EndFunc

; =============================================================================
; Phase M.1 — Tables column queries (count + per-cell index/flags/name).
; =============================================================================

; Constant for the frame once BeginTable opened — read the latched column count
; off the table widget directly (no marker needed). Returns count (>=0) or 0
; on any error (with @error set : 1=DLL not loaded, 2=DllCall failed,
; 3=negative status — @extended carries the C-side code 1/2/3).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_TableGetColumnCount
; Description ...: Read the latched column count of a table (constant for the current frame)
; Syntax.........: _ImGui_TableGetColumnCount($sTableId)
; Parameters ....: $sTableId    - Parent table identifier
; Return values .: Returns the column count (>=0) on success. 0 with @error set on failure
;                  (1=DLL not loaded, 2=DllCall failed, 3=negative status — @extended carries the C-side code).
; ===============================================================================================================================
Func _ImGui_TableGetColumnCount($sTableId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_TableGetColumnCount", _
        "wstr", $sTableId)
    If @error Then Return SetError(2, @error, 0)
    Local $n = $aRet[0]
    If $n < 0 Then Return SetError(3, -$n, 0)
    Return $n
EndFunc

; Marker widget — place as a child of the TableWidget, AFTER the TableNextColumn
; (or TableSetColumnIndex) targeting the column to query. Read back the latched
; values with _ImGui_GetTableColumnIndex / Flags / Name keyed on the marker id.
; $iColumnN = -1 means "use current column" ; non-negative = query that explicit
; column index regardless of cursor position.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTableGetColumnInfo
; Description ...: Emit a marker that latches per-column info (index, flags, name) for later readback
; Syntax.........: _ImGui_CreateTableGetColumnInfo($sId[, $iColumnN = -1])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iColumnN    - -1 = current column (uses cursor) ; >=0 = explicit column index
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Place as a child of the TableWidget, AFTER the TableNextColumn / TableSetColumnIndex
;                  marker targeting the column to query. Read back with _ImGui_GetTableColumn{Index,Flags,Name}.
; ===============================================================================================================================
Func _ImGui_CreateTableGetColumnInfo($sId, $iColumnN = -1)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTableGetColumnInfo", _
        "wstr", $sId, "int", $iColumnN)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Returns the latched column index (>=0), -1 when the marker last rendered
; outside any TableNextColumn scope. On error returns -1 + sets @error.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetTableColumnIndex
; Description ...: Read the latched column index of a TableGetColumnInfo marker
; Syntax.........: _ImGui_GetTableColumnIndex($sMarkerId)
; Parameters ....: $sMarkerId   - Identifier of the matching _ImGui_CreateTableGetColumnInfo marker
; Return values .: Returns the column index (>=0) on success. -1 when the marker rendered outside any
;                  TableNextColumn scope, or with @error set on failure.
; ===============================================================================================================================
Func _ImGui_GetTableColumnIndex($sMarkerId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, -1)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetTableColumnIndex", _
        "wstr", $sMarkerId)
    If @error Then Return SetError(2, @error, -1)
    Local $n = $aRet[0]
    If $n < -1 Then Return SetError(3, -$n, -1)
    Return $n
EndFunc

; Returns the latched ImGuiTableColumnFlags_ mask (int). On error returns 0
; and sets @error (so flags=0 is distinguishable from error via @error).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetTableColumnFlags
; Description ...: Read the latched ImGuiTableColumnFlags mask of a TableGetColumnInfo marker
; Syntax.........: _ImGui_GetTableColumnFlags($sMarkerId)
; Parameters ....: $sMarkerId   - Identifier of the matching _ImGui_CreateTableGetColumnInfo marker
; Return values .: Returns the flags bitmask on success. 0 with @error set on failure
;                  (flags=0 is distinguishable from error via @error).
; ===============================================================================================================================
Func _ImGui_GetTableColumnFlags($sMarkerId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $tBuf = DllStructCreate("int flags")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetTableColumnFlags", _
        "wstr", $sMarkerId, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Return DllStructGetData($tBuf, "flags")
EndFunc

; Returns the latched column name (utf-8 decoded). Empty string when the
; column has no name (no TableSetupColumn label) ; raise $iBufSize for very
; long names. Status 4 = truncated (still returns the prefix).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetTableColumnName
; Description ...: Read the latched column name from a TableGetColumnInfo marker
; Syntax.........: _ImGui_GetTableColumnName($sMarkerId[, $iBufSize = 64])
; Parameters ....: $sMarkerId   - Identifier of the matching _ImGui_CreateTableGetColumnInfo marker
;                  $iBufSize    - Output buffer capacity in wchars (raise for very long names)
; Return values .: Returns the column name on success. Empty string if no name or with @error set
;                  (1=DLL not loaded, 2=DllCall failed, 3=DLL status non-zero and non-truncation).
; Information ...: Status 4 = truncated (still returns the prefix). Bump $iBufSize and retry.
; ===============================================================================================================================
Func _ImGui_GetTableColumnName($sMarkerId, $iBufSize = 64)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, "")
    Local $tBuf = DllStructCreate("wchar buf[" & $iBufSize & "]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetTableColumnName", _
        "wstr", $sMarkerId, "ptr", DllStructGetPtr($tBuf), "int", $iBufSize)
    If @error Then Return SetError(2, @error, "")
    If $aRet[0] <> 0 And $aRet[0] <> 4 Then Return SetError(3, $aRet[0], "")
    Return DllStructGetData($tBuf, "buf")
EndFunc

; =============================================================================
; Phase K — Extensions ciblées
; =============================================================================

; --- K.1 Hover-with-flags (item-level via marker, window-level via setter) ---

; Marker widget that latches ImGui::IsItemHovered($iFlags) — place as the
; IMMEDIATE next sibling after the target widget in the same parent's children
; list. Pattern identique à ItemTooltip (H.2). Poll via _ImGui_GetItemHoveredEx.
; $iFlags = OR de $ImGuiHoveredFlags_* (DelayShort/Long, AllowWhenBlockedByActive*, …).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateIsItemHoveredEx
; Description ...: Emit a marker that latches ImGui::IsItemHovered($iFlags) for the previous widget
; Syntax.........: _ImGui_CreateIsItemHoveredEx($sId, $iFlags)
; Parameters ....: $sId         - Stable marker identifier (must be unique in the tree)
;                  $iFlags      - Bitmask of $ImGuiHoveredFlags_* (DelayShort/Long, AllowWhenBlockedByActive*, ...)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Place as the IMMEDIATE next sibling after the target widget. Poll via _ImGui_GetItemHoveredEx.
; ===============================================================================================================================
Func _ImGui_CreateIsItemHoveredEx($sId, $iFlags)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateIsItemHoveredEx", _
        "wstr", $sId, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetItemHoveredEx
; Description ...: Read the latched flagged-hover state of an IsItemHoveredEx marker
; Syntax.........: _ImGui_GetItemHoveredEx($sId)
; Parameters ....: $sId         - Identifier of the matching _ImGui_CreateIsItemHoveredEx marker
; Return values .: Returns True while the underlying widget is hovered with the configured flags. False otherwise.
; ===============================================================================================================================
Func _ImGui_GetItemHoveredEx($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetItemHoveredEx", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; Set the hovered-flags mask for a window's IsWindowHoveredEx latch. Pass 0
; to reset (= IsWindowHovered() default = same as _ImGui_IsWindowHovered).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetWindowHoveredFlags
; Description ...: Set the hovered-flags mask used by _ImGui_IsWindowHoveredEx on this window
; Syntax.........: _ImGui_SetWindowHoveredFlags($sId, $iFlags)
; Parameters ....: $sId         - Stable window identifier (must be unique in the tree)
;                  $iFlags      - Bitmask of $ImGuiHoveredFlags_* (pass 0 to reset = default IsWindowHovered)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a window)
; ===============================================================================================================================
Func _ImGui_SetWindowHoveredFlags($sId, $iFlags)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetWindowHoveredFlags", _
        "wstr", $sId, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsWindowHoveredEx
; Description ...: Report window hover state honoring the flags configured by _ImGui_SetWindowHoveredFlags
; Syntax.........: _ImGui_IsWindowHoveredEx($sId)
; Parameters ....: $sId         - Stable window identifier (must be unique in the tree)
; Return values .: Returns True while hovered under the configured flags. False otherwise.
; Information ...: Distinct from _ImGui_IsWindowHovered which uses the default IsWindowHovered() behavior.
; ===============================================================================================================================
Func _ImGui_IsWindowHoveredEx($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsWindowHoveredEx", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; --- K.2 RadioButtonGroup --------------------------------------------------

; Create a RadioButton bound to a named group. All widgets sharing the same
; $sGroupId form an exclusive group : clicking one sets the group's value to
; the clicked widget's $iMyValue ; every other member with a different value
; renders unselected. Group state lifetime = the DLL session (wiped on
; _ImGui_Shutdown by render_thread teardown).
;
; $bDefaultActive : True initialises the group to this widget's value if the
; group has no current value yet (the first widget with $bDefaultActive=True
; wins ; subsequent ones silently no-op).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateRadioButtonGroup
; Description ...: Create a RadioButton bound to an exclusive named group
; Syntax.........: _ImGui_CreateRadioButtonGroup($sId, $sLabel, $sGroupId, $iMyValue[, $bDefaultActive = False])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label
;                  $sGroupId    - Logical group identifier — all widgets sharing it form an exclusive group
;                  $iMyValue    - Group value this widget represents (selected when group's value matches)
;                  $bDefaultActive - True initialises the group to this widget's value if not yet set
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Group state lifetime = DLL session (wiped on _ImGui_Shutdown). First widget with
;                  $bDefaultActive=True wins ; subsequent ones silently no-op.
; ===============================================================================================================================
Func _ImGui_CreateRadioButtonGroup($sId, $sLabel, $sGroupId, $iMyValue, $bDefaultActive = False)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iAct = $bDefaultActive ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateRadioButtonGroup", _
        "wstr", $sId, "wstr", $sLabel, "wstr", $sGroupId, "int", $iMyValue, "int", $iAct)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Read the current value of a group. Returns -1 if the group is unknown (no
; widget created, no SetRadioGroupValue called).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetRadioGroupValue
; Description ...: Read the currently-selected value of an exclusive RadioButton group
; Syntax.........: _ImGui_GetRadioGroupValue($sGroupId)
; Parameters ....: $sGroupId    - Group identifier passed to _ImGui_CreateRadioButtonGroup
; Return values .: Returns the active group value on success. -1 if the group is unknown or with @error set.
; ===============================================================================================================================
Func _ImGui_GetRadioGroupValue($sGroupId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, -1)
    Local $tBuf = DllStructCreate("int v")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetRadioGroupValue", _
        "wstr", $sGroupId, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, -1)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], -1)
    Return DllStructGetData($tBuf, "v")
EndFunc

; Programmatic group value setter. Never latches the clicked flag on any
; widget (strict semantics — same rule as _ImGui_SetValue*).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetRadioGroupValue
; Description ...: Programmatically select a value in an exclusive RadioButton group
; Syntax.........: _ImGui_SetRadioGroupValue($sGroupId, $iValue)
; Parameters ....: $sGroupId    - Group identifier passed to _ImGui_CreateRadioButtonGroup
;                  $iValue      - New group value to apply
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Programmatic writes never latch the clicked flag on any group member — see [[imgui_retained_strict_changed]].
; ===============================================================================================================================
Func _ImGui_SetRadioGroupValue($sGroupId, $iValue)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetRadioGroupValue", _
        "wstr", $sGroupId, "int", $iValue)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- K.2 InputDouble (DoubleValueWidget base) ------------------------------

; Double-precision numeric input — preserve full 15-digit precision (vs ~7
; for InputFloat). $sFormat = "" → "%.6f" inside the widget.
; Read / write via _ImGui_GetValueDouble / _ImGui_SetValueDouble (polymorphic).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateInputDouble
; Description ...: Create a double-precision numeric Input widget (15-digit precision)
; Syntax.........: _ImGui_CreateInputDouble($sId, $sLabel, $fDefault[, $fStep = 0.0, $fStepFast = 0.0, $sFormat = "", $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label
;                  $fDefault    - Initial double value
;                  $fStep       - Step value applied by the +/- buttons (0 = disable)
;                  $fStepFast   - Fast-step value applied with Ctrl+click (0 = disable)
;                  $sFormat     - printf-style format string ("" → "%.6f" inside the widget)
;                  $iFlags      - Bitmask of $ImGuiInputTextFlags_*
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read / write via _ImGui_GetValueDouble / _ImGui_SetValueDouble (polymorphic).
; ===============================================================================================================================
Func _ImGui_CreateInputDouble($sId, $sLabel, $fDefault, $fStep = 0.0, $fStepFast = 0.0, $sFormat = "", $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInputDouble", _
        "wstr", $sId, "wstr", $sLabel, _
        "double", $fDefault, "double", $fStep, "double", $fStepFast, _
        "wstr", $sFormat, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetValueDouble
; Description ...: Read the current double value of an InputDouble (or other double-valued) widget
; Syntax.........: _ImGui_GetValueDouble($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Returns the double value on success. 0.0 with @error set (1=DLL not loaded, 2=DllCall failed,
;                  3=unknown widget id or not double-valued).
; ===============================================================================================================================
Func _ImGui_GetValueDouble($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0.0)
    Local $tBuf = DllStructCreate("double v")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetValueDouble", _
        "wstr", $sId, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0.0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0.0)
    Return DllStructGetData($tBuf, "v")
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetValueDouble
; Description ...: Programmatically write a double value into a double-valued widget
; Syntax.........: _ImGui_SetValueDouble($sId, $fValue)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fValue      - New double value to apply
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Programmatic writes never latch the changed flag — see [[imgui_retained_strict_changed]].
; ===============================================================================================================================
Func _ImGui_SetValueDouble($sId, $fValue)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetValueDouble", _
        "wstr", $sId, "double", $fValue)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- K.3 Font extras (LoadFontEx with glyph range + LoadFontFromMemory + GetFontSize) -----

; Same as _ImGui_LoadFont but takes an explicit glyph range enum
; ($ImGuiFontGlyphRange_Default..Thai). Returns the font_id (>= 0) on success,
; -1 on error. @extended = DLL status (1=bad args, 2=load failed, 6=shutdown).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_LoadFontEx
; Description ...: Load a TTF font from disk with an explicit Unicode glyph range
; Syntax.........: _ImGui_LoadFontEx($sPath, $fSize[, $iGlyphRange = 0])
; Parameters ....: $sPath       - Absolute path to the TTF/OTF file (UTF-8)
;                  $fSize       - Pixel size at which to bake the glyphs
;                  $iGlyphRange - One of $ImGuiFontGlyphRange_Default..Thai
; Return values .: Returns the font_id (>=0) on success. -1 with @error set (1=DLL not loaded,
;                  2=DllCall failed, 3=DLL status — @extended = 1=bad args, 2=load failed, 6=shutdown).
; Information ...: Load all fonts BEFORE the widgets that reference them — PushFont with an unknown id falls back to font 0.
; ===============================================================================================================================
Func _ImGui_LoadFontEx($sPath, $fSize, $iGlyphRange = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, -1)
    Local $tId = DllStructCreate("int id")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_LoadFontEx", _
        "wstr", $sPath, "float", $fSize, "int", $iGlyphRange, _
        "ptr", DllStructGetPtr($tId))
    If @error Then Return SetError(2, @error, -1)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], -1)
    Return DllStructGetData($tId, "id")
EndFunc

; Load a TTF from a memory buffer. $pBuffer is a pointer (DllStructGetPtr on
; a struct that holds the bytes — typically populated via FileRead + binary
; mode + DllStructSetData). $iSize is the byte count. ImGui makes its own
; internal copy, so the caller's buffer can be freed right after the call.
; Returns font_id (>= 0) on success, -1 on error.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_LoadFontFromMemory
; Description ...: Load a TTF font from an in-memory byte buffer
; Syntax.........: _ImGui_LoadFontFromMemory($pBuffer, $iSize, $fSize)
; Parameters ....: $pBuffer     - Pointer to a binary buffer holding the TTF bytes (DllStructGetPtr)
;                  $iSize       - Buffer size in bytes
;                  $fSize       - Pixel size at which to bake the glyphs
; Return values .: Returns the font_id (>=0) on success. -1 with @error set on failure.
; Information ...: ImGui makes an internal copy of the bytes — the caller's buffer can be freed right after the call.
; ===============================================================================================================================
Func _ImGui_LoadFontFromMemory($pBuffer, $iSize, $fSize)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, -1)
    Local $tId = DllStructCreate("int id")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_LoadFontFromMemory", _
        "ptr", $pBuffer, "int", $iSize, "float", $fSize, _
        "ptr", DllStructGetPtr($tId))
    If @error Then Return SetError(2, @error, -1)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], -1)
    Return DllStructGetData($tId, "id")
EndFunc

; Current font's pixel size. Reflects the stacked font when called inside a
; PushFont scope ; otherwise the default font size.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetFontSize
; Description ...: Return the current font's pixel size (honors active PushFont scope)
; Syntax.........: _ImGui_GetFontSize()
; Parameters ....: None
; Return values .: Returns the font pixel size on success. 0.0 with @error set (1=DLL not loaded,
;                  2=DllCall failed, 3=DLL status non-zero).
; ===============================================================================================================================
Func _ImGui_GetFontSize()
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0.0)
    Local $tBuf = DllStructCreate("float s")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetFontSize", _
        "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0.0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0.0)
    Return DllStructGetData($tBuf, "s")
EndFunc

; --- K.5 Logging API -------------------------------------------------------
; ImGui's logging captures rendered text into a sink (file / clipboard / TTY).
; Useful for textual screenshots of a panel state. $iAutoOpenDepth controls
; auto-opening of nested TreeNode/CollapsingHeader (-1 = default, 0 = none,
; >0 = max depth). The marker widget _ImGui_CreateLogButtons emits the inline
; row of buttons that drive the same actions visually.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_LogToFile
; Description ...: Start capturing ImGui-rendered text into a file
; Syntax.........: _ImGui_LogToFile($iAutoOpenDepth, $sFilename)
; Parameters ....: $iAutoOpenDepth - Auto-open nested Tree/Header up to this depth (-1 = default, 0 = none, >0 = max)
;                  $sFilename   - Output file path (UTF-8) — overwritten if it exists
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Call _ImGui_LogFinish to flush and close. Useful for textual screenshots of a panel state.
; ===============================================================================================================================
Func _ImGui_LogToFile($iAutoOpenDepth, $sFilename)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_LogToFile", _
        "int", $iAutoOpenDepth, "wstr", $sFilename)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_LogToClipboard
; Description ...: Start capturing ImGui-rendered text into the system clipboard
; Syntax.........: _ImGui_LogToClipboard([$iAutoOpenDepth = -1])
; Parameters ....: $iAutoOpenDepth - Auto-open nested Tree/Header up to this depth (-1 = default, 0 = none, >0 = max)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Call _ImGui_LogFinish to commit. Convenient for sharing a panel snapshot via paste.
; ===============================================================================================================================
Func _ImGui_LogToClipboard($iAutoOpenDepth = -1)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_LogToClipboard", _
        "int", $iAutoOpenDepth)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_LogToTTY
; Description ...: Start capturing ImGui-rendered text into stdout (TTY)
; Syntax.........: _ImGui_LogToTTY([$iAutoOpenDepth = -1])
; Parameters ....: $iAutoOpenDepth - Auto-open nested Tree/Header up to this depth (-1 = default, 0 = none, >0 = max)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Call _ImGui_LogFinish to flush.
; ===============================================================================================================================
Func _ImGui_LogToTTY($iAutoOpenDepth = -1)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_LogToTTY", _
        "int", $iAutoOpenDepth)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_LogFinish
; Description ...: Stop the active logging capture and flush the sink
; Syntax.........: _ImGui_LogFinish()
; Parameters ....: None
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: No-op if no log session is active. Must be called at most once per LogTo* / LogFinish pair.
; ===============================================================================================================================
Func _ImGui_LogFinish()
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_LogFinish")
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Append literal text to the active log sink. No-op if no log is active.
; Embedded "%" characters in $sText are safe — sent through "%s" format.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_LogText
; Description ...: Append literal text to the active log sink
; Syntax.........: _ImGui_LogText($sText)
; Parameters ....: $sText       - Text content to append (UTF-8)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: No-op if no log is active. Embedded "%" characters are safe — sent through "%s" format.
; ===============================================================================================================================
Func _ImGui_LogText($sText)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_LogText", "wstr", $sText)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; =============================================================================
; Phase L — Niches faible valeur
; =============================================================================

; --- L.1 Debug helpers inline ----------------------------------------------

; ShowStyleSelector : combo qui swap Dark/Light/Classic. La sélection persiste
; via ImGui's internal style state (no AutoIt-side latch needed).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateShowStyleSelector
; Description ...: Create a Combo widget that swaps the active ImGui style theme (Dark/Light/Classic)
; Syntax.........: _ImGui_CreateShowStyleSelector($sId[, $sLabel = "Style"])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed combo label
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Selection persists via ImGui's internal style state — no AutoIt-side latch needed.
; ===============================================================================================================================
Func _ImGui_CreateShowStyleSelector($sId, $sLabel = "Style")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateShowStyleSelector", _
        "wstr", $sId, "wstr", $sLabel)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; ShowFontSelector : combo pour choisir parmi les fonts chargées. La sélection
; PushFont sur la durée du frame suivant.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateShowFontSelector
; Description ...: Create a Combo widget that picks the active font from the loaded font registry
; Syntax.........: _ImGui_CreateShowFontSelector($sId[, $sLabel = "Font"])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed combo label
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Selection triggers a PushFont for the next frame.
; ===============================================================================================================================
Func _ImGui_CreateShowFontSelector($sId, $sLabel = "Font")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateShowFontSelector", _
        "wstr", $sId, "wstr", $sLabel)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; ShowUserGuide : bloc statique avec les raccourcis clavier ImGui (move with
; arrows, ctrl+click slider for direct edit, etc.). Zéro-arg.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateShowUserGuide
; Description ...: Render a static block listing ImGui's built-in keyboard shortcuts
; Syntax.........: _ImGui_CreateShowUserGuide($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Useful as a help panel inside a debug/About window.
; ===============================================================================================================================
Func _ImGui_CreateShowUserGuide($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateShowUserGuide", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- L.2 TextLinkOpenURL avec whitelist http/https -------------------------

; Like TextLink but opens an URL on click via ShellExecuteW. SECURITY :
; only http:// and https:// schemes are honored — file://, javascript:, etc.
; are silently ignored. The click is still latched (_ImGui_WasClicked sees it)
; so the script can react regardless of whether the URL was opened.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTextLinkOpenURL
; Description ...: Create a clickable text link that opens an URL via ShellExecuteW
; Syntax.........: _ImGui_CreateTextLinkOpenURL($sId, $sLabel, $sUrl)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed link text
;                  $sUrl        - Target URL (only http:// and https:// schemes are honored)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: SECURITY : file://, javascript:, etc. are silently ignored. The click is still latched
;                  (_ImGui_WasClicked sees it) so the script can react regardless of URL handling.
; ===============================================================================================================================
Func _ImGui_CreateTextLinkOpenURL($sId, $sLabel, $sUrl)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTextLinkOpenURL", _
        "wstr", $sId, "wstr", $sLabel, "wstr", $sUrl)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- L.4 Value() helpers ---------------------------------------------------
; Render "prefix: value" in the flow. Largely overlap with
; _ImGui_SetText("st", "Loop: " & $i) — present for full ImGui API parity.
; Value updates via the polymorphic _ImGui_SetValueBool/Int/Float exports.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateValueBool
; Description ...: Render a "prefix: bool" inline value display
; Syntax.........: _ImGui_CreateValueBool($sId, $sPrefix[, $bInitial = False])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sPrefix     - Text shown before the value (e.g. "Loop:")
;                  $bInitial    - Initial boolean state
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Update via the polymorphic _ImGui_SetValueBool. Overlaps with _ImGui_SetText concatenation.
; ===============================================================================================================================
Func _ImGui_CreateValueBool($sId, $sPrefix, $bInitial = False)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iVal = $bInitial ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateValueBool", _
        "wstr", $sId, "wstr", $sPrefix, "int", $iVal)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateValueInt
; Description ...: Render a "prefix: int" inline value display
; Syntax.........: _ImGui_CreateValueInt($sId, $sPrefix[, $iInitial = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sPrefix     - Text shown before the value
;                  $iInitial    - Initial integer value
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Update via the polymorphic _ImGui_SetValueInt.
; ===============================================================================================================================
Func _ImGui_CreateValueInt($sId, $sPrefix, $iInitial = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateValueInt", _
        "wstr", $sId, "wstr", $sPrefix, "int", $iInitial)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateValueFloat
; Description ...: Render a "prefix: float" inline value display
; Syntax.........: _ImGui_CreateValueFloat($sId, $sPrefix[, $fInitial = 0.0, $sFormat = "%.3f"])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sPrefix     - Text shown before the value
;                  $fInitial    - Initial float value
;                  $sFormat     - printf-style format string applied to the value
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Update via the polymorphic _ImGui_SetValueFloat.
; ===============================================================================================================================
Func _ImGui_CreateValueFloat($sId, $sPrefix, $fInitial = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateValueFloat", _
        "wstr", $sId, "wstr", $sPrefix, "float", $fInitial, "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Images / ImageButton (hand-written, H.4) --------------------------------
; Load PNG/JPG/BMP/TIFF/GIF via Windows WIC, get a tex_id, then use it via
; ImageWidget / ImageButtonWidget. Textures persist until _ImGui_Shutdown ;
; there is intentionally no FreeTexture in the MVP (a bot panel typically
; loads a handful of icons at startup and keeps them).

; Returns tex_id (>= 0) on success, -1 on error. @extended carries the DLL
; status (1=bad args, 2=device not ready, 3=WIC/D3D load failed, 6=shutting
; down). The texture's native dimensions are written to ByRef $iWidth/$iHeight
; (or untouched if you pass 0/Default — call _ImGui_GetTextureSize later).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_LoadTexture
; Description ...: Load a PNG/JPG/BMP/TIFF/GIF image into a GPU texture via Windows WIC
; Syntax.........: _ImGui_LoadTexture($sPath, ByRef $iWidth, ByRef $iHeight)
; Parameters ....: $sPath       - Absolute path to the image file (UTF-8)
;                  $iWidth      - ByRef out — receives the texture's native width in pixels
;                  $iHeight     - ByRef out — receives the texture's native height in pixels
; Return values .: Returns the tex_id (>=0) on success. -1 with @error set (1=DLL not loaded,
;                  2=DllCall failed, 3=DLL error — @extended = 1=bad args, 2=device not ready,
;                  3=WIC/D3D load failed, 6=shutting down).
; Information ...: Textures persist until _ImGui_Shutdown — there is intentionally no FreeTexture in the MVP.
; ===============================================================================================================================
Func _ImGui_LoadTexture($sPath, ByRef $iWidth, ByRef $iHeight)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, -1)
    Local $tW   = DllStructCreate("int w")
    Local $tH   = DllStructCreate("int h")
    Local $tErr = DllStructCreate("int e")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_LoadTexture", _
        "wstr", $sPath, _
        "ptr",  DllStructGetPtr($tW), _
        "ptr",  DllStructGetPtr($tH), _
        "ptr",  DllStructGetPtr($tErr))
    If @error Then Return SetError(2, @error, -1)
    Local $iId = $aRet[0]
    If $iId < 0 Then Return SetError(3, DllStructGetData($tErr, "e"), -1)
    $iWidth  = DllStructGetData($tW, "w")
    $iHeight = DllStructGetData($tH, "h")
    Return $iId
EndFunc

; Returns array[2] = (w, h) for an existing tex_id ; (0, 0) on error.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetTextureSize
; Description ...: Read the native width and height of a previously-loaded texture
; Syntax.........: _ImGui_GetTextureSize($iTexId)
; Parameters ....: $iTexId      - Texture id returned by _ImGui_LoadTexture
; Return values .: Returns array[2] = [width, height] on success. 0 with @error set on failure
;                  (1=DLL not loaded, 2=DllCall failed, 3=unknown tex_id).
; ===============================================================================================================================
Func _ImGui_GetTextureSize($iTexId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $tBuf = DllStructCreate("int buf[2]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetTextureSize", _
        "int", $iTexId, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Local $aOut[2] = [DllStructGetData($tBuf, "buf", 1), DllStructGetData($tBuf, "buf", 2)]
    Return $aOut
EndFunc

; Display-only image widget. Pass $fW = $fH = 0 to render at the texture's
; native dimensions.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateImage
; Description ...: Create a display-only Image widget rendering a previously-loaded texture
; Syntax.........: _ImGui_CreateImage($sId, $iTexId[, $fW = 0.0, $fH = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iTexId      - Texture id returned by _ImGui_LoadTexture
;                  $fW          - Width in pixels (0 = native texture width)
;                  $fH          - Height in pixels (0 = native texture height)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; ===============================================================================================================================
Func _ImGui_CreateImage($sId, $iTexId, $fW = 0.0, $fH = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateImage", _
        "wstr", $sId, "int", $iTexId, "float", $fW, "float", $fH)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Clickable image button. Same latch as Button — poll via _ImGui_WasClicked.
; The label is the ImGui id seed ; it isn't rendered visually (the image is).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateImageButton
; Description ...: Create a clickable image button rendering a previously-loaded texture
; Syntax.........: _ImGui_CreateImageButton($sId, $sLabel, $iTexId[, $fW = 0.0, $fH = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - ImGui id seed (not rendered — the image is)
;                  $iTexId      - Texture id returned by _ImGui_LoadTexture
;                  $fW          - Width in pixels (0 = native texture width)
;                  $fH          - Height in pixels (0 = native texture height)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Same latch as Button — poll user clicks with _ImGui_WasClicked($sId).
; ===============================================================================================================================
Func _ImGui_CreateImageButton($sId, $sLabel, $iTexId, $fW = 0.0, $fH = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateImageButton", _
        "wstr", $sId, "wstr", $sLabel, "int", $iTexId, "float", $fW, "float", $fH)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; M.2 — Image variant with background color drawn UNDER the texture (visible
; through transparent pixels) + tint color (multiplied with the texture).
; Defaults reproduce the look of plain _ImGui_CreateImage : bg=(0,0,0,0) fully
; transparent ; tint=(1,1,1,1) no tint. Component values are in [0.0, 1.0].
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateImageWithBg
; Description ...: Create an Image widget with a background color drawn under the texture and a tint multiplier
; Syntax.........: _ImGui_CreateImageWithBg($sId, $iTexId, $fW, $fH[, $fBgR..$fBgA = 0.0, $fTintR..$fTintA = 1.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iTexId      - Texture id returned by _ImGui_LoadTexture
;                  $fW / $fH    - Width / height in pixels (0 = native texture size)
;                  $fBgR..$fBgA - Background color components [0.0 - 1.0] (default fully transparent)
;                  $fTintR..$fTintA - Tint color components [0.0 - 1.0] (default 1,1,1,1 = no tint)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Background is visible through transparent pixels of the texture ; tint is multiplied per-pixel.
; ===============================================================================================================================
Func _ImGui_CreateImageWithBg($sId, $iTexId, $fW, $fH, _
                              $fBgR = 0.0, $fBgG = 0.0, $fBgB = 0.0, $fBgA = 0.0, _
                              $fTintR = 1.0, $fTintG = 1.0, $fTintB = 1.0, $fTintA = 1.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateImageWithBg", _
        "wstr", $sId, "int", $iTexId, "float", $fW, "float", $fH, _
        "float", $fBgR,   "float", $fBgG,   "float", $fBgB,   "float", $fBgA, _
        "float", $fTintR, "float", $fTintG, "float", $fTintB, "float", $fTintA)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Font management (hand-written, H.3) -------------------------------------
; Load a TTF at runtime, get a font_id, then use it via PushFont / PopFont
; marker widgets. Index 0 is always the default Calibri 15.5pt loaded at init —
; you don't need to register it. Loaded fonts persist until _ImGui_Shutdown.
;
; The atlas is updated incrementally on the next frame (no perceivable hitch
; for a typical TTF). For best UX, load all fonts BEFORE creating widgets that
; reference them ; PushFont with an unknown id silently falls back to font 0.

; Returns the new font_id (>= 1) on success, or -1 on error.
; @extended carries the DLL status on failure (1=bad args, 2=AddFontFromFileTTF
; failed — file missing / not a valid TTF, 6=shutting down).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_LoadFont
; Description ...: Load a TTF font from disk (Default glyph range)
; Syntax.........: _ImGui_LoadFont($sPath, $fSize)
; Parameters ....: $sPath       - Absolute path to the TTF/OTF file (UTF-8)
;                  $fSize       - Pixel size at which to bake the glyphs
; Return values .: Returns the font_id (>=1) on success. -1 with @error set (1=DLL not loaded,
;                  2=DllCall failed, 3=DLL status — @extended = 1=bad args, 2=AddFontFromFileTTF failed,
;                  6=shutting down).
; Information ...: Use _ImGui_LoadFontEx for non-default glyph ranges (Cyrillic/CJK/...).
; ===============================================================================================================================
Func _ImGui_LoadFont($sPath, $fSize)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, -1)
    Local $tId = DllStructCreate("int id")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_LoadFont", _
        "wstr", $sPath, "float", $fSize, "ptr", DllStructGetPtr($tId))
    If @error Then Return SetError(2, @error, -1)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], -1)
    Return DllStructGetData($tId, "id")
EndFunc

; Total number of fonts in the registry. Always >= 1 (default font at index 0).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetFontCount
; Description ...: Return the total number of fonts registered in the ImGui font atlas
; Syntax.........: _ImGui_GetFontCount()
; Parameters ....: None
; Return values .: Returns the count (>=1, default font is index 0) on success. 0 with @error set
;                  (1=DLL not loaded, 2=DllCall failed).
; ===============================================================================================================================
Func _ImGui_GetFontCount()
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetFontCount")
    If @error Then Return SetError(2, @error, 0)
    Return $aRet[0]
EndFunc

; PushFont / PopFont — marker widgets. Place them around the widgets that
; should render with the alternate font. Pair them in the same parent's
; children list ; mismatched Push/Pop = ImGui assertion at end-of-frame.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePushFont
; Description ...: Emit a marker that pushes a font onto ImGui's font stack
; Syntax.........: _ImGui_CreatePushFont($sId, $iFontId)
; Parameters ....: $sId         - Stable marker identifier (must be unique in the tree)
;                  $iFontId     - Font id returned by _ImGui_LoadFont / _ImGui_LoadFontEx
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Pair with a matching _ImGui_CreatePopFont marker at the same parent level —
;                  mismatched Push/Pop = ImGui assertion at end-of-frame.
; ===============================================================================================================================
Func _ImGui_CreatePushFont($sId, $iFontId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePushFont", _
        "wstr", $sId, "int", $iFontId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePopFont
; Description ...: Emit a marker that pops the top font off ImGui's font stack
; Syntax.........: _ImGui_CreatePopFont($sId)
; Parameters ....: $sId         - Stable marker identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Pair with a matching _ImGui_CreatePushFont marker at the same parent level.
; ===============================================================================================================================
Func _ImGui_CreatePopFont($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePopFont", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Rich tooltips (hand-written, H.2) ---------------------------------------
; Distinct from the single-line _ImGui_SetTooltip helper. Create an ItemTooltip
; widget IMMEDIATELY AFTER the target widget at the same parent level, then
; populate it with children (Text / Separator / etc.). When the target widget
; is hovered for the ImGui default delay, the tooltip opens and renders its
; children inside.
;
; Wrong order = tooltip never opens (BeginItemTooltip operates on ImGui's
; "last item" — placing the tooltip elsewhere makes it observe the wrong item).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateItemTooltip
; Description ...: Create a rich tooltip container that opens on hover of the previous widget
; Syntax.........: _ImGui_CreateItemTooltip($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Place IMMEDIATELY AFTER the target widget at the same parent level — wrong order
;                  means the tooltip observes the wrong "last item" and never opens. Populate with children
;                  (Text / Separator / Image / ...) that render inside the tooltip popup.
; ===============================================================================================================================
Func _ImGui_CreateItemTooltip($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateItemTooltip", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; M.3 — Unconditional tooltip container. Calls BeginTooltip() every frame the
; widget is visible, regardless of any "previous item hovered" state. Distinct
; from _ImGui_CreateItemTooltip which requires hover. Display gating is the
; caller's job — toggle visibility via _ImGui_SetVisible based on a custom
; condition (timer, manual hit test, programmatic trigger, …). Children render
; INSIDE the tooltip popup (Text / Separator / Image / whatever, all nestable
; via _ImGui_SetParent).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTooltip
; Description ...: Create an unconditional tooltip container (no hover gating)
; Syntax.........: _ImGui_CreateTooltip($sId)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Calls BeginTooltip() every frame the widget is visible. Display gating is the caller's job —
;                  toggle visibility via _ImGui_SetVisible based on a custom condition. Children nestable via _ImGui_SetParent.
; ===============================================================================================================================
Func _ImGui_CreateTooltip($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTooltip", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- TreeNode + CollapsingHeader (hand-written, D.6) -------------------------
; Both used to be auto-generated; pulled into tree_extras.cpp once D.6 added
; ImGuiTreeNodeFlags, the optional X close button on CollapsingHeader (via the
; p_visible overload, which writes into Widget::visible — the same bool driven
; by _ImGui_SetVisible), and the per-widget SetNextItemOpen pending state.
;
; Old 2-arg callers (e.g. `_ImGui_CreateTreeNode("a", "Label")`) keep working —
; flags/closable default to 0.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTreeNode
; Description ...: Create a TreeNode container (expandable tree item with arrow)
; Syntax.........: _ImGui_CreateTreeNode($sId[, $sLabel = "", $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $iFlags      - Bitmask of $ImGuiTreeNodeFlags_*
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Poll user toggles with _ImGui_IsToggledOpen ; seed initial open state with _ImGui_SetNextItemOpen.
; ===============================================================================================================================
Func _ImGui_CreateTreeNode($sId, $sLabel = "", $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTreeNode", _
        "wstr", $sId, "wstr", $sLabel, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateCollapsingHeader
; Description ...: Create a CollapsingHeader container (top-level expandable section)
; Syntax.........: _ImGui_CreateCollapsingHeader($sId[, $sLabel = "", $bClosable = False, $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label
;                  $bClosable   - True = add an X close button (writes Widget::visible like _ImGui_SetVisible)
;                  $iFlags      - Bitmask of $ImGuiTreeNodeFlags_*
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Poll user toggles with _ImGui_IsToggledOpen ; seed initial open state with _ImGui_SetNextItemOpen.
; ===============================================================================================================================
Func _ImGui_CreateCollapsingHeader($sId, $sLabel = "", $bClosable = False, $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iClos = $bClosable ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateCollapsingHeader", _
        "wstr", $sId, "wstr", $sLabel, "int", $iClos, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Queue a one-shot ImGui::SetNextItemOpen at the next Render() of the named
; tree node or collapsing header. $iCond gates whether the call actually
; overwrites (default Always = overwrite every time the setter is called).
; Use $ImGuiCond_Once to seed initial state once and let the user toggle freely.
;
; Returns True on success ; SetError(3) with @extended carrying the DLL status
; on failure (2 = unknown id, 3 = widget is neither a TreeNode nor a CollapsingHeader).
; Default $iCond = 0 (= ImGuiCond_None, functionally identical to Always — see
; the $ImGuiCond_* block below). Use a numeric default rather than the named
; constant to avoid forward-reference warnings ; same convention as the
; _ImGui_SetWindow* setters from D.3.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetNextItemOpen
; Description ...: Queue a one-shot open/closed state for a TreeNode or CollapsingHeader
; Syntax.........: _ImGui_SetNextItemOpen($sId, $bOpen[, $iCond = 0])
; Parameters ....: $sId         - Identifier of the TreeNode / CollapsingHeader widget
;                  $bOpen       - True to open, False to close
;                  $iCond       - Condition flag ($ImGuiCond_Always/Once/FirstUseEver/Appearing)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a TreeNode/CollapsingHeader)
; Information ...: Use $ImGuiCond_Once to seed initial state and let the user toggle freely afterwards.
; ===============================================================================================================================
Func _ImGui_SetNextItemOpen($sId, $bOpen, $iCond = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iOpen = $bOpen ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetNextItemOpen", _
        "wstr", $sId, "int", $iOpen, "int", $iCond)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; True for exactly one frame when the user clicked the arrow to open or close
; the tree node / collapsing header. Distinct from _ImGui_HasChanged (which
; doesn't apply to non-valued widgets). Returns False for any other widget id.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsToggledOpen
; Description ...: Report whether the user just opened or closed a TreeNode / CollapsingHeader this frame
; Syntax.........: _ImGui_IsToggledOpen($sId)
; Parameters ....: $sId         - Identifier of the TreeNode / CollapsingHeader widget
; Return values .: Returns True for exactly one frame on user-driven toggle. False otherwise.
; Information ...: Distinct from _ImGui_HasChanged (which doesn't apply to non-valued widgets).
; ===============================================================================================================================
Func _ImGui_IsToggledOpen($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsToggledOpen", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; --- TabItem + TabItemButton (hand-written, D.7) -----------------------------
; TabItem used to be auto-generated; pulled into tab_extras.cpp once D.7 added
; the optional X close button (via the p_open overload, reusing Widget::visible
; as the bool*), ImGuiTabItemFlags, and the per-widget pending SetTabItemClosed.
;
; Old 2-arg callers (e.g. `_ImGui_CreateTabItem("tab_a", "Label")`) keep working.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTabItem
; Description ...: Create a TabItem (selectable tab within a TabBar)
; Syntax.........: _ImGui_CreateTabItem($sId[, $sLabel = "", $bClosable = False, $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed tab label
;                  $bClosable   - True = add an X close button (writes Widget::visible like _ImGui_SetVisible)
;                  $iFlags      - Bitmask of $ImGuiTabItemFlags_*
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Children render inside the tab's body when selected. Use _ImGui_SetTabItemClosed to close gracefully.
; ===============================================================================================================================
Func _ImGui_CreateTabItem($sId, $sLabel = "", $bClosable = False, $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iClos = $bClosable ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTabItem", _
        "wstr", $sId, "wstr", $sLabel, "int", $iClos, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Inline clickable tab — renders inside a TabBar but has no body and no
; sticky-selected state. Common patterns :
;   - "+" with $ImGuiTabItemFlags_Trailing for "add new tab"
;   - "≡" or burger with $ImGuiTabItemFlags_Leading for an inline menu
; Read clicks via _ImGui_WasClicked($sId), same as any clickable widget.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateTabItemButton
; Description ...: Create an inline clickable tab (no body, no selected state)
; Syntax.........: _ImGui_CreateTabItemButton($sId[, $sLabel = "", $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (e.g. "+" or burger glyph)
;                  $iFlags      - Bitmask of $ImGuiTabItemFlags_* (Trailing for "+ add new", Leading for menu, ...)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Poll user clicks with _ImGui_WasClicked($sId), same as any clickable widget.
; ===============================================================================================================================
Func _ImGui_CreateTabItemButton($sId, $sLabel = "", $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateTabItemButton", _
        "wstr", $sId, "wstr", $sLabel, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Notify the TabBar that a tab is closing — reduces visual flicker on
; reorderable bars compared to a plain _ImGui_SetVisible($sId, False). The
; DLL flushes both the pending_closed flag (for the next-frame ImGui::
; SetTabItemClosed call) and visible=false atomically under the tree mutex.
;
; Returns True on success ; SetError(3) with @extended carrying the DLL status
; on failure (2 = unknown id, 3 = widget is not a TabItem).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetTabItemClosed
; Description ...: Notify the TabBar that a tab is closing (reduces flicker on reorderable bars)
; Syntax.........: _ImGui_SetTabItemClosed($sId)
; Parameters ....: $sId         - Identifier of the TabItem widget
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a TabItem)
; Information ...: Atomically flushes pending_closed (for the next-frame ImGui::SetTabItemClosed call) and
;                  visible=false. Cleaner than calling _ImGui_SetVisible($sId, False) directly.
; ===============================================================================================================================
Func _ImGui_SetTabItemClosed($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetTabItemClosed", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; --- Popups / Modals (hand-written, E.1) -------------------------------------
; Two container widget variants : Popup (regular floating, no title bar) and
; PopupModal (dim background + title bar + optional X close button). Both are
; top-level (IsTopLevelWindow=true) — rendered OUTSIDE the host Begin/End.
;
; Open/close are driven by pending one-shots on the widget : the script calls
; _ImGui_OpenPopup at any time, and the next render frame consumes it. Same
; for _ImGui_ClosePopup, which is honored only if the popup is currently open
; (consumed inside the BeginPopup body, where ImGui::CloseCurrentPopup expects
; to be called).
;
; Modal closable uses Widget::visible as bool* (same pattern as Window/TabItem/
; CollapsingHeader). The X click sets visible=false ; re-open via _ImGui_OpenPopup
; auto-resets visible=true so the cycle stays clean.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePopup
; Description ...: Create a top-level Popup container (regular floating, no title bar)
; Syntax.........: _ImGui_CreatePopup($sId[, $sLabel = "", $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Optional displayed title (most popups omit it)
;                  $iFlags      - Bitmask of $ImGuiPopupFlags_* / $ImGuiWindowFlags_* combined
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Rendered OUTSIDE the host Begin/End. Drive open/close via _ImGui_OpenPopup / _ImGui_ClosePopup.
; ===============================================================================================================================
Func _ImGui_CreatePopup($sId, $sLabel = "", $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePopup", _
        "wstr", $sId, "wstr", $sLabel, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePopupModal
; Description ...: Create a top-level modal Popup container (dim background + title bar)
; Syntax.........: _ImGui_CreatePopupModal($sId[, $sLabel = "", $bClosable = False, $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Title bar text
;                  $bClosable   - True = add an X close button (writes Widget::visible)
;                  $iFlags      - Bitmask of $ImGuiPopupFlags_* / $ImGuiWindowFlags_*
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Re-opening via _ImGui_OpenPopup auto-resets Widget::visible=true ; cycle stays clean.
; ===============================================================================================================================
Func _ImGui_CreatePopupModal($sId, $sLabel = "", $bClosable = False, $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iClos = $bClosable ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePopupModal", _
        "wstr", $sId, "wstr", $sLabel, "int", $iClos, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Queue an open at the next Render(). Idempotent : re-calling while the popup
; is already open is a no-op (ImGui's OpenPopup will reposition + reinit nav
; unless $ImGuiPopupFlags_NoReopen is set, but that flag lives on the C side
; for now — pass it via $iFlags on Create if needed). Always returns True on
; success ; SetError(3) on widget-not-a-popup.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_OpenPopup
; Description ...: Queue an open at the next Render for a Popup / PopupModal / ContextPopup
; Syntax.........: _ImGui_OpenPopup($sId)
; Parameters ....: $sId         - Identifier of the target popup widget
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a popup)
; Information ...: Idempotent — re-calling while open is a no-op (ImGui repositions + reinits nav).
; ===============================================================================================================================
Func _ImGui_OpenPopup($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_OpenPopup", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; Queue a close at the next Render(). Honored only if the popup is open at
; that moment — silently dropped otherwise (so you can spam ClosePopup from
; a button handler without checking IsPopupOpen first).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_ClosePopup
; Description ...: Queue a close at the next Render for a Popup / PopupModal / ContextPopup
; Syntax.........: _ImGui_ClosePopup($sId)
; Parameters ....: $sId         - Identifier of the target popup widget
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a popup)
; Information ...: Honored only if the popup is open at that moment — silently dropped otherwise.
;                  Safe to spam from a button handler without checking _ImGui_IsPopupOpen first.
; ===============================================================================================================================
Func _ImGui_ClosePopup($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_ClosePopup", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; True iff the popup is currently open (= the last frame rendered its body).
; False for unknown ids or non-popup widgets.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsPopupOpen
; Description ...: Report whether a popup widget is currently open
; Syntax.........: _ImGui_IsPopupOpen($sId)
; Parameters ....: $sId         - Identifier of the target popup widget
; Return values .: Returns True while the popup body is rendering. False for unknown ids or non-popups.
; ===============================================================================================================================
Func _ImGui_IsPopupOpen($sId)
    If $__g_hImGuiDll = -1 Then Return False
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsPopupOpen", "wstr", $sId)
    If @error Then Return False
    Return ($aRet[0] = 1)
EndFunc

; --- Context popups + OpenPopupOnItemClick (hand-written, E.1.x) -------------
; ContextPopup is an INLINE container (not top-level) that fuses ImGui's
; BeginPopupContext{Item,Window,Void} trigger logic with the popup body.
; Placement rule depends on $iKind :
;   0 = Item   : insert as the next child AFTER the item you want right-click
;                to attach to (ImGui's "previous item" semantic).
;   1 = Window : insert anywhere inside the enclosing window's children.
;   2 = Void   : insert anywhere (right-click fires when no window is hovered).
;
; The popup body lives in the widget's children[] — add Selectables/MenuItems
; like for a regular Popup. _ImGui_OpenPopup / _ImGui_ClosePopup / _ImGui_IsPopupOpen
; also accept ContextPopup ids (same uniform routing as Popup / PopupModal).
;
; $iFlags default 0 = ImGui's $ImGuiPopupFlags_MouseButtonRight (since 1.92.6).
; Force left button with $ImGuiPopupFlags_MouseButtonLeft, etc.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateContextPopup
; Description ...: Create an inline context popup that fuses BeginPopupContext{Item,Window,Void} with its body
; Syntax.........: _ImGui_CreateContextPopup($sId[, $sLabel = "", $iKind = 0, $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Optional popup title
;                  $iKind       - 0 = Item (place after target widget), 1 = Window, 2 = Void
;                  $iFlags      - Bitmask of $ImGuiPopupFlags_* (default 0 = MouseButtonRight since 1.92.6)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Inline (not top-level). Same uniform routing as Popup for _ImGui_OpenPopup / _ImGui_IsPopupOpen.
; ===============================================================================================================================
Func _ImGui_CreateContextPopup($sId, $sLabel = "", $iKind = 0, $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateContextPopup", _
        "wstr", $sId, "wstr", $sLabel, "int", $iKind, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Pure trigger marker. Placed as the next child after a target item, it
; checks each frame whether the previous sibling was clicked with the mouse
; button encoded in $iFlags (default $ImGuiPopupFlags_MouseButtonRight). On
; click it directly sets pending_open_dirty on the target popup widget
; (Popup / PopupModal / ContextPopup) via tree lookup — bypassing ImGui's
; cross-pass id hashing, so the target can live anywhere in the tree (typical :
; a top-level Popup at root, while the marker lives deep inside a Child).
; $sTargetPopupId is NOT validated at create time — typos silently no-op.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateOpenPopupOnItemClick
; Description ...: Create a pure trigger marker that opens a target popup when the previous sibling is clicked
; Syntax.........: _ImGui_CreateOpenPopupOnItemClick($sId, $sTargetPopupId[, $iFlags = 0])
; Parameters ....: $sId         - Stable marker identifier (must be unique in the tree)
;                  $sTargetPopupId - Identifier of the Popup / PopupModal / ContextPopup to open
;                  $iFlags      - Bitmask of $ImGuiPopupFlags_* (default = MouseButtonRight)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Bypasses ImGui's cross-pass id hashing via tree lookup — the target popup can live anywhere
;                  in the tree. $sTargetPopupId is NOT validated at create time ; typos silently no-op.
; ===============================================================================================================================
Func _ImGui_CreateOpenPopupOnItemClick($sId, $sTargetPopupId, $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateOpenPopupOnItemClick", _
        "wstr", $sId, "wstr", $sTargetPopupId, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Numeric / Color extras (hand-written, E.2) ------------------------------
; 6 widgets that don't fit the generator templates. All read/write via the
; existing generic helpers : _ImGui_GetValueFloat[N], _ImGui_GetValueInt[N],
; _ImGui_GetValueString, _ImGui_WasClicked, _ImGui_HasChanged.

; DragFloatRange2 — two floats (min, max) tracked together. Read with
; _ImGui_GetValueFloatN($sId, 2) → array of 2 floats ; write back with
; _ImGui_SetValueFloatN. Bounds (v_min/v_max), speed and format are
; creation-time constants.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateDragFloatRange2
; Description ...: Create a DragFloatRange2 widget (two floats min/max tracked together)
; Syntax.........: _ImGui_CreateDragFloatRange2($sId[, $sLabel = "", $fVMin = 0.0, $fVMax = 0.0, $fSpeed = 1.0, $fDefMin = 0.0, $fDefMax = 0.0, $sFormat = "%.3f", $sFormatMax = "", $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label
;                  $fVMin/$fVMax - Hard bounds for both values
;                  $fSpeed      - Drag speed (units per pixel of mouse movement)
;                  $fDefMin/$fDefMax - Initial min/max
;                  $sFormat / $sFormatMax - printf-style formats ; $sFormatMax empty = reuse $sFormat
;                  $iFlags      - Bitmask of $ImGuiSliderFlags_*
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read with _ImGui_GetValueFloatN($sId, 2) ; write via _ImGui_SetValueFloatN.
; ===============================================================================================================================
Func _ImGui_CreateDragFloatRange2($sId, $sLabel = "", $fVMin = 0.0, $fVMax = 0.0, _
                                    $fSpeed = 1.0, $fDefMin = 0.0, $fDefMax = 0.0, _
                                    $sFormat = "%.3f", $sFormatMax = "", $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateDragFloatRange2", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fVMin, "float", $fVMax, "float", $fSpeed, _
        "float", $fDefMin, "float", $fDefMax, _
        "wstr", $sFormat, "wstr", $sFormatMax, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; DragIntRange2 — same as above for ints. Use _ImGui_GetValueIntN($sId, 2).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateDragIntRange2
; Description ...: Create a DragIntRange2 widget (two integers min/max tracked together)
; Syntax.........: _ImGui_CreateDragIntRange2($sId[, $sLabel = "", $iVMin = 0, $iVMax = 0, $fSpeed = 1.0, $iDefMin = 0, $iDefMax = 0, $sFormat = "%d", $sFormatMax = "", $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label
;                  $iVMin/$iVMax - Hard bounds for both values
;                  $fSpeed      - Drag speed (units per pixel of mouse movement)
;                  $iDefMin/$iDefMax - Initial min/max integer values
;                  $sFormat / $sFormatMax - printf-style formats ; $sFormatMax empty = reuse $sFormat
;                  $iFlags      - Bitmask of $ImGuiSliderFlags_*
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read with _ImGui_GetValueIntN($sId, 2) ; write via _ImGui_SetValueIntN.
; ===============================================================================================================================
Func _ImGui_CreateDragIntRange2($sId, $sLabel = "", $iVMin = 0, $iVMax = 0, _
                                  $fSpeed = 1.0, $iDefMin = 0, $iDefMax = 0, _
                                  $sFormat = "%d", $sFormatMax = "", $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateDragIntRange2", _
        "wstr", $sId, "wstr", $sLabel, _
        "int", $iVMin, "int", $iVMax, "float", $fSpeed, _
        "int", $iDefMin, "int", $iDefMax, _
        "wstr", $sFormat, "wstr", $sFormatMax, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; SliderAngle — slider in degrees, value stored in radians (ImGui convention).
; Read/write the radian value via _ImGui_GetValueFloat / SetValueFloat. Bounds
; expressed in degrees ; conversion is automatic in the ImGui call.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSliderAngle
; Description ...: Create a SliderAngle widget (slider in degrees, value stored in radians)
; Syntax.........: _ImGui_CreateSliderAngle($sId[, $sLabel = "", $fDegMin = -360.0, $fDegMax = 360.0, $fDefaultRad = 0.0, $sFormat = "%.0f deg", $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label
;                  $fDegMin     - Lower bound in degrees
;                  $fDegMax     - Upper bound in degrees
;                  $fDefaultRad - Initial value IN RADIANS (ImGui convention for the stored value)
;                  $sFormat     - printf-style format string
;                  $iFlags      - Bitmask of $ImGuiSliderFlags_*
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write the radian value via _ImGui_GetValueFloat / _ImGui_SetValueFloat.
; ===============================================================================================================================
Func _ImGui_CreateSliderAngle($sId, $sLabel = "", $fDegMin = -360.0, $fDegMax = 360.0, _
                                $fDefaultRad = 0.0, $sFormat = "%.0f deg", $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSliderAngle", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fDegMin, "float", $fDegMax, "float", $fDefaultRad, _
        "wstr", $sFormat, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Vertical sliders. $fW/$fH set the rendered box (default 18x160 — typical
; ImGui demo size). Read/write via _ImGui_GetValueFloat or GetValueInt.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateVSliderFloat
; Description ...: Create a vertical Slider widget for float values
; Syntax.........: _ImGui_CreateVSliderFloat($sId[, $sLabel = "", $fW = 18.0, $fH = 160.0, $fVMin = 0.0, $fVMax = 1.0, $fDefault = 0.0, $sFormat = "%.3f", $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label
;                  $fW          - Width in pixels (default 18 — typical ImGui demo size)
;                  $fH          - Height in pixels (default 160)
;                  $fVMin/$fVMax - Range bounds
;                  $fDefault    - Initial float value
;                  $sFormat     - printf-style format string
;                  $iFlags      - Bitmask of $ImGuiSliderFlags_*
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueFloat / _ImGui_SetValueFloat.
; ===============================================================================================================================
Func _ImGui_CreateVSliderFloat($sId, $sLabel = "", $fW = 18.0, $fH = 160.0, _
                                 $fVMin = 0.0, $fVMax = 1.0, $fDefault = 0.0, _
                                 $sFormat = "%.3f", $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateVSliderFloat", _
        "wstr", $sId, "wstr", $sLabel, "float", $fW, "float", $fH, _
        "float", $fVMin, "float", $fVMax, "float", $fDefault, _
        "wstr", $sFormat, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateVSliderInt
; Description ...: Create a vertical Slider widget for integer values
; Syntax.........: _ImGui_CreateVSliderInt($sId[, $sLabel = "", $fW = 18.0, $fH = 160.0, $iVMin = 0, $iVMax = 100, $iDefault = 0, $sFormat = "%d", $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label
;                  $fW          - Width in pixels (default 18)
;                  $fH          - Height in pixels (default 160)
;                  $iVMin/$iVMax - Range bounds
;                  $iDefault    - Initial integer value
;                  $sFormat     - printf-style format string
;                  $iFlags      - Bitmask of $ImGuiSliderFlags_*
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueInt / _ImGui_SetValueInt.
; ===============================================================================================================================
Func _ImGui_CreateVSliderInt($sId, $sLabel = "", $fW = 18.0, $fH = 160.0, _
                               $iVMin = 0, $iVMax = 100, $iDefault = 0, _
                               $sFormat = "%d", $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateVSliderInt", _
        "wstr", $sId, "wstr", $sLabel, "float", $fW, "float", $fH, _
        "int", $iVMin, "int", $iVMax, "int", $iDefault, _
        "wstr", $sFormat, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; InputText with a hint string (placeholder shown when buffer is empty).
; Read/write via _ImGui_GetValueString / _ImGui_SetValueString.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateInputTextWithHint
; Description ...: Create an InputText widget that shows a placeholder hint when the buffer is empty
; Syntax.........: _ImGui_CreateInputTextWithHint($sId[, $sLabel = "", $sHint = "", $sDefault = "", $iMaxLength = 256, $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label
;                  $sHint       - Placeholder text shown when the buffer is empty
;                  $sDefault    - Initial text content (UTF-8)
;                  $iMaxLength  - Maximum buffer length in chars
;                  $iFlags      - Bitmask of $ImGuiInputTextFlags_*
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write via _ImGui_GetValueString / _ImGui_SetValueString.
; ===============================================================================================================================
Func _ImGui_CreateInputTextWithHint($sId, $sLabel = "", $sHint = "", $sDefault = "", _
                                      $iMaxLength = 256, $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInputTextWithHint", _
        "wstr", $sId, "wstr", $sLabel, "wstr", $sHint, "wstr", $sDefault, _
        "int", $iMaxLength, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; ColorButton — display-only clickable color swatch. Color via Get/SetValueFloatN
; (4 floats RGBA, in 0..1 range). Clicks via _ImGui_WasClicked.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateColorButton
; Description ...: Create a display-only clickable color swatch
; Syntax.........: _ImGui_CreateColorButton($sId[, $sLabel = "", $fR = 1.0, $fG = 0.0, $fB = 0.0, $fA = 1.0, $iFlags = 0, $fW = 0.0, $fH = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Tooltip / accessibility label
;                  $fR / $fG / $fB / $fA - Initial color components [0.0 - 1.0]
;                  $iFlags      - Bitmask of $ImGuiColorEditFlags_*
;                  $fW          - Width in pixels (0 = auto)
;                  $fH          - Height in pixels (0 = auto)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read/write the RGBA via _ImGui_GetValueFloatN / _ImGui_SetValueFloatN (4 floats).
;                  Poll clicks with _ImGui_WasClicked.
; ===============================================================================================================================
Func _ImGui_CreateColorButton($sId, $sLabel = "", $fR = 1.0, $fG = 0.0, $fB = 0.0, $fA = 1.0, _
                                $iFlags = 0, $fW = 0.0, $fH = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateColorButton", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fR, "float", $fG, "float", $fB, "float", $fA, _
        "int", $iFlags, "float", $fW, "float", $fH)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Mouse / Clipboard helpers (hand-written, E.3) ---------------------------
; Read ImGui global state — taken under the tree mutex for safety against
; concurrent NewFrame mutations. Values may be one frame stale, that's the
; expected polling latency for retained mode.

; Returns AutoIt array[2] = (x, y) in ImGui screen-space. (0, 0) on error.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetMousePos
; Description ...: Read the current mouse position in ImGui screen-space
; Syntax.........: _ImGui_GetMousePos()
; Parameters ....: None
; Return values .: Returns array[2] = [x, y] on success. 0 with @error set (1=DLL not loaded,
;                  2=DllCall failed, 3=DLL status non-zero).
; ===============================================================================================================================
Func _ImGui_GetMousePos()
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $tBuf = DllStructCreate("float buf[2]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetMousePos", _
        "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Local $aOut[2] = [DllStructGetData($tBuf, "buf", 1), DllStructGetData($tBuf, "buf", 2)]
    Return $aOut
EndFunc

; $iButton : 0=Left (default), 1=Right, 2=Middle. Returns array[2] = (dx, dy) ;
; (0, 0) when not currently dragging that button.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetMouseDragDelta
; Description ...: Read the accumulated drag delta of the given mouse button
; Syntax.........: _ImGui_GetMouseDragDelta([$iButton = 0])
; Parameters ....: $iButton     - Mouse button (0=Left, 1=Right, 2=Middle)
; Return values .: Returns array[2] = [dx, dy] on success. (0, 0) when not currently dragging that button.
;                  Sets @error on DLL failure.
; ===============================================================================================================================
Func _ImGui_GetMouseDragDelta($iButton = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $tBuf = DllStructCreate("float buf[2]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetMouseDragDelta", _
        "int", $iButton, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Local $aOut[2] = [DllStructGetData($tBuf, "buf", 1), DllStructGetData($tBuf, "buf", 2)]
    Return $aOut
EndFunc

; Read the ImGui clipboard (distinct from AutoIt's ClipGet/Put — ImGui has its
; own per-context clipboard backed by the OS clipboard). $iBufSize is the max
; wchar count for the result ; raise it if your script may handle very long
; clipped strings (4096 covers most typical text).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetClipboardText
; Description ...: Read the ImGui clipboard contents (backed by the OS clipboard)
; Syntax.........: _ImGui_GetClipboardText([$iBufSize = 4096])
; Parameters ....: $iBufSize    - Output buffer capacity in wchars
; Return values .: Returns the clipboard string on success. Empty string with @error set
;                  (1=DLL not loaded, 2=DllCall failed, 3=DLL status non-zero and non-truncation).
; Information ...: Status 4 = truncated ; bump $iBufSize and retry. Distinct from AutoIt's ClipGet — ImGui maintains its own clipboard.
; ===============================================================================================================================
Func _ImGui_GetClipboardText($iBufSize = 4096)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, "")
    Local $tBuf = DllStructCreate("wchar buf[" & $iBufSize & "]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetClipboardText", _
        "ptr", DllStructGetPtr($tBuf), "int", $iBufSize)
    If @error Then Return SetError(2, @error, "")
    If $aRet[0] <> 0 And $aRet[0] <> 4 Then Return SetError(3, $aRet[0], "")
    ; status 4 = truncated ; the string up to capacity-1 is still valid.
    Return DllStructGetData($tBuf, "buf")
EndFunc

; Set the ImGui clipboard. Empty string clears.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetClipboardText
; Description ...: Write a string to the ImGui clipboard
; Syntax.........: _ImGui_SetClipboardText($sText)
; Parameters ....: $sText       - Text to put in the clipboard (UTF-8). Empty clears the clipboard.
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; ===============================================================================================================================
Func _ImGui_SetClipboardText($sText)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetClipboardText", "wstr", $sText)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Color conversion (hand-written, E.4) ------------------------------------
; Pure math helpers — no mutex needed. Useful for building custom palettes
; or doing hue rotations from a script.

; Decode a U32 packed color (0xAABBGGRR — ImGui's native byte order) into
; an array[4] = (r, g, b, a) in [0..1]. The U32 value is what _ImGui_ColorFloat4ToU32
; produces ; round-trip exact (modulo float quantization).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_ColorU32ToFloat4
; Description ...: Decode a packed U32 color into 4 float components in [0..1]
; Syntax.........: _ImGui_ColorU32ToFloat4($iU32)
; Parameters ....: $iU32        - Packed color (0xAABBGGRR — ImGui's native byte order)
; Return values .: Returns array[4] = [R, G, B, A] in [0..1] on success. 0 with @error set on failure.
; Information ...: Round-trip exact (modulo float quantization) against _ImGui_ColorFloat4ToU32.
; ===============================================================================================================================
Func _ImGui_ColorU32ToFloat4($iU32)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $tBuf = DllStructCreate("float buf[4]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_ColorConvertU32ToFloat4", _
        "uint", $iU32, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Local $aOut[4] = [DllStructGetData($tBuf, "buf", 1), DllStructGetData($tBuf, "buf", 2), _
                       DllStructGetData($tBuf, "buf", 3), DllStructGetData($tBuf, "buf", 4)]
    Return $aOut
EndFunc

; Encode 4 floats in [0..1] into a packed U32 (0xAABBGGRR).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_ColorFloat4ToU32
; Description ...: Encode 4 float components [0..1] into a packed U32 color
; Syntax.........: _ImGui_ColorFloat4ToU32($fR, $fG, $fB, $fA)
; Parameters ....: $fR / $fG / $fB / $fA - Color components [0.0 - 1.0]
; Return values .: Returns the packed U32 (0xAABBGGRR) on success. 0 with @error set on failure.
; ===============================================================================================================================
Func _ImGui_ColorFloat4ToU32($fR, $fG, $fB, $fA)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $aRet = DllCall($__g_hImGuiDll, "uint:cdecl", "ImGui_ColorConvertFloat4ToU32", _
        "float", $fR, "float", $fG, "float", $fB, "float", $fA)
    If @error Then Return SetError(2, @error, 0)
    Return $aRet[0]
EndFunc

; RGB → HSV. All in [0..1]. Returns array[3] = (h, s, v).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_ColorRGBtoHSV
; Description ...: Convert RGB to HSV (both spaces in [0..1])
; Syntax.........: _ImGui_ColorRGBtoHSV($fR, $fG, $fB)
; Parameters ....: $fR / $fG / $fB - Source color components [0.0 - 1.0]
; Return values .: Returns array[3] = [H, S, V] in [0..1] on success. 0 with @error set on failure.
; ===============================================================================================================================
Func _ImGui_ColorRGBtoHSV($fR, $fG, $fB)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $tBuf = DllStructCreate("float buf[3]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_ColorConvertRGBtoHSV", _
        "float", $fR, "float", $fG, "float", $fB, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Local $aOut[3] = [DllStructGetData($tBuf, "buf", 1), DllStructGetData($tBuf, "buf", 2), _
                       DllStructGetData($tBuf, "buf", 3)]
    Return $aOut
EndFunc

; HSV → RGB. All in [0..1]. Returns array[3] = (r, g, b).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_ColorHSVtoRGB
; Description ...: Convert HSV to RGB (both spaces in [0..1])
; Syntax.........: _ImGui_ColorHSVtoRGB($fH, $fS, $fV)
; Parameters ....: $fH / $fS / $fV - Source color components [0.0 - 1.0]
; Return values .: Returns array[3] = [R, G, B] in [0..1] on success. 0 with @error set on failure.
; ===============================================================================================================================
Func _ImGui_ColorHSVtoRGB($fH, $fS, $fV)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $tBuf = DllStructCreate("float buf[3]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_ColorConvertHSVtoRGB", _
        "float", $fH, "float", $fS, "float", $fV, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Local $aOut[3] = [DllStructGetData($tBuf, "buf", 1), DllStructGetData($tBuf, "buf", 2), _
                       DllStructGetData($tBuf, "buf", 3)]
    Return $aOut
EndFunc

; --- Color edit options (hand-written, E.2.x) --------------------------------
; Global one-shot setter — applies to every ColorEdit / ColorPicker created
; afterwards (default display format Float/HSV/Hex, picker style, etc.).
; Typical use : call once at script init right after _ImGui_Init, before
; creating any color widgets. Out-of-range bits are silently ignored by ImGui.
; $iFlags = bitmask of $ImGuiColorEditFlags_DisplayHSV / _PickerHueBar / etc.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetColorEditOptions
; Description ...: Set global default options applied to every ColorEdit / ColorPicker created afterwards
; Syntax.........: _ImGui_SetColorEditOptions($iFlags)
; Parameters ....: $iFlags      - Bitmask of $ImGuiColorEditFlags_* (DisplayHSV, PickerHueBar, ...)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Typical use : call once at script init right after _ImGui_Init, before creating any color widgets.
;                  Out-of-range bits are silently ignored by ImGui.
; ===============================================================================================================================
Func _ImGui_SetColorEditOptions($iFlags)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetColorEditOptions", "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Focus / misc helpers (hand-written, F.2) --------------------------------

; Show or hide the keyboard navigation focus ring. Visible by default ; hide
; when starting mouse-driven, the ring reappears automatically on first key.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetNavCursorVisible
; Description ...: Show or hide the keyboard navigation focus ring
; Syntax.........: _ImGui_SetNavCursorVisible($bVisible)
; Parameters ....: $bVisible    - True to show, False to hide
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: The ring reappears automatically on the next keyboard input even after hiding.
; ===============================================================================================================================
Func _ImGui_SetNavCursorVisible($bVisible)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iVal = $bVisible ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetNavCursorVisible", "int", $iVal)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; ImGui's internal monotonic time, seconds (double). Distinct from AutoIt's
; TimerInit/TimerDiff — advances by io.DeltaTime each frame.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetTime
; Description ...: Read ImGui's internal monotonic time in seconds (double precision)
; Syntax.........: _ImGui_GetTime()
; Parameters ....: None
; Return values .: Returns the elapsed time in seconds on success. 0 with @error set on failure.
; Information ...: Advances by io.DeltaTime each rendered frame — distinct from AutoIt's TimerInit/TimerDiff.
; ===============================================================================================================================
Func _ImGui_GetTime()
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $tBuf = DllStructCreate("double t")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetTime", "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Return DllStructGetData($tBuf, "t")
EndFunc

; Frame counter — increments by 1 each rendered frame. Wraps at INT_MAX
; (~2 years at 60fps, no practical concern).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetFrameCount
; Description ...: Read the count of frames rendered since _ImGui_Init
; Syntax.........: _ImGui_GetFrameCount()
; Parameters ....: None
; Return values .: Returns the frame counter on success. 0 with @error set on failure.
; Information ...: Increments by 1 each rendered frame. Wraps at INT_MAX (~2 years at 60 fps, no practical concern).
; ===============================================================================================================================
Func _ImGui_GetFrameCount()
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetFrameCount")
    If @error Then Return SetError(2, @error, 0)
    Return $aRet[0]
EndFunc

; Look up the name of an ImGuiCol_ slot (e.g. $ImGuiCol_Text → "Text").
; Returns "" if the index is out of range or on error. $iBufSize is the max
; wchar count for the result (default 64 — names are short).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetStyleColorName
; Description ...: Look up the human-readable name of an ImGuiCol_ slot
; Syntax.........: _ImGui_GetStyleColorName($iColIdx[, $iBufSize = 64])
; Parameters ....: $iColIdx     - $ImGuiCol_* index (e.g. $ImGuiCol_Text)
;                  $iBufSize    - Output buffer capacity in wchars
; Return values .: Returns the slot name on success. Empty string with @error set
;                  (1=DLL not loaded, 2=DllCall failed, 3=DLL status non-zero and non-truncation).
; ===============================================================================================================================
Func _ImGui_GetStyleColorName($iColIdx, $iBufSize = 64)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, "")
    Local $tBuf = DllStructCreate("wchar buf[" & $iBufSize & "]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetStyleColorName", _
        "int", $iColIdx, "ptr", DllStructGetPtr($tBuf), "int", $iBufSize)
    If @error Then Return SetError(2, @error, "")
    If $aRet[0] <> 0 And $aRet[0] <> 4 Then Return SetError(3, $aRet[0], "")
    Return DllStructGetData($tBuf, "buf")
EndFunc

; Swap the global ImGui theme. $iTheme : 0=Dark (default), 1=Light, 2=Classic.
; Idempotent — call as often as you want. Re-applies the multi-viewport tweak
; (opaque WindowBg + zero WindowRounding) so dragged-out windows stay clean.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetStyleTheme
; Description ...: Swap the global ImGui visual theme
; Syntax.........: _ImGui_SetStyleTheme($iTheme)
; Parameters ....: $iTheme      - 0=Dark (default), 1=Light, 2=Classic
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Idempotent — re-applies the multi-viewport tweak (opaque WindowBg + zero WindowRounding)
;                  so dragged-out windows stay clean.
; ===============================================================================================================================
Func _ImGui_SetStyleTheme($iTheme)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetStyleTheme", "int", $iTheme)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Phase G — finition mix (TextLink + SetMouseCursor + IsKey* + StyleEditor
; +  Cursor pos markers + CalcTextSize) -----------------------------------------
;
; TextLink lives in the generated wrappers (clickable category) — created via
; _ImGui_CreateTextLink and clicked via _ImGui_WasClicked. Likewise the
; SetCursorPos / SetCursorPosX / SetCursorPosY markers live in imgui_generated.au3
; (display category). Everything below is hand-written.

; Sticky mouse-cursor override. Pass a $ImGuiMouseCursor_* value (e.g.
; $ImGuiMouseCursor_Hand) ; pass -1 (= $ImGuiMouseCursor_None) to release —
; ImGui then resumes its usual per-widget behaviour (I-beam on InputText,
; resize arrows, etc.). Canonical usage : in your loop, if hovering a custom
; widget set Hand else release.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetMouseCursor
; Description ...: Override the mouse cursor for the current frame
; Syntax.........: _ImGui_SetMouseCursor($iCursor)
; Parameters ....: $iCursor     - $ImGuiMouseCursor_* value (e.g. _Hand, _ResizeNS). Pass -1 (_None) to release.
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Re-call each frame to keep the override active — ImGui resets the cursor every NewFrame.
;                  Canonical use : set Hand while hovering a custom widget, release otherwise.
; ===============================================================================================================================
Func _ImGui_SetMouseCursor($iCursor)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetMouseCursor", "int", $iCursor)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- ImGui-side keyboard queries (G.3) -----------------------------------------
; Distinct from AutoIt's _IsPressed : these read ImGui's input state, so they
; only return true when our window has focus AND the key isn't already consumed
; by an ImGui widget (Shortcut, InputText, …). Use them when you want a hotkey
; that fires ONLY while the panel is in focus, not while the bot is in-game.

; $iKey : an $ImGuiKey_* constant (e.g. $ImGuiKey_Space, $ImGuiKey_F1).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsKeyDown
; Description ...: Report whether an ImGui key is currently held down
; Syntax.........: _ImGui_IsKeyDown($iKey)
; Parameters ....: $iKey        - Key code ($ImGuiKey_*)
; Return values .: Returns True while the key is held. False otherwise or DLL not loaded.
; Information ...: Reads ImGui's input state — only true when our window has focus AND the key isn't consumed by a widget.
; ===============================================================================================================================
Func _ImGui_IsKeyDown($iKey)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsKeyDown", "int", $iKey)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 1)
EndFunc

; $bRepeat : True (default) = repeats fire at io.KeyRepeatDelay/Rate intervals ;
; False = initial press only.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsKeyPressed
; Description ...: Report whether an ImGui key was just pressed (with optional repeat)
; Syntax.........: _ImGui_IsKeyPressed($iKey[, $bRepeat = True])
; Parameters ....: $iKey        - Key code ($ImGuiKey_*)
;                  $bRepeat     - True (default) = repeats fire at io.KeyRepeatDelay/Rate ; False = initial press only
; Return values .: Returns True on press events. False otherwise or DLL not loaded.
; ===============================================================================================================================
Func _ImGui_IsKeyPressed($iKey, $bRepeat = True)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iRep = $bRepeat ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsKeyPressed", _
        "int", $iKey, "int", $iRep)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsKeyReleased
; Description ...: Report whether an ImGui key was just released this frame
; Syntax.........: _ImGui_IsKeyReleased($iKey)
; Parameters ....: $iKey        - Key code ($ImGuiKey_*)
; Return values .: Returns True on the release edge. False otherwise or DLL not loaded.
; ===============================================================================================================================
Func _ImGui_IsKeyReleased($iKey)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsKeyReleased", "int", $iKey)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 1)
EndFunc

; --- Mouse helpers complete (J.1) -------------------------------------------
; $iButton convention everywhere : 0 = Left, 1 = Right, 2 = Middle. Distinct
; from AutoIt's _IsPressed — these reflect ImGui's per-frame input snapshot
; (only true when our window has focus and the click wasn't already consumed).

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsMouseDown
; Description ...: Report whether a mouse button is currently held down
; Syntax.........: _ImGui_IsMouseDown([$iButton = 0])
; Parameters ....: $iButton     - Mouse button (0=Left, 1=Right, 2=Middle)
; Return values .: Returns True while the button is held. False otherwise or DLL not loaded.
; Information ...: Reflects ImGui's per-frame input snapshot — only true when our window has focus AND the click is not consumed.
; ===============================================================================================================================
Func _ImGui_IsMouseDown($iButton = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsMouseDown", "int", $iButton)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 1)
EndFunc

; $bRepeat True = also fires on repeat events ; False = initial press only.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsMouseClicked
; Description ...: Report whether a mouse button was just clicked (with optional repeat)
; Syntax.........: _ImGui_IsMouseClicked([$iButton = 0, $bRepeat = False])
; Parameters ....: $iButton     - Mouse button (0=Left, 1=Right, 2=Middle)
;                  $bRepeat     - True = also fires on repeat events ; False = initial press only
; Return values .: Returns True on the click event. False otherwise or DLL not loaded.
; ===============================================================================================================================
Func _ImGui_IsMouseClicked($iButton = 0, $bRepeat = False)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iRep = $bRepeat ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsMouseClicked", _
        "int", $iButton, "int", $iRep)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsMouseReleased
; Description ...: Report whether a mouse button was just released this frame
; Syntax.........: _ImGui_IsMouseReleased([$iButton = 0])
; Parameters ....: $iButton     - Mouse button (0=Left, 1=Right, 2=Middle)
; Return values .: Returns True on the release edge. False otherwise or DLL not loaded.
; ===============================================================================================================================
Func _ImGui_IsMouseReleased($iButton = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsMouseReleased", "int", $iButton)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsMouseDoubleClicked
; Description ...: Report whether a mouse button was just double-clicked this frame
; Syntax.........: _ImGui_IsMouseDoubleClicked([$iButton = 0])
; Parameters ....: $iButton     - Mouse button (0=Left, 1=Right, 2=Middle)
; Return values .: Returns True on the double-click event. False otherwise or DLL not loaded.
; Information ...: Use _ImGui_GetMouseClickedCount to distinguish double vs. triple click etc.
; ===============================================================================================================================
Func _ImGui_IsMouseDoubleClicked($iButton = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsMouseDoubleClicked", "int", $iButton)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 1)
EndFunc

; $fThreshold < 0 = use io.MouseDragThreshold (default ~6px). Otherwise a
; pixel distance from the initial click position before "dragging" turns true.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsMouseDragging
; Description ...: Report whether the user is currently dragging with a mouse button
; Syntax.........: _ImGui_IsMouseDragging([$iButton = 0, $fThreshold = -1.0])
; Parameters ....: $iButton     - Mouse button (0=Left, 1=Right, 2=Middle)
;                  $fThreshold  - Pixel distance from initial click before "dragging" turns true.
;                                 -1 = use io.MouseDragThreshold (default ~6px).
; Return values .: Returns True while dragging. False otherwise or DLL not loaded.
; ===============================================================================================================================
Func _ImGui_IsMouseDragging($iButton = 0, $fThreshold = -1.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsMouseDragging", _
        "int", $iButton, "float", $fThreshold)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 1)
EndFunc

; Reset the drag delta for a button (so the next _ImGui_GetMouseDragDelta starts
; from the current mouse position rather than the original click). Useful when
; consuming a drag in chunks — e.g. "pan the canvas by the current delta, then
; reset so the next frame's delta is the incremental move".
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_ResetMouseDragDelta
; Description ...: Reset the accumulated drag delta of a mouse button
; Syntax.........: _ImGui_ResetMouseDragDelta([$iButton = 0])
; Parameters ....: $iButton     - Mouse button (0=Left, 1=Right, 2=Middle)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Use after consuming a drag in chunks — e.g. pan the canvas by current delta, then reset
;                  so the next frame's delta is the incremental move.
; ===============================================================================================================================
Func _ImGui_ResetMouseDragDelta($iButton = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_ResetMouseDragDelta", "int", $iButton)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Rect in ImGui screen-space coords (the same space as _ImGui_GetMousePos).
; NOTE : the $bClip parameter is accepted for API symmetry but always treated
; as False at the DLL — clip=true would dereference ImGui's current window
; pointer, which is null on the AutoIt thread (we run between frames). If you
; need window-local clipping, intersect the rect with _ImGui_GetWindowPos +
; _ImGui_GetWindowSize before calling.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsMouseHoveringRect
; Description ...: Report whether the mouse is inside an arbitrary rect (ImGui screen-space)
; Syntax.........: _ImGui_IsMouseHoveringRect($fMinX, $fMinY, $fMaxX, $fMaxY[, $bClip = True])
; Parameters ....: $fMinX/$fMinY - Top-left corner in screen pixels
;                  $fMaxX/$fMaxY - Bottom-right corner in screen pixels
;                  $bClip       - Accepted for API symmetry but always treated as False DLL-side
; Return values .: Returns True while hovering. False otherwise or DLL not loaded.
; Information ...: For window-local clipping, intersect the rect with _ImGui_GetWindowPos + _ImGui_GetWindowSize first.
; ===============================================================================================================================
Func _ImGui_IsMouseHoveringRect($fMinX, $fMinY, $fMaxX, $fMaxY, $bClip = True)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iClip = $bClip ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsMouseHoveringRect", _
        "float", $fMinX, "float", $fMinY, "float", $fMaxX, "float", $fMaxY, "int", $iClip)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 1)
EndFunc

; True iff io.MousePos was last reported inside one of the registered viewports
; (i.e. not lost / off-screen). Cheap pre-check before reading GetMousePos.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsMousePosValid
; Description ...: Report whether the last reported mouse position is inside a registered viewport
; Syntax.........: _ImGui_IsMousePosValid()
; Parameters ....: None
; Return values .: Returns True when the mouse is on-screen. False when lost / off-screen or DLL not loaded.
; Information ...: Cheap pre-check before reading _ImGui_GetMousePos.
; ===============================================================================================================================
Func _ImGui_IsMousePosValid()
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsMousePosValid")
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 1)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsAnyMouseDown
; Description ...: Report whether any mouse button is currently held down
; Syntax.........: _ImGui_IsAnyMouseDown()
; Parameters ....: None
; Return values .: Returns True while at least one button is held. False otherwise or DLL not loaded.
; ===============================================================================================================================
Func _ImGui_IsAnyMouseDown()
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsAnyMouseDown")
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 1)
EndFunc

; Number of clicks accumulated within io.MouseDoubleClickTime — useful to
; distinguish double-click (2) from triple-click (3) in custom shortcut logic.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetMouseClickedCount
; Description ...: Read the number of clicks accumulated within io.MouseDoubleClickTime
; Syntax.........: _ImGui_GetMouseClickedCount([$iButton = 0])
; Parameters ....: $iButton     - Mouse button (0=Left, 1=Right, 2=Middle)
; Return values .: Returns the click count on success. 0 with @error set on failure.
; Information ...: Distinguish 2=double from 3=triple click etc. for custom shortcut logic.
; ===============================================================================================================================
Func _ImGui_GetMouseClickedCount($iButton = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetMouseClickedCount", "int", $iButton)
    If @error Then Return SetError(2, @error, 0)
    Return $aRet[0]
EndFunc

; Returns the current $ImGuiMouseCursor_* value (-1 = $ImGuiMouseCursor_None).
; Distinct from _ImGui_SetMouseCursor in that it reads ImGui's CURRENT decision
; (which may be overridden by our sticky setter, or driven by hovered widgets).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetMouseCursor
; Description ...: Read ImGui's current mouse cursor decision
; Syntax.........: _ImGui_GetMouseCursor()
; Parameters ....: None
; Return values .: Returns the $ImGuiMouseCursor_* value (-1 = _None). 0 with @error set on DLL failure.
; Information ...: Reflects ImGui's CURRENT decision (overrides + hovered widget behavior).
;                  Distinct from _ImGui_SetMouseCursor which queues a per-frame override.
; ===============================================================================================================================
Func _ImGui_GetMouseCursor()
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetMouseCursor")
    If @error Then Return SetError(2, @error, 0)
    Return $aRet[0]
EndFunc

; Force io.WantCaptureMouse for the next frame only. True = ImGui takes the
; mouse from the host application even if no widget is hovered (useful to
; swallow a click). False = ImGui releases it.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetNextFrameWantCaptureMouse
; Description ...: Force io.WantCaptureMouse for the next frame only
; Syntax.........: _ImGui_SetNextFrameWantCaptureMouse($bWant)
; Parameters ....: $bWant       - True = ImGui takes the mouse from the host app ; False = ImGui releases it
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Useful to swallow a click in custom logic, or to release the cursor for one frame on demand.
; ===============================================================================================================================
Func _ImGui_SetNextFrameWantCaptureMouse($bWant)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iVal = $bWant ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetNextFrameWantCaptureMouse", "int", $iVal)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Mouse niches (M.4) ------------------------------------------------------

; Delayed mouse release : True on the frame the release fires AND the prior
; down event was at least $fDelay seconds ago. Per ImGui's note, the canonical
; pairing is with delay >= io.MouseDoubleClickTime to avoid colliding with
; the double-click idiom. Use case : "click then wait, then act" — Windows
; Explorer single-click rename, deferred action confirmation, etc.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsMouseReleasedWithDelay
; Description ...: Report mouse release ONLY if the prior down event was at least $fDelay seconds ago
; Syntax.........: _ImGui_IsMouseReleasedWithDelay([$iButton = 0, $fDelay = 0.5])
; Parameters ....: $iButton     - Mouse button (0=Left, 1=Right, 2=Middle)
;                  $fDelay      - Minimum hold time in seconds before the release fires
; Return values .: Returns True on qualifying release events. False otherwise or DLL not loaded.
; Information ...: Canonical pairing : $fDelay >= io.MouseDoubleClickTime to avoid colliding with the double-click idiom.
;                  Use case : Explorer-style single-click rename or deferred action confirmation.
; ===============================================================================================================================
Func _ImGui_IsMouseReleasedWithDelay($iButton = 0, $fDelay = 0.5)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsMouseReleasedWithDelay", _
        "int", $iButton, "float", $fDelay)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 1)
EndFunc

; --- PopupOpenMousePos marker (M.4) ------------------------------------------
; Marker widget that latches ImGui::GetMousePosOnOpeningCurrentPopup() — the
; mouse position at the time the enclosing popup was opened, frozen even when
; the mouse moves afterward. Place it as a CHILD of a Popup / PopupModal /
; ContextPopup (via _ImGui_SetParent) ; otherwise it never renders inside a
; popup scope and the latch never updates.
;
; Why a marker widget rather than a free function : ImGui's free function
; reads g.BeginPopupStack which is empty between frames — from the AutoIt
; thread (always between frames under our frame mutex) it falls back to the
; current mouse pos, which defeats the purpose. The marker runs DURING the
; popup's Render() on the render thread where the stack is non-empty.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePopupOpenMousePos
; Description ...: Create a marker that latches the mouse position at the moment the enclosing popup opened
; Syntax.........: _ImGui_CreatePopupOpenMousePos($sId)
; Parameters ....: $sId         - Stable marker identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Place as a CHILD of a Popup / PopupModal / ContextPopup (via _ImGui_SetParent) — outside a popup
;                  scope the marker never updates. Read the latched value via _ImGui_GetPopupOpenMousePos.
; ===============================================================================================================================
Func _ImGui_CreatePopupOpenMousePos($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePopupOpenMousePos", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Read the latched pos. Returns array[2] = [x, y] in screen pixels. Stays at
; the value last latched when the popup was open ; (0, 0) until the marker has
; rendered at least once inside a popup body.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetPopupOpenMousePos
; Description ...: Read the latched mouse position from a CreatePopupOpenMousePos marker
; Syntax.........: _ImGui_GetPopupOpenMousePos($sMarkerId)
; Parameters ....: $sMarkerId   - Identifier of the matching _ImGui_CreatePopupOpenMousePos marker
; Return values .: Returns array[2] = [x, y] in screen pixels. (0, 0) until the marker has rendered inside a popup at least once.
;                  Sets @error on DLL failure.
; ===============================================================================================================================
Func _ImGui_GetPopupOpenMousePos($sMarkerId)
    Local $aOut[2] = [0.0, 0.0]
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, $aOut)
    Local $tBuf = DllStructCreate("float xy[2]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetPopupOpenMousePos", _
        "wstr", $sMarkerId, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, $aOut)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], $aOut)
    $aOut[0] = DllStructGetData($tBuf, "xy", 1)
    $aOut[1] = DllStructGetData($tBuf, "xy", 2)
    Return $aOut
EndFunc

; --- Keyboard helpers complete (J.2) -----------------------------------------

; $iKeyChord : a key OR'd with one or more $ImGuiMod_* modifier bits.
; e.g. $ImGuiMod_Ctrl + $ImGuiKey_S for Ctrl+S, or just $ImGuiKey_F1 for no
; modifier. Returns True only on the press event (no repeat).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsKeyChordPressed
; Description ...: Report whether a key chord (key + modifiers) was just pressed
; Syntax.........: _ImGui_IsKeyChordPressed($iKeyChord)
; Parameters ....: $iKeyChord   - A $ImGuiKey_* OR'd with one or more $ImGuiMod_* modifier bits
; Return values .: Returns True on press events (no repeat). False otherwise.
; Information ...: e.g. $ImGuiMod_Ctrl + $ImGuiKey_S for Ctrl+S ; just $ImGuiKey_F1 for no modifier.
; ===============================================================================================================================
Func _ImGui_IsKeyChordPressed($iKeyChord)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsKeyChordPressed", "int", $iKeyChord)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 1)
EndFunc

; Returns how many press events fired this frame for $iKey at the given
; repeat_delay/rate (seconds). Useful for "Page Down held = scroll N rows
; per frame at this cadence".
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetKeyPressedAmount
; Description ...: Count how many press events fired this frame for $iKey at the given repeat rate
; Syntax.........: _ImGui_GetKeyPressedAmount($iKey, $fRepeatDelay, $fRate)
; Parameters ....: $iKey        - Key code ($ImGuiKey_*)
;                  $fRepeatDelay - Delay before the first repeat in seconds
;                  $fRate       - Interval between subsequent repeats in seconds
; Return values .: Returns the press count on success. 0 with @error set on DLL failure.
; Information ...: Useful for "Page Down held = scroll N rows per frame at this cadence".
; ===============================================================================================================================
Func _ImGui_GetKeyPressedAmount($iKey, $fRepeatDelay, $fRate)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetKeyPressedAmount", _
        "int", $iKey, "float", $fRepeatDelay, "float", $fRate)
    If @error Then Return SetError(2, @error, 0)
    Return $aRet[0]
EndFunc

; Human-readable name of an ImGuiKey_ value (e.g. $ImGuiKey_Tab → "Tab",
; $ImGuiKey_A → "A"). Returns "" on shutdown or invalid key.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetKeyName
; Description ...: Look up the human-readable name of an ImGuiKey_ value
; Syntax.........: _ImGui_GetKeyName($iKey[, $iBufSize = 32])
; Parameters ....: $iKey        - Key code ($ImGuiKey_*)
;                  $iBufSize    - Output buffer capacity in wchars
; Return values .: Returns the key name (e.g. "Tab", "A") on success. Empty string with @error set on failure.
; ===============================================================================================================================
Func _ImGui_GetKeyName($iKey, $iBufSize = 32)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, "")
    Local $tBuf = DllStructCreate("wchar buf[" & $iBufSize & "]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetKeyName", _
        "int", $iKey, "ptr", DllStructGetPtr($tBuf), "int", $iBufSize)
    If @error Then Return SetError(2, @error, "")
    If $aRet[0] <> 0 And $aRet[0] <> 4 Then Return SetError(3, $aRet[0], "")
    Return DllStructGetData($tBuf, "buf")
EndFunc

; Counterpart to SetNextFrameWantCaptureMouse — force keyboard capture state
; for the next frame only.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetNextFrameWantCaptureKeyboard
; Description ...: Force io.WantCaptureKeyboard for the next frame only
; Syntax.........: _ImGui_SetNextFrameWantCaptureKeyboard($bWant)
; Parameters ....: $bWant       - True = ImGui takes keyboard input from the host app ; False = ImGui releases it
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; ===============================================================================================================================
Func _ImGui_SetNextFrameWantCaptureKeyboard($bWant)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iVal = $bWant ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetNextFrameWantCaptureKeyboard", "int", $iVal)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Style Editor (G.4) — debug window with live theme tuner ------------------
; Same round-trip pattern as the D.2 windows : the X close button on the
; wrapper Begin() propagates back to the AutoIt state on the next poll.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_ShowStyleEditor
; Description ...: Show or hide ImGui's built-in Style Editor (live theme tuner)
; Syntax.........: _ImGui_ShowStyleEditor([$bShow = True])
; Parameters ....: $bShow       - True to show, False to hide
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Same round-trip pattern as the D.2 debug windows : the X close button propagates back to AutoIt state.
; ===============================================================================================================================
Func _ImGui_ShowStyleEditor($bShow = True)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iVal = $bShow ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_ShowStyleEditor", "int", $iVal)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_IsShowingStyleEditor
; Description ...: Report whether ImGui's Style Editor window is currently shown
; Syntax.........: _ImGui_IsShowingStyleEditor()
; Parameters ....: None
; Return values .: Returns True while the Style Editor is shown. False otherwise.
; ===============================================================================================================================
Func _ImGui_IsShowingStyleEditor()
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_IsShowingStyleEditor")
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 1)
EndFunc

; --- Cursor position query (G.5, marker-based) --------------------------------
; SetCursorPos / SetCursorPosX / SetCursorPosY are created via the generated
; wrappers (display category). To READ the current cursor position, create a
; GetCursorPos marker as a child of the Window/Child/Group where the position
; matters ; the DLL latches ImGui::GetCursorPos() during that marker's Render()
; and _ImGui_GetCursorPos returns the latched window-local (x, y).
;
; CreateGetCursorPos is hand-written (not generator-emitted) because the widget
; has its own latched state — outside the display marker shape.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateGetCursorPos
; Description ...: Create a marker that latches ImGui::GetCursorPos() during its Render
; Syntax.........: _ImGui_CreateGetCursorPos($sId)
; Parameters ....: $sId         - Stable marker identifier (must be unique in the tree)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Place as a child of the Window/Child/Group where the position matters. Read with _ImGui_GetCursorPos.
; ===============================================================================================================================
Func _ImGui_CreateGetCursorPos($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateGetCursorPos", "wstr", $sId)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetCursorPos
; Description ...: Read the latched window-local cursor position from a GetCursorPos marker
; Syntax.........: _ImGui_GetCursorPos($sId)
; Parameters ....: $sId         - Identifier of the matching _ImGui_CreateGetCursorPos marker
; Return values .: Returns array[2] = [x, y] in window-local pixels on success. 0 with @error set on failure.
; ===============================================================================================================================
Func _ImGui_GetCursorPos($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $tBuf = DllStructCreate("float buf[2]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetCursorPos", _
        "wstr", $sId, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Local $aOut[2] = [DllStructGetData($tBuf, "buf", 1), DllStructGetData($tBuf, "buf", 2)]
    Return $aOut
EndFunc

; --- CalcTextSize (G.6) — measure a string in the active font ----------------
; Useful for manual layout (centering, right-alignment, custom panels). $fWrapWidth
; <= 0 = no wrap ; > 0 = wrap at that pixel width. Returns array[2] = (w, h).
; (0, 0) on error.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CalcTextSize
; Description ...: Measure a string in the currently active font with optional wrapping
; Syntax.........: _ImGui_CalcTextSize($sText[, $fWrapWidth = -1.0])
; Parameters ....: $sText       - Text to measure (UTF-8)
;                  $fWrapWidth  - Wrap width in pixels (<= 0 means no wrap)
; Return values .: Returns array[2] = [width, height] in pixels on success. 0 with @error set on failure.
; Information ...: Useful for manual layout (centering, right-alignment, custom panels).
; ===============================================================================================================================
Func _ImGui_CalcTextSize($sText, $fWrapWidth = -1.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, 0)
    Local $tBuf = DllStructCreate("float buf[2]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CalcTextSize", _
        "wstr", $sText, "float", $fWrapWidth, "ptr", DllStructGetPtr($tBuf))
    If @error Then Return SetError(2, @error, 0)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], 0)
    Local $aOut[2] = [DllStructGetData($tBuf, "buf", 1), DllStructGetData($tBuf, "buf", 2)]
    Return $aOut
EndFunc

; Enable / disable — disabled widgets are greyed and don't accept interaction.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetEnabled
; Description ...: Enable or disable a widget (disabled widgets are greyed and reject interaction)
; Syntax.........: _ImGui_SetEnabled($sId, $bEnabled)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $bEnabled    - True to enable, False to disable
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; ===============================================================================================================================
Func _ImGui_SetEnabled($sId, $bEnabled)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iVal = $bEnabled ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetEnabled", "wstr", $sId, "int", $iVal)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Move a widget under a different container. Empty $sParent = back to root.
; @extended carries the DLL status on failure (2=unknown child, 3=unknown
; parent, 4=cycle attempt). Returns True on success.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetParent
; Description ...: Re-parent a widget under a different container
; Syntax.........: _ImGui_SetParent($sChild[, $sParent = ""])
; Parameters ....: $sChild      - Identifier of the widget to move
;                  $sParent     - Identifier of the new parent container (empty = back to root)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=tree error — @extended = 2=unknown child, 3=unknown parent, 4=cycle attempt)
; ===============================================================================================================================
Func _ImGui_SetParent($sChild, $sParent = "")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetParent", "wstr", $sChild, "wstr", $sParent)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; --- Dynamic List ------------------------------------------------------------
; A container-like widget whose item set is replaced wholesale via
; _ImGui_SetListItems(). Scroll position and per-row visual state survive
; updates (the DLL renders each row inside PushID(index)); selection is
; preserved by content — see ApplyItems() in list_widget.cpp.
;
; $fW = $fH = 0 means "fill remaining content region". Sensible defaults inside
; a sized Window or Child.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateList
; Description ...: Create a dynamic List widget whose items can be replaced wholesale at runtime
; Syntax.........: _ImGui_CreateList($sId[, $sLabel = "", $fW = 0, $fH = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label
;                  $fW          - Width in pixels (0 = fill remaining content region)
;                  $fH          - Height in pixels (0 = fill remaining content region)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Populate via _ImGui_SetListItems. Scroll position and selection survive content updates.
; ===============================================================================================================================
Func _ImGui_CreateList($sId, $sLabel = "", $fW = 0, $fH = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateList", _
        "wstr", $sId, "wstr", $sLabel, "float", $fW, "float", $fH)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Replace the list's content. $aItems is a 1D AutoIt array of strings. They
; are joined with $sSep ("|" by default) and passed to the DLL as one wstr;
; the DLL splits them back on the same separator.
;
; Validation: if any item contains $sSep, SetError(4) — pick a different
; separator (e.g. Chr(31), the ASCII "Unit Separator" control char, which is
; never present in normal text).
;
; @extended on success/failure mirrors the DLL status code (2=unknown id,
; 3=widget is not a list).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetListItems
; Description ...: Replace the items of a List widget with a 1D AutoIt array
; Syntax.........: _ImGui_SetListItems($sId, $aItems[, $sSep = "|"])
; Parameters ....: $sId         - Identifier of the List widget
;                  $aItems      - 1D string array — must not contain $sSep in any element
;                  $sSep        - Separator used to marshal the array across the DLL boundary
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a List, 4=item contains $sSep — @extended = offending index,
;                  5=$aItems is not an array)
; Information ...: Pick Chr(31) (Unit Separator) as $sSep if "|" can appear in items. Selection is preserved by content.
; ===============================================================================================================================
Func _ImGui_SetListItems($sId, $aItems, $sSep = "|")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If Not IsArray($aItems) Then Return SetError(5, 0, False)

    Local $iN = UBound($aItems)
    Local $sJoined = ""
    For $i = 0 To $iN - 1
        Local $sItem = String($aItems[$i])
        If StringInStr($sItem, $sSep, 1) > 0 Then
            ; Separator collision — caller must choose a different separator.
            Return SetError(4, $i, False)
        EndIf
        If $i > 0 Then $sJoined &= $sSep
        $sJoined &= $sItem
    Next

    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetListItems", _
        "wstr", $sId, "wstr", $sJoined, "wstr", $sSep)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; Returns the selected index, or -1 if no selection / widget not a list.
; _ImGui_GetValueInt($sId) works as an alias for this on a list widget.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetListSelection
; Description ...: Read the index of the currently selected row in a List or Combo widget
; Syntax.........: _ImGui_GetListSelection($sId)
; Parameters ....: $sId         - Identifier of the List / Combo widget
; Return values .: Returns the selected index (>=0) on success. -1 if no selection / widget not a list / DLL not loaded.
; Information ...: _ImGui_GetValueInt($sId) is an alias on list/combo widgets.
; ===============================================================================================================================
Func _ImGui_GetListSelection($sId)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, -1)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetListSelection", "wstr", $sId)
    If @error Then Return SetError(2, @error, -1)
    Return $aRet[0]
EndFunc

; Programmatic selection. -1 clears, valid index sets, out-of-range clears.
; Never latches _ImGui_HasChanged — strict semantics, same as Set*Bool/Float/Int.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetListSelection
; Description ...: Programmatically set the selected row of a List or Combo widget
; Syntax.........: _ImGui_SetListSelection($sId[, $iIndex = -1])
; Parameters ....: $sId         - Identifier of the List / Combo widget
;                  $iIndex      - 0-based selected index ; -1 clears the selection ; out-of-range also clears
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a list/combo)
; Information ...: Never latches _ImGui_HasChanged — strict semantics, same as _ImGui_SetValue*.
; ===============================================================================================================================
Func _ImGui_SetListSelection($sId, $iIndex = -1)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetListSelection", _
        "wstr", $sId, "int", $iIndex)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; --- InputText / InputTextMultiline ------------------------------------------
; A single string-valued widget family. ImGui owns the buffer in-place while
; the user types ; we hand it a fixed-size buffer at creation and never grow
; it. $iMaxLength caps user input (default 256) ; $iFlags accepts any combo
; of the $ImGuiInputTextFlags_* constants below.
;
; Marshalling of the get : the caller allocates the receiving wide-char buffer
; via DllStructCreate, the DLL writes into it. The struct-and-pointer pattern
; is verbose but explicit about size — much safer than relying on the "wstr"
; out-param implicit allocator across AutoIt versions.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateInputText
; Description ...: Create a single-line InputText widget (string-valued)
; Syntax.........: _ImGui_CreateInputText($sId[, $sLabel = "", $sDefault = "", $iMaxLength = 256, $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label
;                  $sDefault    - Initial text content (UTF-8)
;                  $iMaxLength  - Maximum buffer length in chars
;                  $iFlags      - Bitmask of $ImGuiInputTextFlags_*
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read / write via _ImGui_GetValueString / _ImGui_SetValueString.
; ===============================================================================================================================
Func _ImGui_CreateInputText($sId, $sLabel = "", $sDefault = "", $iMaxLength = 256, $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInputText", _
        "wstr", $sId, "wstr", $sLabel, "wstr", $sDefault, _
        "int",  $iMaxLength, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Multiline input — $fW/$fH set the rendered box size (0,0 = ImGui auto-size).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateInputTextMultiline
; Description ...: Create a multiline InputText widget
; Syntax.........: _ImGui_CreateInputTextMultiline($sId[, $sLabel = "", $sDefault = "", $iMaxLength = 1024, $iFlags = 0, $fW = 0, $fH = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label
;                  $sDefault    - Initial text content (UTF-8)
;                  $iMaxLength  - Maximum buffer length in chars
;                  $iFlags      - Bitmask of $ImGuiInputTextFlags_*
;                  $fW / $fH    - Rendered box size in pixels (0, 0 = ImGui auto-size)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read / write via _ImGui_GetValueString / _ImGui_SetValueString.
; ===============================================================================================================================
Func _ImGui_CreateInputTextMultiline($sId, $sLabel = "", $sDefault = "", $iMaxLength = 1024, $iFlags = 0, $fW = 0, $fH = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInputTextMultiline", _
        "wstr", $sId, "wstr", $sLabel, "wstr", $sDefault, _
        "int",  $iMaxLength, "int", $iFlags, _
        "float", $fW, "float", $fH)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Reads the current buffer contents. $iBufSize is the size (in wchar) of the
; AutoIt-side receiving buffer — default 4096 covers max_length up to 4095
; ASCII chars (less if multi-byte UTF-8 expands beyond BMP). Increase if you
; created the widget with a larger max_length AND expect long values.
;
; SetError(3) carries the DLL status in @extended : 2=unknown id, 3=widget is
; not string-valued, 4=value didn't fit (returned content is still usable but
; possibly truncated — @extended=4 is treated as soft error so the caller can
; ignore it if it's OK with truncation).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_GetValueString
; Description ...: Read the current string contents of an InputText widget
; Syntax.........: _ImGui_GetValueString($sId[, $iBufSize = 4096])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $iBufSize    - Receiving buffer size in wchars
; Return values .: Returns the string contents on success. Empty string with @error set
;                  (1=DLL not loaded, 2=DllCall failed, 3=unknown id or not string-valued).
; Information ...: Status 4 (truncation) is surfaced via @extended on success — the partial string is still returned.
;                  Bump $iBufSize when @extended=4 if you want the full payload.
; ===============================================================================================================================
Func _ImGui_GetValueString($sId, $iBufSize = 4096)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, "")
    If $iBufSize < 1 Then $iBufSize = 1
    Local $tBuf = DllStructCreate("wchar buf[" & $iBufSize & "]")
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_GetValueString", _
        "wstr", $sId, _
        "ptr",  DllStructGetPtr($tBuf), _
        "int",  $iBufSize)
    If @error Then Return SetError(2, @error, "")
    Local $iStatus = $aRet[0]
    Local $sOut = DllStructGetData($tBuf, "buf")
    ; Status 4 = truncated. Still return the partial string ; surface via @extended.
    If $iStatus = 0 Then Return $sOut
    If $iStatus = 4 Then Return SetError(0, 4, $sOut)   ; soft : caller can detect via @extended
    Return SetError(3, $iStatus, "")
EndFunc

; Programmatic set — truncates server-side to (max_length-1). Never latches.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetValueString
; Description ...: Programmatically write a string into an InputText widget
; Syntax.........: _ImGui_SetValueString($sId, $sValue)
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sValue      - New string content (UTF-8) ; server-side truncated to (max_length - 1)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not string-valued)
; Information ...: Programmatic writes never latch the changed flag — see [[imgui_retained_strict_changed]].
; ===============================================================================================================================
Func _ImGui_SetValueString($sId, $sValue)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetValueString", _
        "wstr", $sId, "wstr", $sValue)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; --- Combo -------------------------------------------------------------------
; Dropdown combo. Same data model as List under the hood (item set + selected
; index + by-content preservation across SetComboItems). Selection is read via
; the same _ImGui_GetListSelection / _ImGui_HasChanged calls already used for
; List — they dispatch on the shared base class.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateCombo
; Description ...: Create a Combo widget (dropdown selector)
; Syntax.........: _ImGui_CreateCombo($sId[, $sLabel = "", $iFlags = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label
;                  $iFlags      - Bitmask of $ImGuiComboFlags_*
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Populate via _ImGui_SetComboItems. Read selection via _ImGui_GetListSelection (shared base class).
; ===============================================================================================================================
Func _ImGui_CreateCombo($sId, $sLabel = "", $iFlags = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateCombo", _
        "wstr", $sId, "wstr", $sLabel, "int", $iFlags)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Replace the combo's content. Same validation/marshalling as SetListItems —
; items are joined with $sSep ("|" by default), the wrapper rejects items
; containing the separator (SetError(4)).
; @extended on failure : 2=unknown id, 3=widget is not a Combo, 4=sep collision.
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetComboItems
; Description ...: Replace the dropdown items of a Combo widget with a 1D AutoIt array
; Syntax.........: _ImGui_SetComboItems($sId, $aItems[, $sSep = "|"])
; Parameters ....: $sId         - Identifier of the Combo widget
;                  $aItems      - 1D string array — must not contain $sSep in any element
;                  $sSep        - Separator used to marshal the array across the DLL boundary
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a Combo, 4=item contains $sSep — @extended = offending index,
;                  5=$aItems is not an array)
; ===============================================================================================================================
Func _ImGui_SetComboItems($sId, $aItems, $sSep = "|")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If Not IsArray($aItems) Then Return SetError(5, 0, False)

    Local $iN = UBound($aItems)
    Local $sJoined = ""
    For $i = 0 To $iN - 1
        Local $sItem = String($aItems[$i])
        If StringInStr($sItem, $sSep, 1) > 0 Then Return SetError(4, $i, False)
        If $i > 0 Then $sJoined &= $sSep
        $sJoined &= $sItem
    Next

    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetComboItems", _
        "wstr", $sId, "wstr", $sJoined, "wstr", $sSep)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; --- Plot widgets (PlotLines, PlotHistogram) ---------------------------------
; Display-only graphs. The script pushes a fresh float array via
; _ImGui_SetPlotValues at its own cadence. scale_min/scale_max default to
; FLT_MAX (auto-scale) ; override at creation or via _ImGui_SetPlotScale.
; size_x = 0 stretches to available width ; size_y default 60 pixels.

Global Const $FLT_MAX = 3.402823466e+38

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePlotLines
; Description ...: Create a PlotLines widget (display-only line graph of a float array)
; Syntax.........: _ImGui_CreatePlotLines($sId[, $sLabel = "", $sOverlay = "", $fW = 0, $fH = 60.0, $fScaleMin = $FLT_MAX, $fScaleMax = $FLT_MAX])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $sOverlay    - Optional overlay text centered on the plot
;                  $fW          - Width in pixels (0 = stretch to available)
;                  $fH          - Height in pixels (default 60)
;                  $fScaleMin/$fScaleMax - Vertical range bounds ($FLT_MAX = auto-scale)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Push data via _ImGui_SetPlotValues ; change range via _ImGui_SetPlotScale.
; ===============================================================================================================================
Func _ImGui_CreatePlotLines($sId, $sLabel = "", $sOverlay = "", $fW = 0, $fH = 60.0, $fScaleMin = $FLT_MAX, $fScaleMax = $FLT_MAX)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePlotLines", _
        "wstr", $sId, "wstr", $sLabel, "wstr", $sOverlay, _
        "float", $fW, "float", $fH, _
        "float", $fScaleMin, "float", $fScaleMax)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreatePlotHistogram
; Description ...: Create a PlotHistogram widget (display-only bar histogram of a float array)
; Syntax.........: _ImGui_CreatePlotHistogram($sId[, $sLabel = "", $sOverlay = "", $fW = 0, $fH = 60.0, $fScaleMin = $FLT_MAX, $fScaleMax = $FLT_MAX])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $sOverlay    - Optional overlay text centered on the plot
;                  $fW          - Width in pixels (0 = stretch to available)
;                  $fH          - Height in pixels (default 60)
;                  $fScaleMin/$fScaleMax - Vertical range bounds ($FLT_MAX = auto-scale)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Push data via _ImGui_SetPlotValues ; change range via _ImGui_SetPlotScale.
; ===============================================================================================================================
Func _ImGui_CreatePlotHistogram($sId, $sLabel = "", $sOverlay = "", $fW = 0, $fH = 60.0, $fScaleMin = $FLT_MAX, $fScaleMax = $FLT_MAX)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreatePlotHistogram", _
        "wstr", $sId, "wstr", $sLabel, "wstr", $sOverlay, _
        "float", $fW, "float", $fH, _
        "float", $fScaleMin, "float", $fScaleMax)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; Replace the plot's data with $aValues (1D float array).
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetPlotValues
; Description ...: Replace a PlotLines / PlotHistogram dataset with a fresh 1D float array
; Syntax.........: _ImGui_SetPlotValues($sId, $aValues)
; Parameters ....: $sId         - Identifier of the plot widget
;                  $aValues     - 1D float array (empty array is allowed = clear the plot)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a plot, 5=$aValues is not an array)
; Information ...: Push at any cadence — the DLL holds its own internal copy. Empty array clears the plot data.
; ===============================================================================================================================
Func _ImGui_SetPlotValues($sId, $aValues)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If Not IsArray($aValues) Then Return SetError(5, 0, False)
    Local $iN = UBound($aValues)
    Local $tBuf, $pBuf
    If $iN > 0 Then
        $tBuf = DllStructCreate("float buf[" & $iN & "]")
        For $i = 0 To $iN - 1
            DllStructSetData($tBuf, "buf", $aValues[$i], $i + 1)
        Next
        $pBuf = DllStructGetPtr($tBuf)
    Else
        ; Empty array → still need a valid (non-null) pointer ; pass a 1-element
        ; dummy buffer with count=0. The DLL just calls assign(buf, buf+0).
        $tBuf = DllStructCreate("float buf[1]")
        $pBuf = DllStructGetPtr($tBuf)
    EndIf
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetPlotValues", _
        "wstr", $sId, "ptr", $pBuf, "int", $iN)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetPlotScale
; Description ...: Update the vertical range bounds of a PlotLines / PlotHistogram widget
; Syntax.........: _ImGui_SetPlotScale($sId[, $fScaleMin = $FLT_MAX, $fScaleMax = $FLT_MAX])
; Parameters ....: $sId         - Identifier of the plot widget
;                  $fScaleMin   - Lower bound ($FLT_MAX = auto-scale on this side)
;                  $fScaleMax   - Upper bound ($FLT_MAX = auto-scale on this side)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a plot)
; ===============================================================================================================================
Func _ImGui_SetPlotScale($sId, $fScaleMin = $FLT_MAX, $fScaleMax = $FLT_MAX)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetPlotScale", _
        "wstr", $sId, "float", $fScaleMin, "float", $fScaleMax)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; --- ProgressBar -------------------------------------------------------------
; Display widget showing a fraction [0, 1] as a filled horizontal bar with
; an optional centered overlay. Value is set via _ImGui_SetValueFloat ; the
; overlay text via _ImGui_SetProgressBarOverlay (empty string = ImGui default
; "XX%"). $fW < 0 stretches the bar to fill the available width.

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateProgressBar
; Description ...: Create a ProgressBar widget (filled horizontal bar with optional centered text)
; Syntax.........: _ImGui_CreateProgressBar($sId[, $fDefault = 0.0, $sOverlay = "", $fW = -1.0, $fH = 0.0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $fDefault    - Initial fraction [0.0 - 1.0]
;                  $sOverlay    - Overlay text drawn centered on the bar (empty = ImGui default "XX%")
;                  $fW          - Width in pixels (-1 = stretch to available width)
;                  $fH          - Height in pixels (0 = auto)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Update the fill via _ImGui_SetValueFloat ; change the overlay via _ImGui_SetProgressBarOverlay.
; ===============================================================================================================================
Func _ImGui_CreateProgressBar($sId, $fDefault = 0.0, $sOverlay = "", $fW = -1.0, $fH = 0.0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateProgressBar", _
        "wstr", $sId, "float", $fDefault, "wstr", $sOverlay, _
        "float", $fW, "float", $fH)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_SetProgressBarOverlay
; Description ...: Update the centered overlay text of a ProgressBar widget
; Syntax.........: _ImGui_SetProgressBarOverlay($sId, $sOverlay)
; Parameters ....: $sId         - Identifier of the ProgressBar widget
;                  $sOverlay    - New overlay text (UTF-8) ; empty restores ImGui's default "XX%"
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed,
;                  3=unknown id or not a ProgressBar)
; ===============================================================================================================================
Func _ImGui_SetProgressBarOverlay($sId, $sOverlay)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_SetProgressBarOverlay", _
        "wstr", $sId, "wstr", $sOverlay)
    If @error Then Return SetError(2, @error, False)
    If $aRet[0] <> 0 Then Return SetError(3, $aRet[0], False)
    Return True
EndFunc

; --- RadioButton -------------------------------------------------------------
; Visual radio bullet. Read/write the visual "active" state via the generic
; _ImGui_GetValueBool / _ImGui_SetValueBool. Click events are latched via
; _ImGui_WasClicked. The script owns exclusivity — when a click is seen,
; uncheck the other radios in the group by SetValueBool(other, False).

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateRadioButton
; Description ...: Create a standalone RadioButton widget (visual bullet with manual exclusivity)
; Syntax.........: _ImGui_CreateRadioButton($sId[, $sLabel = "", $bActive = False])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $bActive     - Initial active state
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: The script owns exclusivity — clear other radios via _ImGui_SetValueBool on click.
;                  For automatic exclusivity, use _ImGui_CreateRadioButtonGroup (K.2) instead.
; ===============================================================================================================================
Func _ImGui_CreateRadioButton($sId, $sLabel = "", $bActive = False)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $iAct = $bActive ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateRadioButton", _
        "wstr", $sId, "wstr", $sLabel, "int", $iAct)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- MenuItem (D.5, hand-written) -------------------------------------------
; Click event via _ImGui_WasClicked (consume-and-reset). Persistent visual
; selected state read/written via _ImGui_GetValueBool / _ImGui_SetValueBool —
; the checkmark on the left flips on user click (and on programmatic Set),
; both producing the same visual ; _ImGui_HasChanged catches user-driven
; toggles (strict semantics : SetValueBool from script doesn't latch).
;
; For action-style items ("Save", "Quit"), pass $bSelected = False and ignore
; the bool state — just listen for _ImGui_WasClicked.
; For toggle-style items ("Show debug", "Mute sound"), seed $bSelected to
; the desired initial state and poll _ImGui_HasChanged or _ImGui_GetValueBool.
;
; $sShortcut is a display-only hint ("Ctrl+S") shown right-aligned in the menu.
; It does NOT register a real keyboard shortcut — wire that up via HotKeySet().
; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateMenuItem
; Description ...: Create a MenuItem widget (clickable row inside a Menu / MainMenuBar)
; Syntax.........: _ImGui_CreateMenuItem($sId[, $sLabel = "", $sShortcut = "", $bSelected = False, $bEnabled = True])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $sShortcut   - Display-only hint shown right-aligned (e.g. "Ctrl+S") ; does NOT register a real hotkey
;                  $bSelected   - Initial checkmark state (for toggle-style items)
;                  $bEnabled    - True to enable, False to grey out
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Action-style : ignore the bool and listen for _ImGui_WasClicked. Toggle-style : read _ImGui_HasChanged
;                  or _ImGui_GetValueBool. Wire real shortcuts via HotKeySet() — $sShortcut is text only.
; ===============================================================================================================================
Func _ImGui_CreateMenuItem($sId, $sLabel = "", $sShortcut = "", $bSelected = False, $bEnabled = True)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $iSel = $bSelected ? 1 : 0
    Local $iEna = $bEnabled  ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateMenuItem", _
        "wstr", $sId, "wstr", $sLabel, "wstr", $sShortcut, "int", $iSel, "int", $iEna)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- CheckboxFlags -----------------------------------------------------------
; Toggles a single bit (or combo) of an int mask. Useful for settings dialogs
; with multiple boolean flags packed in one int. The full mask is read via
; _ImGui_GetValueInt ; whether THIS specific box is checked via
; _ImGui_GetValueBool (true iff all bits in $iFlagsValue are set in the mask).

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateCheckboxFlags
; Description ...: Create a Checkbox bound to one or more bits of an integer mask
; Syntax.........: _ImGui_CreateCheckboxFlags($sId[, $sLabel = "", $iDefault = 0, $iFlagsValue = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label (empty = falls back to $sId)
;                  $iDefault    - Initial mask value (all bits combined)
;                  $iFlagsValue - Bit (or bit combo) this checkbox toggles
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read the full mask via _ImGui_GetValueInt ; this box's state via _ImGui_GetValueBool
;                  (True iff all bits of $iFlagsValue are set in the mask).
; ===============================================================================================================================
Func _ImGui_CreateCheckboxFlags($sId, $sLabel = "", $iDefault = 0, $iFlagsValue = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateCheckboxFlags", _
        "wstr", $sId, "wstr", $sLabel, _
        "int",  $iDefault, "int", $iFlagsValue)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

; --- Selectable --------------------------------------------------------------
; Hybrid widget — both a selected state (read with _ImGui_GetValueBool,
; latched on toggle via _ImGui_HasChanged) and a click event (latched via
; _ImGui_WasClicked, distinct from the state change). Programmatic
; _ImGui_SetValueBool never latches either flag.
;
; $fW = $fH = 0 → ImGui auto-sizes (single line, full content width).

; #FUNCTION# ====================================================================================================================
; Name...........: _ImGui_CreateSelectable
; Description ...: Create a Selectable widget (hybrid — both a toggleable selected state and a click event)
; Syntax.........: _ImGui_CreateSelectable($sId[, $sLabel = "", $bDefault = False, $iFlags = 0, $fW = 0, $fH = 0])
; Parameters ....: $sId         - Stable widget identifier (must be unique in the tree)
;                  $sLabel      - Displayed label
;                  $bDefault    - Initial selected state
;                  $iFlags      - Bitmask of $ImGuiSelectableFlags_*
;                  $fW          - Width in pixels (0 = auto, full content width)
;                  $fH          - Height in pixels (0 = single line auto)
; Return values .: Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)
; Information ...: Read state via _ImGui_GetValueBool ; user toggle via _ImGui_HasChanged ; click event via _ImGui_WasClicked.
;                  Programmatic _ImGui_SetValueBool never latches either flag (strict semantics).
; ===============================================================================================================================
Func _ImGui_CreateSelectable($sId, $sLabel = "", $bDefault = False, $iFlags = 0, $fW = 0, $fH = 0)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    Local $iSel = $bDefault ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateSelectable", _
        "wstr", $sId, "wstr", $sLabel, _
        "int",  $iSel, "int", $iFlags, _
        "float", $fW, "float", $fH)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc
