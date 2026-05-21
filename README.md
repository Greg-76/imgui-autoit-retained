# imgui-autoit-retained

A C++ DLL that hosts Dear ImGui in its own render thread and exposes a
**retained-mode API** to single-threaded AutoIt scripts. The goal is that an
AutoIt application no longer needs a second loop dedicated to UI rendering —
the script keeps its own main loop and the UI stays responsive thanks to the
C++ render thread.

Typical use cases:

- Configuration panels and tool dashboards backed by AutoIt logic.
- Live log viewers, status monitors, process explorers.
- Visual editors driven by an AutoIt script (text editors, data viewers,
  asset previewers).
- Any AutoIt application that would benefit from a modern, responsive UI
  without the limitations of native Win32 controls or the latency cost of
  a polling loop.

The DLL ships in **two flavours, x86 and x64**, both under the unified name
`imgui_autoit.dll` placed in `dll/bin/x86/` and `dll/bin/x64/`. The wrapper
picks the correct folder based on `@AutoItX64`, so the same script works
under either interpreter.

## Layout

```
imgui-autoit-retained/
├── CMakeLists.txt          ← emits dll/bin/x86/imgui_autoit.dll OR dll/bin/x64/imgui_autoit.dll
├── dll/
│   ├── bin/
│   │   ├── x86/imgui_autoit.dll
│   │   └── x64/imgui_autoit.dll
│   ├── build/              ← CMake/MSBuild scratch (gitignored)
│   ├── imgui-docking/      ← vendored Dear ImGui (docking branch, shallow clone)
│   ├── src/
│   │   ├── dllmain.cpp
│   │   ├── dll_api.cpp     ← C-ABI exports consumed by DllCall (cdecl)
│   │   ├── render_thread.* ← Win32 thread + DX11 + ImGui loop
│   │   ├── widget.*        ← Widget base class + concrete widgets
│   │   ├── widget_tree.*   ← persistent tree + mutex
│   │   └── utf.*           ← wstr (AutoIt) ↔ utf-8 (ImGui)
│   └── tools/
│       └── generate.py     ← codegen for widget categories
└── autoit/
    ├── imgui_retained.au3  ← wrapper (selects dll/bin/<arch>/ via @AutoItX64)
    ├── imgui_generated.au3 ← auto-generated AutoIt API
    ├── tests/              ← test_*.au3 + smoke_test.au3 + concurrency_test.au3
    └── exemples/           ← example_*.au3 (e.g. example_bot_panel.au3)
```

ImGui is vendored in `dll/imgui-docking/` (the docking branch of ImGui,
required for multi-viewport — see the "Multi-viewport (D.2.1)" section).
`CMakeLists.txt` points there by default ; override with `-DIMGUI_DIR=...`.
The master branch (1.92.x) compiles too but without multi-viewport support.

## Build (both architectures)

From `imgui-autoit-retained/` :

```bat
:: x64
cmake -S . -B dll/build/x64 -G "Visual Studio 17 2022" -A x64
cmake --build dll/build/x64 --config Release

:: x86
cmake -S . -B dll/build/x86 -G "Visual Studio 17 2022" -A Win32
cmake --build dll/build/x86 --config Release
```

Outputs (`RUNTIME_OUTPUT_DIRECTORY` is forced) :

- `dll/bin/x64/imgui_autoit.dll`
- `dll/bin/x86/imgui_autoit.dll`

The `dll/build/` folder only contains intermediate files from CMake/MSBuild
(objects, .lib import libraries, .pdb). It is gitignored and can be removed
without affecting the runtime.

Note: the C/C++ runtime is linked **statically** (`/MT`) — no VCRedist
dependency on target machines.

## Run

```bat
:: With the x86 interpreter
"C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     autoit\tests\test_button.au3

:: With the x64 interpreter
"C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" autoit\tests\test_button.au3
```

The same script works under either interpreter — `@AutoItX64` routes the
DllCall to the matching architecture.

Success criteria covered by the initial step:

1. A button is displayed, with no ImGui loop in the script.
2. The script's `Sleep(200)` in its main loop does not freeze the UI (the
   render thread runs independently).
3. The other criteria (multi-widget, visibility, lists, multi-instance,
   concurrency stress) are addressed by the later phases.

## Exported API

| Symbol                | Signature (C, `__cdecl`)                                              | Return                                            |
|------------------------|-----------------------------------------------------------------------|---------------------------------------------------|
| `ImGui_Init`           | `int(const wchar_t* title, int w, int h)`                             | 0 = OK, ≠0 = error                                |
| `ImGui_Shutdown`       | `int()`                                                               | 0                                                 |
| `ImGui_IsRunning`      | `int()`                                                               | 1 if the window is alive, 0 otherwise             |
| `ImGui_CreateButton`*  | `int(const wchar_t* id, const wchar_t* label)`                        | 0 = OK, 1 = invalid id, 2 = duplicate             |
| `ImGui_CreateSmallButton`* | `int(const wchar_t* id, const wchar_t* label)`                    | 0 = OK, 1 = invalid id, 2 = duplicate             |
| `ImGui_WasClicked`     | `int(const wchar_t* id)`                                              | 1 = pending click (consumed)                      |
| `ImGui_CreateCheckbox`*| `int(const wchar_t* id, const wchar_t* label, int default_value)`     | 0 = OK, 1 = invalid id, 2 = duplicate             |
| `ImGui_GetValueBool`   | `int(const wchar_t* id)`                                              | 0/1, or -1 if unknown / not bool-valued           |
| `ImGui_SetValueBool`   | `int(const wchar_t* id, int value)`                                   | 0 = OK, 1 = invalid id, 2 = unknown, 3 = type     |
| `ImGui_CreateSliderFloat`* | `int(id, label, float v_min, float v_max, float default, wchar_t* format)` | 0 = OK, 1 = invalid id, 2 = duplicate     |
| `ImGui_CreateSliderInt`*   | `int(id, label, int v_min, int v_max, int default, wchar_t* format)`       | 0 = OK, 1 = invalid id, 2 = duplicate     |
| `ImGui_CreateDragFloat`*   | `int(id, label, float v_speed, float v_min, float v_max, float default, wchar_t* format)` | 0 = OK, 1, 2          |
| `ImGui_CreateDragInt`*     | `int(id, label, float v_speed, int v_min, int v_max, int default, wchar_t* format)`       | 0 = OK, 1, 2          |
| `ImGui_CreateInputFloat`*  | `int(id, label, float default, float step, float step_fast, wchar_t* format)` | 0 = OK, 1, 2                             |
| `ImGui_CreateInputInt`*    | `int(id, label, int default, int step, int step_fast)`                | 0 = OK, 1, 2                                       |
| `ImGui_GetValueFloat`  | `int(const wchar_t* id, float* out)`                                  | 0 = ok, 1 = id, 2 = unknown, 3 = type (out written if 0) |
| `ImGui_SetValueFloat`  | `int(const wchar_t* id, float value)`                                 | 0 = OK, 1 = invalid id, 2 = unknown, 3 = type     |
| `ImGui_GetValueInt`    | `int(const wchar_t* id, int* out)`                                    | 0 = ok, 1 = id, 2 = unknown, 3 = type             |
| `ImGui_SetValueInt`    | `int(const wchar_t* id, int value)`                                   | 0 = OK, 1 = invalid id, 2 = unknown, 3 = type     |
| `ImGui_HasChanged`     | `int(const wchar_t* id)`                                              | 1 = changed since last read (consumed)            |
| `ImGui_CreateSeparator`*   | `int(const wchar_t* id)`                                          | 0 = OK, 1 = invalid id, 2 = duplicate             |
| `ImGui_CreateNewLine`*     | `int(const wchar_t* id)`                                          | 0 = OK, 1, 2                                       |
| `ImGui_CreateSpacing`*     | `int(const wchar_t* id)`                                          | 0 = OK, 1, 2                                       |
| `ImGui_CreateBullet`*      | `int(const wchar_t* id)`                                          | 0 = OK, 1, 2                                       |
| `ImGui_CreateSameLine`*    | `int(const wchar_t* id, float offset_x, float spacing)`           | 0 = OK, 1, 2                                       |
| `ImGui_CreateIndent`*      | `int(const wchar_t* id, float indent_w)`                          | 0 = OK, 1, 2                                       |
| `ImGui_CreateUnindent`*    | `int(const wchar_t* id, float indent_w)`                          | 0 = OK, 1, 2                                       |
| `ImGui_CreateText`     | `int(const wchar_t* id, const wchar_t* text)`                         | 0 = OK, 1 = invalid id, 2 = duplicate             |
| `ImGui_SetText`        | `int(const wchar_t* id, const wchar_t* text)`                         | 0 = OK, 1 = invalid id, 2 = unknown               |
| `ImGui_CreatePushStyleColor`*    | `int(id, int idx, float r, float g, float b, float a)`      | 0 = OK, 1, 2                              |
| `ImGui_CreatePopStyleColor`*     | `int(id, int count)`                                        | 0 = OK, 1, 2                              |
| `ImGui_CreatePushStyleVarFloat`* | `int(id, int idx, float value)`                             | 0 = OK, 1, 2                              |
| `ImGui_CreatePushStyleVarVec2`*  | `int(id, int idx, float value_x, float value_y)`            | 0 = OK, 1, 2                              |
| `ImGui_CreatePopStyleVar`*       | `int(id, int count)`                                        | 0 = OK, 1, 2                              |
| `ImGui_SetConfigFlags`           | `int(int flags)`                                            | 0 = OK, 1 = not initialised               |
| `ImGui_SetFontGlobalScale`       | `int(float scale)`                                          | 0 = OK, 1 = not initialised, 2 = scale ≤ 0 |
| `ImGui_SetUnfocusedFps`          | `int(int fps)`                                              | 0 = OK (fps clamped to [1, 60])           |
| `ImGui_CreateChild`*             | `int(id, label, float w, float h, int border)`              | 0 = OK, 1, 2                              |
| `ImGui_CreateTabBar`*            | `int(id, label, int flags)`                                 | 0 = OK, 1, 2 — D.7 ; flags = `$ImGuiTabBarFlags_*` |
| `ImGui_CreateTabItem`            | `int(id, label, int closable, int flags)`                   | 0 = OK, 1, 2 — D.7 ; closable=1 → X button via `&visible` |
| `ImGui_CreateTabItemButton`      | `int(id, label, int flags)`                                 | 0 = OK, 1, 2 — D.7 ; inline tab, poll via `WasClicked` |
| `ImGui_SetTabItemClosed`         | `int(id)`                                                   | 0 = OK, 1, 2, 3 (not a TabItem) — D.7 ; anti-flicker close |
| `ImGui_CreatePopup`              | `int(id, label, int flags)`                                 | 0 = OK, 1, 2 — E.1 ; regular floating popup, no title bar |
| `ImGui_CreatePopupModal`         | `int(id, label, int closable, int flags)`                   | 0 = OK, 1, 2 — E.1 ; dim background + title bar + optional X |
| `ImGui_OpenPopup`                | `int(id)`                                                   | 0 = OK, 1, 2, 3 (not a popup) — E.1 ; pending open at next Render |
| `ImGui_ClosePopup`               | `int(id)`                                                   | 0 = OK, 1, 2, 3 — E.1 ; honored only while popup is open |
| `ImGui_IsPopupOpen`              | `int(id)`                                                   | 0/1 — E.1 ; latched after BeginPopup. Also routes to ContextPopup (E.1.x). |
| `ImGui_CreateContextPopup`       | `int(id, label, int kind, int flags)`                       | 0=OK, 1, 2 — E.1.x ; inline container, kind=0/1/2 (Item/Window/Void). Open/Close/IsOpen via the 3 E.1 exports. |
| `ImGui_CreateOpenPopupOnItemClick` | `int(id, target_popup_id, int flags)`                     | 0=OK, 1, 2, 3 (empty target) — E.1.x ; inline marker, routes click to `target.pending_open_dirty`. |
| `ImGui_CreateDragFloatRange2`    | `int(id, label, vmin, vmax, speed, def_min, def_max, fmt, fmt_max, flags)` | 0=OK, 1, 2 — E.2 ; read via `GetValueFloatN($id, 2)` |
| `ImGui_CreateDragIntRange2`      | `int(id, label, vmin, vmax, speed, def_min, def_max, fmt, fmt_max, flags)` | 0=OK, 1, 2 — E.2 ; read via `GetValueIntN($id, 2)` |
| `ImGui_CreateSliderAngle`        | `int(id, label, deg_min, deg_max, default_rad, fmt, flags)` | 0=OK, 1, 2 — E.2 ; value in radians, bounds in degrees |
| `ImGui_CreateVSliderFloat`       | `int(id, label, w, h, v_min, v_max, default, fmt, flags)`   | 0=OK, 1, 2 — E.2 ; vertical slider                |
| `ImGui_CreateVSliderInt`         | `int(id, label, w, h, v_min, v_max, default, fmt, flags)`   | 0=OK, 1, 2 — E.2                                   |
| `ImGui_CreateInputTextWithHint`  | `int(id, label, hint, default, max_length, flags)`          | 0=OK, 1, 2 — E.2 ; placeholder when buffer is empty |
| `ImGui_CreateColorButton`        | `int(id, label, r, g, b, a, flags, w, h)`                   | 0=OK, 1, 2 — E.2 ; display-only, RGBA via `Get/SetValueFloatN($id, 4)` |
| `ImGui_GetMousePos`              | `int(float* out_xy)`                                        | 0=OK — E.3 ; ImGui screen-space (x, y)           |
| `ImGui_GetMouseDragDelta`        | `int(int button, float* out_xy)`                            | 0=OK, 2=bad button — E.3 ; (0,0) if not dragging |
| `ImGui_GetClipboardText`         | `int(wchar_t* out, int capacity)`                           | 0=OK, 4=truncated — E.3 ; per-context ImGui clipboard |
| `ImGui_SetClipboardText`         | `int(const wchar_t* text)`                                  | 0=OK — E.3                                       |
| `ImGui_ColorConvertU32ToFloat4`  | `int(uint u32, float* out_rgba)`                            | 0=OK — E.4 ; pure math, no mutex                 |
| `ImGui_ColorConvertFloat4ToU32`  | `uint(float r, float g, float b, float a)`                  | returns U32 directly — E.4                       |
| `ImGui_ColorConvertRGBtoHSV`     | `int(r, g, b, float* out_hsv)`                              | 0=OK — E.4                                       |
| `ImGui_ColorConvertHSVtoRGB`     | `int(h, s, v, float* out_rgb)`                              | 0=OK — E.4                                       |
| `ImGui_SetColorEditOptions`      | `int(int flags)`                                            | 0=OK — E.2.x ; global one-shot setter, applies to ColorEdit/Picker created afterwards. |
| `ImGui_CreateDummy`              | `int(id, float w, float h)`                                 | 0=OK, 1, 2 — F.1 ; invisible rectangle taking a given space |
| `ImGui_CreateAlignTextToFramePadding` | `int(id)`                                              | 0=OK, 1, 2 — F.1 ; aligns the next Text with a framed widget |
| `ImGui_CreateSetNextItemWidth`   | `int(id, float item_width)`                                 | 0=OK, 1, 2 — F.1 ; one-shot marker, overrides the width of the next item |
| `ImGui_CreatePushItemWidth`      | `int(id, float item_width)`                                 | 0=OK, 1, 2 — F.1 ; push onto the stack |
| `ImGui_CreatePopItemWidth`       | `int(id)`                                                   | 0=OK, 1, 2 — F.1 |
| `ImGui_CreatePushTextWrapPos`    | `int(id, float wrap_local_pos_x)`                           | 0=OK, 1, 2 — F.1 ; <0 = no wrap, 0 = window edge, >0 = local position |
| `ImGui_CreatePopTextWrapPos`     | `int(id)`                                                   | 0=OK, 1, 2 — F.1 |
| `ImGui_CreatePushItemFlag`       | `int(id, int option, int enabled)`                          | 0=OK, 1, 2 — F.1 ; option = `$ImGuiItemFlags_*` |
| `ImGui_CreatePopItemFlag`        | `int(id)`                                                   | 0=OK, 1, 2 — F.1 |
| `ImGui_CreatePushStyleVarX`      | `int(id, int idx, float value_x)`                           | 0=OK, 1, 2 — F.1 ; override only the X component of a Vec2 StyleVar |
| `ImGui_CreatePushStyleVarY`      | `int(id, int idx, float value_y)`                           | 0=OK, 1, 2 — F.1 ; same for Y |
| `ImGui_CreateSetItemDefaultFocus`     | `int(id)`                                              | 0=OK, 1, 2 — F.2 ; placed after the widget to pre-focus |
| `ImGui_CreateSetNextItemAllowOverlap` | `int(id)`                                              | 0=OK, 1, 2 — F.2 ; marker, next widget accepts overlaps |
| `ImGui_CreateSetKeyboardFocusHere`    | `int(id, int offset)`                                  | 0=OK, 1, 2 — F.2 ; offset=0 = focus the NEXT item, fires every frame |
| `ImGui_SetNavCursorVisible`      | `int(int b)`                                                | 0=OK — F.2 ; show/hide the nav focus ring |
| `ImGui_GetTime`                  | `int(double* out)`                                          | 0=OK — F.2 ; ImGui internal time in seconds |
| `ImGui_GetFrameCount`            | `int(void)` → int                                           | returns the frame counter |
| `ImGui_GetStyleColorName`        | `int(int idx, wchar_t* out, int cap)`                       | 0=OK, 2=out-of-range, 4=truncated — F.2 |
| `ImGui_SetStyleTheme`            | `int(int theme)`                                            | 0=OK, 2=bad theme — F.2 ; 0=Dark/1=Light/2=Classic |
| `ImGui_CreateCollapsingHeader`   | `int(id, label, int closable, int flags)`                   | 0 = OK, 1, 2 — D.6 ; closable=1 → X button via `&visible` |
| `ImGui_CreateTreeNode`           | `int(id, label, int flags)`                                 | 0 = OK, 1, 2 — D.6 ; flags = `$ImGuiTreeNodeFlags_*` |
| `ImGui_SetNextItemOpen`          | `int(id, int b_open, int cond)`                             | 0 = OK, 1, 2, 3 (not tree/header) — D.6   |
| `ImGui_IsToggledOpen`            | `int(id)`                                                   | 0/1 — `IsItemToggledOpen()` latch (D.6)   |
| `ImGui_CreateGroup`*             | `int(id, label)`                                            | 0 = OK, 1, 2                              |
| `ImGui_CreateWindow`*            | `int(id, title, int closable, int flags)`                   | 0 = OK, 1, 2                              |
| `ImGui_CreateMenuBar`*           | `int(id, label)`                                            | 0 = OK, 1, 2                              |
| `ImGui_CreateMenu`*              | `int(id, label)`                                            | 0 = OK, 1, 2                              |
| `ImGui_CreateMenuItem`           | `int(id, label, shortcut, int selected, int enabled)`       | 0 = OK, 1, 2 — D.5 ; Get/SetValueBool on `selected`, `WasClicked` on action |
| `ImGui_CreateMainMenuBar`*       | `int(id, label)`                                            | 0 = OK, 1, 2 — D.5 ; rendered in a pre-pass at the top of the viewport |
| `ImGui_SetParent`                | `int(child_id, parent_id)`                                  | 0=ok, 1=id, 2=unknown child, 3=unknown parent, 4=cycle |
| `ImGui_SetVisible`               | `int(id, int value)`                                        | 0 = OK, 1, 2                              |
| `ImGui_GetVisible`               | `int(id)`                                                   | 0/1                                       |
| `ImGui_SetEnabled`               | `int(id, int value)`                                        | 0 = OK, 1, 2                              |
| `ImGui_CreateList`               | `int(id, label, float w, float h)`                          | 0 = OK, 1 = invalid id, 2 = duplicate     |
| `ImGui_SetListItems`             | `int(id, joined_items, sep)`                                | 0 = OK, 1 = invalid id, 2 = unknown, 3 = not a list |
| `ImGui_GetListSelection`         | `int(id)`                                                   | selected index, -1 if none / unknown / not a list |
| `ImGui_SetListSelection`         | `int(id, int index)`                                        | 0 = OK, 1 = invalid id, 2 = unknown, 3 = not a list |
| `ImGui_CreateInputText`          | `int(id, label, default_value, int max_length, int flags)`  | 0 = OK, 1 = invalid id, 2 = duplicate     |
| `ImGui_CreateInputTextMultiline` | `int(id, label, default_value, int max_length, int flags, float w, float h)` | 0 = OK, 1, 2          |
| `ImGui_GetValueString`           | `int(id, wchar_t* out, int capacity)`                       | 0=ok, 1=id/buf, 2=unknown, 3=type, 4=truncated |
| `ImGui_SetValueString`           | `int(id, value)`                                            | 0 = OK, 1, 2, 3                            |
| `ImGui_CreateCombo`              | `int(id, label, int flags)`                                 | 0 = OK, 1 = invalid id, 2 = duplicate     |
| `ImGui_SetComboItems`            | `int(id, joined_items, sep)`                                | 0 = OK, 1 = invalid id, 2 = unknown, 3 = not a combo |
| `ImGui_CreateSelectable`         | `int(id, label, int default_selected, int flags, float w, float h)` | 0 = OK, 1 = invalid id, 2 = duplicate |
| `ImGui_IsHovered`                | `int(id)`                                                   | 0/1 — pointer over the widget         |
| `ImGui_IsActive`                 | `int(id)`                                                   | 0/1 — interaction in progress         |
| `ImGui_IsFocused`                | `int(id)`                                                   | 0/1 — keyboard focus                  |
| `ImGui_IsClicked`                | `int(id)`                                                   | 0/1 — left mouse, frame-state (D.1)   |
| `ImGui_IsEdited`                 | `int(id)`                                                   | 0/1 — value changed this frame        |
| `ImGui_IsActivated`              | `int(id)`                                                   | 0/1 — "start" edge frame              |
| `ImGui_IsDeactivated`            | `int(id)`                                                   | 0/1 — "stop" edge frame               |
| `ImGui_IsDeactivatedAfterEdit`   | `int(id)`                                                   | 0/1 — deactivated edge frame + value changed |
| `ImGui_IsVisible`                | `int(id)`                                                   | 0/1 — not clipped                     |
| `ImGui_GetItemRectMin`           | `int(id, float* out_xy)`                                    | 0=ok (out 2 floats), 1=id, 2=unknown  |
| `ImGui_GetItemRectMax`           | `int(id, float* out_xy)`                                    | same                                  |
| `ImGui_GetItemRectSize`          | `int(id, float* out_xy)`                                    | same (size = max - min)               |
| `ImGui_IsAnyItemHovered`         | `int()`                                                     | 0/1 — global, 2-pass OR-merged        |
| `ImGui_IsAnyItemActive`          | `int()`                                                     | 0/1 — same                            |
| `ImGui_IsAnyItemFocused`         | `int()`                                                     | 0/1 — same                            |
| `ImGui_SetTooltip`               | `int(id, text)`                                             | 0 = OK, 1 = invalid id, 2 = unknown   |
| `ImGui_ShowDemoWindow`           | `int(int show)`                                             | 0 — set atomic (D.2)                  |
| `ImGui_ShowMetricsWindow`        | `int(int show)`                                             | 0                                     |
| `ImGui_ShowDebugLogWindow`       | `int(int show)`                                             | 0                                     |
| `ImGui_ShowIDStackToolWindow`    | `int(int show)`                                             | 0                                     |
| `ImGui_ShowAboutWindow`          | `int(int show)`                                             | 0                                     |
| `ImGui_IsShowingDemoWindow`      | `int()`                                                     | 0/1 — round-trip after X click        |
| `ImGui_IsShowingMetricsWindow`   | `int()`                                                     | 0/1                                   |
| `ImGui_IsShowingDebugLogWindow`  | `int()`                                                     | 0/1                                   |
| `ImGui_IsShowingIDStackToolWindow` | `int()`                                                   | 0/1                                   |
| `ImGui_IsShowingAboutWindow`     | `int()`                                                     | 0/1                                   |
| `ImGui_GetVersion`               | `int(wchar_t* out, int cap)`                                | 0 = ok, 1 = null buffer, 4 = truncated |
| `ImGui_CreateWindow`             | `int(id, title, int closable, int flags)`                   | 0 = OK, 1, 2 (hand-written D.3)       |
| `ImGui_SetWindowPos`             | `int(id, float x, float y, int cond)`                       | 0 = OK, 1, 2 = unknown, 3 = not window |
| `ImGui_SetWindowSize`            | `int(id, float w, float h, int cond)`                       | same                                  |
| `ImGui_SetWindowCollapsed`       | `int(id, int collapsed, int cond)`                          | same                                  |
| `ImGui_SetWindowFocus`           | `int(id)`                                                   | one-shot, 0 = OK, 1, 2, 3             |
| `ImGui_SetWindowBgAlpha`         | `int(id, float alpha)`                                      | clamped to [0,1], 0 = OK, 1, 2, 3     |
| `ImGui_SetWindowSizeConstraints` | `int(id, float minW, float minH, float maxW, float maxH)`   | maxW/H ≤ 0 → FLT_MAX (no limit)       |
| `ImGui_IsWindowAppearing`        | `int(id)`                                                   | 0/1 — edge frame                      |
| `ImGui_IsWindowCollapsed`        | `int(id)`                                                   | 0/1                                   |
| `ImGui_IsWindowFocused`          | `int(id)`                                                   | 0/1 — window-level, NOT item          |
| `ImGui_IsWindowHovered`          | `int(id)`                                                   | 0/1 — window-level                    |
| `ImGui_GetWindowPos`             | `int(id, float* out_xy)`                                    | 0 = ok, 1, 2, 3                       |
| `ImGui_GetWindowSize`            | `int(id, float* out_wh)`                                    | 0 = ok, 1, 2, 3                       |
| `ImGui_LoadSettings`             | `int(const wchar_t* path)`                                  | 0 = ok, 1 = not init, 2 = empty path (D.4) |
| `ImGui_SaveSettings`             | `int(const wchar_t* path)`                                  | 0 = ok, 1 = not init, 2 = empty path  |
| `ImGui_GetValueFloatN`           | `int(id, float* out, int capacity)`                         | number of components written (0/2/3/4) |
| `ImGui_SetValueFloatN`           | `int(id, const float* in, int n)`                           | 0=ok, 1, 2, 3                          |
| `ImGui_GetValueIntN`             | `int(id, int* out, int capacity)`                           | number of components written          |
| `ImGui_SetValueIntN`             | `int(id, const int* in, int n)`                             | 0=ok, 1, 2, 3                          |
| `ImGui_CreateRadioButton`        | `int(id, label, int default_active)`                        | 0 = OK, 1, 2                          |
| `ImGui_CreateCheckboxFlags`      | `int(id, label, int default_value, int flags_value)`        | 0 = OK, 1, 2                          |
| `ImGui_CreateProgressBar`        | `int(id, float default, overlay, float w, float h)`         | 0 = OK, 1, 2                          |
| `ImGui_SetProgressBarOverlay`    | `int(id, overlay)`                                          | 0 = OK, 1, 2, 3                       |
| `ImGui_CreatePlotLines`*         | `int(id, label, overlay, float w, float h, float smin, float smax)` | 0 = OK, 1, 2          |
| `ImGui_CreatePlotHistogram`*     | `int(id, label, overlay, float w, float h, float smin, float smax)` | 0 = OK, 1, 2          |
| `ImGui_SetPlotValues`            | `int(id, const float* in, int n)`                           | 0 = OK, 1, 2, 3                       |
| `ImGui_SetPlotScale`             | `int(id, float smin, float smax)`                           | 0 = OK, 1, 2, 3                       |

\* Auto-generated by `dll/tools/generate.py`. See the [Generator](#generator--widget-categories) section for the mapping details.

All strings are UTF-16 on the DLL side ; the AutoIt wrapper uses `"wstr"` in
its `DllCall`. Conversion to UTF-8 happens internally before reaching ImGui.

Calling convention: `__cdecl` on the DLL side, `:cdecl` on the AutoIt side —
pinned explicitly in the wrapper to be insensitive to the default value of
the running AutoIt build.

## Concurrency model

The `g_tree.mtx` mutex (a `std::recursive_mutex` since Phase G) protects every
access to the widget tree, in both directions:

- AutoIt side: `Create*`, `Set*`, `WasClicked` take the lock before mutating
  or read-and-reset of a flag.
- Render thread side: `RenderHostWindow` holds the same lock around the
  whole frame body (NewFrame → widget render → Render → multi-viewport
  platform render). Present is performed OUTSIDE the lock to avoid blocking
  AutoIt on vsync.

The rest of the shared state is single-thread (DX/ImGui belong to the render
thread ; `m_running`/`m_stop`/`m_initDone` are `std::atomic`).

Empirically validated by [autoit/concurrency_test.au3](autoit/concurrency_test.au3):
10 seconds of tight-loop mutations on the AutoIt side (`_ImGui_SetText` with
no `Sleep`) while the render thread takes the same lock every frame. Result
on both architectures (x86 + x64): no crashes, the counter stays monotonic,
the UI stays responsive (drag/collapse/close work during the stress).

## Generator — widget categories

The script [dll/tools/generate.py](dll/tools/generate.py) parses `imgui-1.92.8/imgui.h`
then emits, **per category**, a trio of C++ files and a block in the
aggregated AutoIt wrapper:

```
dll/tools/generate.py
        │
        ├─→ dll/src/generated/widgets_<cat>.h        (C++ classes)
        ├─→ dll/src/generated/widgets_<cat>.cpp      (Render() impls)
        ├─→ dll/src/generated/dll_api_<cat>.cpp      (Create* C-ABI exports)
        └─→ autoit/imgui_generated.au3           (single file, one block per category)
```

Implemented categories:

| Category        | Widgets                                                                    | ImGui pattern                                      | C++ base(s)                              | Generic exports                                                                                              |
|-----------------|----------------------------------------------------------------------------|----------------------------------------------------|------------------------------------------|--------------------------------------------------------------------------------------------------------------|
| `clickable`     | `Button`, `SmallButton`, `ArrowButton`, `InvisibleButton`                  | `bool Foo(label, ...)` with optional params        | `ClickableWidget`                        | `ImGui_WasClicked`                                                                                           |
| `value_bool`    | `Checkbox`                                                                 | `bool Foo(const char* label, bool* v)`             | `BoolValueWidget`                        | `ImGui_GetValueBool`, `ImGui_SetValueBool`, `ImGui_HasChanged`                                               |
| `value_numeric` | `SliderFloat/Int` + `…2/3/4`, `DragFloat/Int` + `…2/3/4`, `InputFloat/Int` + `…2/3/4` (20 widgets) | `bool Foo(label, T* v, ...)` or vector `T v[N]` | `FloatValueWidget`/`IntValueWidget` + `FloatVec{N}ValueWidget`/`IntVec{N}ValueWidget` | `ImGui_GetValueFloat/Int`, `ImGui_GetValueFloatN/IntN` (vector), `Set*`, `ImGui_HasChanged`   |
| `display`       | `Separator`, `NewLine`, `Spacing`, `Bullet`, `SameLine`, `Indent`, `Unindent` | `void Foo(…)` — stateless markers in the flow   | `Widget` (direct)                       | none (just `SetVisible` when exposed)                                                                       |
| `config`        | `PushStyleColor`/`PopStyleColor`, `PushStyleVarFloat`/`Vec2`/`PopStyleVar`  | `void PushStyle…/PopStyle…` — pairs in the flow  | `Widget` (direct)                       | hand-written: `ImGui_SetConfigFlags`, `ImGui_SetFontGlobalScale` (one-shot global setters)                  |
| `container`     | `Child`, `TabBar`, `Group`, `MenuBar`, `MainMenuBar`, `Menu` (`CollapsingHeader` and `TreeNode` moved to hand-written in D.6 ; `TabItem` in D.7) | `Begin…/End…` with children inside | `Widget` (direct, owns `children`) | hand-written: `ImGui_SetParent`, `ImGui_SetVisible`, `ImGui_GetVisible`, `ImGui_SetEnabled`                  |
| `text`          | `TextColored`, `TextWrapped`, `TextDisabled`, `LabelText`, `BulletText`, `SeparatorText` | Variants of `Text` — color, wrap, label/value, separator with text | `Widget` (direct, optional color/extra storage) | none new — `_ImGui_SetText` updates the label |
| `color`         | `ColorEdit3/4`, `ColorPicker3/4`                                           | `bool Foo(label, float v[N], flags)`                | `FloatVec3/4ValueWidget`                 | `ImGui_GetValueFloatN`, `ImGui_SetValueFloatN`, `ImGui_HasChanged`                                           |
| _hand-written_  | `List`, `Combo`                                                            | List: `BeginChild` + `Selectable` loop. Combo: `BeginCombo`/`EndCombo` popup. Both with `PushID(index)`. | `IndexedSelectionWidget` (shared base) | hand-written: `ImGui_CreateList`, `ImGui_SetListItems`, `ImGui_CreateCombo`, `ImGui_SetComboItems`, plus `ImGui_GetListSelection`/`SetListSelection` dispatching on both. `_ImGui_HasChanged` and `_ImGui_GetValueInt` too.   |
| _hand-written_  | `InputText`, `InputTextMultiline`                                          | `ImGui::InputText[Multiline](label, char* buf, size, flags)` | `StringValueWidget`     | hand-written: `ImGui_CreateInputText`, `ImGui_CreateInputTextMultiline`, `ImGui_GetValueString`, `ImGui_SetValueString`. `_ImGui_HasChanged` too.    |
| _hand-written_  | `Selectable`                                                               | `ImGui::Selectable(label, bool*, flags, size)` — toggle + click event | `SelectableWidget` ext `BoolValueWidget` | hand-written: `ImGui_CreateSelectable`. State via `_ImGui_GetValueBool`/`_ImGui_SetValueBool`/`_ImGui_HasChanged`, click event via `_ImGui_WasClicked`. |
| _hand-written_  | `RadioButton`, `CheckboxFlags`, `MenuItem`                                 | RadioButton: visual radio + persistent active state. CheckboxFlags: toggle a bit of an int mask. MenuItem (D.5): click + shortcut hint + persistent selected (checkmark). | `ClickableWidget` (Radio), `Widget` direct (Flags), `BoolValueWidget` (MenuItem) | RadioButton: `ImGui_CreateRadioButton` + `_ImGui_Get/SetValueBool`. CheckboxFlags: `ImGui_CreateCheckboxFlags` + `_ImGui_GetValueInt` (full mask) / `_ImGui_GetValueBool` (this bit) / `_ImGui_HasChanged`. MenuItem: `ImGui_CreateMenuItem($id, $label, $shortcut, $bSelected, $bEnabled)` + `_ImGui_WasClicked` (action) / `_ImGui_GetValueBool` + `_ImGui_HasChanged` (toggle). |
| _hand-written_  | `WindowWidget` (D.3)                                                       | Top-level Window with pending-state setters (pos/size/collapsed/focus/bg_alpha/size_constraints) + window-level latched queries. | `Widget` (direct, IsTopLevelWindow override) | `ImGui_CreateWindow` + 12 D.3 setters/getters. See "Window manipulation (D.3)". |
| _hand-written_  | `TreeNode`, `CollapsingHeader` (D.6)                                       | One-shot pending `SetNextItemOpen` + `IsItemToggledOpen` latch. CollapsingHeader gains an X close button via `&visible`. | `Widget` (direct, owns `children`)       | `ImGui_CreateTreeNode($id, $label, $iFlags)`, `ImGui_CreateCollapsingHeader($id, $label, $bClosable, $iFlags)`, `ImGui_SetNextItemOpen`, `ImGui_IsToggledOpen`. See "Tree extensions (D.6)". |
| _hand-written_  | `TabItem`, `TabItemButton` (D.7)                                           | TabItem gains `closable` (X via `&visible`) + `flags` + pending `SetTabItemClosed`. TabItemButton is a new inline `ClickableWidget`. | `Widget` (TabItem, owns `children`), `ClickableWidget` (TabItemButton) | `ImGui_CreateTabItem($id, $label, $bClosable, $iFlags)`, `ImGui_CreateTabItemButton`, `ImGui_SetTabItemClosed`. TabBar stays generated with `flags`. See "Tab extensions (D.7)". |
| _hand-written_  | `Popup`, `PopupModal` (E.1)                                                | Top-level containers with pending open/close state + `IsPopupOpen` latch. Modal supports X close via `&visible`. | `Widget` (direct, IsTopLevelWindow override, owns `children`) | `ImGui_CreatePopup($id, $label, $iFlags)`, `ImGui_CreatePopupModal($id, $label, $bClosable, $iFlags)`, `ImGui_OpenPopup`, `ImGui_ClosePopup`, `ImGui_IsPopupOpen`. See "Popups / Modals (E.1)". |
| _hand-written_  | `ContextPopup`, `OpenPopupOnItemClick` (E.1.x)                             | ContextPopup = inline container for `BeginPopupContext{Item,Window,Void}` discriminated by `int kind`. Marker = pure trigger with no body, routes the click directly to `target.pending_open_dirty`. | `Widget` (direct, inline so NOT top-level) | `ImGui_CreateContextPopup($id, $label, $iKind, $iFlags)`, `ImGui_CreateOpenPopupOnItemClick($id, $sTargetPopupId, $iFlags)`. See "Context popups + OpenPopupOnItemClick (E.1.x)". |
| _hand-written_  | `DragFloatRange2`, `DragIntRange2`, `SliderAngle`, `VSliderFloat`, `VSliderInt`, `InputTextWithHint`, `ColorButton` (E.2) | 6 numeric/color widgets that don't fit the generator's templates. Range2 stores 2 values; SliderAngle converts rad↔deg; VSlider* are vertical; ColorButton is display+click. | mixin depending on the case (`FloatValueWidget`, `IntValueWidget`, `StringValueWidget`, `ClickableWidget`) | `_ImGui_CreateDragFloatRange2/IntRange2`, `_ImGui_CreateSliderAngle`, `_ImGui_CreateVSliderFloat/Int`, `_ImGui_CreateInputTextWithHint`, `_ImGui_CreateColorButton`. All use the existing generic Get/Set helpers. |
| _hand-written_  | `ProgressBar`                                                              | `ImGui::ProgressBar(fraction, size, overlay)` — display only | `FloatValueWidget`                     | `ImGui_CreateProgressBar`, `ImGui_SetProgressBarOverlay` + `_ImGui_SetValueFloat`                            |
| _hand-written_  | `PlotLines`, `PlotHistogram`                                               | `ImGui::PlotLines/PlotHistogram(label, float* values, N, ...)` — display | `PlotBaseWidget` (vector<float>)      | `ImGui_CreatePlotLines/Histogram`, `ImGui_SetPlotValues`, `ImGui_SetPlotScale`                                |

**Adding a widget** in an existing category = one line in the corresponding
list (`CLICKABLE`, `VALUE_BOOL`, `SLIDER`/`DRAG`/`INPUT`, `DISPLAY`, `CONFIG`,
`CONTAINER`) then `python dll/tools/generate.py`.

**Adding a new category** = `@dataclass` + list + `emit_*` trio + templates +
a section in `main()`. Each category stays **explicit** and doesn't touch the
others — see the `value_bool` pattern as a model.

Dispatch is polymorphic: a single C-ABI export per operation (e.g.
`ImGui_GetValueBool`) routes to the virtual `Widget::GetValueBool()`. Neutral
defaults in the `Widget` base class let any widget receive the call without
supporting it (returns -1/false).

### Semantics of the `changed` flag

- Latched **only** by user interaction in `Render()` (e.g. when
  `ImGui::Checkbox` returns `true`).
- `_ImGui_SetValueBool` from AutoIt **does not latch** `changed` — by design
  (consistent with `WasClicked`: the script does not see its own writes as
  notifications).
- Reading via `_ImGui_HasChanged`: read-and-reset under the lock, returns
  `True` exactly once per user toggle.

### Typed access pattern for numeric values

`GetValueBool` returns `-1` as a "not a bool widget" sentinel — possible
because bool only has `0`/`1`. For float/int there is no valid sentinel, so
the numeric getters use an **out-param + status code**:

```cpp
int ImGui_GetValueFloat(const wchar_t* id, float* out); // 0=ok, 1/2/3=err
int ImGui_GetValueInt  (const wchar_t* id, int*   out);
```

On the AutoIt side this stays transparent: `_ImGui_GetValueFloat($sId)`
returns the float directly and `SetError(3)` if the widget is not
float-valued (`@extended` carries the originating DLL code: 2=unknown id,
3=incompatible type).

### Tests

- [autoit/test_checkbox.au3](autoit/test_checkbox.au3) — `value_bool`:
  creation, get/set, strict semantics of the `changed` flag.
- [autoit/test_numeric.au3](autoit/test_numeric.au3) — `value_numeric`:
  the 6 widgets (Slider/Drag/Input × float/int), live display of values,
  user-change counters, and a "Reset" button that calls `Set*` on all six
  widgets and **must not** increment the counters (strict semantics
  verified for float and int in addition to bool).
- [autoit/test_display.au3](autoit/test_display.au3) — `display`: purely
  visual validation (Separator + Spacing in sections, SameLine aligning
  three buttons, Indent/Unindent shifting a block, Bullet at line start,
  NewLine forcing a break). No script-side logic to test.
- [autoit/test_config.au3](autoit/test_config.au3) — `config`: style stack
  (red buttons via PushStyleColor, wide padding via PushStyleVarVec2,
  rounded corners via PushStyleVarFloat — all properly reverted after the
  matching Pop), plus a slider driving `_ImGui_SetFontGlobalScale` live and
  a button toggling `ImGuiConfigFlags_NavEnableKeyboard`. Validates that
  global setters cross the inter-thread barrier correctly.
- [autoit/test_container.au3](autoit/test_container.au3) — `container`:
  scrollable Child (30 items), foldable CollapsingHeader, 2-tab TabBar with
  distinct subtrees, expandable TreeNode, Group with SameLine, plus a
  "Reparent" button that moves a widget dynamically between 2 Childs via
  `_ImGui_SetParent`. Validates the tree-based parent/children refactor.
- [autoit/test_window_menu.au3](autoit/test_window_menu.au3) — top-level
  floating `Window` + `MenuBar`/`Menu`/`MenuItem`: a Debug window separate
  from the host (movable/resizable, X close), File/Edit menus with items,
  plus `SetVisible`/`GetVisible`/`SetEnabled` validated via host checkboxes
  that drive the window's visibility and a target button's enabled state.
- [autoit/test_list.au3](autoit/test_list.au3) — dynamic `List`: two lists
  side by side. Static (10 items) to validate selection, scroll, and the
  programmatic pattern (`SetListSelection` does not latch `HasChanged`).
  Dynamic (a subset shuffled every 2s from the "Window A..J" master list)
  to validate **content-based preservation**: select "Window E", wait for
  a shuffle, "Window E" stays highlighted even if its index changed. If E
  disappears, the selection drops to `(none)` without incrementing the
  change counter.
- [autoit/test_input_text.au3](autoit/test_input_text.au3) — `InputText` /
  `InputTextMultiline`: 5 single-line fields (free, decimal-only, read-only,
  password, no-blank) + 1 multiline 3-line field. Buttons `Set free='Hello'`,
  `Clear all` and `Read all` validate the strict programmatic pattern
  (writes don't latch) and the `DllStructCreate("wchar buf[N]")` marshalling
  for `_ImGui_GetValueString`. Snapshot of the 6 values displayed in a Text
  for visual comparison.
- [autoit/test_combo.au3](autoit/test_combo.au3) — `Combo`: main "Profile"
  combo with 5 generic items, validation of click + popup + change counter
  (only increments on user selection). `Pick 'Option 3'` / `Clear` via
  `_ImGui_SetListSelection` (same exports as List — the
  `IndexedSelectionWidget` base unifies them). `Add Option F` /
  `Remove Option A` repopulates the items via `_ImGui_SetComboItems` and
  demonstrates content-based preservation. Two secondary combos test
  `$ImGuiComboFlags_HeightSmall` (popup truncated to 4 items out of 12) and
  `$ImGuiComboFlags_NoArrowButton`. On the right, an independent `List`
  serves as a regression control of the `IndexedSelectionWidget` refactor.
- [autoit/test_selectable.au3](autoit/test_selectable.au3) — `Selectable`:
  "Item A" validates the double-latching (state + click event on the same
  click, read via `_ImGui_HasChanged` AND `_ImGui_WasClicked`). Flags
  section: Disabled (uncloseable, greyed), AllowDoubleClick (only reacts
  to double-click), Highlight (rendered permanently as hover).
  **Radio-button-style group** of 4 Selectables: exclusivity handled in
  the script via `_ImGui_SetValueBool` on the others; critical test of
  strict semantics — the cascade of SetValueBool must not retrigger clicks
  (otherwise infinite loop). "Toggle A programmatically" button validates
  that looping writes never increments the counters.

### Comprehensive example

- [autoit/test_extras.au3](autoit/test_extras.au3) — **Phase A+B (Item
  queries, tooltips, text variants, button variants, CheckboxFlags,
  numeric vectors, ProgressBar, Color, Plot)**: 7 tabs. *Queries*
  hover/click/focus latched via `_ImGui_IsHovered/IsActive/IsFocused`,
  tooltips on hover via `_ImGui_SetTooltip`. *Text*: 6 Text variants
  (Colored RGB, Wrapped, Disabled, LabelText key:value, BulletText,
  SeparatorText). *Buttons*: 4 ArrowButtons L/R/U/D, InvisibleButton with
  counter, RadioButton group of 3 with script-side exclusivity,
  CheckboxFlags Read/Write/Execute sharing a synchronized int mask across
  the 3 boxes. *Vectors*: SliderFloat3 + DragInt2 + InputFloat4 with live
  read-back via `_ImGui_GetValueFloatN/IntN`. *Progress*: ProgressBar
  animated 0↔1 + 3 direct-set buttons. *Color*: ColorEdit4 + ColorPicker3
  (HueWheel) with read-back of the selected color. *Plot*: PlotLines
  (animated sinusoid) + PlotHistogram (random) repopulated every second
  via `_ImGui_SetPlotValues`. Demonstrates the full Phase A+B surface.

### End-to-end example

- [autoit/example_bot_panel.au3](autoit/example_bot_panel.au3) — a full
  application panel built end-to-end on the API: MenuBar with File/View,
  TabBar with Main/Settings/Log, action buttons (Start/Pause/Stop), Combo
  with profiles, InputText for a target, **live window list** updated
  every 2s via `WinList()` (scroll and selection survive refreshes thanks
  to content-based preservation), sliders + checkboxes in Settings,
  **ReadOnly InputTextMultiline** as a timestamped log, live status bar
  at the bottom, and **top-level Debug window** toggleable via menu OR
  checkbox (bidirectionally synchronised). Also calls
  `_ImGui_SetUnfocusedFps(15)` to demonstrate the polish pattern. Single
  loop with `Sleep(50)` — shows that the script can block its thread
  without freezing the UI.

Feedback flows entirely through the UI (no `ConsoleWrite`, no `ToolTip`).

### Render thread architecture

The render thread runs **two passes** per frame, under the same `g_tree.mtx`:

1. **Host (internal)** — opens `ImGui::Begin("##host")` (the borderless
   fullscreen OS window), iterates `g_tree.roots` skipping widgets with
   `IsTopLevelWindow()=true`. Recursion into nested containers happens
   naturally via `Widget::Render()` which calls its children.
2. **Top-level Windows (external)** — after the host's `ImGui::End()`,
   iterates `g_tree.roots` again and renders ONLY widgets with
   `IsTopLevelWindow()=true`. Each `WindowWidget::Render()` does its own
   floating `Begin/End` — ImGui draws these windows on top of the host
   (movable, resizable, independent focus).

`WindowWidget` is the only widget overriding `IsTopLevelWindow()` (auto-
generated via the `is_top_level_window=True` flag in the dataclass).

## List / Combo — shared IndexedSelectionWidget base

The `List` ([dll/src/list_widget.cpp](dll/src/list_widget.cpp)) and `Combo`
([dll/src/combo_widget.cpp](dll/src/combo_widget.cpp)) widgets share all their
**item management and selection** logic via the `IndexedSelectionWidget`
base (items + selected_index + selected_value + changed + `ApplyItems()`
with content-based preservation + `SetValueInt`/`GetValueInt`/
`ConsumeChanged`). Subclasses only add what is specific to them:

- `ListWidget`: `size_x`/`size_y` (size of the inline `BeginChild`);
- `ComboWidget`: `flags` (`ImGuiComboFlags_` bitmask) and its `BeginCombo`
  popup.

Practical consequence on the AutoIt side: **the same generic exports work
on both** — `_ImGui_GetListSelection`, `_ImGui_SetListSelection`,
`_ImGui_HasChanged`, `_ImGui_GetValueInt` dispatch on the base via
`dynamic_cast<IndexedSelectionWidget*>` (Get/Set Selection) or via the
virtual `Widget::GetValueInt` / `ConsumeChanged` (the others). Only the
item setters differ: `_ImGui_SetListItems` vs `_ImGui_SetComboItems`, to
preserve a sane `dynamic_cast` on the right type DLL-side (a call on the
wrong widget returns status 3 "not a combo / not a list" rather than
silently mutating).

## Dynamic List — content-based preservation

The `List` widget (and `Combo` by inheritance) is a special case: the only
retained widget whose **content** (not just value) is mutable from AutoIt.
Designed for the typical scenario where an AutoIt application needs to
display a list of currently-open windows, available files, dynamic
selections, etc. — items appearing and disappearing while the application
runs.

- **Marshalling.** AutoIt joins the array with a separator (`"|"` by
  default, override possible). The wrapper validates that no item contains
  the separator (otherwise `SetError(4)`); the DLL splits on the C++ side.
  A single DllCall per update, regardless of item count.
- **Scroll preservation.** Rendering happens in a `BeginChild` keyed on
  the widget id, and each line is wrapped in a `PushID(index)`. Result:
  ImGui naturally retains the scroll position and Selectable state across
  frames, even when the list has been repopulated.
- **Content-based selection preservation.** On each `SetListItems`,
  `ApplyItems()` snapshots the selected string (`selected_value`) and
  searches for it in the new list. If still present, `selected_index` is
  remapped to its new rank. If gone, selection drops to -1. Practical
  consequence: selecting "Window E" keeps it highlighted even if its
  index moves from 4 to 1 after a re-shuffle.
- **Strict `changed` semantics.** Like value widgets, only a user click
  in `Render()` latches `changed`. `SetListSelection`, `SetListItems`
  (even when the selection is silently cleared because the item is gone),
  and `SetValueInt` never latch.
- **GetValueInt aliased.** `_ImGui_GetValueInt($listId)` is equivalent to
  `_ImGui_GetListSelection` — the selected index is exposed as the int
  value of the widget.

## InputText — string out-param marshalling

The `InputText`/`InputTextMultiline` pair ([dll/src/input_text.cpp](dll/src/input_text.cpp))
introduces the only retained widget that exposes a **string value**
modifiable by the user. AutoIt → DLL marshalling is asymmetric:

- **Setter** (`_ImGui_SetValueString`): trivial, `"wstr"` on input, the
  DLL receives UTF-16 and converts to UTF-8 before copying into the buffer.
- **Getter** (`_ImGui_GetValueString`): the DLL has to *write* UTF-16
  into a caller-allocated buffer. The pattern is: the AutoIt wrapper does
  `DllStructCreate("wchar buf[N]")`, passes the pointer as `"ptr"` plus
  the capacity as `"int"`. The DLL converts UTF-8 → UTF-16 and writes up
  to N-1 wchars + null.

The alternative — using `"wstr"` as an out-param with a buffer auto-
allocated by AutoIt — does work but its size is implicit (sized to the
length of the initial value passed, with no minimum guaranteed in the
documentation). The struct pattern is more verbose but explicit, and
survives AutoIt updates without surprise.

Status code `4` (truncated) is treated as a soft success: the returned
value is usable, just possibly shortened. `@extended` carries the DLL
code for callers who want to distinguish.

**ImGui buffer.** `ImGui::InputText` does **in-place editing** on the
buffer it receives. The size is fixed at creation time (`max_length + 1`)
and never grows — the retained MVP does not expose `CallbackResize`. For
a field that needs to grow past `max_length`, create the widget with a
larger size from the start (the memory cost is trivial — a few KB per
field).

**Strict semantics reminder.** `_ImGui_SetValueString` never latches
`HasChanged`; same for initial writes via `default_value` at creation.
Only a user edit in `Render()` (= `ImGui::InputText` returning `true`)
latches the flag. Verified in `test_input_text.au3` via counters that
only move on keyboard input.

## Multi-instance (several scripts in parallel)

The earlier design mentioned a "multi-instance extraction: unique temp
filename per PID via `@AutoItPID`" requirement. **Not applicable to this
design.** The DLL is not extracted — it ships as a separate file under
`dll/bin/<arch>/imgui_autoit.dll` that each script loads via `DllOpen()` on
the path resolved by `@AutoItX64`.

Multi-instance isolation comes for free from Windows:

- **Code segment**: Windows shares the DLL code memory read-only across
  all processes that load it. No duplication, no conflict.
- **Data segment**: each process has its own copy (copy-on-write) of
  global variables — `g_tree`, `g_renderThread`, `g_pd3dDevice`, the
  ImGui context, etc. Each running script is strictly independent.
- **Windows resources**: each process creates its own window class
  (`RegisterClassExW("ImGuiAutoItRetained")` — the name is process-local
  for non-global classes), its own HWND, its own DX11 device.
- **Locks**: `g_tree.mtx` is a namespace-global `std::mutex`, so
  process-local. No named mutex, no shared section.

The only problematic scenario would be **rebuilding** the DLL while
several scripts are loading it — Windows refuses to write the file (file
lock on the loader side). This is a dev-only concern, not runtime. The
AutoIt wrapper does `DllOpen()`/`DllClose()` cleanly via
`OnAutoItExitRegister(_ImGui_Shutdown)`, so file locks are released as
soon as a script exits.

Cumulative cost. Each DX11 device + render thread + ImGui context ≈ 30 MB
of RAM and ~5-15% of a CPU core at rest (focused). The
**[unfocused FPS limiter](#unfocused-fps-limiter)** brings the GPU load
back to ~1-3% per instance once focus is lost, making it practical to
keep multiple idle instances in the background.

## Unfocused FPS limiter

`render_thread.cpp` detects `WM_ACTIVATE` in its `WndProc` and stores the
focus state in a `std::atomic<bool>`. In the loop, after `Present(1, 0)`
(VSync, ~16ms), if the window does not have focus, an additional `Sleep()`
calibrates the frame to the target rate.

- **Focused**: no added sleep, VSync alone → ~60 fps.
- **Unfocused**: complementary sleep computed to reach the configured fps
  (clamped to [1, 60], default 20).

The unfocused fps is exposed via `_ImGui_SetUnfocusedFps($iFps)` on the
AutoIt side (callable any time after `_ImGui_Init`). The value is read by
the render thread on every iteration (atomic load) — no restart required.

VSync stays enabled in both cases (`Present(1, 0)`) to eliminate tearing
even at low rates. The downside is that sleep precision depends on
`::Sleep()` (~1-2 ms of jitter on Windows), which is largely sufficient
when targeting 20 fps (50 ms per frame).

## Item queries & tooltips

Each widget has 3 state flags (`is_hovered`, `is_active`, `is_focused`)
latched at the end of each frame by `Widget::RenderAndQueryState()` via
`ImGui::IsItemHovered()` etc. — called just after the widget renders so
`IsItem*` refers to the correct ImGui item. The
`RenderAndQueryState()` method is called in place of direct `Render()` by:

- the render thread on every root widget (passes 1 and 2 over `g_tree.roots`);
- each generated container as it iterates its `children`.

Hand-written widgets (List, Combo, InputText, Selectable, RadioButton,
CheckboxFlags, ProgressBar, PlotLines/Histogram) keep their `Render()`
unchanged — their flags are latched by the parent's
`RenderAndQueryState()` wrapper. Consequence: no bug surface added to
existing widgets.

**Tooltips**: `Widget::tooltip` is a string. If non-empty and the widget
is hovered at `RenderAndQueryState()` time, `ImGui::SetTooltip("%s", tooltip)`
is called automatically. No need to handle tooltip rendering in the
script — just assign once via `_ImGui_SetTooltip($id, $text)`.

### Extended item queries (D.1)

Phase D.1 extended `RenderAndQueryState()` to latch 6 additional flags
plus the bounding rect of each widget. All **read-only frame state**:
reading does not reset state (unlike `WasClicked`/`HasChanged` which
consume). Reset to `0`/`false` when the widget is `!visible`.

| Export                              | Semantics                                              |
|-------------------------------------|--------------------------------------------------------|
| `_ImGui_IsClicked($id)`             | Left mouse clicked this frame. Distinct from `WasClicked` (which consumes). |
| `_ImGui_IsEdited($id)`              | Value changed this frame. Distinct from `HasChanged` (which consumes between reads). |
| `_ImGui_IsActivated($id)`           | Edge frame: start of interaction (e.g. mouse down).    |
| `_ImGui_IsDeactivated($id)`         | Edge frame: end of interaction.                        |
| `_ImGui_IsDeactivatedAfterEdit($id)`| Deactivated edge frame **AND** the value has changed.  |
| `_ImGui_IsVisible($id)`             | Widget currently drawn (not clipped).                  |
| `_ImGui_GetItemRectMin/Max($id)`    | Returns array[2] = (x, y) in ImGui screen-space coords. |
| `_ImGui_GetItemRectSize($id)`       | Derived `(max - min)` DLL-side — identical to `ImGui::GetItemRectSize()`. |

Plus the global **`_ImGui_IsAnyItemHovered/Active/Focused()`** — stored
as namespace-global `std::atomic<bool>` in `render_thread.cpp`, OR-merged
after each pass (host + top-level Windows) at frame end. No mutex
required AutoIt-side to read them.

Interactive validation: [autoit/test_item_queries.au3](autoit/test_item_queries.au3)
shows live all flags for 3 widgets (Button, Slider, InputText), with
edge counters to verify they fire exactly once.

### Debug windows + version (D.2)

5 built-in ImGui debug windows are drivable via atomic setters:

| Helper                            | ImGui window                                   |
|-----------------------------------|------------------------------------------------|
| `_ImGui_ShowDemoWindow($bShow)`        | Complete gallery of every ImGui widget    |
| `_ImGui_ShowMetricsWindow($bShow)`     | Per-frame stats, draw calls, perf counters |
| `_ImGui_ShowDebugLogWindow($bShow)`    | ImGui's internal log                       |
| `_ImGui_ShowIDStackToolWindow($bShow)` | Widget ID collision diagnostic             |
| `_ImGui_ShowAboutWindow($bShow)`       | Version + build info                       |

The render thread tests each atomic at the end of `RenderHostWindow()`
and calls the matching `ImGui::Show*Window(&p_open)` with a `bool*` that
round-trips: if the user closes the window via its X, the atomic flips
to False and `_ImGui_IsShowing*()` reflects the state. Typical script
pattern (see [test_debug_windows.au3](autoit/test_debug_windows.au3)):

```autoit
If _ImGui_HasChanged("cb_demo") Then _ImGui_ShowDemoWindow(_ImGui_GetValueBool("cb_demo"))
; ... then pull back so an X click reflects on the checkbox:
_ImGui_SetValueBool("cb_demo", _ImGui_IsShowingDemoWindow())
```

`_ImGui_GetVersion()` returns the embedded `IMGUI_VERSION` string (e.g.
`"1.92.8"`) via the `DllStructCreate("wchar buf[32]")` pattern. No
parsing needed script-side — `Return DllStructGetData($tBuf, "buf")` is
a direct AutoIt string.

**CMake note.** `imgui_demo.cpp` was added to `IMGUI_SOURCES` because it
defines `ImGui::ShowDemoWindow` and `ImGui::ShowAboutWindow` (the 3
other Show*Window are in `imgui.cpp`). +~250KB of binary — acceptable to
gain these 2 debug windows.

### Multi-viewport (D.2.1)

By default, ImGui windows (debug and top-level `WindowWidget`) are
constrained to stay INSIDE the host OS window — ImGui draws them into
the same DX11 backbuffer. To let the user drag them outside the OS
window (and have them become their own OS HWND), **multi-viewport** is
needed, which requires the **docking branch** of ImGui (not `master`).

The project therefore uses `dll/imgui-docking/` (shallow clone of
`ocornut/imgui` branch `docking`, v1.92.9 WIP) instead of
`imgui-1.92.8`. Three minimal changes in `render_thread.cpp`:

- Init: `io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable;`
- Style: when viewports are enabled, `WindowRounding = 0` +
  `WindowBg.w = 1` (windows outside the OS host must not be translucent
  or rounded at the edge — otherwise visually broken).
- Loop: between `ImGui_ImplDX11_RenderDrawData(...)` and `Present(1, 0)`,
  add `ImGui::UpdatePlatformWindows(); ImGui::RenderPlatformWindowsDefault();`
  which create/destroy secondary HWNDs + render+present each.

**Backend**: `imgui_impl_win32.cpp` + `imgui_impl_dx11.cpp` (docking
branch) automatically handle secondary viewports — no custom code to
write on the backend side. The secondary HWND WindowProcs are
registered/cleared by the backend.

**Docking deliberately not enabled**: only `ViewportsEnable` is set. Do
not add `ImGuiConfigFlags_DockingEnable` without discussing with the
user — the dock-zones UX was explicitly declined (see Phase D sprint
decision).

**Residual limitation**: the `##host` window itself (our borderless
host) stays attached to the OS window — it's the main viewport, and it
has `NoMove`. Only top-level windows can migrate elsewhere.

### Window manipulation (D.3)

`WindowWidget` moved from the generator (`container` category) to a
hand-written widget in [dll/src/window_widget.{h,cpp}](dll/src/window_widget.cpp),
because D.3 adds **pending state** fields + window-level queries that
don't fit the 4 `template_kind`s of the generator.

**Pending-state pattern.** Each setter (`_ImGui_SetWindowPos`,
`_ImGui_SetWindowSize`, `_ImGui_SetWindowCollapsed`,
`_ImGui_SetWindowFocus`, `_ImGui_SetWindowBgAlpha`,
`_ImGui_SetWindowSizeConstraints`) writes to a `pending_*` struct on
the widget + flips a `dirty` flag. `WindowWidget::Render()` consumes
the pending dirty BEFORE `ImGui::Begin()` by calling the corresponding
`ImGui::SetNextWindow*()`, then clears the dirty.

```autoit
; Center the window on startup, then let the user move it freely:
_ImGui_SetWindowPos("debug", 400, 200, $ImGuiCond_FirstUseEver)

; Force the window to take focus:
_ImGui_SetWindowFocus("debug")

; Live opacity slider:
_ImGui_SetWindowBgAlpha("debug", _ImGui_GetValueFloat("opacity"))
```

The `$iCond` parameter lets you choose between single-shot application
(`$ImGuiCond_Once` / `$ImGuiCond_FirstUseEver`) and every-frame
(`$ImGuiCond_Always` or `0`; ImGui's docs say `None` and `Always` are
equivalent).

**Window-level queries.** Latched in `WindowWidget::Render()` between
`Begin` and `End` (where `ImGui::IsWindow*()` and `GetWindow*()` are
valid):

| Helper                                | Semantics                                          |
|---------------------------------------|----------------------------------------------------|
| `_ImGui_IsWindowAppearing($id)`       | Frame of appearance (hidden→visible transition).   |
| `_ImGui_IsWindowCollapsed($id)`       | True if the user clicked the collapse arrow.       |
| `_ImGui_IsWindowFocused($id)`         | Window has keyboard focus (≠ item-level focus).    |
| `_ImGui_IsWindowHovered($id)`         | Mouse over the window (title OR body).             |
| `_ImGui_GetWindowPos($id)` → array[2] | Current position in desktop coords (multi-vp).     |
| `_ImGui_GetWindowSize($id)` → array[2]| Current size including title + body.               |

**Important distinction**: `_ImGui_IsHovered($windowId)` (item-level via
`ImGui::IsItemHovered`) returns a different result from
`_ImGui_IsWindowHovered($id)`. The first treats the window as the
"current item" (typically after End — its title bar area); the second
treats the window as a global entity including its content. Use as
needed.

**Strict semantics preserved.** Setters do not latch the queries —
`Set*` just sets a dirty flag, it's `Render()` that writes
`is_appearing` etc. according to what ImGui actually returns. No silent
loop possible.

Validation: [autoit/test_window_manip.au3](autoit/test_window_manip.au3):
9 setter buttons + 6 live queries + an `IsAppearing` edge counter to
verify it fires on each hide→show.

### Settings persistence (D.4)

ImGui natively saves position/size/collapsed-state of top-level
WindowWidget into a readable `.ini` file. The project **keeps
`io.IniFilename = nullptr`** in init → no .ini is created automatically
next to the scripts. Opt-in persistence via two helpers:

```autoit
; Canonical pattern: load BEFORE CreateWindow, save on user action or exit.
_ImGui_Init("My Application", 800, 600)
_ImGui_LoadSettings(@ScriptDir & "\layout.ini")  ; silent no-op if missing
_ImGui_CreateWindow("debug", "Debug")            ; 1st Begin() applies the cache
_ImGui_CreateWindow("settings", "Settings")

; ... user drags/resizes the windows during use ...

OnAutoItExitRegister(SaveLayout)
Func SaveLayout()
    _ImGui_SaveSettings(@ScriptDir & "\layout.ini")
EndFunc
```

**Important pitfall**: Load applies its cache to the NEXT `Begin()` of
a widget. If you call Load AFTER creating the windows, they have already
applied their initial state — Load has no effect on them. To handle this
case, manually call `_ImGui_SetWindowPos/Size/Collapsed` after the Load
with the desired values. The canonical pattern (Load before Create) is
the simplest.

Validation: [autoit/test_settings.au3](autoit/test_settings.au3) — first
run positions the window at the default location, the user moves it and
clicks Save, the restart repositions it automatically. "Delete .ini"
button to reset between tests.

### Menu extensions (D.5)

`MenuItemWidget` moved out of the generated clickable category and
became hand-written in [dll/src/bool_extras.cpp](dll/src/bool_extras.cpp),
because it now has 3 jobs: display a label, optionally show a
right-aligned shortcut hint, and maintain a persistent "selected" state
(checkmark on the left). Inherits `BoolValueWidget` + adds its own
`clicked` flag (same double-latch as Selectable).

**New signature**:

```autoit
_ImGui_CreateMenuItem($sId, $sLabel = "", $sShortcut = "", $bSelected = False, $bEnabled = True)
```

Old 2-arg callers (`_ImGui_CreateMenuItem("save", "Save")`) keep
working — the D.5 params all have defaults.

| Use case                | Script pattern                                              |
|-------------------------|-------------------------------------------------------------|
| Action (Save, Quit)     | `_ImGui_WasClicked($id)` (consume-and-reset)                |
| Toggle (Show debug)     | `_ImGui_GetValueBool($id)` / `_ImGui_HasChanged($id)`       |
| Programmatic toggle     | `_ImGui_SetValueBool($id, $bValue)` (latches NOTHING)       |

**Strict semantics preserved**: the checkmark flips on user click OR on
`SetValueBool`, but `HasChanged`/`WasClicked` only fire on user click.

**MainMenuBar** (`_ImGui_CreateMainMenuBar`) — added as a generated
container with a new `is_main_menu_bar=True` flag that routes it to a
**dedicated pre-pass** in the render thread, BEFORE the host.
`BeginMainMenuBar()` reserves its area via the main viewport's
`WorkOffsetMin`, then the host positions itself at `viewport->WorkPos`
(= just below the menu bar). Result: the custom title bar + min/close
buttons no longer overlap with the menu, everything stacks properly
(menu bar → title bar → content).

This requires two changes to the render thread:
- Pre-pass `for (w : roots) if (w->IsMainMenuBar()) w->RenderAndQueryState()` before the host Begin.
- Host uses `main_viewport->WorkPos/WorkSize` instead of `Pos/Size`.
- Pass 1 and 2 skip MainMenuBarWidgets (already rendered in pre-pass).

Validation: [autoit/test_menu.au3](autoit/test_menu.au3) — MainMenuBar
with 2 menus (File + View), items with shortcut hints (`Ctrl+S`),
toggleable items with HasChanged/WasClicked counters verifying strict
semantics.

### Tree extensions (D.6)

`TreeNodeWidget` and `CollapsingHeaderWidget` moved out of the generator
container and were hand-written in [dll/src/tree_extras.{h,cpp}](dll/src/tree_extras.h).
Same motivation as D.3 for `WindowWidget`: they gain per-widget
pending-state (`SetNextItemOpen` consumed on the next Render) and
latched queries (`IsItemToggledOpen`) that don't fit the four
`template_kind`s of the generator.

**New signatures (2-arg backward-compat)**:

```autoit
_ImGui_CreateTreeNode($sId, $sLabel = "", $iFlags = 0)
_ImGui_CreateCollapsingHeader($sId, $sLabel = "", $bClosable = False, $iFlags = 0)
_ImGui_SetNextItemOpen($sId, $bOpen, $iCond = 0)        ; 0 ≡ Always
_ImGui_IsToggledOpen($sId)
```

`$iFlags` accepts any BitOR combination of `$ImGuiTreeNodeFlags_*` (22
constants added, values from `imgui-docking/imgui.h:1349-1380`).

**X close button semantics**: when `$bClosable = True`, Render() routes
to the `ImGui::CollapsingHeader(label, &visible, flags)` overload. If
the user clicks the X, ImGui writes `false` into `Widget::visible` —
exactly the same bool that `_ImGui_SetVisible` reads/writes. On the
next frame, the early-return at the top of Render() hides the entire
subtree. To re-show the section, the script calls
`_ImGui_SetVisible($sId, True)`. Consistent with the WindowWidget pattern.

**SetNextItemOpen pending semantics**: each setter writes
`pending_open_*` + flips `pending_open_dirty = true` under mutex. The
next Render() calls `ImGui::SetNextItemOpen(value, cond)` BEFORE the
TreeNodeEx/CollapsingHeader then resets the dirty flag.
`$ImGuiCond_Always` (0) = override every frame; `$ImGuiCond_Once` =
seed once then let the user toggle freely.

**Strict semantics preserved**: neither `SetNextItemOpen` nor
`SetVisible` latches `is_toggled_open`. Only a real user click on the
arrow/header makes `IsItemToggledOpen()` return true (the widget
records it just after the `TreeNodeEx/CollapsingHeader` call, before
walking children, to avoid a child's last-item shadowing the query).

Validation: [autoit/test_treenode.au3](autoit/test_treenode.au3) —
TreeNode with DefaultOpen / Leaf / SpanAvailWidth, CollapsingHeader
with and without X, Force-open/close + Pin (Cond_Always) + Seed once
(Cond_Once), toggle counters that only advance on user toggle.

### Tab extensions (D.7)

TabBar stays generated (`flags` added via DisplayParam —
`$ImGuiTabBarFlags_*`). TabItem moved out of the generator and is now
hand-written in [dll/src/tab_extras.{h,cpp}](dll/src/tab_extras.h), for the
same reasons as TreeNode/CollapsingHeader in D.6: per-widget pending
state + closable X + flags constructor. **TabItemButton** is a brand
new widget (inline ClickableWidget, no body) for tabs-as-buttons (`+`
/ `≡`).

**New signatures (2-arg backward-compat)**:

```autoit
_ImGui_CreateTabBar($sId, $sLabel = "", $iFlags = 0)
_ImGui_CreateTabItem($sId, $sLabel = "", $bClosable = False, $iFlags = 0)
_ImGui_CreateTabItemButton($sId, $sLabel = "", $iFlags = 0)
_ImGui_SetTabItemClosed($sId)
```

**X close button semantics**: identical to CollapsingHeader (D.6) and
Window (D.3). When `$bClosable = True`, Render() routes to
`ImGui::BeginTabItem(label, &visible, flags)`. X click → ImGui writes
`false` into `Widget::visible`; on the next frame the early-return
hides the tab and its body. `_ImGui_SetVisible($sId, True)` re-shows.

**SetTabItemClosed semantics**: different from a simple
`SetVisible(False)`. The setter writes `pending_closed = true` AND
`visible = false` atomically under mutex. On the next Render() of the
TabItemWidget (which runs INSIDE the parent's BeginTabBar/EndTabBar),
the FIRST thing is the call to `ImGui::SetTabItemClosed(label)` BEFORE
any `BeginTabItem`. This is exactly the ImGui contract to reduce visual
flicker on reorderable TabBars.

**TabItemButton** — a `ClickableWidget` inline rendered via
`ImGui::TabItemButton(label, flags)`. No body, no children. The most
useful flags are `$ImGuiTabItemFlags_Leading` (pin to the left of the
bar) and `$ImGuiTabItemFlags_Trailing` (pin to the right). Read clicks
via `_ImGui_WasClicked($sId)`, identical to any Button.

**Strict semantics preserved**: neither `SetTabItemClosed` nor
`SetVisible` latches `WasClicked`/`HasChanged`. Only a real click on a
TabItemButton or selection of a TabItem by the user advances these
counters.

Validation: [autoit/test_tabs.au3](autoit/test_tabs.au3) — TabBar with
Reorderable/AutoSelect/Overline, `UnsavedDocument` tab (dot), Closable
X, Bye + SetTabItemClosed, TabItemButton Leading "≡" / Trailing "+".

### Popups / Modals (E.1)

Two new top-level widgets in [dll/src/popup_extras.{h,cpp}](dll/src/popup_extras.h):
`PopupWidget` (regular floating popup, no title bar) and
`PopupModalWidget` (dim background + title bar + optional X close
button). Both inherit `Widget` directly, override `IsTopLevelWindow() =
true` (rendered OUTSIDE the host Begin/End, like WindowWidget).

**Signatures**:

```autoit
_ImGui_CreatePopup($sId, $sLabel = "", $iFlags = 0)              ; floating popup
_ImGui_CreatePopupModal($sId, $sLabel = "", $bClosable = False, $iFlags = 0)
_ImGui_OpenPopup($sId)         ; pending open consumed at next Render
_ImGui_ClosePopup($sId)        ; pending close — honored only when popup IS open
_ImGui_IsPopupOpen($sId)       ; latched after BeginPopup
```

`$iFlags` accepts `$ImGuiWindowFlags_*` (forwarded to BeginPopup/Modal).
`$ImGuiPopupFlags_*` (11 constants) are exposed for future use via
IsPopupOpen (AnyPopupId/AnyPopupLevel not wired in E.1) and the
eventual Context* helpers.

**Pending open/close semantics**:
- `_ImGui_OpenPopup` sets `pending_open_dirty = true`. On the next
  Render, before any `BeginPopup`, calls `ImGui::OpenPopup(id)` then
  resets the flag.
- `_ImGui_ClosePopup` sets `pending_close_dirty = true`. Consumed
  INSIDE the `BeginPopup` body (= only when the popup is open) by a
  call to `ImGui::CloseCurrentPopup()`. If the popup is already closed
  at Render time, the flag is silently dropped.

**Modal X close button semantics**: identical to Window /
CollapsingHeader / TabItem. Closable=True → `&visible` passed as
`bool* p_open` to BeginPopupModal. X click → ImGui writes `false` into
`Widget::visible` and closes the popup internally. Re-open via
`_ImGui_OpenPopup`: Render auto-resets `visible=true` just before
`ImGui::OpenPopup` so the cycle stays clean. No need for the script to
call SetVisible(True) explicitly.

**Note on what is out of scope for E.1**: the `AnyPopupId`/
`AnyPopupLevel` flags on `IsPopupOpen` are not wired (niche). Everything
else — context popups + chain trigger — is delivered in E.1.x (next
section).

Validation: [autoit/test_popups.au3](autoit/test_popups.au3) — simple
popup + modal without X + modal with X, dim background on modals,
IsPopupOpen live, OpenPopup/ClosePopup counters verifying strict
semantics.

### Context popups + OpenPopupOnItemClick (E.1.x)

Extension of [dll/src/popup_extras.{h,cpp}](dll/src/popup_extras.h) with two
new **inline** widgets (not top-level — their Render must run in the
right window scope for ImGui to hash the id correctly):

- **`ContextPopupWidget`** — unified container merging
  `BeginPopupContext{Item,Window,Void}` + body. Discriminated by
  `int kind` (0=Item / 1=Window / 2=Void). Inherits the same
  pending_open/close + is_popup_open contract as `PopupWidget`;
  `FindPopupView` extended to route it to the existing E.1 exports
  (`_ImGui_OpenPopup`/`ClosePopup`/`IsPopupOpen`).
- **`OpenPopupOnItemClickWidget`** — pure marker with no body. On
  every frame, checks `IsItemHovered + IsMouseReleased(button)` (the
  button comes from the `ImGuiPopupFlags_MouseButton*` mask, default
  Right). On match, routes **directly** to
  `target.pending_open_dirty=true` via `g_tree.Find` — bypasses ImGui's
  id-hashing which mismatches between Pass 1 (host) and Pass 2
  (fallback window). Practical consequence: an inline marker can chain
  to a top-level popup (PopupWidget at root) without issue.

**Signatures**:

```autoit
_ImGui_CreateContextPopup($sId, $sLabel = "", $iKind = 0, $iFlags = 0)
;   $iKind: 0=Item (place after the target sibling)
;           1=Window (anywhere in the enclosing window)
;           2=Void (right-click outside any window)
_ImGui_CreateOpenPopupOnItemClick($sId, $sTargetPopupId, $iFlags = 0)
;   target = id of a PopupWidget / PopupModalWidget / ContextPopupWidget
;   silent typos (target not validated at create), no-op at use
```

`$iFlags` accepts `$ImGuiPopupFlags_*`. Default 0 = `MouseButtonRight`
in ImGui (since 1.92.6). Force left with `$ImGuiPopupFlags_MouseButtonLeft`.

**Placement rule**:
- `kind=Item` AND the `OpenPopupOnItemClick` marker: insert as the
  **next child after** the target item in the same `children[]`
  (ImGui's "previous item" semantics).
- `kind=Window`: anywhere in the enclosing window — a Child or the
  host itself.
- `kind=Void`: anywhere (the trigger requires that no window be
  hovered at release time).

Validation: [autoit/test_context_popups.au3](autoit/test_context_popups.au3)
— the 3 kinds in action (Item on Button, Window in Child, Void at
root) + chain marker left-click on Button → top-level PopupWidget
(`p_chained`), proving the cross-pass bypass.

### Layout extras + Focus helpers + Constants (F.1 + F.2 + F.3)

Final block to reach ~95% of useful coverage.

**F.1 — 14 widgets added to the generator** (`display` + `config`
categories):

- *Layout markers* (display): `Dummy(w, h)`, `AlignTextToFramePadding()`,
  `SetNextItemWidth(width)`.
- *Stack pairs* (config): `PushItemWidth(width)`/`PopItemWidth()`,
  `PushTextWrapPos(pos)`/`PopTextWrapPos()`,
  `PushItemFlag(option, enabled)`/`PopItemFlag()`,
  `PushStyleVarX(idx, x)` and `PushStyleVarY(idx, y)` (single-component
  variants of a Vec2 StyleVar).

The `Display` dataclass of the generator was extended with an optional
`render_call: str = ""` field (default empty → historical behavior) —
used by `Dummy` to wrap the 2 floats into an `ImVec2`. Same pattern as
`Config` / `Clickable`. No new hand-written code.

**F.2 — 5 hand-written free functions** in `utils_extras.cpp`:

```autoit
_ImGui_SetNavCursorVisible($bVisible)        ; show/hide nav focus ring
_ImGui_GetTime()                              ; double seconds — ImGui internal clock
_ImGui_GetFrameCount()                        ; int frame counter
_ImGui_GetStyleColorName($iColIdx [, $iBufSize])  ; "Text", "Button", ...
_ImGui_SetStyleTheme($iTheme)                 ; 0=Dark / 1=Light / 2=Classic
```

`_ImGui_SetStyleTheme` automatically reapplies the multi-viewport tweak
(opaque WindowBg + WindowRounding=0) after each swap because
`StyleColors*` overwrites both. The 3 focus markers
(`SetItemDefaultFocus`, `SetNextItemAllowOverlap`,
`SetKeyboardFocusHere`) are delivered via the generator (`display`
category) and listed in F.1.

**F.3 — Constants audit**: `ImGuiCol_` and `ImGuiStyleVar_` rewritten
with indices corrected for the docking branch (insertions of
`InputTextCursor`/`TabHovered`/`Docking*` etc. shifted the values). New
blocks `$ImGuiChildFlags_*`, `$ImGuiHoveredFlags_*`,
`$ImGuiFocusedFlags_*`, `$ImGuiItemFlags_*`, `$ImGuiMouseCursor_*`
(the last one anticipating a future SetMouseCursor). Pseudo-enum
`$ImGuiStyleTheme_Dark/Light/Classic` for `_ImGui_SetStyleTheme`.

**Migration**: if you had hardcoded `$ImGuiCol_Tab = 36` or
`$ImGuiCol_PlotLines = 41` (1.92.8 master values), switch back to the
named constants — these two values became respectively `36` (unchanged,
but surrounded by `35=TabHovered`) and `44` (was 41).

Validation: [autoit/test_f_extras.au3](autoit/test_f_extras.au3) — 10
sections covering ItemWidth + SetNextItemWidth, PushTextWrapPos,
PushItemFlag(NoTabStop), PushStyleVarX, Dummy +
AlignTextToFramePadding, SetItemDefaultFocus in Popup,
SetKeyboardFocusHere auto-focus, SetNextItemAllowOverlap,
GetTime/GetFrameCount/GetStyleColorName live, Dark/Light/Classic theme
switcher.

### Finishing mix (G.1 to G.6)

Terminal block to fill in the residual gaps.

**G.1 — TextLink**: added to the `clickable` category of the generator
with `render_call="ImGui::TextLink(shown)"` (returns bool like Button).
Latch via `ClickableWidget::ConsumeClick` → `_ImGui_WasClicked($id)`.
`TextLinkOpenURL` deliberately skipped (URL validation safety).

**G.2 — SetMouseCursor (sticky)**: free function
`_ImGui_SetMouseCursor($iCursor)` + atomic `g_pendingMouseCursor` in
`render_thread.cpp`. Applied after each `NewFrame()` to survive ImGui's
per-frame reset. Pass -1 (= `$ImGuiMouseCursor_None`) to release.

```autoit
While _ImGui_IsRunning()
    If _ImGui_IsHovered("mybutton") Then
        _ImGui_SetMouseCursor($ImGuiMouseCursor_Hand)
    Else
        _ImGui_SetMouseCursor($ImGuiMouseCursor_None)   ; release
    EndIf
    Sleep(30)
WEnd
```

**G.3 — IsKey* + `$ImGuiKey_*` block**: 3 free functions under
`g_tree.mtx`:

```autoit
_ImGui_IsKeyDown($iKey)
_ImGui_IsKeyPressed($iKey, $bRepeat = True)
_ImGui_IsKeyReleased($iKey)
```

120 `$ImGuiKey_*` constants added (Tab=512 → Oem102=631) + 4
modifiers `$ImGuiMod_Ctrl/Shift/Alt/Super` (high bits for chord values).
Value added vs AutoIt's `_IsPressed`: only fires when ImGui has
actually captured the input — the panel must be focused AND the key
must not be consumed by an InputText/Shortcut.

**G.4 — ShowStyleEditor**: same round-trip pattern as D.2.
`ShowStyleEditor()` is a block (not a window), so wrapped in
`ImGui::Begin("Style Editor", &open)` on the render-thread side.
`_ImGui_ShowStyleEditor($bShow)` + `_ImGui_IsShowingStyleEditor()` — a
user X click flips `g_showStyleEditor` to false, visible at the next
AutoIt poll.

**G.5 — SetCursorPos / GetCursorPos**: 3 markers via the display
generator (`SetCursorPos`, `SetCursorPosX`, `SetCursorPosY`) + 1
hand-written widget `GetCursorPosWidget` (latch in `utils_extras.cpp`):

```autoit
_ImGui_CreateSetCursorPosX("setx", 200.0)
_ImGui_CreateText("text", "<- I am at local x=200")
_ImGui_CreateGetCursorPos("query")   ; marker that latches the current pos

; In the loop:
Local $aPos = _ImGui_GetCursorPos("query")    ; (x, y) in window-local coords
```

Window-local coords (not screen-space). `GetCursorScreenPos` /
`SetCursorScreenPos` skipped — the local variant covers the layout use
case.

**G.6 — CalcTextSize**: free function
`_ImGui_CalcTextSize($sText, $fWrapWidth = -1.0)` → array[2] = (w, h).
Under `g_tree.mtx`. Thread-safety solved by a **pre-tick** at init: the
render thread runs an empty `NewFrame()` + `EndFrame()` before
signaling `m_initOk` to AutoIt, which populates `GImGui->Font` (without
which an immediate CalcTextSize call from the AutoIt thread would
dereference a null pointer). `GImGui` is NOT thread-local in our build
(`IMGUI_USE_BX_THREAD_LOCAL_CONTEXT` not defined), so the AutoIt thread
sees the same context.

Validation: [autoit/test_g_extras.au3](autoit/test_g_extras.au3) — 6
sections covering TextLink + click counter, SetMouseCursor sticky
hover, IsKey* Down/Press/Release readouts, ShowStyleEditor with X
round-trip, SetCursorPosX(200) + GetCursorPos latch, CalcTextSize live.

**Simultaneous hardening (race fixes)**: Phase G also reinforced the
concurrency model — the `g_tree.mtx` mutex became `std::recursive_mutex`,
the render thread takes a **frame-wide lock** around NewFrame → widget
render → Render → multi-viewport platform render (Present stays out of
the lock to avoid blocking AutoIt on vsync), and ImGui teardown
(DestroyContext) is also under the lock with a `BAIL_IF_NO_IMGUI_CTX`
guard on every AutoIt-thread helper that touches ImGui (CalcTextSize,
IsKey*, GetMousePos, …). Without these protections, the new G.3/G.6
readers would segfault during interaction (NewFrame ↔ CalcTextSize race)
and on shutdown (DestroyContext ↔ in-flight helper race).

### Phase H — Targeted small extensions (H.1 → H.4)

**H.1 Scroll helpers** — new `ScrollableState` struct (4 latched floats
+ 6 pending fields) shared between `WindowWidget` and a now hand-written
`ChildWidget` (moved out of the generator container to embed scroll
state). Routing via `Widget::GetScrollable()` virtual; non-scrollable
→ nullptr. 9 exports: `_ImGui_GetScrollX/Y/MaxX/MaxY` (out-param float),
`_ImGui_SetScrollX/Y`, `_ImGui_SetScrollHereX/Y($fCenterRatio)`,
`_ImGui_SetScrollFromPosX/Y($fLocalPos, $fCenterRatio)`. Setters are
applied AFTER children but BEFORE End/EndChild, which gives the
canonical "scroll to bottom" semantics for log panels (the cursor is
at its final position when `SetScrollHereY(1.0)` runs). Canonical use
case:

```autoit
_ImGui_CreateChild("logs", "", 0, 200, True)
_ImGui_CreateText("log_text", "")
_ImGui_SetParent("log_text", "logs")

While _ImGui_IsRunning()
    If $bNewLine Then
        _ImGui_SetText("log_text", $sLog)
        ; Composable "user has scrolled manually" detection:
        Local $fY = _ImGui_GetScrollY("logs")
        Local $fM = _ImGui_GetScrollMaxY("logs")
        If ($fM - $fY) < 4.0 Then _ImGui_SetScrollHereY("logs", 1.0)
    EndIf
WEnd
```

**H.2 Multi-widget tooltips** — new hand-written `ItemTooltipWidget`
container in `dll/src/tooltip_extras.{h,cpp}`. Render() uses
`ImGui::BeginItemTooltip()` (= `IsItemHovered(ForTooltip)` +
`BeginTooltip()`), renders its children inside, then `EndTooltip()`.
Distinct from `Widget::tooltip` (single-line string) — the new widget
carries an arbitrary tree of children (Text + Separator + another Text
+ Image as in H.4 if needed). **Placement constraint**: must be the
immediately-next sibling after the target widget at the same parent
level (ImGui operates on the "last item"). 1 export:
`_ImGui_CreateItemTooltip($sId)`.

**H.3 Font management** — new `font_registry` namespace in
`dll/src/font_extras.{h,cpp}`. Append-only `std::vector<ImFont*>` storage.
Index 0 = the default font (Calibri 15.5pt loaded by render_thread at
init); indices 1+ = fonts loaded via `_ImGui_LoadFont($sPath, $fSize)`
which returns a font_id or -1 on error. PushFont/PopFont are
hand-written marker widgets — PushFont with an unknown id falls back to
the default (index 0) without crashing (avoids stack imbalance
assertions). In ImGui 1.92 the DX11 backend has
`BackendFlags_RendererHasTextures` which incrementally rebuilds the
atlas on every NewFrame, so hot-loading has no visible hitch. No
FreeFont in the MVP — the atlas can't shrink without invalidating every
ImFont*. 4 exports: `LoadFont`, `GetFontCount`, `CreatePushFont`,
`CreatePopFont`.

**H.4 Images / ImageButton** — native Windows loader via WIC
(`windowscodecs.lib`; PNG / JPG / BMP / TIFF / GIF supported) in
`dll/src/texture_loader.{h,cpp}`. Pipeline: `CreateDecoderFromFilename` →
`GetFrame` → `CreateFormatConverter(32bppRGBA)` → `CopyPixels` →
`ID3D11Device::CreateTexture2D` → `CreateShaderResourceView`. The SRV
is cast to `(ImTextureID)(intptr_t)srv` and passed to `ImGui::Image` /
`ImageButton` via the implicit `ImTextureRef` constructor. The DX11
device is exposed via `render_thread::GetD3DDevice()` (returns nullptr
post-shutdown — guard 2 = "device not ready"). No FreeTexture in the
MVP — releases everything via `texture_registry::Reset()` at teardown,
BEFORE `CleanupDeviceD3D` to avoid dangling COM refs. 4 exports:
`LoadTexture`, `GetTextureSize`, `CreateImage`, `CreateImageButton`.
`ImageWidget` is display-only; `ImageButtonWidget` inherits
ClickableWidget → standard `_ImGui_WasClicked`. Bad tex_id = Dummy hit
area + TextDisabled placeholder, no crash. Tests:
[autoit/test_scroll.au3](autoit/test_scroll.au3),
[autoit/test_tooltips_rich.au3](autoit/test_tooltips_rich.au3),
[autoit/test_fonts.au3](autoit/test_fonts.au3),
[autoit/test_images.au3](autoit/test_images.au3).

### Phase I — Tables

Target: `BeginTable / EndTable` + row/column markers +
`TableSetupColumn` + `TableHeadersRow` + sort spec latching +
`TableSetupScrollFreeze` + 60+ constants (`ImGuiTableFlags_*`,
`ImGuiTableColumnFlags_*`, `ImGuiTableRowFlags_*`,
`ImGuiSortDirection_*`).

**Architecture**: 5 hand-written widgets in `dll/src/table_extras.{h,cpp}`:

- `TableWidget` — root container, walks children between BeginTable
  and EndTable. Stores `column_count`, `flags`, `outer_size`,
  `inner_width`, the vector of `ColumnConfig` (label + flags +
  width-or-weight, populated by `_ImGui_TableSetupColumn`),
  `freeze_cols/rows`, and the latched sort spec (`sort_col_index`,
  `sort_direction`).
- `TableNextRowWidget` / `TableNextColumnWidget` /
  `TableSetColumnIndexWidget` — stateless markers, one Render() = one
  corresponding ImGui call.
- `TableHeadersRowWidget` — zero-arg marker, calls
  `ImGui::TableHeadersRow()`.

**Markers + siblings model**: cells ARE NOT subcontainers. Content
widgets (Text, Button, Selectable, …) are siblings AFTER the matching
`TableNextColumn` marker, at the same level of the table's children
list. This is exactly how ImGui's native table API works: "move the
cursor to the next cell, then everything you submit goes into that
cell". Keeps the children tree flat (no double-nesting per cell).

**Sort spec latching**: at the end of each Render, reads
`ImGui::TableGetSortSpecs()` → stores `Specs[0].ColumnIndex` and
`SortDirection` on the widget. AutoIt polls via
`_ImGui_TableGetSortSpecs($sId)` → array[2]. Single-column in the MVP
(SortMulti via specs[1..] exposed in J.6 — see below).

**Canonical use case** — sortable scoreboard:

```autoit
_ImGui_CreateTable("scores", 3, BitOR($ImGuiTableFlags_Borders, _
    $ImGuiTableFlags_Sortable, $ImGuiTableFlags_RowBg))
_ImGui_TableSetupColumn("scores", "Name",  $ImGuiTableColumnFlags_WidthStretch, 2.0)
_ImGui_TableSetupColumn("scores", "Value", BitOR($ImGuiTableColumnFlags_WidthStretch, _
                                                  $ImGuiTableColumnFlags_DefaultSort), 1.0)
_ImGui_TableSetupColumn("scores", "Tag",   $ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_CreateTableHeadersRow("scores_hdr")
_ImGui_SetParent("scores_hdr", "scores")

For $i = 0 To 7
    Local $sR = "row_" & $i
    _ImGui_CreateTableNextRow($sR)
    _ImGui_SetParent($sR, "scores")
    For $col = 0 To 2
        Local $sC = "c_" & $i & "_" & $col
        _ImGui_CreateTableNextColumn($sC)
        _ImGui_SetParent($sC, "scores")
        Local $sT = "t_" & $i & "_" & $col
        _ImGui_CreateText($sT, String($g_aRows[$i][$col]))
        _ImGui_SetParent($sT, "scores")
    Next
Next

While _ImGui_IsRunning()
    Local $aSpec = _ImGui_TableGetSortSpecs("scores")
    If IsArray($aSpec) And $aSpec[0] >= 0 Then
        ; Re-sort $g_aRows by column $aSpec[0] direction $aSpec[1] (1=Asc, 2=Desc)
        ; Then push back into the text widgets via _ImGui_SetText
    EndIf
WEnd
```

Test: [autoit/test_tables.au3](autoit/test_tables.au3) — 3 sections
(basic 3×5 + sortable 8-row scoreboard + ScrollY 50-row with frozen
header row).

### Phase J — Helpers roundout

No new container, just broadening of the free-function surface plus a
few extensions on existing widgets. 25 new exports split into 6
sub-phases:

**J.1 — Mouse helpers complete** (12 free functions,
`utils_extras.cpp`): `IsMouseDown/Clicked/Released/DoubleClicked($iButton)`,
`IsMouseDragging($iButton, $fThreshold)`,
`ResetMouseDragDelta($iButton)`,
`IsMouseHoveringRect($fMinX, $fMinY, $fMaxX, $fMaxY)`,
`IsMousePosValid()`, `IsAnyMouseDown()`,
`GetMouseClickedCount($iButton)`, `GetMouseCursor()`,
`SetNextFrameWantCaptureMouse($bWant)`. All under `g_tree.mtx` +
`BAIL_IF_NO_IMGUI_CTX`. **Crash fix note**: `IsMouseHoveringRect` with
`clip=true` dereferenced `g.CurrentWindow` which is null between frames
on the AutoIt thread — `$bClip` is now ignored on the C-ABI side
(always false). Documented in the AutoIt wrapper.

**J.2 — Keyboard helpers complete** (4 free functions):
`IsKeyChordPressed($iKeyChord)` (combine
`$ImGuiMod_Ctrl + $ImGuiKey_S`), `GetKeyPressedAmount($iKey, $fDelay,
$fRate)`, `GetKeyName($iKey, $iBufSize = 32)` (out-param wchar buffer),
`SetNextFrameWantCaptureKeyboard($bWant)`.

**J.3 — Window manip extras** (2 setters via pending state on
`WindowWidget`):

- `_ImGui_SetWindowContentSize($sId, $fW, $fH)` —
  `SetNextWindowContentSize` to pin the content area used by scrollbars
  when ScrollX/Y is active.
- `_ImGui_SetWindowScroll($sId, $fX, $fY)` — `SetNextWindowScroll`
  BEFORE Begin (distinct from H.1 `SetScrollX/Y` which fires AFTER
  children).

**J.4 — Settings memory variants** (2 free functions, for persistence
into Registry / custom INI / save file profile):

- `_ImGui_LoadSettingsFromMemory($sIniData)` — applies an ini-format
  blob.
- `_ImGui_SaveSettingsToMemory($iBufSize = 8192)` → string. Status 4 =
  truncated.

**J.5 — Tables runtime extras** (4 distinct features):

- `_ImGui_TableSetColumnEnabled($sTableId, $iCol, $bEnabled)` —
  pending vector on `TableWidget`, applied inside the
  `BeginTable/EndTable` scope at the start of Render. Toggle a
  column's visibility at runtime (vs flag-time).
- `_ImGui_CreateTableSetBgColor($sId, $iTarget, $iU32Color, $iColumnN = -1)`
  — `TableSetBgColorWidget` marker widget placed as a sibling AFTER
  the targeted `TableNextRow`/`TableNextColumn`. ImGui's
  `TableSetBgColor` acts on the current row/cell at call time — so
  sibling order guarantees the target. Constants
  `$ImGuiTableBgTarget_RowBg0/RowBg1/CellBg`.
- `_ImGui_CreateTableHeader($sId, $sLabel)` — single-cell marker.
  Place after `TableNextRow($ImGuiTableRowFlags_Headers)` +
  `TableNextColumn`. For custom row layouts where each header differs
  (icon + text, two-line, …).
- `_ImGui_CreateTableAngledHeadersRow($sId)` — zero-arg marker, requires
  `$ImGuiTableColumnFlags_AngledHeader` on at least one column to
  render visibly (otherwise silent no-op).

**J.6 — SortMulti extension**:
`_ImGui_TableGetSortSpecsN($sId, $iMaxSpecs = 4)` → 2D array `[N][2]` =
(col, dir) in priority order for `$ImGuiTableFlags_SortMulti`
(Shift+click headers). Latched in parallel with the existing single-col
(I.3) — `_ImGui_TableGetSortSpecs` is still there for back-compat.

Test: [autoit/test_phase_j.au3](autoit/test_phase_j.au3) — 6 isolated
sections.

### Phase K — Targeted extensions

Orthogonal broadening: hover-with-flags, RadioButton group state,
InputDouble, font extras (memory + glyph ranges), clipping markers,
logging API. 20 new exports + 3 new generator widgets + 2 new
hand-written compilation units (`hover_extras`, `radio_group_extras`,
`input_double_extras`).

**K.1 — Hover-with-flags**: `IsItemHovered(flags)` can't be a free
function (it needs the context of the just-rendered item), so it
becomes a marker widget. Same pattern as `ItemTooltip` (H.2): place as
the immediate next sibling after the target.

```autoit
_ImGui_CreateButton("k1_btn", "Hover me (delayed hover)")
Local $iFlags = BitOR($ImGuiHoveredFlags_DelayShort, $ImGuiHoveredFlags_Stationary)
_ImGui_CreateIsItemHoveredEx("k1_hov", $iFlags)
; in loop:
If _ImGui_GetItemHoveredEx("k1_hov") Then ...
```

For window-level: `_ImGui_SetWindowHoveredFlags($sId, $iFlags)`
configures the mask, then `_ImGui_IsWindowHoveredEx($sId)` polls. 22
`$ImGuiHoveredFlags_*` constants exposed (Stationary,
DelayShort/Normal/None, ForTooltip,
AllowWhenBlockedBy{ActiveItem,Popup}, AllowWhenOverlapped*,
ChildWindows, RootWindow, AnyWindow, NoSharedDelay…).

**K.2 — RadioButtonGroup**: `radio_group_state` global namespace
(`std::unordered_map<std::string, int>`, group_id → current value) in
[radio_group_extras.{h,cpp}](dll/src/radio_group_extras.h). All
`RadioButtonGroupWidget` sharing the same `$sGroupId` form an exclusive
group: clicking one sets the group's value to its `$iMyValue`, the
others render unselected. State reset in `render_thread::Stop`
teardown (same pattern as `font_registry`).

```autoit
_ImGui_CreateRadioButtonGroup("r0", "Easy",   "diff", 0, True)   ; default-active
_ImGui_CreateRadioButtonGroup("r1", "Normal", "diff", 1)
_ImGui_CreateRadioButtonGroup("r2", "Hard",   "diff", 2)
; in loop:
Local $iCurrent = _ImGui_GetRadioGroupValue("diff")   ; → 0/1/2 or -1 if unset
```

**K.2 — InputDouble**: new `DoubleValueWidget` base in
[widget.h](dll/src/widget.h) + `InputDoubleWidget` in
[input_double_extras.{h,cpp}](dll/src/input_double_extras.h). Preserves the
15 digits of precision of a double (vs ~7 for InputFloat).

```autoit
_ImGui_CreateInputDouble("pi", "Pi (15 digits)", 3.141592653589793, 0.001, 0.01, "%.15f")
Local $fPi = _ImGui_GetValueDouble("pi")
```

**K.3 — Font extras**:

- `_ImGui_LoadFontEx($sPath, $fSize, $iGlyphRange)` — 9 ranges:
  `$ImGuiFontGlyphRange_Default/Vietnamese/Cyrillic/Greek/ChineseFull/`
  `ChineseSimplifiedCommon/Japanese/Korean/Thai`.
- `_ImGui_LoadFontFromMemory($pBuffer, $iSize, $fSize)` — to bundle a
  font into a user-side file (encrypted profile, vault, etc.). The
  buffer is copied internally via `IM_ALLOC` then transferred to
  `AddFontFromMemoryTTF` with ownership transferred to the atlas —
  AutoIt can free its `DllStruct` immediately after the call.
- `_ImGui_GetFontSize()` → float. Reflects the stacked font if called
  inside `_ImGui_CreatePushFont` scope, otherwise the default.

**K.4 — Clipping markers**: push/pop pair added to the generator
config ([dll/tools/generate.py](dll/tools/generate.py)).

```autoit
_ImGui_CreatePushClipRect("clip1", $fMinX, $fMinY, $fMaxX, $fMaxY, True)
_ImGui_CreateText("clipped", "This text only renders inside the rect.")
_ImGui_CreatePopClipRect("pop_clip1")
```

Push must be balanced by a Pop — ImGui asserts at end-of-frame if the
stack leaks. `$bIntersect = True` (default) intersects with the
current clip rect; `False` replaces it entirely.

**K.5 — Logging API**: 5 free functions + 1 marker.

```autoit
_ImGui_LogToClipboard(2)               ; auto-open depth 2 (descend into TreeNode/CollapsingHeader)
_ImGui_LogText("Custom prefix: ")      ; append literal text
; ... one render frame later, the logged content is in the clipboard
_ImGui_LogFinish()
```

The marker `_ImGui_CreateLogButtons($sId)` renders the inline row of
buttons (Clipboard / TTY / File / Finish) which drives the same
mechanism on the UI.

**Technical note**: `LogToFile/Clipboard/TTY` + `LogFinish` are
*deferred* — queued in pending state on the C-ABI side and drained at
the start of the host window's Render. `ImGui::LogBegin` dereferences
`g.CurrentWindow->DC.TreeDepth` which is null between frames on the
AutoIt thread (same class as the `IsMouseHoveringRect` fix in J.1).
Practical consequence: the `_ImGui_LogToClipboard()` call returns
immediately but the log is only effectively active on the next frame;
the logged widgets will be those of the next frame. `LogText` itself
is immediate.

Test: [autoit/test_phase_k.au3](autoit/test_phase_k.au3) — 5 isolated
sections (hover + RadioGroup + InputDouble + Cyrillic + memory font +
clip + logging).

### Phase L — Low-value niches

Final MVP phase: 4 sub-phases, ~7 new exports, hand-written except
SetCursorScreenPos which goes through the display generator. The scope
is explicitly "niche" — each feature covers a specific use case that
can also be composed differently on the script side.

**L.1 — Inline debug helpers**: `ShowStyleSelector` /
`ShowFontSelector` / `ShowUserGuide`. Hand-written in
[debug_inline_extras.{h,cpp}](dll/src/debug_inline_extras.h). Convenient for
a "Settings" panel: a combo that swaps between the 3 built-in themes
(Dark/Light/Classic) or between the loaded fonts, without having to
re-implement the selection logic on the AutoIt side.

```autoit
_ImGui_CreateShowStyleSelector("theme_combo", "Theme")
_ImGui_CreateShowFontSelector("font_combo",   "Font")
_ImGui_CreateShowUserGuide("guide")           ; static cheatsheet block
```

**L.2 — TextLinkOpenURL**: TextLink variant that opens a URL on click
via `ShellExecuteW`. **Security**: STRICT whitelist — only `http://`
and `https://` pass; any other scheme (`file://`, `javascript:`,
`mailto:`, custom protocols, …) is silently ignored. This avoids a
poisoned external payload triggering
`file:///C:/Windows/System32/cmd.exe` or worse. The click is ALWAYS
latched (`_ImGui_WasClicked` sees the event), regardless of whether
the URL actually opened — the script can therefore track a click even
on a refused URL.

```autoit
_ImGui_CreateTextLinkOpenURL("doc_link", "View documentation",
                              "https://github.com/ocornut/imgui/wiki")
; click → opens the browser; click on a file:// URL → no-op, but
; _ImGui_WasClicked("doc_link") returns True regardless.
```

**L.3 — SetCursorScreenPos**: display marker for positioning the ImGui
cursor in absolute screen-space coordinates (vs G.5 SetCursorPos which
is window-local). Useful for absolute overlays.

```autoit
_ImGui_CreateSetCursorScreenPos("jump", 400.0, 380.0)
_ImGui_CreateButton("anchor_btn", "Pinned at (400, 380)")
```

**L.4 — Value() helpers**: `ValueBool/Int/Float` — "prefix: value"
display with embedded format. Largely overlaps with
`_ImGui_SetText("st", "Loop: " & $i)` on the AutoIt side; exposed for
ImGui API completeness (and for scripts that prefer to keep the
typed-value semantics on the wrapper side). The 3 widgets inherit the
`BoolValueWidget`/`IntValueWidget`/`FloatValueWidget` bases, so
updates go through the polymorphic setters:

```autoit
_ImGui_CreateValueInt("loop_count", "Loop", 0)
; in loop:
_ImGui_SetValueInt("loop_count", $iIter)   ; display becomes "Loop: 42"
```

Test: [autoit/test_phase_l.au3](autoit/test_phase_l.au3) — 4 isolated
sections with a safe URL and a refused `file://` URL to demonstrate the
whitelist.

### Phase M — Remaining items (100% useful coverage)

Four sub-phases closing the last legitimate ❌ items from the previous
MISSING_API. **9 new exports + 3 hand-written widgets.** ~218 C-ABI
exports in total, 78 generated widgets + 39 hand-written.

**M.1 — Tables column queries.** Four runtime queries on the current
table: `TableGetColumnCount` (constant for the frame) +
`TableGetColumnIndex/Flags/Name` (per-cell, depend on the current
cell post-TableNextColumn). Count is latched at the top of
`TableWidget::Render` after `BeginTable` (read via a free function on
the table id). The 3 per-cell queries via a new marker
[`TableGetColumnInfoWidget`](dll/src/table_extras.h) placed as a child of
the TableWidget (sibling of the row/column markers — same J.5
`TableSetBgColorWidget` pattern). `query_column_n = -1` → uses the
current column, otherwise explicit index.

```autoit
_ImGui_CreateTable("t", 3, $iFlags, 0, 0, 0)
_ImGui_TableSetupColumn("t", "Name",  $ImGuiTableColumnFlags_WidthStretch, 2.0)
_ImGui_TableSetupColumn("t", "Value", BitOR($ImGuiTableColumnFlags_WidthStretch, $ImGuiTableColumnFlags_DefaultSort), 1.0)
_ImGui_TableSetupColumn("t", "Tag",   $ImGuiTableColumnFlags_WidthStretch, 1.0)
_ImGui_CreateTableHeadersRow("t_hdr")
_ImGui_SetParent("t_hdr", "t")
; ... rows ...
; Three markers querying explicit column indices:
_ImGui_CreateTableGetColumnInfo("info0", 0)
_ImGui_SetParent("info0", "t")
_ImGui_CreateTableGetColumnInfo("info1", 1)
_ImGui_SetParent("info1", "t")
_ImGui_CreateTableGetColumnInfo("info2", 2)
_ImGui_SetParent("info2", "t")

; in loop:
Local $iCount = _ImGui_TableGetColumnCount("t")
Local $iIdx   = _ImGui_GetTableColumnIndex("info1")    ; 1
Local $iFlg   = _ImGui_GetTableColumnFlags("info1")    ; ImGuiTableColumnFlags_*
Local $sName  = _ImGui_GetTableColumnName("info1")     ; "Value"
```

**M.2 — ImageWithBg.** `Image` variant with `bg_col` (4 floats, drawn
UNDER the texture — visible through transparent pixels) + `tint_col`
(4 floats, multiplied with the texture). Defaults `(0,0,0,0) +
(1,1,1,1)` reproduce the look of plain `Image()`. Hand-written in
[image_extras.{h,cpp}](dll/src/image_extras.h) — not through the generator
because of the 8+ float params. Reuses `texture_registry::GetSRV` +
ImageWidget's placeholder fallback (`DrawImagePlaceholder`) to handle
invalid tex_ids without crashing.

```autoit
; semi-transparent red bg, no tint:
_ImGui_CreateImageWithBg("img_red_bg", $g_iTex, 80, 80, 1.0, 0.0, 0.0, 0.5)
; transparent bg (default), multiplicative pure-red tint:
_ImGui_CreateImageWithBg("img_tint", $g_iTex, 80, 80, 0.0, 0.0, 0.0, 0.0, _
                                                       1.0, 0.2, 0.2, 1.0)
```

**M.3 — Standalone BeginTooltip/EndTooltip.** Hand-written container
[`TooltipWidget`](dll/src/tooltip_extras.h) next to `ItemTooltipWidget`
(H.2). Key difference: `ItemTooltipWidget` opens via
`BeginItemTooltip` (= iff the previous item is hovered with the
ForTooltip delay); `TooltipWidget` opens via `BeginTooltip`
(unconditional, every frame the widget is visible). Display gating is
the caller's job via `_ImGui_SetVisible($id, $bShow)` — useful for
tooltips opened on arbitrary conditions (timer, custom hit area,
programmatic trigger, …). Same `EndTooltip` discipline as
ItemTooltipWidget: End only if `BeginTooltip` returned true.

```autoit
_ImGui_CreateTooltip("custom_tip")
_ImGui_SetVisible("custom_tip", False)   ; hidden initially
_ImGui_CreateText("tip_l1", "Custom info...")
_ImGui_SetParent("tip_l1", "custom_tip")
_ImGui_CreateSeparator("tip_sep")
_ImGui_SetParent("tip_sep", "custom_tip")
_ImGui_CreateText("tip_l2", "Multi-line, no hover required.")
_ImGui_SetParent("tip_l2", "custom_tip")

; in loop:
If $g_bShowTip Then
    _ImGui_SetVisible("custom_tip", True)    ; tooltip follows the mouse
Else
    _ImGui_SetVisible("custom_tip", False)
EndIf
```

**M.4 — Mouse niches.** Two items, one as a free function the other as
a marker widget (pivot from the initial design — detailed below).

* **`IsMouseReleasedWithDelay`**: standard free function in
  `utils_extras.cpp` (J.1 pattern). True on the release frame iff the
  press is at least `$fDelay` seconds ago. Native ImGui signature =
  `(button, delay)` — no threshold (verified against the source).

  ```autoit
  ; Long-press release detector (>0.5s).
  If _ImGui_IsMouseReleasedWithDelay($ImGuiMouseButton_Left, 0.5) Then
      $g_iLongPressCount += 1
  EndIf
  ```

* **`GetMousePosOnOpeningCurrentPopup` (pivot)**: exposed via the marker
  widget [`PopupOpenMousePosWidget`](dll/src/popup_extras.h), NOT via a
  free function. Reason: the ImGui implementation reads
  `g.BeginPopupStack.Size > 0 ? g.OpenPopupStack[...].OpenMousePos : g.IO.MousePos`
  — so outside a `BeginPopup` scope, it falls back to the current
  cursor position. The AutoIt thread is ALWAYS between frames (under
  the frame lock), so `g.BeginPopupStack.Size = 0` systematically →
  the free function would return the current position, useless for
  "capture where the user clicked when they opened the popup". The
  marker must be placed as a child of a Popup / PopupModal /
  ContextPopup; its Render fires INSIDE the BeginPopup body where the
  stack is non-empty and the function returns the frozen position.

  ```autoit
  _ImGui_CreatePopup("p", "", 0)
  _ImGui_CreateText("p_l1", "Popup opened.")
  _ImGui_SetParent("p_l1", "p")
  _ImGui_CreatePopupOpenMousePos("p_capture")
  _ImGui_SetParent("p_capture", "p")
  _ImGui_CreateText("p_pos", "")
  _ImGui_SetParent("p_pos", "p")
  _ImGui_CreateButton("p_close", "Close")
  _ImGui_SetParent("p_close", "p")

  ; in loop:
  If _ImGui_WasClicked("open_btn")  Then _ImGui_OpenPopup("p")
  If _ImGui_WasClicked("p_close")   Then _ImGui_ClosePopup("p")
  Local $aPos = _ImGui_GetPopupOpenMousePos("p_capture")
  _ImGui_SetText("p_pos", "captured at (" & $aPos[0] & ", " & $aPos[1] & ")")
  ```

Test: [autoit/test_phase_m.au3](autoit/test_phase_m.au3) — 4 sections
covering the 4 sub-phases. Exit 0 clean on x64 + x86.

## Numeric vectors

Vector widgets (SliderFloat3, DragInt2, InputFloat4, ColorEdit4, etc.)
inherit from `FloatVecValueWidget<N>` / `IntVecValueWidget<N>`
templates that provide storage (`T values[N]`) + override
`Get/SetValueFloatN/IntN`. Aliases: `FloatVec2/3/4ValueWidget`,
`IntVec2/3/4ValueWidget`.

**AutoIt marshalling**: `_ImGui_GetValueFloatN($id, $iMaxN)` returns a
1D array of N floats via `DllStructCreate("float buf[N]")`.
`_ImGui_SetValueFloatN($id, $aValues)` does the reverse. The DLL-side
buffer size must match the widget's arity (no truncation); otherwise
return code 3 (type mismatch).

**ColorEdit/ColorPicker** use the same virtuals — that is,
`_ImGui_GetValueFloatN($colorId, 4)` reads the 4 RGBA components of a
ColorEdit4.

## Known limitations

- **Status**: the MVP is complete. Phases D through M are all
  delivered. The `Global Const $ImGui*` constants in the wrapper are a
  curated subset for most enums, except `ImGuiInputTextFlags_`,
  `ImGuiComboFlags_`, `ImGuiSelectableFlags_` and
  `ImGuiColorEditFlags_` (exhaustive coverage).
- **Out of scope by design** (see [MISSING_API.md](MISSING_API.md) for
  the detailed list):
  - **Drag/Drop** — callbacks during Render() incompatible with our
    thread isolation
  - **GetIO / GetStyle raw** — return non-marshallable C++ structs
  - **DragScalar / SliderScalar / InputScalar + u8/u16/u32/u64
    variants** — overlap with existing Float/Int; each ImGuiDataType
    would need its own widget storage
  - **va_list variants** (`TextV`, etc.) — pre-formatted on the AutoIt
    side
  - **GetBackgroundDrawList / GetForegroundDrawList raw** — see
    "Custom Drawing" below
  - **Multi-select [BETA]** — ImGui API still moving
  - **Shortcut / SetNextItemShortcut / SetItemKeyOwner** — BETA,
    overlaps with `HotKeySet`
  - **MemAlloc / SetAllocatorFunctions** — internal
  - **BeginChild(ImGuiID)** — overlap with `BeginChild(str_id)`
  - **DebugFlash / DebugStartItemPicker /
    DebugCheckVersionAndDataLayout** — internal
- **Hypothetical large effort**: **Custom Drawing primitives** (5-8h)
  — expose a subset of ImDrawList (`AddLine/Circle/Rect/Text/Triangle`)
  via a `DrawListWidget` that takes a marshallable primitive buffer.
  Refactor of the retained model towards "draw commands". Would enable
  custom graphs, mini-maps, HUD overlays. To tackle only if a concrete
  use case demands it.
