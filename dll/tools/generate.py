"""
generate.py â€” retained-mode binding generator for imgui-autoit-retained.

Reads imgui-1.92.8/imgui.h, applies a curated set of mapping rules per widget
category, and emits:
  - src/generated/widgets_<category>.h        â† widget class declarations
  - src/generated/widgets_<category>.cpp      â† Render() implementations
  - src/generated/dll_api_<category>.cpp      â† C-ABI exports
  - autoit/imgui_generated.au3                â† aggregated AutoIt wrappers
                                                 (one shared file, one block
                                                 appended per category)

Run: python tools/generate.py
The generated files are checked in so the build doesn't depend on Python.

Categories currently handled:
  - "clickable"     : `bool Foo(const char* label)` â†’ ClickableWidget subclass.
                      _ImGui_WasClicked dispatches via Widget::ConsumeClick.
  - "value_bool"    : `bool Foo(const char* label, bool* v)` â†’ BoolValueWidget
                      subclass. _ImGui_GetValueBool / _ImGui_SetValueBool /
                      _ImGui_HasChanged dispatch via Widget virtuals.
  - "value_numeric" : SliderFloat/Int, DragFloat/Int, InputFloat/Int.
                      Three shapes Ã— two types. FloatValueWidget /
                      IntValueWidget mixins. _ImGui_GetValueFloat/Int /
                      _ImGui_SetValueFloat/Int + _ImGui_HasChanged.
  - "display"       : Stateless markers in the render stream (Separator,
                      SameLine, NewLine, Spacing, Bullet, Indent, Unindent).
                      No new generic exports â€” each is a Widget subclass whose
                      Render() makes a single ImGui call.
  - "config"        : Style stack â€” PushStyleColor/Pop, PushStyleVar(Float|Vec2)
                      /Pop. Same model as `display` (stateless markers paired
                      in the render stream). Global config setters (ConfigFlags
                      etc.) are NOT in the generator â€” they live in dll_api.cpp.
  - "container"     : Nested containers â€” Child, TabBar, TabItem,
                      CollapsingHeader, TreeNode, Group. These own children
                      via Widget::children; Render() walks them between
                      Begin/End. Three render shapes (always_pair,
                      conditional_pair, conditional_no_end).

Adding a new category = new @dataclass + new list + new emit_* trio + a line
in main(). The pipeline is deliberately explicit per category â€” each one
writes ITS OWN files, and only the AutoIt wrapper is aggregated.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT      = Path(__file__).resolve().parent.parent.parent  # imgui-autoit-retained/ (script lives in dll/tools/)
IMGUI_H   = ROOT / "dll" / "imgui-docking" / "imgui.h"
SRC_GEN   = ROOT / "dll" / "src" / "generated"
WRAPPER   = ROOT / "autoit" / "imgui_generated.au3"


# -----------------------------------------------------------------------------
# imgui.h parser
# -----------------------------------------------------------------------------

@dataclass
class Decl:
    return_type: str
    name: str
    params: str  # raw params string (may include defaults, refs, etc.)


# Matches up to the opening "(" of an IMGUI_API declaration. We don't try to
# parse the parameter list here â€” it can contain nested parens via default
# values like `ImVec2(0, 0)` which break a naive `[^)]*` capture. For the MVP
# we only need the function name to verify existence; future categories can
# walk the parameter list with proper paren-balancing.
_DECL_RE = re.compile(
    r"^\s*IMGUI_API\s+([\w\s\*&:<>,]+?)\s+(\w+)\s*\(",
    re.MULTILINE,
)


def parse_imgui_h(path: Path) -> list[Decl]:
    """Best-effort scan of IMGUI_API declarations. The MVP only needs the
    function NAME (and return type) â€” we use this as a sanity check that
    the function we intend to wrap still exists in this ImGui version.
    """
    text = path.read_text(encoding="utf-8")
    out: list[Decl] = []
    for m in _DECL_RE.finditer(text):
        ret, name = m.group(1).strip(), m.group(2).strip()
        # Filter junk: the regex can match macro-like fragments. A valid C++
        # function name doesn't start with a digit and must be a real word.
        if not name or not name[0].isalpha() and name[0] != "_":
            continue
        out.append(Decl(ret, name, ""))
    return out


def find_decl(decls: list[Decl], name: str) -> Decl | None:
    """Find a declaration by ImGui function name. Overload disambiguation
    will come later when we walk the parameter list."""
    for d in decls:
        if d.name == name:
            return d
    return None


# Shared parameter descriptor â€” used by display, config, container and the
# clickable category (since the ArrowButton/InvisibleButton/RadioButton
# variants take extra params beyond label). Defined here at module scope so
# every category can reference it before its own section runs.
@dataclass
class WParam:
    cpp_name:    str   # field name on the widget struct
    cpp_type:    str   # C++ field type
    cpp_default: str   # C++ field default
    au3_var:     str   # AutoIt parameter name (e.g. "$fW")
    au3_type:    str   # DllCall type ("float", "int", ...)
    au3_default: str   # AutoIt default value


# =============================================================================
# AutoIt #FUNCTION# docstring helpers
# =============================================================================
#
# Every generated wrapper carries a standard UDF-style header so users see
# documentation in SciTE's calltip, AutoIt3Wrapper code completion, etc.
# Style chosen: short and factual (one-line description, compact parameters).

# Standard parameter descriptions reused across most Create* wrappers. The key
# is the AutoIt variable name (with `$` prefix) ; lookup falls back to a
# generic description when the param isn't listed.
_PARAM_DESC = {
    "$sId":          "Stable widget identifier (must be unique in the tree)",
    "$sLabel":       "Displayed label (empty = falls back to $sId)",
    "$sText":        "Text content (UTF-8)",
    "$sFormat":      "printf-style format string",
    "$bDefault":     "Initial boolean state (False = unchecked)",
    "$iDefault":     "Initial integer value",
    "$fDefault":     "Initial float value",
    "$fMin":         "Minimum value of the range",
    "$fMax":         "Maximum value of the range",
    "$iMin":         "Minimum integer value",
    "$iMax":         "Maximum integer value",
    "$fSpeed":       "Drag speed (units per pixel of mouse movement)",
    "$fStep":        "Step value applied by the +/- buttons",
    "$fStepFast":    "Fast-step value applied with Ctrl+click",
    "$iStep":        "Integer step value applied by the +/- buttons",
    "$iStepFast":    "Fast integer step applied with Ctrl+click",
    "$iFlags":       "Bitmask of widget-specific flags ($ImGuiXxxFlags_*)",
    "$iDir":         "Arrow direction (0=Left, 1=Right, 2=Up, 3=Down)",
    "$fW":           "Width in pixels (0 = auto)",
    "$fH":           "Height in pixels (0 = auto)",
    "$fOffsetX":     "Horizontal offset in pixels (0 = use default spacing)",
    "$fSpacing":     "Custom spacing in pixels (-1.0 = use default)",
    "$fIndentW":     "Indent width in pixels (0 = use ImGui default)",
    "$fWidth":       "Item width (negative = right-aligned, 0 = auto)",
    "$iOffset":      "Focus offset (0 = next item)",
    "$iOption":      "Item flag option ($ImGuiItemFlags_*)",
    "$iEnabled":     "1 = enable the flag, 0 = disable",
    "$bIntersect":   "True = intersect with current clip rect, False = replace",
    "$iIdx":         "Style enum index ($ImGuiCol_* or $ImGuiStyleVar_*)",
    "$iCol":         "Style color enum index ($ImGuiCol_*)",
    "$iVar":         "Style variable enum index ($ImGuiStyleVar_*)",
    "$fValue":       "Float value to push onto the style stack",
    "$fValueX":      "X-axis float value",
    "$fValueY":      "Y-axis float value",
    "$iCount":       "Number of stack entries to pop",
    "$fX":           "X coordinate in pixels",
    "$fY":           "Y coordinate in pixels",
    "$fScreenX":     "X coordinate in screen-space pixels",
    "$fScreenY":     "Y coordinate in screen-space pixels",
    "$fMinX":        "Minimum X coordinate (screen-space)",
    "$fMinY":        "Minimum Y coordinate (screen-space)",
    "$fMaxX":        "Maximum X coordinate (screen-space)",
    "$fMaxY":        "Maximum Y coordinate (screen-space)",
    "$fWrapPos":     "Wrap position in pixels (<0 = no wrap, 0 = window edge, >0 = local x)",
    "$bEnabled":     "True = enable, False = disable",
    "$fR":           "Red component [0.0 - 1.0]",
    "$fG":           "Green component [0.0 - 1.0]",
    "$fB":           "Blue component [0.0 - 1.0]",
    "$fA":           "Alpha component [0.0 - 1.0]",
    "$sValue":       "Displayed value (formatted on the right)",
    "$sKey":         "Displayed key/label (left side)",
    "$bBorder":      "True = draw a border around the child region",
    "$fMinRowH":     "Minimum row height in pixels (0 = auto)",
    "$fClipMinX":    "Clip rect minimum X (screen-space)",
    "$fClipMinY":    "Clip rect minimum Y (screen-space)",
    "$fClipMaxX":    "Clip rect maximum X (screen-space)",
    "$fClipMaxY":    "Clip rect maximum Y (screen-space)",
}


def _au3_param_desc(au3_var: str) -> str:
    """Return a human description for a parameter name. Falls back to a
    generic '<type> parameter' label when the variable is unknown."""
    if au3_var in _PARAM_DESC:
        return _PARAM_DESC[au3_var]
    # Heuristic fallback based on the hungarian prefix.
    pfx = au3_var[1:2] if len(au3_var) >= 2 else ""
    return {
        "s": "String parameter",
        "i": "Integer parameter",
        "f": "Float parameter",
        "b": "Boolean parameter",
        "a": "Array parameter",
        "p": "Pointer parameter",
        "h": "Handle parameter",
    }.get(pfx, "Parameter")


# Standard return-value text used by most Create* wrappers.
_RETURN_CREATE = "Success - True. Failure - False, @error = 1 (DLL not loaded), 2 (DllCall failed)"


def _au3_func_header(name: str,
                     description: str,
                     syntax: str,
                     params,            # list of (au3_var, description_override_or_None)
                     returns: str = _RETURN_CREATE,
                     information: str = "") -> str:
    """Build a standard AutoIt UDF-style #FUNCTION# documentation block.

    `params` is a list of (au3_var_name, optional_description_override). When
    the override is None / "", the description is looked up in _PARAM_DESC.
    Pass an empty list (or None) for "Parameters ....: None".
    """
    bar_open  = "; #FUNCTION# " + "=" * 116
    bar_close = "; " + "=" * 127
    lines = [bar_open]
    lines.append(f"; Name...........: {name}")
    lines.append(f"; Description ...: {description}")
    lines.append(f"; Syntax.........: {syntax}")
    if not params:
        lines.append("; Parameters ....: None")
    else:
        # Align parameter names to a fixed column width for readability.
        max_name = max(len(v) for v, _ in params)
        name_w = max(max_name, 12)
        first_prefix = "; Parameters ....: "
        cont_prefix  = ";                  "
        for i, (var, override) in enumerate(params):
            desc = override if override else _au3_param_desc(var)
            prefix = first_prefix if i == 0 else cont_prefix
            lines.append(f"{prefix}{var:<{name_w}} - {desc}")
    lines.append(f"; Return values .: {returns}")
    if information:
        # Information may have multiple lines split by \n.
        info_lines = information.split("\n")
        lines.append(f"; Information ...: {info_lines[0]}")
        for il in info_lines[1:]:
            lines.append(f";                  {il}")
    lines.append(bar_close)
    return "\n".join(lines) + "\n"


# =============================================================================
# Category: "clickable"
# =============================================================================

@dataclass
class Clickable:
    """Family: button-like widgets that return bool on click. Retained mapping :
    ClickableWidget subclass with Render() calling the appropriate ImGui
    function and latching `clicked`. _ImGui_WasClicked dispatches generically
    via Widget::ConsumeClick.

    The simple form (Button/SmallButton/MenuItem) takes just the label. The
    extended form (ArrowButton/InvisibleButton/RadioButton) takes extra
    constant-at-create-time params stored on the widget struct, plugged into
    the Render() call via `render_call`.
    """
    imgui_name:    str
    autoit_create: str
    # Optional extra fields stored on the widget. Empty for plain Button-style.
    params:        list = field(default_factory=list)   # list[WParam]
    # The exact body of the ImGui call inside `if (...)`. References `shown`
    # (the label C string) and each param by its cpp_name. Empty string means
    # "default" â†’ ImGui::<imgui_name>(shown).
    render_call:   str  = ""


# Constant params reused below.
_CP_ARROW_DIR     = WParam("dir",    "int",   "0",    "$iDir",    "int",   "0")
_CP_INVIS_W       = WParam("w",      "float", "0.0f", "$fW",      "float", "0.0")
_CP_INVIS_H       = WParam("h",      "float", "0.0f", "$fH",      "float", "0.0")
_CP_RADIO_ACTIVE  = WParam("active", "int",   "0",    "$bActive", "int",   "0")


CLICKABLE: list[Clickable] = [
    Clickable("Button",          "ImGui_CreateButton",      [],
              "ImGui::Button(shown)"),
    Clickable("SmallButton",     "ImGui_CreateSmallButton", [],
              "ImGui::SmallButton(shown)"),
    # MenuItem was here in Phase A but Phase D.5 added shortcut + persistent
    # selected state (toggleable like a Checkbox-in-a-menu), which doesn't fit
    # the plain "clickable label" shape. Now hand-written in src/bool_extras.cpp
    # as MenuItemWidget : BoolValueWidget + clicked flag (like Selectable).
    # ArrowButton(label, ImGuiDir) â€” square button with a directional triangle.
    # `dir` is ImGuiDir_ (0=Left, 1=Right, 2=Up, 3=Down). Label is hidden;
    # it's used only as the ImGui ID.
    Clickable("ArrowButton",     "ImGui_CreateArrowButton",
              [_CP_ARROW_DIR],
              "ImGui::ArrowButton(shown, (ImGuiDir)dir)"),
    # InvisibleButton(label, size) â€” clickable hit-rect with no visual. Useful
    # for custom-rendered controls or hit zones on top of other widgets.
    Clickable("InvisibleButton", "ImGui_CreateInvisibleButton",
              [_CP_INVIS_W, _CP_INVIS_H],
              "ImGui::InvisibleButton(shown, ImVec2(w, h))"),
    # NOTE: RadioButton(label, bool active) is hand-written (radio_widget.cpp)
    # because it needs Get/SetValueBool overrides that the generator doesn't
    # synthesize. See src/radio_widget.cpp.
    # G.1 â€” TextLink(label) returns bool when clicked. Visual hyperlink â€” rendered
    # as underlined text in ImGuiCol_TextLink, click latches via ClickableWidget.
    # TextLinkOpenURL skipped on purpose (security: URL validation + ShellExecute
    # surface).
    Clickable("TextLink",        "ImGui_CreateTextLink",      [],
              "ImGui::TextLink(shown)"),
]


CLICKABLE_HEADER_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
// Re-run the script to regenerate after changing CATEGORIES.
#pragma once
#include "widget.h"

"""

CLICKABLE_IMPL_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include "generated/widgets_clickable.h"
#include "imgui.h"

"""

CLICKABLE_API_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include <Windows.h>
#include <memory>
#include <string>
#include "widget_tree.h"
#include "utf.h"
#include "generated/widgets_clickable.h"

#define API_EXPORT extern "C" __declspec(dllexport)

"""


def _clickable_struct(c: Clickable) -> str:
    fields = "".join(f"    {p.cpp_type} {p.cpp_name} = {p.cpp_default};\n" for p in c.params)
    call = c.render_call or f"ImGui::{c.imgui_name}(shown)"
    return (
        f"// Wraps {call.split('(')[0]} â€” bool, latches click in ConsumeClick().\n"
        f"struct {c.imgui_name}Widget : ClickableWidget {{\n"
        f"{fields}"
        f"    void Render() override;\n"
        f"}};\n\n"
    )


def _clickable_render(c: Clickable) -> str:
    call = c.render_call or f"ImGui::{c.imgui_name}(shown)"
    return (
        f"void {c.imgui_name}Widget::Render()\n"
        f"{{\n"
        f"    if (!visible) return;\n"
        f"    if (!enabled) ImGui::BeginDisabled();\n"
        f"    // PushID with the user's stable key so duplicate labels remain distinct.\n"
        f"    ImGui::PushID(id.c_str());\n"
        f"    const char* shown = label.empty() ? id.c_str() : label.c_str();\n"
        f"    if ({call}) {{\n"
        f"        clicked = true;\n"
        f"    }}\n"
        f"    ImGui::PopID();\n"
        f"    if (!enabled) ImGui::EndDisabled();\n"
        f"}}\n\n"
    )


def _clickable_api(c: Clickable) -> str:
    sig_params = "".join(f", {p.cpp_type} {p.cpp_name}" for p in c.params)
    # NB: local is named `widget` (not `w`) to avoid shadowing the `float w`
    # parameter on InvisibleButton / any future clickable with a `w`/`h`/etc.
    # param. Same rationale as the container generator.
    assigns    = "".join(f"    widget->{p.cpp_name} = {p.cpp_name};\n" for p in c.params)
    return (
        f"API_EXPORT int __cdecl {c.autoit_create}(const wchar_t* id, const wchar_t* label{sig_params})\n"
        f"{{\n"
        f"    if (!id || !*id) return 1;\n"
        f"    std::string uid  = WideToUtf8(id);\n"
        f"    std::string ulbl = WideToUtf8(label ? label : L\"\");\n"
        f"    if (uid.empty()) return 1;\n"
        f"    auto widget = std::make_unique<{c.imgui_name}Widget>();\n"
        f"    widget->id    = uid;\n"
        f"    widget->label = ulbl;\n"
        f"{assigns}"
        f"    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);\n"
        f"    return g_tree.Add(std::move(widget)) ? 0 : 2;\n"
        f"}}\n\n"
    )


_CLICKABLE_DESC = {
    "ImGui_CreateButton":          "Create a Button widget (basic rectangular clickable)",
    "ImGui_CreateSmallButton":     "Create a SmallButton widget (compact, no frame padding)",
    "ImGui_CreateArrowButton":     "Create an ArrowButton widget (directional arrow glyph)",
    "ImGui_CreateInvisibleButton": "Create an InvisibleButton (clickable hit area, no rendering)",
    "ImGui_CreateTextLink":        "Create a TextLink widget (clickable underlined text)",
}


def _clickable_au3(c: Clickable) -> str:
    au_params = "".join(f", {p.au3_var} = {p.au3_default}" for p in c.params)
    call_args = "".join(f', "{p.au3_type}", {p.au3_var}' for p in c.params)
    desc = _CLICKABLE_DESC.get(c.autoit_create, f"Create a {c.imgui_name} widget")
    sig_params = "".join(f", {p.au3_var} = {p.au3_default}" for p in c.params)
    syntax = f'_{c.autoit_create}($sId[, $sLabel = ""{sig_params}])'
    doc_params = [("$sId", None), ("$sLabel", None)] + [(p.au3_var, None) for p in c.params]
    header = _au3_func_header(
        name=f"_{c.autoit_create}",
        description=desc,
        syntax=syntax,
        params=doc_params,
        returns="Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)",
        information="Poll user clicks with _ImGui_WasClicked($sId).",
    )
    return (
        header +
        f'Func _{c.autoit_create}($sId, $sLabel = ""{au_params})\n'
        f'    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)\n'
        f'    If $sLabel = "" Then $sLabel = $sId\n'
        f'    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{c.autoit_create}", "wstr", $sId, "wstr", $sLabel{call_args})\n'
        f'    If @error Then Return SetError(2, @error, False)\n'
        f'    Return ($aRet[0] = 0)\n'
        f'EndFunc\n\n'
    )


def emit_clickable_header(items: list[Clickable]) -> str:
    return CLICKABLE_HEADER_PROLOG + "".join(_clickable_struct(c) for c in items)


def emit_clickable_impl(items: list[Clickable]) -> str:
    return CLICKABLE_IMPL_PROLOG + "".join(_clickable_render(c) for c in items)


def emit_clickable_api(items: list[Clickable]) -> str:
    return CLICKABLE_API_PROLOG + "".join(_clickable_api(c) for c in items)


def emit_clickable_au3(items: list[Clickable]) -> str:
    return "; --- clickable ---\n\n" + "".join(_clickable_au3(c) for c in items)


# =============================================================================
# Category: "value_bool"
# =============================================================================

@dataclass
class ValueBool:
    """Family: `bool ImGui::Foo(const char* label, bool* v)`. Returns true
    when the user toggled. Retained mapping: BoolValueWidget subclass storing
    `value` + `changed`. _ImGui_GetValueBool / _ImGui_SetValueBool /
    _ImGui_HasChanged dispatch generically via Widget virtuals.
    """
    imgui_name: str        # e.g. "Checkbox"
    autoit_create: str     # e.g. "ImGui_CreateCheckbox"


VALUE_BOOL: list[ValueBool] = [
    ValueBool("Checkbox", "ImGui_CreateCheckbox"),
    # Future: CheckboxFlags (overloads), RadioButton (the bool* variant), â€¦
]


VALUE_BOOL_HEADER_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#pragma once
#include "widget.h"

"""

VALUE_BOOL_HEADER_TMPL = """\
// Wraps ImGui::{name}(label, bool*) â€” toggles BoolValueWidget::value, latches
// `changed` on user interaction.
struct {name}Widget : BoolValueWidget {{
    void Render() override;
}};

"""

VALUE_BOOL_IMPL_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include "generated/widgets_value_bool.h"
#include "imgui.h"

"""

VALUE_BOOL_RENDER_TMPL = """\
void {name}Widget::Render()
{{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    if (ImGui::{name}(shown, &value)) {{
        changed = true;
    }}
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}}

"""

VALUE_BOOL_API_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include <Windows.h>
#include <memory>
#include <string>
#include "widget_tree.h"
#include "utf.h"
#include "generated/widgets_value_bool.h"

#define API_EXPORT extern "C" __declspec(dllexport)

"""

VALUE_BOOL_API_TMPL = """\
API_EXPORT int __cdecl {export}(const wchar_t* id, const wchar_t* label, int default_value)
{{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<{name}Widget>();
    w->id    = uid;
    w->label = ulbl;
    w->value = (default_value != 0);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}}

"""

AU3_VALUE_BOOL_TMPL = """\
{header}Func _{export}($sId, $sLabel = "", $bDefault = False)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $iDef = $bDefault ? 1 : 0
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{export}", "wstr", $sId, "wstr", $sLabel, "int", $iDef)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

"""


def emit_value_bool_header(items: list[ValueBool]) -> str:
    out = [VALUE_BOOL_HEADER_PROLOG]
    for c in items:
        out.append(VALUE_BOOL_HEADER_TMPL.format(name=c.imgui_name))
    return "".join(out)


def emit_value_bool_impl(items: list[ValueBool]) -> str:
    out = [VALUE_BOOL_IMPL_PROLOG]
    for c in items:
        out.append(VALUE_BOOL_RENDER_TMPL.format(name=c.imgui_name))
    return "".join(out)


def emit_value_bool_api(items: list[ValueBool]) -> str:
    out = [VALUE_BOOL_API_PROLOG]
    for c in items:
        out.append(VALUE_BOOL_API_TMPL.format(name=c.imgui_name, export=c.autoit_create))
    return "".join(out)


def _value_bool_au3_header(export: str) -> str:
    desc = "Create a Checkbox widget (toggleable boolean state)"
    syntax = f'_{export}($sId[, $sLabel = "", $bDefault = False])'
    params = [("$sId", None), ("$sLabel", None), ("$bDefault", None)]
    return _au3_func_header(
        name=f"_{export}",
        description=desc,
        syntax=syntax,
        params=params,
        returns="Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)",
        information="Read/write the value via _ImGui_GetValueBool / _ImGui_SetValueBool.\nUser toggles are reported by _ImGui_HasChanged ; programmatic writes never latch.",
    )


def emit_value_bool_au3(items: list[ValueBool]) -> str:
    out = ["; --- value_bool ---\n\n"]
    for c in items:
        header = _value_bool_au3_header(c.autoit_create)
        out.append(AU3_VALUE_BOOL_TMPL.format(export=c.autoit_create, header=header))
    return "".join(out)


# =============================================================================
# Category: "value_numeric"
# =============================================================================
#
# Three shapes (Slider, Drag, Input) Ã— two scalar types (float, int) = six
# widgets. Each shape stores different "constant" parameters:
#   - Slider: v_min, v_max, format
#   - Drag:   v_speed (always float), v_min, v_max, format
#   - Input:  step, step_fast, format (InputInt has no format)
#
# All inherit FloatValueWidget or IntValueWidget so the generic getters/setters
# (ImGui_GetValueFloat/Int, â€¦) and ImGui_HasChanged work uniformly.

@dataclass
class Slider:
    imgui_name: str       # "SliderFloat", "SliderInt", "SliderFloat3", ...
    autoit_create: str    # "ImGui_CreateSliderFloat3", ...
    value_type: str       # "float" | "int"
    n: int = 1            # 1 = scalar, 2/3/4 = vector

@dataclass
class Drag:
    imgui_name: str
    autoit_create: str
    value_type: str
    n: int = 1

@dataclass
class Input:
    imgui_name: str
    autoit_create: str
    value_type: str       # "float" | "int" (int variant has no format)
    n: int = 1


SLIDER: list[Slider] = [
    Slider("SliderFloat",  "ImGui_CreateSliderFloat",  "float", 1),
    Slider("SliderInt",    "ImGui_CreateSliderInt",    "int",   1),
    Slider("SliderFloat2", "ImGui_CreateSliderFloat2", "float", 2),
    Slider("SliderFloat3", "ImGui_CreateSliderFloat3", "float", 3),
    Slider("SliderFloat4", "ImGui_CreateSliderFloat4", "float", 4),
    Slider("SliderInt2",   "ImGui_CreateSliderInt2",   "int",   2),
    Slider("SliderInt3",   "ImGui_CreateSliderInt3",   "int",   3),
    Slider("SliderInt4",   "ImGui_CreateSliderInt4",   "int",   4),
]

DRAG: list[Drag] = [
    Drag("DragFloat",  "ImGui_CreateDragFloat",  "float", 1),
    Drag("DragInt",    "ImGui_CreateDragInt",    "int",   1),
    Drag("DragFloat2", "ImGui_CreateDragFloat2", "float", 2),
    Drag("DragFloat3", "ImGui_CreateDragFloat3", "float", 3),
    Drag("DragFloat4", "ImGui_CreateDragFloat4", "float", 4),
    Drag("DragInt2",   "ImGui_CreateDragInt2",   "int",   2),
    Drag("DragInt3",   "ImGui_CreateDragInt3",   "int",   3),
    Drag("DragInt4",   "ImGui_CreateDragInt4",   "int",   4),
]

INPUT: list[Input] = [
    Input("InputFloat",  "ImGui_CreateInputFloat",  "float", 1),
    Input("InputInt",    "ImGui_CreateInputInt",    "int",   1),
    Input("InputFloat2", "ImGui_CreateInputFloat2", "float", 2),
    Input("InputFloat3", "ImGui_CreateInputFloat3", "float", 3),
    Input("InputFloat4", "ImGui_CreateInputFloat4", "float", 4),
    Input("InputInt2",   "ImGui_CreateInputInt2",   "int",   2),
    Input("InputInt3",   "ImGui_CreateInputInt3",   "int",   3),
    Input("InputInt4",   "ImGui_CreateInputInt4",   "int",   4),
]


def _base_for(value_type: str, n: int = 1) -> str:
    """Base widget class for a (value_type, n) combination.
    n=1 â†’ scalar value widget ; n>=2 â†’ vector mixin.
    """
    if n == 1:
        return "FloatValueWidget" if value_type == "float" else "IntValueWidget"
    prefix = "FloatVec" if value_type == "float" else "IntVec"
    return f"{prefix}{n}ValueWidget"


VALUE_NUMERIC_HEADER_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#pragma once
#include "widget.h"
#include <string>

"""

SLIDER_HEADER_TMPL = """\
// Wraps ImGui::{name}(label, &value, v_min, v_max, format).
struct {name}Widget : {base} {{
    {vt} v_min = 0, v_max = 0;
    std::string format;
    void Render() override;
}};

"""

DRAG_HEADER_TMPL = """\
// Wraps ImGui::{name}(label, &value, v_speed, v_min, v_max, format).
struct {name}Widget : {base} {{
    float v_speed = 1.0f;
    {vt} v_min = 0, v_max = 0;
    std::string format;
    void Render() override;
}};

"""

# Input templates are appended directly (no .format() call) â€” use single braces.
INPUT_FLOAT_HEADER_TMPL = """\
// Wraps ImGui::InputFloat(label, &value, step, step_fast, format).
struct InputFloatWidget : FloatValueWidget {
    float step = 0.0f, step_fast = 0.0f;
    std::string format;
    void Render() override;
};

"""

INPUT_INT_HEADER_TMPL = """\
// Wraps ImGui::InputInt(label, &value, step, step_fast). No format param.
struct InputIntWidget : IntValueWidget {
    int step = 1, step_fast = 100;
    void Render() override;
};

"""


VALUE_NUMERIC_IMPL_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include "generated/widgets_value_numeric.h"
#include "imgui.h"

"""

SLIDER_RENDER_TMPL = """\
void {name}Widget::Render()
{{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    if (ImGui::{name}(shown, &value, v_min, v_max, format.c_str())) {{
        changed = true;
    }}
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}}

"""

DRAG_RENDER_TMPL = """\
void {name}Widget::Render()
{{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    if (ImGui::{name}(shown, &value, v_speed, v_min, v_max, format.c_str())) {{
        changed = true;
    }}
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}}

"""

INPUT_FLOAT_RENDER_TMPL = """\
void InputFloatWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    if (ImGui::InputFloat(shown, &value, step, step_fast, format.c_str())) {
        changed = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

"""

INPUT_INT_RENDER_TMPL = """\
void InputIntWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    if (ImGui::InputInt(shown, &value, step, step_fast)) {
        changed = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

"""


VALUE_NUMERIC_API_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include <Windows.h>
#include <memory>
#include <string>
#include "widget_tree.h"
#include "utf.h"
#include "generated/widgets_value_numeric.h"

#define API_EXPORT extern "C" __declspec(dllexport)

"""

SLIDER_API_TMPL = """\
API_EXPORT int __cdecl {export}(const wchar_t* id, const wchar_t* label,
                                {vt} v_min, {vt} v_max, {vt} default_value,
                                const wchar_t* format)
{{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    std::string ufmt = WideToUtf8(format && *format ? format : L"{default_fmt}");
    if (uid.empty()) return 1;
    auto w = std::make_unique<{name}Widget>();
    w->id = uid; w->label = ulbl;
    w->v_min = v_min; w->v_max = v_max; w->value = default_value;
    w->format = ufmt;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}}

"""

DRAG_API_TMPL = """\
API_EXPORT int __cdecl {export}(const wchar_t* id, const wchar_t* label,
                                float v_speed, {vt} v_min, {vt} v_max,
                                {vt} default_value, const wchar_t* format)
{{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    std::string ufmt = WideToUtf8(format && *format ? format : L"{default_fmt}");
    if (uid.empty()) return 1;
    auto w = std::make_unique<{name}Widget>();
    w->id = uid; w->label = ulbl;
    w->v_speed = v_speed;
    w->v_min = v_min; w->v_max = v_max; w->value = default_value;
    w->format = ufmt;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}}

"""

INPUT_FLOAT_API_TMPL = """\
API_EXPORT int __cdecl ImGui_CreateInputFloat(const wchar_t* id, const wchar_t* label,
                                              float default_value, float step,
                                              float step_fast, const wchar_t* format)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    std::string ufmt = WideToUtf8(format && *format ? format : L"%.3f");
    if (uid.empty()) return 1;
    auto w = std::make_unique<InputFloatWidget>();
    w->id = uid; w->label = ulbl;
    w->value = default_value;
    w->step = step; w->step_fast = step_fast;
    w->format = ufmt;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

"""

INPUT_INT_API_TMPL = """\
API_EXPORT int __cdecl ImGui_CreateInputInt(const wchar_t* id, const wchar_t* label,
                                            int default_value, int step, int step_fast)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto w = std::make_unique<InputIntWidget>();
    w->id = uid; w->label = ulbl;
    w->value = default_value;
    w->step = step; w->step_fast = step_fast;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

"""

# AutoIt wrappers â€” DllCall types match the C-ABI signatures above.
AU3_SLIDER_FLOAT_TMPL = """\
{header}Func _{export}($sId, $sLabel = "", $fMin = 0.0, $fMax = 1.0, $fDefault = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{export}", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fMin, "float", $fMax, "float", $fDefault, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

"""

AU3_SLIDER_INT_TMPL = """\
{header}Func _{export}($sId, $sLabel = "", $iMin = 0, $iMax = 100, $iDefault = 0, $sFormat = "%d")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{export}", _
        "wstr", $sId, "wstr", $sLabel, _
        "int", $iMin, "int", $iMax, "int", $iDefault, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

"""

AU3_DRAG_FLOAT_TMPL = """\
{header}Func _{export}($sId, $sLabel = "", $fSpeed = 1.0, $fMin = 0.0, $fMax = 0.0, $fDefault = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{export}", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fSpeed, "float", $fMin, "float", $fMax, "float", $fDefault, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

"""

AU3_DRAG_INT_TMPL = """\
{header}Func _{export}($sId, $sLabel = "", $fSpeed = 1.0, $iMin = 0, $iMax = 0, $iDefault = 0, $sFormat = "%d")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{export}", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fSpeed, "int", $iMin, "int", $iMax, "int", $iDefault, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

"""

AU3_INPUT_FLOAT_TMPL = """\
{header}Func _ImGui_CreateInputFloat($sId, $sLabel = "", $fDefault = 0.0, $fStep = 0.0, $fStepFast = 0.0, $sFormat = "%.3f")
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInputFloat", _
        "wstr", $sId, "wstr", $sLabel, _
        "float", $fDefault, "float", $fStep, "float", $fStepFast, _
        "wstr", $sFormat)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

"""

AU3_INPUT_INT_TMPL = """\
{header}Func _ImGui_CreateInputInt($sId, $sLabel = "", $iDefault = 0, $iStep = 1, $iStepFast = 100)
    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)
    If $sLabel = "" Then $sLabel = $sId
    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "ImGui_CreateInputInt", _
        "wstr", $sId, "wstr", $sLabel, _
        "int", $iDefault, "int", $iStep, "int", $iStepFast)
    If @error Then Return SetError(2, @error, False)
    Return ($aRet[0] = 0)
EndFunc

"""


# --- Vector variants (n>=2) ---------------------------------------------------
# For SliderFloat2/3/4, DragInt3, InputFloat4, etc. The shape parameters
# (v_min/v_max for slider, v_speed/v_min/v_max for drag, step/step_fast for
# Input scalar) carry over from the scalar templates, but each VECTOR widget
# stores N defaults instead of one and Render() passes `values` (array) into
# the matching ImGui function instead of `&value`.

def _slider_struct_vec(s: Slider) -> str:
    return (
        f"// Wraps ImGui::{s.imgui_name}(label, {s.value_type}[{s.n}], v_min, v_max, format).\n"
        f"struct {s.imgui_name}Widget : {_base_for(s.value_type, s.n)} {{\n"
        f"    {s.value_type} v_min = 0, v_max = 0;\n"
        f"    std::string format;\n"
        f"    void Render() override;\n"
        f"}};\n\n"
    )

def _slider_render_vec(s: Slider) -> str:
    return (
        f"void {s.imgui_name}Widget::Render()\n"
        f"{{\n"
        f"    if (!visible) return;\n"
        f"    if (!enabled) ImGui::BeginDisabled();\n"
        f"    ImGui::PushID(id.c_str());\n"
        f"    const char* shown = label.empty() ? id.c_str() : label.c_str();\n"
        f"    if (ImGui::{s.imgui_name}(shown, values, v_min, v_max, format.c_str())) {{\n"
        f"        changed = true;\n"
        f"    }}\n"
        f"    ImGui::PopID();\n"
        f"    if (!enabled) ImGui::EndDisabled();\n"
        f"}}\n\n"
    )

def _slider_api_vec(s: Slider) -> str:
    fmt        = "%.3f" if s.value_type == "float" else "%d"
    default_sig    = ", ".join(f"{s.value_type} default_{i}" for i in range(s.n))
    default_assign = "".join(f"    w->values[{i}] = default_{i};\n" for i in range(s.n))
    return (
        f"API_EXPORT int __cdecl {s.autoit_create}(const wchar_t* id, const wchar_t* label,\n"
        f"                                {s.value_type} v_min, {s.value_type} v_max,\n"
        f"                                {default_sig},\n"
        f"                                const wchar_t* format)\n"
        f"{{\n"
        f"    if (!id || !*id) return 1;\n"
        f"    std::string uid  = WideToUtf8(id);\n"
        f"    std::string ulbl = WideToUtf8(label ? label : L\"\");\n"
        f"    std::string ufmt = WideToUtf8(format && *format ? format : L\"{fmt}\");\n"
        f"    if (uid.empty()) return 1;\n"
        f"    auto w = std::make_unique<{s.imgui_name}Widget>();\n"
        f"    w->id = uid; w->label = ulbl;\n"
        f"    w->v_min = v_min; w->v_max = v_max;\n"
        f"{default_assign}"
        f"    w->format = ufmt;\n"
        f"    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);\n"
        f"    return g_tree.Add(std::move(w)) ? 0 : 2;\n"
        f"}}\n\n"
    )

def _drag_struct_vec(d: Drag) -> str:
    return (
        f"// Wraps ImGui::{d.imgui_name}(label, {d.value_type}[{d.n}], v_speed, v_min, v_max, format).\n"
        f"struct {d.imgui_name}Widget : {_base_for(d.value_type, d.n)} {{\n"
        f"    float v_speed = 1.0f;\n"
        f"    {d.value_type} v_min = 0, v_max = 0;\n"
        f"    std::string format;\n"
        f"    void Render() override;\n"
        f"}};\n\n"
    )

def _drag_render_vec(d: Drag) -> str:
    return (
        f"void {d.imgui_name}Widget::Render()\n"
        f"{{\n"
        f"    if (!visible) return;\n"
        f"    if (!enabled) ImGui::BeginDisabled();\n"
        f"    ImGui::PushID(id.c_str());\n"
        f"    const char* shown = label.empty() ? id.c_str() : label.c_str();\n"
        f"    if (ImGui::{d.imgui_name}(shown, values, v_speed, v_min, v_max, format.c_str())) {{\n"
        f"        changed = true;\n"
        f"    }}\n"
        f"    ImGui::PopID();\n"
        f"    if (!enabled) ImGui::EndDisabled();\n"
        f"}}\n\n"
    )

def _drag_api_vec(d: Drag) -> str:
    fmt            = "%.3f" if d.value_type == "float" else "%d"
    default_sig    = ", ".join(f"{d.value_type} default_{i}" for i in range(d.n))
    default_assign = "".join(f"    w->values[{i}] = default_{i};\n" for i in range(d.n))
    return (
        f"API_EXPORT int __cdecl {d.autoit_create}(const wchar_t* id, const wchar_t* label,\n"
        f"                                float v_speed, {d.value_type} v_min, {d.value_type} v_max,\n"
        f"                                {default_sig},\n"
        f"                                const wchar_t* format)\n"
        f"{{\n"
        f"    if (!id || !*id) return 1;\n"
        f"    std::string uid  = WideToUtf8(id);\n"
        f"    std::string ulbl = WideToUtf8(label ? label : L\"\");\n"
        f"    std::string ufmt = WideToUtf8(format && *format ? format : L\"{fmt}\");\n"
        f"    if (uid.empty()) return 1;\n"
        f"    auto w = std::make_unique<{d.imgui_name}Widget>();\n"
        f"    w->id = uid; w->label = ulbl;\n"
        f"    w->v_speed = v_speed;\n"
        f"    w->v_min = v_min; w->v_max = v_max;\n"
        f"{default_assign}"
        f"    w->format = ufmt;\n"
        f"    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);\n"
        f"    return g_tree.Add(std::move(w)) ? 0 : 2;\n"
        f"}}\n\n"
    )

def _input_struct_vec(i: Input) -> str:
    has_format = (i.value_type == "float")
    fmt_field  = "    std::string format;\n" if has_format else ""
    sig = "label, {0}[{1}]{2}".format(i.value_type, i.n, ", format" if has_format else "")
    return (
        f"// Wraps ImGui::{i.imgui_name}({sig}).\n"
        f"struct {i.imgui_name}Widget : {_base_for(i.value_type, i.n)} {{\n"
        f"{fmt_field}"
        f"    void Render() override;\n"
        f"}};\n\n"
    )

def _input_render_vec(i: Input) -> str:
    if i.value_type == "float":
        call = f"ImGui::{i.imgui_name}(shown, values, format.c_str())"
    else:
        call = f"ImGui::{i.imgui_name}(shown, values)"
    return (
        f"void {i.imgui_name}Widget::Render()\n"
        f"{{\n"
        f"    if (!visible) return;\n"
        f"    if (!enabled) ImGui::BeginDisabled();\n"
        f"    ImGui::PushID(id.c_str());\n"
        f"    const char* shown = label.empty() ? id.c_str() : label.c_str();\n"
        f"    if ({call}) {{\n"
        f"        changed = true;\n"
        f"    }}\n"
        f"    ImGui::PopID();\n"
        f"    if (!enabled) ImGui::EndDisabled();\n"
        f"}}\n\n"
    )

def _input_api_vec(i: Input) -> str:
    fmt            = "%.3f" if i.value_type == "float" else "%d"
    default_sig    = ", ".join(f"{i.value_type} default_{j}" for j in range(i.n))
    default_assign = "".join(f"    w->values[{j}] = default_{j};\n" for j in range(i.n))
    if i.value_type == "float":
        return (
            f"API_EXPORT int __cdecl {i.autoit_create}(const wchar_t* id, const wchar_t* label,\n"
            f"                                {default_sig},\n"
            f"                                const wchar_t* format)\n"
            f"{{\n"
            f"    if (!id || !*id) return 1;\n"
            f"    std::string uid  = WideToUtf8(id);\n"
            f"    std::string ulbl = WideToUtf8(label ? label : L\"\");\n"
            f"    std::string ufmt = WideToUtf8(format && *format ? format : L\"{fmt}\");\n"
            f"    if (uid.empty()) return 1;\n"
            f"    auto w = std::make_unique<{i.imgui_name}Widget>();\n"
            f"    w->id = uid; w->label = ulbl;\n"
            f"{default_assign}"
            f"    w->format = ufmt;\n"
            f"    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);\n"
            f"    return g_tree.Add(std::move(w)) ? 0 : 2;\n"
            f"}}\n\n"
        )
    # int variant â€” no format
    return (
        f"API_EXPORT int __cdecl {i.autoit_create}(const wchar_t* id, const wchar_t* label,\n"
        f"                                {default_sig})\n"
        f"{{\n"
        f"    if (!id || !*id) return 1;\n"
        f"    std::string uid  = WideToUtf8(id);\n"
        f"    std::string ulbl = WideToUtf8(label ? label : L\"\");\n"
        f"    if (uid.empty()) return 1;\n"
        f"    auto w = std::make_unique<{i.imgui_name}Widget>();\n"
        f"    w->id = uid; w->label = ulbl;\n"
        f"{default_assign}"
        f"    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);\n"
        f"    return g_tree.Add(std::move(w)) ? 0 : 2;\n"
        f"}}\n\n"
    )

def _au3_slider_vec(s: Slider) -> str:
    is_float = (s.value_type == "float")
    range_default = "0.0, 1.0" if is_float else "0, 100"
    type_kw  = "float" if is_float else "int"
    var_pfx  = "$f" if is_float else "$i"
    zero     = "0.0" if is_float else "0"
    fmt      = "%.3f" if is_float else "%d"
    defaults_au3 = ", ".join(f"{var_pfx}D{i} = {zero}" for i in range(s.n))
    defaults_call = ", _\n        ".join(f'"{type_kw}", {var_pfx}D{i}' for i in range(s.n))
    header = _value_numeric_au3_header(s.autoit_create, "slider", s.value_type, s.n)
    return (
        header +
        f'Func _{s.autoit_create}($sId, $sLabel = "", '
        f'{var_pfx}Min = {range_default.split(",")[0].strip()}, '
        f'{var_pfx}Max = {range_default.split(",")[1].strip()}, '
        f'{defaults_au3}, $sFormat = "{fmt}")\n'
        f'    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)\n'
        f'    If $sLabel = "" Then $sLabel = $sId\n'
        f'    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{s.autoit_create}", _\n'
        f'        "wstr", $sId, "wstr", $sLabel, _\n'
        f'        "{type_kw}", {var_pfx}Min, "{type_kw}", {var_pfx}Max, _\n'
        f'        {defaults_call}, _\n'
        f'        "wstr", $sFormat)\n'
        f'    If @error Then Return SetError(2, @error, False)\n'
        f'    Return ($aRet[0] = 0)\n'
        f'EndFunc\n\n'
    )

def _au3_drag_vec(d: Drag) -> str:
    is_float = (d.value_type == "float")
    type_kw  = "float" if is_float else "int"
    var_pfx  = "$f" if is_float else "$i"
    zero     = "0.0" if is_float else "0"
    fmt      = "%.3f" if is_float else "%d"
    defaults_au3 = ", ".join(f"{var_pfx}D{i} = {zero}" for i in range(d.n))
    defaults_call = ", _\n        ".join(f'"{type_kw}", {var_pfx}D{i}' for i in range(d.n))
    header = _value_numeric_au3_header(d.autoit_create, "drag", d.value_type, d.n)
    return (
        header +
        f'Func _{d.autoit_create}($sId, $sLabel = "", $fSpeed = 1.0, '
        f'{var_pfx}Min = {zero}, {var_pfx}Max = {zero}, '
        f'{defaults_au3}, $sFormat = "{fmt}")\n'
        f'    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)\n'
        f'    If $sLabel = "" Then $sLabel = $sId\n'
        f'    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{d.autoit_create}", _\n'
        f'        "wstr", $sId, "wstr", $sLabel, _\n'
        f'        "float", $fSpeed, "{type_kw}", {var_pfx}Min, "{type_kw}", {var_pfx}Max, _\n'
        f'        {defaults_call}, _\n'
        f'        "wstr", $sFormat)\n'
        f'    If @error Then Return SetError(2, @error, False)\n'
        f'    Return ($aRet[0] = 0)\n'
        f'EndFunc\n\n'
    )

def _au3_input_vec(i: Input) -> str:
    is_float = (i.value_type == "float")
    type_kw  = "float" if is_float else "int"
    var_pfx  = "$f" if is_float else "$i"
    zero     = "0.0" if is_float else "0"
    fmt      = "%.3f"
    defaults_au3 = ", ".join(f"{var_pfx}D{j} = {zero}" for j in range(i.n))
    defaults_call = ", _\n        ".join(f'"{type_kw}", {var_pfx}D{j}' for j in range(i.n))
    header = _value_numeric_au3_header(i.autoit_create, "input", i.value_type, i.n)
    if is_float:
        return (
            header +
            f'Func _{i.autoit_create}($sId, $sLabel = "", '
            f'{defaults_au3}, $sFormat = "{fmt}")\n'
            f'    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)\n'
            f'    If $sLabel = "" Then $sLabel = $sId\n'
            f'    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{i.autoit_create}", _\n'
            f'        "wstr", $sId, "wstr", $sLabel, _\n'
            f'        {defaults_call}, _\n'
            f'        "wstr", $sFormat)\n'
            f'    If @error Then Return SetError(2, @error, False)\n'
            f'    Return ($aRet[0] = 0)\n'
            f'EndFunc\n\n'
        )
    return (
        header +
        f'Func _{i.autoit_create}($sId, $sLabel = "", {defaults_au3})\n'
        f'    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)\n'
        f'    If $sLabel = "" Then $sLabel = $sId\n'
        f'    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{i.autoit_create}", _\n'
        f'        "wstr", $sId, "wstr", $sLabel, _\n'
        f'        {defaults_call})\n'
        f'    If @error Then Return SetError(2, @error, False)\n'
        f'    Return ($aRet[0] = 0)\n'
        f'EndFunc\n\n'
    )


def emit_value_numeric_header() -> str:
    out = [VALUE_NUMERIC_HEADER_PROLOG]
    for s in SLIDER:
        if s.n == 1:
            out.append(SLIDER_HEADER_TMPL.format(name=s.imgui_name, base=_base_for(s.value_type), vt=s.value_type))
        else:
            out.append(_slider_struct_vec(s))
    for d in DRAG:
        if d.n == 1:
            out.append(DRAG_HEADER_TMPL.format(name=d.imgui_name, base=_base_for(d.value_type), vt=d.value_type))
        else:
            out.append(_drag_struct_vec(d))
    # InputFloat / InputInt scalar (n=1)
    out.append(INPUT_FLOAT_HEADER_TMPL)
    out.append(INPUT_INT_HEADER_TMPL)
    for inp in INPUT:
        if inp.n >= 2:
            out.append(_input_struct_vec(inp))
    return "".join(out)


def emit_value_numeric_impl() -> str:
    out = [VALUE_NUMERIC_IMPL_PROLOG]
    for s in SLIDER:
        if s.n == 1:
            out.append(SLIDER_RENDER_TMPL.format(name=s.imgui_name))
        else:
            out.append(_slider_render_vec(s))
    for d in DRAG:
        if d.n == 1:
            out.append(DRAG_RENDER_TMPL.format(name=d.imgui_name))
        else:
            out.append(_drag_render_vec(d))
    out.append(INPUT_FLOAT_RENDER_TMPL)
    out.append(INPUT_INT_RENDER_TMPL)
    for inp in INPUT:
        if inp.n >= 2:
            out.append(_input_render_vec(inp))
    return "".join(out)


def emit_value_numeric_api() -> str:
    out = [VALUE_NUMERIC_API_PROLOG]
    for s in SLIDER:
        if s.n == 1:
            fmt = "%.3f" if s.value_type == "float" else "%d"
            out.append(SLIDER_API_TMPL.format(name=s.imgui_name, export=s.autoit_create, vt=s.value_type, default_fmt=fmt))
        else:
            out.append(_slider_api_vec(s))
    for d in DRAG:
        if d.n == 1:
            fmt = "%.3f" if d.value_type == "float" else "%d"
            out.append(DRAG_API_TMPL.format(name=d.imgui_name, export=d.autoit_create, vt=d.value_type, default_fmt=fmt))
        else:
            out.append(_drag_api_vec(d))
    out.append(INPUT_FLOAT_API_TMPL)
    out.append(INPUT_INT_API_TMPL)
    for inp in INPUT:
        if inp.n >= 2:
            out.append(_input_api_vec(inp))
    return "".join(out)


_VALUE_NUMERIC_INFO = {
    "slider": "Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.\nUser edits are reported by _ImGui_HasChanged ; programmatic writes never latch.",
    "drag":   "Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.\nUser edits are reported by _ImGui_HasChanged ; programmatic writes never latch.",
    "input":  "Read/write via _ImGui_GetValueFloat/Int and _ImGui_SetValueFloat/Int.\nUser edits are reported by _ImGui_HasChanged ; programmatic writes never latch.",
}


def _value_numeric_au3_header(export: str, kind: str, value_type: str, n: int = 1) -> str:
    """kind in {slider, drag, input}, value_type in {float, int}, n=1..4."""
    if n == 1:
        desc_base = {
            "slider": "Create a slider widget bound to a range",
            "drag":   "Create a draggable numeric widget",
            "input":  "Create a numeric input field with +/- buttons",
        }[kind]
        desc = f"{desc_base} ({value_type} value)"
        if kind == "input":
            if value_type == "float":
                params = [("$sId", None), ("$sLabel", None), ("$fDefault", None),
                          ("$fStep", None), ("$fStepFast", None), ("$sFormat", None)]
                syntax = f'_{export}($sId[, $sLabel = "", $fDefault = 0.0, $fStep = 0.0, $fStepFast = 0.0, $sFormat = "%.3f"])'
            else:
                params = [("$sId", None), ("$sLabel", None), ("$iDefault", None),
                          ("$iStep", None), ("$iStepFast", None)]
                syntax = f'_{export}($sId[, $sLabel = "", $iDefault = 0, $iStep = 1, $iStepFast = 100])'
        elif kind == "slider":
            if value_type == "float":
                params = [("$sId", None), ("$sLabel", None), ("$fMin", None),
                          ("$fMax", None), ("$fDefault", None), ("$sFormat", None)]
                syntax = f'_{export}($sId[, $sLabel = "", $fMin = 0.0, $fMax = 1.0, $fDefault = 0.0, $sFormat = "%.3f"])'
            else:
                params = [("$sId", None), ("$sLabel", None), ("$iMin", None),
                          ("$iMax", None), ("$iDefault", None), ("$sFormat", None)]
                syntax = f'_{export}($sId[, $sLabel = "", $iMin = 0, $iMax = 100, $iDefault = 0, $sFormat = "%d"])'
        else:  # drag
            if value_type == "float":
                params = [("$sId", None), ("$sLabel", None), ("$fSpeed", None),
                          ("$fMin", None), ("$fMax", None), ("$fDefault", None),
                          ("$sFormat", None)]
                syntax = f'_{export}($sId[, $sLabel = "", $fSpeed = 1.0, $fMin = 0.0, $fMax = 0.0, $fDefault = 0.0, $sFormat = "%.3f"])'
            else:
                params = [("$sId", None), ("$sLabel", None), ("$fSpeed", None),
                          ("$iMin", None), ("$iMax", None), ("$iDefault", None),
                          ("$sFormat", None)]
                syntax = f'_{export}($sId[, $sLabel = "", $fSpeed = 1.0, $iMin = 0, $iMax = 0, $iDefault = 0, $sFormat = "%d"])'
    else:
        # Vector variant
        desc_base = {
            "slider": f"Create a {n}-component slider widget",
            "drag":   f"Create a {n}-component draggable widget",
            "input":  f"Create a {n}-component numeric input",
        }[kind]
        desc = f"{desc_base} ({value_type} values)"
        var_pfx = "$f" if value_type == "float" else "$i"
        params = [("$sId", None), ("$sLabel", None)]
        if kind == "slider":
            params.append((f"{var_pfx}Min", f"Range minimum ({value_type})"))
            params.append((f"{var_pfx}Max", f"Range maximum ({value_type})"))
        elif kind == "drag":
            params.append(("$fSpeed", None))
            params.append((f"{var_pfx}Min", f"Range minimum ({value_type})"))
            params.append((f"{var_pfx}Max", f"Range maximum ({value_type})"))
        for i in range(n):
            params.append((f"{var_pfx}D{i}", f"Initial value for component {i}"))
        if not (kind == "input" and value_type == "int"):
            params.append(("$sFormat", None))
        syntax = f'_{export}($sId, $sLabel, ...) - {n} components'
    info = _VALUE_NUMERIC_INFO.get(kind, "")
    if n >= 2:
        info += f"\nVector access via _ImGui_GetValueFloatN/_ImGui_SetValueFloatN (or *IntN) with size {n}."
    return _au3_func_header(
        name=f"_{export}",
        description=desc,
        syntax=syntax,
        params=params,
        returns="Success - True. Failure - False (@error = 1=DLL not loaded, 2=DllCall failed)",
        information=info,
    )


def emit_value_numeric_au3() -> str:
    out = ["; --- value_numeric ---\n\n"]
    out.append(AU3_SLIDER_FLOAT_TMPL.format(
        export="ImGui_CreateSliderFloat",
        header=_value_numeric_au3_header("ImGui_CreateSliderFloat", "slider", "float")))
    out.append(AU3_SLIDER_INT_TMPL.format(
        export="ImGui_CreateSliderInt",
        header=_value_numeric_au3_header("ImGui_CreateSliderInt", "slider", "int")))
    out.append(AU3_DRAG_FLOAT_TMPL.format(
        export="ImGui_CreateDragFloat",
        header=_value_numeric_au3_header("ImGui_CreateDragFloat", "drag", "float")))
    out.append(AU3_DRAG_INT_TMPL.format(
        export="ImGui_CreateDragInt",
        header=_value_numeric_au3_header("ImGui_CreateDragInt", "drag", "int")))
    out.append(AU3_INPUT_FLOAT_TMPL.format(
        header=_value_numeric_au3_header("ImGui_CreateInputFloat", "input", "float")))
    out.append(AU3_INPUT_INT_TMPL.format(
        header=_value_numeric_au3_header("ImGui_CreateInputInt", "input", "int")))
    # Vector variants
    for s in SLIDER:
        if s.n >= 2:
            out.append(_au3_slider_vec(s))
    for d in DRAG:
        if d.n >= 2:
            out.append(_au3_drag_vec(d))
    for inp in INPUT:
        if inp.n >= 2:
            out.append(_au3_input_vec(inp))
    return "".join(out)


# =============================================================================
# Category: "display"
# =============================================================================
#
# Stateless markers â€” no value, no click, no `changed` flag. Each Render()
# makes one ImGui call. Per-widget "constant" params (e.g. SameLine's offset
# and spacing) are stored on the widget and passed through at render time.
# All seven widgets fit a single dataclass with a variable-length param list.

# DisplayParam is the original name kept for clarity in display/config/container
# sections. It's the same shape as WParam declared earlier.
DisplayParam = WParam

@dataclass
class Display:
    imgui_name:    str        # "Separator", "SameLine", â€¦
    autoit_create: str        # "ImGui_CreateSeparator", â€¦
    params:        list       # list[DisplayParam] â€” may be empty
    # Optional explicit Render() call body. Empty = default
    # `ImGui::<imgui_name>(<comma-joined param names>)`. Useful when the
    # ImGui signature differs from "n flat params" (e.g. Dummy takes ImVec2
    # not (float, float)).
    render_call:   str = ""


_P_OFFSET_X = DisplayParam("offset_x", "float", "0.0f",  "$fOffsetX", "float", "0.0")
_P_SPACING  = DisplayParam("spacing",  "float", "-1.0f", "$fSpacing", "float", "-1.0")
_P_INDENT_W = DisplayParam("indent_w", "float", "0.0f",  "$fIndentW", "float", "0.0")

# F.1 â€” dummy / next-item-width / next-item allow-overlap / set-keyboard-focus-here
_P_DUMMY_W      = DisplayParam("size_x",     "float", "0.0f", "$fW",      "float", "0.0")
_P_DUMMY_H      = DisplayParam("size_y",     "float", "0.0f", "$fH",      "float", "0.0")
_P_ITEM_WIDTH   = DisplayParam("item_width", "float", "0.0f", "$fWidth",  "float", "0.0")
_P_KEYFOCUS_OFF = DisplayParam("offset",     "int",   "0",    "$iOffset", "int",   "0")

# G.5 â€” SetCursorPos / SetCursorPosX / SetCursorPosY marker params. Names are
# `local_x`/`local_y` to make the window-local coordinate space explicit (these
# are NOT screen-space; they're relative to the enclosing window/child top-left).
_P_CURSOR_LX    = DisplayParam("local_x",    "float", "0.0f", "$fX",      "float", "0.0")
_P_CURSOR_LY    = DisplayParam("local_y",    "float", "0.0f", "$fY",      "float", "0.0")

# L.3 â€” SetCursorScreenPos params. Screen-space (absolute pixels in viewport),
# in contrast with SetCursorPos which is window-local.
_P_CURSOR_SX    = DisplayParam("screen_x",   "float", "0.0f", "$fScreenX", "float", "0.0")
_P_CURSOR_SY    = DisplayParam("screen_y",   "float", "0.0f", "$fScreenY", "float", "0.0")


DISPLAY: list[Display] = [
    Display("Separator", "ImGui_CreateSeparator", []),
    Display("NewLine",   "ImGui_CreateNewLine",   []),
    Display("Spacing",   "ImGui_CreateSpacing",   []),
    Display("Bullet",    "ImGui_CreateBullet",    []),
    Display("SameLine",  "ImGui_CreateSameLine",  [_P_OFFSET_X, _P_SPACING]),
    Display("Indent",    "ImGui_CreateIndent",    [_P_INDENT_W]),
    Display("Unindent",  "ImGui_CreateUnindent",  [_P_INDENT_W]),
    # F.1 layout markers
    Display("Dummy", "ImGui_CreateDummy", [_P_DUMMY_W, _P_DUMMY_H],
            render_call="ImGui::Dummy(ImVec2(size_x, size_y))"),
    Display("AlignTextToFramePadding",  "ImGui_CreateAlignTextToFramePadding", []),
    Display("SetNextItemWidth",         "ImGui_CreateSetNextItemWidth",        [_P_ITEM_WIDTH]),
    # F.2 focus markers (placed here because they share the generator's
    # display template â€” zero-arg or one-arg one-shot markers in the flow).
    Display("SetItemDefaultFocus",      "ImGui_CreateSetItemDefaultFocus",     []),
    Display("SetNextItemAllowOverlap",  "ImGui_CreateSetNextItemAllowOverlap", []),
    Display("SetKeyboardFocusHere",     "ImGui_CreateSetKeyboardFocusHere",    [_P_KEYFOCUS_OFF]),
    # G.5 cursor positioning markers. Window-local â€” use inside a Window/Child/
    # Group to align widgets at a specific offset within the parent's content
    # region. `SetCursorPos` takes an ImVec2 so we need an explicit render_call
    # (the default would be `ImGui::SetCursorPos(local_x, local_y)` which is wrong).
    Display("SetCursorPos",  "ImGui_CreateSetCursorPos",  [_P_CURSOR_LX, _P_CURSOR_LY],
            render_call="ImGui::SetCursorPos(ImVec2(local_x, local_y))"),
    Display("SetCursorPosX", "ImGui_CreateSetCursorPosX", [_P_CURSOR_LX]),
    Display("SetCursorPosY", "ImGui_CreateSetCursorPosY", [_P_CURSOR_LY]),
    # K.5 â€” LogButtons : renders an inline row of buttons (Clipboard / TTY /
    # File / Finish) that drive ImGui's logging stream. Each button click is
    # handled internally by ImGui ; AutoIt only needs to place the marker.
    Display("LogButtons", "ImGui_CreateLogButtons", []),
    # L.3 â€” SetCursorScreenPos : screen-space variant of SetCursorPos. Place
    # inside a Window/Child/Group ; ImVec2 packed render call.
    Display("SetCursorScreenPos", "ImGui_CreateSetCursorScreenPos",
            [_P_CURSOR_SX, _P_CURSOR_SY],
            render_call="ImGui::SetCursorScreenPos(ImVec2(screen_x, screen_y))"),
]


DISPLAY_HEADER_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#pragma once
#include "widget.h"

"""

DISPLAY_IMPL_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include "generated/widgets_display.h"
#include "imgui.h"

"""

DISPLAY_API_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include <Windows.h>
#include <memory>
#include <string>
#include "widget_tree.h"
#include "utf.h"
#include "generated/widgets_display.h"

#define API_EXPORT extern "C" __declspec(dllexport)

"""


def _display_struct(d: Display) -> str:
    fields = "".join(f"    {p.cpp_type} {p.cpp_name} = {p.cpp_default};\n" for p in d.params)
    return (
        f"// Stateless wrapper around ImGui::{d.imgui_name}().\n"
        f"struct {d.imgui_name}Widget : Widget {{\n"
        f"{fields}"
        f"    void Render() override;\n"
        f"}};\n\n"
    )


def _display_render(d: Display) -> str:
    if d.render_call:
        call = d.render_call
    else:
        args = ", ".join(p.cpp_name for p in d.params)
        call = f"ImGui::{d.imgui_name}({args})"
    return (
        f"void {d.imgui_name}Widget::Render()\n"
        f"{{\n"
        f"    if (!visible) return;\n"
        f"    {call};\n"
        f"}}\n\n"
    )


def _display_api(d: Display) -> str:
    sig_params = "".join(f", {p.cpp_type} {p.cpp_name}" for p in d.params)
    assigns    = "".join(f"    w->{p.cpp_name} = {p.cpp_name};\n" for p in d.params)
    return (
        f"API_EXPORT int __cdecl {d.autoit_create}(const wchar_t* id{sig_params})\n"
        f"{{\n"
        f"    if (!id || !*id) return 1;\n"
        f"    std::string uid = WideToUtf8(id);\n"
        f"    if (uid.empty()) return 1;\n"
        f"    auto w = std::make_unique<{d.imgui_name}Widget>();\n"
        f"    w->id = uid;\n"
        f"{assigns}"
        f"    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);\n"
        f"    return g_tree.Add(std::move(w)) ? 0 : 2;\n"
        f"}}\n\n"
    )


_DISPLAY_DESC = {
    "ImGui_CreateSeparator":             "Insert a horizontal separator line",
    "ImGui_CreateNewLine":               "Insert a vertical blank line (newline)",
    "ImGui_CreateSpacing":               "Insert a small vertical gap",
    "ImGui_CreateBullet":                "Render a bullet point at the cursor",
    "ImGui_CreateSameLine":              "Keep the next widget on the same line",
    "ImGui_CreateIndent":                "Move the cursor right by an indent width",
    "ImGui_CreateUnindent":              "Move the cursor left by an indent width",
    "ImGui_CreateDummy":                 "Reserve an invisible rectangular space",
    "ImGui_CreateAlignTextToFramePadding": "Align the next Text with a framed widget",
    "ImGui_CreateSetNextItemWidth":      "Override the width of the next item (one-shot)",
    "ImGui_CreateSetItemDefaultFocus":   "Mark the previous item as default-focused",
    "ImGui_CreateSetNextItemAllowOverlap": "Allow the next item to be overlapped",
    "ImGui_CreateSetKeyboardFocusHere":  "Set keyboard focus on a following item",
    "ImGui_CreateSetCursorPos":          "Set the cursor position (window-local)",
    "ImGui_CreateSetCursorPosX":         "Set the X component of the cursor (window-local)",
    "ImGui_CreateSetCursorPosY":         "Set the Y component of the cursor (window-local)",
    "ImGui_CreateSetCursorScreenPos":    "Set the cursor position in screen-space",
}


def _display_au3(d: Display) -> str:
    au_params = "".join(f", {p.au3_var} = {p.au3_default}" for p in d.params)
    call_args = "".join(f', "{p.au3_type}", {p.au3_var}' for p in d.params)
    desc = _DISPLAY_DESC.get(d.autoit_create, f"Create a {d.imgui_name} layout marker")
    sig_params = "".join(f", {p.au3_var} = {p.au3_default}" for p in d.params)
    syntax = f'_{d.autoit_create}($sId{(sig_params and "[" + sig_params + "]") or ""})'
    doc_params = [("$sId", None)] + [(p.au3_var, None) for p in d.params]
    header = _au3_func_header(
        name=f"_{d.autoit_create}",
        description=desc,
        syntax=syntax,
        params=doc_params,
    )
    return (
        header +
        f'Func _{d.autoit_create}($sId{au_params})\n'
        f'    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)\n'
        f'    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{d.autoit_create}", "wstr", $sId{call_args})\n'
        f'    If @error Then Return SetError(2, @error, False)\n'
        f'    Return ($aRet[0] = 0)\n'
        f'EndFunc\n\n'
    )


def emit_display_header() -> str:
    return DISPLAY_HEADER_PROLOG + "".join(_display_struct(d) for d in DISPLAY)


def emit_display_impl() -> str:
    return DISPLAY_IMPL_PROLOG + "".join(_display_render(d) for d in DISPLAY)


def emit_display_api() -> str:
    return DISPLAY_API_PROLOG + "".join(_display_api(d) for d in DISPLAY)


def emit_display_au3() -> str:
    return "; --- display ---\n\n" + "".join(_display_au3(d) for d in DISPLAY)


# =============================================================================
# Category: "config" (style stack)
# =============================================================================
#
# Stack-scoped style overrides â€” paired Push/Pop widgets in the render stream.
# Same retained model as Indent/Unindent in `display`. Each widget stores its
# constant params (idx, color components, count, â€¦) and Render() emits the
# matching ImGui call; pairing is the user's responsibility â€” ImGui asserts at
# end-of-frame if the stack is unbalanced.
#
# Global one-shot setters (ImGui_SetConfigFlags, ImGui_SetFontGlobalScale) are
# NOT in this category â€” they're hand-written in src/dll_api.cpp.

@dataclass
class Config:
    name:          str        # widget class prefix ("PushStyleColor", "PushStyleVarFloat", â€¦)
    autoit_create: str        # exported function name
    imgui_check:   str        # name to look up in imgui.h for the sanity pass
    params:        list       # list[DisplayParam]
    render_call:   str        # exact ImGui call body inside Render() â€” references field names


# Params reused across config widgets.
_P_STYLE_IDX_COL = DisplayParam("idx",  "int",   "0",     "$iCol",     "int",   "0")
_P_STYLE_IDX_VAR = DisplayParam("idx",  "int",   "0",     "$iVar",     "int",   "0")
_P_FLOAT_R       = DisplayParam("r",    "float", "1.0f",  "$fR",       "float", "1.0")
_P_FLOAT_G       = DisplayParam("g",    "float", "1.0f",  "$fG",       "float", "1.0")
_P_FLOAT_B       = DisplayParam("b",    "float", "1.0f",  "$fB",       "float", "1.0")
_P_FLOAT_A       = DisplayParam("a",    "float", "1.0f",  "$fA",       "float", "1.0")
_P_STYLE_VALUE   = DisplayParam("value","float", "0.0f",  "$fValue",   "float", "0.0")
_P_STYLE_VALUE_X = DisplayParam("value_x","float","0.0f", "$fX",       "float", "0.0")
_P_STYLE_VALUE_Y = DisplayParam("value_y","float","0.0f", "$fY",       "float", "0.0")
_P_POP_COUNT     = DisplayParam("count","int",   "1",     "$iCount",   "int",   "1")

# F.1 â€” Push/Pop pair extras.
_P_PUSH_ITEM_WIDTH  = DisplayParam("item_width",       "float", "0.0f", "$fWidth",   "float", "0.0")
_P_PUSH_WRAP_POS    = DisplayParam("wrap_local_pos_x", "float", "0.0f", "$fWrapPos", "float", "0.0")
_P_ITEMFLAG_OPTION  = DisplayParam("option",  "int", "0", "$iOption",  "int", "0")
_P_ITEMFLAG_ENABLED = DisplayParam("enabled", "int", "0", "$bEnabled", "int", "0")

# K.4 â€” clipping rect pair. ImVec2 packed as 2 floats per corner.
_P_CLIP_MIN_X   = DisplayParam("min_x", "float", "0.0f", "$fMinX", "float", "0.0")
_P_CLIP_MIN_Y   = DisplayParam("min_y", "float", "0.0f", "$fMinY", "float", "0.0")
_P_CLIP_MAX_X   = DisplayParam("max_x", "float", "0.0f", "$fMaxX", "float", "0.0")
_P_CLIP_MAX_Y   = DisplayParam("max_y", "float", "0.0f", "$fMaxY", "float", "0.0")
_P_CLIP_INTERSECT = DisplayParam("intersect", "int", "1", "$bIntersect", "int", "1")


CONFIG: list[Config] = [
    Config(
        "PushStyleColor", "ImGui_CreatePushStyleColor", "PushStyleColor",
        [_P_STYLE_IDX_COL, _P_FLOAT_R, _P_FLOAT_G, _P_FLOAT_B, _P_FLOAT_A],
        "ImGui::PushStyleColor(idx, ImVec4(r, g, b, a))",
    ),
    Config(
        "PopStyleColor", "ImGui_CreatePopStyleColor", "PopStyleColor",
        [_P_POP_COUNT],
        "ImGui::PopStyleColor(count)",
    ),
    Config(
        "PushStyleVarFloat", "ImGui_CreatePushStyleVarFloat", "PushStyleVar",
        [_P_STYLE_IDX_VAR, _P_STYLE_VALUE],
        "ImGui::PushStyleVar(idx, value)",
    ),
    Config(
        "PushStyleVarVec2", "ImGui_CreatePushStyleVarVec2", "PushStyleVar",
        [_P_STYLE_IDX_VAR, _P_STYLE_VALUE_X, _P_STYLE_VALUE_Y],
        "ImGui::PushStyleVar(idx, ImVec2(value_x, value_y))",
    ),
    Config(
        "PopStyleVar", "ImGui_CreatePopStyleVar", "PopStyleVar",
        [_P_POP_COUNT],
        "ImGui::PopStyleVar(count)",
    ),
    # F.1 â€” single-component PushStyleVar variants (1.92+ X/Y helpers).
    Config(
        "PushStyleVarX", "ImGui_CreatePushStyleVarX", "PushStyleVarX",
        [_P_STYLE_IDX_VAR, _P_STYLE_VALUE_X],
        "ImGui::PushStyleVarX(idx, value_x)",
    ),
    Config(
        "PushStyleVarY", "ImGui_CreatePushStyleVarY", "PushStyleVarY",
        [_P_STYLE_IDX_VAR, _P_STYLE_VALUE_Y],
        "ImGui::PushStyleVarY(idx, value_y)",
    ),
    # F.1 â€” item-width stack (per-window).
    Config(
        "PushItemWidth", "ImGui_CreatePushItemWidth", "PushItemWidth",
        [_P_PUSH_ITEM_WIDTH],
        "ImGui::PushItemWidth(item_width)",
    ),
    Config(
        "PopItemWidth", "ImGui_CreatePopItemWidth", "PopItemWidth",
        [],
        "ImGui::PopItemWidth()",
    ),
    # F.1 â€” text wrap stack (per-window).
    Config(
        "PushTextWrapPos", "ImGui_CreatePushTextWrapPos", "PushTextWrapPos",
        [_P_PUSH_WRAP_POS],
        "ImGui::PushTextWrapPos(wrap_local_pos_x)",
    ),
    Config(
        "PopTextWrapPos", "ImGui_CreatePopTextWrapPos", "PopTextWrapPos",
        [],
        "ImGui::PopTextWrapPos()",
    ),
    # F.1 â€” item-flag stack (shared by all items in the scope).
    Config(
        "PushItemFlag", "ImGui_CreatePushItemFlag", "PushItemFlag",
        [_P_ITEMFLAG_OPTION, _P_ITEMFLAG_ENABLED],
        "ImGui::PushItemFlag(static_cast<ImGuiItemFlags>(option), enabled != 0)",
    ),
    Config(
        "PopItemFlag", "ImGui_CreatePopItemFlag", "PopItemFlag",
        [],
        "ImGui::PopItemFlag()",
    ),
    # K.4 â€” manual clipping stack. Each Push must be balanced by a Pop ; ImGui
    # asserts at end-of-frame if the stack leaks.
    Config(
        "PushClipRect", "ImGui_CreatePushClipRect", "PushClipRect",
        [_P_CLIP_MIN_X, _P_CLIP_MIN_Y, _P_CLIP_MAX_X, _P_CLIP_MAX_Y, _P_CLIP_INTERSECT],
        "ImGui::PushClipRect(ImVec2(min_x, min_y), ImVec2(max_x, max_y), intersect != 0)",
    ),
    Config(
        "PopClipRect", "ImGui_CreatePopClipRect", "PopClipRect",
        [],
        "ImGui::PopClipRect()",
    ),
]


CONFIG_HEADER_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#pragma once
#include "widget.h"

"""

CONFIG_IMPL_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include "generated/widgets_config.h"
#include "imgui.h"

"""

CONFIG_API_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include <Windows.h>
#include <memory>
#include <string>
#include "widget_tree.h"
#include "utf.h"
#include "generated/widgets_config.h"

#define API_EXPORT extern "C" __declspec(dllexport)

"""


def _config_struct(c: Config) -> str:
    fields = "".join(f"    {p.cpp_type} {p.cpp_name} = {p.cpp_default};\n" for p in c.params)
    return (
        f"// Stack-scoped: wraps {c.render_call}.\n"
        f"struct {c.name}Widget : Widget {{\n"
        f"{fields}"
        f"    void Render() override;\n"
        f"}};\n\n"
    )


def _config_render(c: Config) -> str:
    return (
        f"void {c.name}Widget::Render()\n"
        f"{{\n"
        f"    if (!visible) return;\n"
        f"    {c.render_call};\n"
        f"}}\n\n"
    )


def _config_api(c: Config) -> str:
    sig_params = "".join(f", {p.cpp_type} {p.cpp_name}" for p in c.params)
    assigns    = "".join(f"    w->{p.cpp_name} = {p.cpp_name};\n" for p in c.params)
    return (
        f"API_EXPORT int __cdecl {c.autoit_create}(const wchar_t* id{sig_params})\n"
        f"{{\n"
        f"    if (!id || !*id) return 1;\n"
        f"    std::string uid = WideToUtf8(id);\n"
        f"    if (uid.empty()) return 1;\n"
        f"    auto w = std::make_unique<{c.name}Widget>();\n"
        f"    w->id = uid;\n"
        f"{assigns}"
        f"    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);\n"
        f"    return g_tree.Add(std::move(w)) ? 0 : 2;\n"
        f"}}\n\n"
    )


_CONFIG_DESC = {
    "ImGui_CreatePushStyleColor":     "Push a color override onto the style stack",
    "ImGui_CreatePopStyleColor":      "Pop one or more color overrides from the style stack",
    "ImGui_CreatePushStyleVarFloat":  "Push a scalar style variable override",
    "ImGui_CreatePushStyleVarVec2":   "Push a Vec2 style variable override",
    "ImGui_CreatePushStyleVarX":      "Push only the X component of a Vec2 style variable",
    "ImGui_CreatePushStyleVarY":      "Push only the Y component of a Vec2 style variable",
    "ImGui_CreatePopStyleVar":        "Pop one or more style variable overrides",
    "ImGui_CreatePushItemWidth":      "Push an item-width override onto the layout stack",
    "ImGui_CreatePopItemWidth":       "Pop the last item-width override",
    "ImGui_CreatePushTextWrapPos":    "Push a text-wrap position onto the stack",
    "ImGui_CreatePopTextWrapPos":     "Pop the last text-wrap position",
    "ImGui_CreatePushItemFlag":       "Push an item flag (enable/disable a behavior)",
    "ImGui_CreatePopItemFlag":        "Pop the last pushed item flag",
    "ImGui_CreatePushClipRect":       "Push a clipping rectangle onto the draw stack",
    "ImGui_CreatePopClipRect":        "Pop the last clipping rectangle",
}


def _config_au3(c: Config) -> str:
    au_params = "".join(f", {p.au3_var} = {p.au3_default}" for p in c.params)
    call_args = "".join(f', "{p.au3_type}", {p.au3_var}' for p in c.params)
    desc = _CONFIG_DESC.get(c.autoit_create, f"Create a {c.imgui_check} style marker")
    sig_params = "".join(f", {p.au3_var} = {p.au3_default}" for p in c.params)
    syntax = f'_{c.autoit_create}($sId{(sig_params and "[" + sig_params + "]") or ""})'
    doc_params = [("$sId", None)] + [(p.au3_var, None) for p in c.params]
    header = _au3_func_header(
        name=f"_{c.autoit_create}",
        description=desc,
        syntax=syntax,
        params=doc_params,
        information="Push/Pop must be balanced ; ImGui asserts at end-of-frame if the stack leaks.",
    )
    return (
        header +
        f'Func _{c.autoit_create}($sId{au_params})\n'
        f'    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)\n'
        f'    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{c.autoit_create}", "wstr", $sId{call_args})\n'
        f'    If @error Then Return SetError(2, @error, False)\n'
        f'    Return ($aRet[0] = 0)\n'
        f'EndFunc\n\n'
    )


def emit_config_header() -> str:
    return CONFIG_HEADER_PROLOG + "".join(_config_struct(c) for c in CONFIG)


def emit_config_impl() -> str:
    return CONFIG_IMPL_PROLOG + "".join(_config_render(c) for c in CONFIG)


def emit_config_api() -> str:
    return CONFIG_API_PROLOG + "".join(_config_api(c) for c in CONFIG)


def emit_config_au3() -> str:
    return "; --- config (style stack) ---\n\n" + "".join(_config_au3(c) for c in CONFIG)


# =============================================================================
# Category: "container"
# =============================================================================
#
# Containers own children (via Widget::children) and walk them between
# Begin/End in their Render(). Four render shapes corresponding to ImGui's
# pairing patterns:
#   - always_pair                       : Begin returns void or its return is
#                                         ignored; End must always be called.
#                                         (Group)
#   - conditional_pair                  : Begin returns bool; render children
#                                         and call End only when true.
#                                         (TabBar, TabItem, TreeNode,
#                                         MenuBar, Menu)
#   - conditional_children_always_end   : Begin returns bool; render children
#                                         only when true; End is ALWAYS called
#                                         regardless. (Window, Child)
#   - conditional_no_end                : Begin returns bool; render children
#                                         when true; no End at all.
#                                         (CollapsingHeader)
#
# is_top_level_window=True emits an IsTopLevelWindow() override so the render
# thread renders this widget OUTSIDE the host's Begin/End. (Window only.)

@dataclass
class Container:
    name:                 str        # widget class prefix
    autoit_create:        str        # exported function name
    imgui_check:          str        # name to look up in imgui.h
    params:               list       # list[DisplayParam]
    begin_call:           str        # exact ImGui call body
    end_call:             str        # exact ImGui call body; empty for conditional_no_end
    template_kind:        str        # one of the four kinds above
    is_top_level_window:  bool = False
    is_main_menu_bar:     bool = False


_P_WIN_CLOSABLE = DisplayParam("closable","int",  "1",    "$bClosable","int",  "1")
_P_WIN_FLAGS    = DisplayParam("flags",  "int",   "0",    "$iFlags",  "int",   "0")
_P_TABBAR_FLAGS = DisplayParam("flags",  "int",   "0",    "$iFlags",  "int",   "0")


CONTAINER: list[Container] = [
    # NOTE: ChildWidget used to live here as a generated container, but Phase H.1
    # added a ScrollableState member + ScrollableState* GetScrollable() override
    # so the new _ImGui_GetScroll* / _ImGui_SetScroll* helpers can route to it
    # without dynamic_cast. The generator's conditional_children_always_end
    # template doesn't have a hook to inject scroll Consume/Latch calls between
    # the children walk and EndChild. ChildWidget is now hand-written in
    # src/window_widget.{h,cpp} (right next to WindowWidget, with which it
    # shares the ScrollableState struct).
    Container(
        # D.7 added `flags` (ImGuiTabBarFlags) on the BeginTabBar call.
        # TabBar still fits the conditional_pair template (no pending state).
        "TabBar", "ImGui_CreateTabBar", "BeginTabBar",
        [_P_TABBAR_FLAGS],
        "ImGui::BeginTabBar(id.c_str(), flags)",
        "ImGui::EndTabBar()",
        "conditional_pair",
    ),
    # NOTE: TabItem used to live here as a generated container, but Phase D.7
    # added :
    #   - the optional X close button via the p_open overload, reusing
    #     Widget::visible as bool* (cf. CollapsingHeader closable in D.6)
    #   - constructor `int flags` (ImGuiTabItemFlags)
    #   - per-widget pending SetTabItemClosed (consumed before BeginTabItem
    #     by the FIRST line of the next Render, still inside the parent
    #     TabBar's Begin/End block)
    # Plus a brand-new TabItemButtonWidget (clickable inline tab, no body).
    # All hand-written in src/tab_extras.{h,cpp}.
    # NOTE: CollapsingHeader and TreeNode used to live here as generated
    # containers, but Phase D.6 added :
    #   - an optional `closable` (X close button via the p_visible overload)
    #     on CollapsingHeader, using Widget::visible as the bool*
    #   - a constructor `int flags` (ImGuiTreeNodeFlags) on both
    #   - per-widget pending state (ImGui::SetNextItemOpen consumed at the
    #     start of the next Render)
    #   - the IsItemToggledOpen latch + a routed `ImGui_IsToggledOpen` query
    # None of that fits the four template_kinds of the container generator.
    # Both are now hand-written in src/tree_extras.{h,cpp}.
    Container(
        # always_pair emits begin_call as a statement, so a void return is fine.
        "Group", "ImGui_CreateGroup", "BeginGroup",
        [],
        "ImGui::BeginGroup()",
        "ImGui::EndGroup()",
        "always_pair",
    ),
    # NOTE: WindowWidget used to live here as a generated container, but Phase
    # D.3 added pending-state setters (pos/size/collapsed/focus/bg_alpha/size
    # constraints) + window-level latched queries (is_appearing/collapsed/
    # focused/hovered/pos/size). Those don't fit the four template_kinds of the
    # container generator. WindowWidget is now hand-written in src/window_widget.{h,cpp}.
    Container(
        # MenuBar lives inside a Window that was created with
        # ImGuiWindowFlags_MenuBar (1024).
        "MenuBar", "ImGui_CreateMenuBar", "BeginMenuBar",
        [],
        "ImGui::BeginMenuBar()",
        "ImGui::EndMenuBar()",
        "conditional_pair",
    ),
    Container(
        # MainMenuBar (D.5) â€” global menu bar at the top of the main viewport.
        # Unlike MenuBar (which lives inside a Window with MenuBar flag), this
        # is standalone and must be called OUTSIDE any Begin/End block. We
        # mark it `is_main_menu_bar` so the render thread renders it in a
        # PRE-pass before the host : BeginMainMenuBar reserves space at the
        # top of the main viewport via WorkOffsetMin, so the host (positioned
        # at viewport->WorkPos) automatically slots below the menu bar â€” no
        # more overlap with our custom title bar.
        "MainMenuBar", "ImGui_CreateMainMenuBar", "BeginMainMenuBar",
        [],
        "ImGui::BeginMainMenuBar()",
        "ImGui::EndMainMenuBar()",
        "conditional_pair",
        is_main_menu_bar=True,
    ),
    Container(
        "Menu", "ImGui_CreateMenu", "BeginMenu",
        [],
        "ImGui::BeginMenu(label.empty() ? id.c_str() : label.c_str())",
        "ImGui::EndMenu()",
        "conditional_pair",
    ),
]


CONTAINER_HEADER_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#pragma once
#include "widget.h"

"""

CONTAINER_IMPL_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include "generated/widgets_container.h"
#include "imgui.h"

"""

CONTAINER_API_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include <Windows.h>
#include <memory>
#include <string>
#include "widget_tree.h"
#include "utf.h"
#include "generated/widgets_container.h"

#define API_EXPORT extern "C" __declspec(dllexport)

"""


def _container_struct(c: Container) -> str:
    fields  = "".join(f"    {p.cpp_type} {p.cpp_name} = {p.cpp_default};\n" for p in c.params)
    extra   = ""
    if c.is_top_level_window:
        extra += "    bool IsTopLevelWindow() const override { return true; }\n"
    if c.is_main_menu_bar:
        extra += "    bool IsMainMenuBar() const override { return true; }\n"
    return (
        f"// Container â€” walks children between {c.begin_call.split('(')[0]} / "
        f"{c.end_call.split('(')[0] if c.end_call else '(no end)'} ({c.template_kind}).\n"
        f"struct {c.name}Widget : Widget {{\n"
        f"{fields}"
        f"    void Render() override;\n"
        f"{extra}"
        f"}};\n\n"
    )


def _container_render(c: Container) -> str:
    if c.template_kind == "always_pair":
        body = (
            f"    {c.begin_call};\n"
            f"    for (auto& child : children) child->RenderAndQueryState();\n"
            f"    {c.end_call};\n"
        )
    elif c.template_kind == "conditional_pair":
        body = (
            f"    if ({c.begin_call}) {{\n"
            f"        for (auto& child : children) child->RenderAndQueryState();\n"
            f"        {c.end_call};\n"
            f"    }}\n"
        )
    elif c.template_kind == "conditional_children_always_end":
        # Begin returns bool; render children only when true; End is ALWAYS
        # called (Window/Child semantics).
        body = (
            f"    if ({c.begin_call}) {{\n"
            f"        for (auto& child : children) child->RenderAndQueryState();\n"
            f"    }}\n"
            f"    {c.end_call};\n"
        )
    elif c.template_kind == "conditional_no_end":
        body = (
            f"    if ({c.begin_call}) {{\n"
            f"        for (auto& child : children) child->RenderAndQueryState();\n"
            f"    }}\n"
        )
    else:
        raise ValueError(f"unknown template_kind {c.template_kind}")
    return (
        f"void {c.name}Widget::Render()\n"
        f"{{\n"
        f"    if (!visible) return;\n"
        f"{body}"
        f"}}\n\n"
    )


def _container_api(c: Container) -> str:
    sig_params = "".join(f", {p.cpp_type} {p.cpp_name}" for p in c.params)
    # NB: local is named `widget` (not `w`) to avoid shadowing the `float w`
    # parameter on Child / any future container param called `w`/`h`/etc.
    assigns    = "".join(f"    widget->{p.cpp_name} = {p.cpp_name};\n" for p in c.params)
    # Containers like TabItem/CollapsingHeader/TreeNode show a label â€” accept
    # an optional label param. Child/TabBar/Group don't need one; we accept
    # one anyway for a uniform signature, no extra cost.
    return (
        f"API_EXPORT int __cdecl {c.autoit_create}(const wchar_t* id, const wchar_t* label{sig_params})\n"
        f"{{\n"
        f"    if (!id || !*id) return 1;\n"
        f"    std::string uid  = WideToUtf8(id);\n"
        f"    std::string ulbl = WideToUtf8(label ? label : L\"\");\n"
        f"    if (uid.empty()) return 1;\n"
        f"    auto widget = std::make_unique<{c.name}Widget>();\n"
        f"    widget->id    = uid;\n"
        f"    widget->label = ulbl;\n"
        f"{assigns}"
        f"    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);\n"
        f"    return g_tree.Add(std::move(widget)) ? 0 : 2;\n"
        f"}}\n\n"
    )


_CONTAINER_DESC = {
    "ImGui_CreateChild":        "Create a Child region (scrollable inline sub-area)",
    "ImGui_CreateTabBar":       "Create a TabBar container (holds TabItem children)",
    "ImGui_CreateGroup":        "Create a Group container (treats children as a single item)",
    "ImGui_CreateMenuBar":      "Create a MenuBar container (must be inside a Window)",
    "ImGui_CreateMainMenuBar":  "Create the main viewport menu bar (top of the screen)",
    "ImGui_CreateMenu":         "Create a Menu (drop-down within a MenuBar)",
}


def _container_au3(c: Container) -> str:
    au_params = "".join(f", {p.au3_var} = {p.au3_default}" for p in c.params)
    call_args = "".join(f', "{p.au3_type}", {p.au3_var}' for p in c.params)
    desc = _CONTAINER_DESC.get(c.autoit_create, f"Create a {c.imgui_check} container widget")
    sig_params = "".join(f", {p.au3_var} = {p.au3_default}" for p in c.params)
    syntax = f'_{c.autoit_create}($sId[, $sLabel = ""{sig_params}])'
    doc_params = [("$sId", None), ("$sLabel", None)] + [(p.au3_var, None) for p in c.params]
    header = _au3_func_header(
        name=f"_{c.autoit_create}",
        description=desc,
        syntax=syntax,
        params=doc_params,
        information="Attach children with _ImGui_SetParent($sChildId, $sId).",
    )
    return (
        header +
        f'Func _{c.autoit_create}($sId, $sLabel = ""{au_params})\n'
        f'    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)\n'
        f'    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{c.autoit_create}", "wstr", $sId, "wstr", $sLabel{call_args})\n'
        f'    If @error Then Return SetError(2, @error, False)\n'
        f'    Return ($aRet[0] = 0)\n'
        f'EndFunc\n\n'
    )


def emit_container_header() -> str:
    return CONTAINER_HEADER_PROLOG + "".join(_container_struct(c) for c in CONTAINER)


def emit_container_impl() -> str:
    return CONTAINER_IMPL_PROLOG + "".join(_container_render(c) for c in CONTAINER)


def emit_container_api() -> str:
    return CONTAINER_API_PROLOG + "".join(_container_api(c) for c in CONTAINER)


def emit_container_au3() -> str:
    return "; --- container ---\n\n" + "".join(_container_au3(c) for c in CONTAINER)


# =============================================================================
# Category: "text"
# =============================================================================
#
# Variants of the basic Text widget : colored, wrapped, disabled, bulleted,
# separator-with-label, and key:value (LabelText). Each stores the display
# string in Widget::label (mutable via _ImGui_SetText) plus optional creation-
# time params (color rgba for TextColored ; "extra" string holding the key
# part for LabelText). The render body is a single ImGui call with %s formatting
# to avoid printf-style parsing of user-provided strings.

@dataclass
class Text:
    imgui_name:    str   # widget class prefix (e.g. "TextColored")
    autoit_create: str   # export function name
    imgui_check:   str   # name to look up in imgui.h
    has_color:     bool  # 4 float params r,g,b,a stored on widget
    is_label_text: bool  # extra std::string "extra" (the key on the right)
    render_call:   str   # exact ImGui call body â€” uses fields by name


TEXT: list[Text] = [
    Text("TextColored",   "ImGui_CreateTextColored",   "TextColored",   True,  False,
         'ImGui::TextColored(ImVec4(r, g, b, a), "%s", label.c_str())'),
    Text("TextWrapped",   "ImGui_CreateTextWrapped",   "TextWrapped",   False, False,
         'ImGui::TextWrapped("%s", label.c_str())'),
    Text("TextDisabled",  "ImGui_CreateTextDisabled",  "TextDisabled",  False, False,
         'ImGui::TextDisabled("%s", label.c_str())'),
    Text("BulletText",    "ImGui_CreateBulletText",    "BulletText",    False, False,
         'ImGui::BulletText("%s", label.c_str())'),
    Text("SeparatorText", "ImGui_CreateSeparatorText", "SeparatorText", False, False,
         'ImGui::SeparatorText(label.c_str())'),
    Text("LabelText",     "ImGui_CreateLabelText",     "LabelText",     False, True,
         'ImGui::LabelText(extra.c_str(), "%s", label.c_str())'),
]


TEXT_HEADER_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#pragma once
#include "widget.h"
#include <string>

"""

TEXT_IMPL_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include "generated/widgets_text.h"
#include "imgui.h"

"""

TEXT_API_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include <Windows.h>
#include <memory>
#include <string>
#include "widget_tree.h"
#include "utf.h"
#include "generated/widgets_text.h"

#define API_EXPORT extern "C" __declspec(dllexport)

"""


def _text_struct(t: Text) -> str:
    fields = ""
    if t.has_color:
        fields  += "    float r = 1.0f, g = 1.0f, b = 1.0f, a = 1.0f;\n"
    if t.is_label_text:
        fields  += "    std::string extra;\n"
    return (
        f"// Wraps ImGui::{t.imgui_name}.\n"
        f"struct {t.imgui_name}Widget : Widget {{\n"
        f"{fields}"
        f"    void Render() override;\n"
        f"}};\n\n"
    )


def _text_render(t: Text) -> str:
    return (
        f"void {t.imgui_name}Widget::Render()\n"
        f"{{\n"
        f"    if (!visible) return;\n"
        f"    {t.render_call};\n"
        f"}}\n\n"
    )


def _text_api(t: Text) -> str:
    sig_extra    = ""
    body_extra   = ""
    if t.has_color:
        sig_extra  = ", float r, float g, float b, float a"
        body_extra = "    w->r = r; w->g = g; w->b = b; w->a = a;\n"
    if t.is_label_text:
        sig_extra  = ", const wchar_t* extra_key"
        body_extra = "    w->extra = WideToUtf8(extra_key ? extra_key : L\"\");\n"
    return (
        f"API_EXPORT int __cdecl {t.autoit_create}(const wchar_t* id, const wchar_t* text{sig_extra})\n"
        f"{{\n"
        f"    if (!id || !*id) return 1;\n"
        f"    std::string uid  = WideToUtf8(id);\n"
        f"    std::string utxt = WideToUtf8(text ? text : L\"\");\n"
        f"    if (uid.empty()) return 1;\n"
        f"    auto w = std::make_unique<{t.imgui_name}Widget>();\n"
        f"    w->id = uid; w->label = utxt;\n"
        f"{body_extra}"
        f"    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);\n"
        f"    return g_tree.Add(std::move(w)) ? 0 : 2;\n"
        f"}}\n\n"
    )


_TEXT_DESC = {
    "ImGui_CreateTextColored":   "Create a colored Text widget (RGBA tint)",
    "ImGui_CreateTextWrapped":   "Create a Text widget that wraps at the available width",
    "ImGui_CreateTextDisabled":  "Create a Text widget rendered with disabled style",
    "ImGui_CreateLabelText":     "Create a key/value Text widget (value left, key right)",
    "ImGui_CreateBulletText":    "Create a bulleted Text widget",
    "ImGui_CreateSeparatorText": "Create a separator line with embedded text",
}


def _text_au3(t: Text) -> str:
    desc = _TEXT_DESC.get(t.autoit_create, f"Create a {t.imgui_check} text widget")
    if t.has_color:
        header = _au3_func_header(
            name=f"_{t.autoit_create}",
            description=desc,
            syntax=f'_{t.autoit_create}($sId, $sText[, $fR = 1.0, $fG = 1.0, $fB = 1.0, $fA = 1.0])',
            params=[("$sId", None), ("$sText", None),
                    ("$fR", None), ("$fG", None), ("$fB", None), ("$fA", None)],
            information="Update the text content later via _ImGui_SetText.",
        )
        return (
            header +
            f'Func _{t.autoit_create}($sId, $sText, $fR = 1.0, $fG = 1.0, $fB = 1.0, $fA = 1.0)\n'
            f'    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)\n'
            f'    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{t.autoit_create}", _\n'
            f'        "wstr", $sId, "wstr", $sText, _\n'
            f'        "float", $fR, "float", $fG, "float", $fB, "float", $fA)\n'
            f'    If @error Then Return SetError(2, @error, False)\n'
            f'    Return ($aRet[0] = 0)\n'
            f'EndFunc\n\n'
        )
    if t.is_label_text:
        # LabelText layout : value is on the LEFT (the formatted "%s" part),
        # key is on the RIGHT (passed as ImGui's `label` arg). Param order
        # in the wrapper follows the natural reading order : value first
        # (mutable via SetText), then key.
        header = _au3_func_header(
            name=f"_{t.autoit_create}",
            description=desc,
            syntax=f'_{t.autoit_create}($sId, $sValue[, $sKey = ""])',
            params=[("$sId", None), ("$sValue", None), ("$sKey", None)],
            information="Update the value later via _ImGui_SetText($sId, $sNewValue).",
        )
        return (
            header +
            f'Func _{t.autoit_create}($sId, $sValue, $sKey = "")\n'
            f'    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)\n'
            f'    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{t.autoit_create}", _\n'
            f'        "wstr", $sId, "wstr", $sValue, "wstr", $sKey)\n'
            f'    If @error Then Return SetError(2, @error, False)\n'
            f'    Return ($aRet[0] = 0)\n'
            f'EndFunc\n\n'
        )
    header = _au3_func_header(
        name=f"_{t.autoit_create}",
        description=desc,
        syntax=f'_{t.autoit_create}($sId, $sText)',
        params=[("$sId", None), ("$sText", None)],
        information="Update the text content later via _ImGui_SetText.",
    )
    return (
        header +
        f'Func _{t.autoit_create}($sId, $sText)\n'
        f'    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)\n'
        f'    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{t.autoit_create}", _\n'
        f'        "wstr", $sId, "wstr", $sText)\n'
        f'    If @error Then Return SetError(2, @error, False)\n'
        f'    Return ($aRet[0] = 0)\n'
        f'EndFunc\n\n'
    )


def emit_text_header() -> str:
    return TEXT_HEADER_PROLOG + "".join(_text_struct(t) for t in TEXT)


def emit_text_impl() -> str:
    return TEXT_IMPL_PROLOG + "".join(_text_render(t) for t in TEXT)


def emit_text_api() -> str:
    return TEXT_API_PROLOG + "".join(_text_api(t) for t in TEXT)


def emit_text_au3() -> str:
    return "; --- text ---\n\n" + "".join(_text_au3(t) for t in TEXT)


# =============================================================================
# Category: "color"
# =============================================================================
#
# ColorEdit3/4 (3- or 4-component RGB[A] editor with inline preview) and
# ColorPicker3/4 (popup picker with hue/saturation/value sliders, etc.). All
# inherit FloatVec3/4ValueWidget so the same _ImGui_GetValueFloatN /
# _ImGui_SetValueFloatN exports work. Each widget stores `flags` as a constant-
# at-creation int (ImGuiColorEditFlags).
#
# ColorButton is hand-written (clickable display widget, different paradigm).

@dataclass
class Color:
    imgui_name:    str   # "ColorEdit3", "ColorPicker4", ...
    autoit_create: str
    n:             int   # 3 or 4


COLOR: list[Color] = [
    Color("ColorEdit3",   "ImGui_CreateColorEdit3",   3),
    Color("ColorEdit4",   "ImGui_CreateColorEdit4",   4),
    Color("ColorPicker3", "ImGui_CreateColorPicker3", 3),
    Color("ColorPicker4", "ImGui_CreateColorPicker4", 4),
]


COLOR_HEADER_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#pragma once
#include "widget.h"

"""

COLOR_IMPL_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include "generated/widgets_color.h"
#include "imgui.h"

"""

COLOR_API_PROLOG = """\
// Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
#include <Windows.h>
#include <memory>
#include <string>
#include "widget_tree.h"
#include "utf.h"
#include "generated/widgets_color.h"

#define API_EXPORT extern "C" __declspec(dllexport)

"""


def _color_struct(c: Color) -> str:
    return (
        f"// Wraps ImGui::{c.imgui_name}(label, float[{c.n}], flags).\n"
        f"struct {c.imgui_name}Widget : FloatVec{c.n}ValueWidget {{\n"
        f"    int flags = 0;\n"
        f"    void Render() override;\n"
        f"}};\n\n"
    )


def _color_render(c: Color) -> str:
    return (
        f"void {c.imgui_name}Widget::Render()\n"
        f"{{\n"
        f"    if (!visible) return;\n"
        f"    if (!enabled) ImGui::BeginDisabled();\n"
        f"    ImGui::PushID(id.c_str());\n"
        f"    const char* shown = label.empty() ? id.c_str() : label.c_str();\n"
        f"    if (ImGui::{c.imgui_name}(shown, values, static_cast<ImGuiColorEditFlags>(flags))) {{\n"
        f"        changed = true;\n"
        f"    }}\n"
        f"    ImGui::PopID();\n"
        f"    if (!enabled) ImGui::EndDisabled();\n"
        f"}}\n\n"
    )


def _color_api(c: Color) -> str:
    default_sig    = ", ".join(f"float default_{i}" for i in range(c.n))
    default_assign = "".join(f"    w->values[{i}] = default_{i};\n" for i in range(c.n))
    return (
        f"API_EXPORT int __cdecl {c.autoit_create}(const wchar_t* id, const wchar_t* label,\n"
        f"                                {default_sig}, int flags)\n"
        f"{{\n"
        f"    if (!id || !*id) return 1;\n"
        f"    std::string uid  = WideToUtf8(id);\n"
        f"    std::string ulbl = WideToUtf8(label ? label : L\"\");\n"
        f"    if (uid.empty()) return 1;\n"
        f"    auto w = std::make_unique<{c.imgui_name}Widget>();\n"
        f"    w->id = uid; w->label = ulbl;\n"
        f"{default_assign}"
        f"    w->flags = flags;\n"
        f"    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);\n"
        f"    return g_tree.Add(std::move(w)) ? 0 : 2;\n"
        f"}}\n\n"
    )


_COLOR_DESC = {
    "ImGui_CreateColorEdit3":   "Create a ColorEdit3 widget (RGB color edit field)",
    "ImGui_CreateColorEdit4":   "Create a ColorEdit4 widget (RGBA color edit field)",
    "ImGui_CreateColorPicker3": "Create a ColorPicker3 widget (RGB color picker)",
    "ImGui_CreateColorPicker4": "Create a ColorPicker4 widget (RGBA color picker)",
}


def _color_au3(c: Color) -> str:
    defaults_au3 = ", ".join(f"$f{ch} = {default}" for ch, default in
                              zip("RGBA"[:c.n], ["1.0", "1.0", "1.0", "1.0"][:c.n]))
    defaults_call = ", _\n        ".join(f'"float", $f{ch}' for ch in "RGBA"[:c.n])
    desc = _COLOR_DESC.get(c.autoit_create, f"Create a {c.imgui_name} color widget")
    chan_params = [(f"$f{ch}", None) for ch in "RGBA"[:c.n]]
    params = [("$sId", None), ("$sLabel", None)] + chan_params + [("$iFlags", None)]
    syntax_chans = ", ".join(f"$f{ch} = 1.0" for ch in "RGBA"[:c.n])
    header = _au3_func_header(
        name=f"_{c.autoit_create}",
        description=desc,
        syntax=f'_{c.autoit_create}($sId[, $sLabel = "", {syntax_chans}, $iFlags = 0])',
        params=params,
        information=f"Read/write the {c.n}-component value with _ImGui_GetValueFloatN/_ImGui_SetValueFloatN.",
    )
    return (
        header +
        f'Func _{c.autoit_create}($sId, $sLabel = "", {defaults_au3}, $iFlags = 0)\n'
        f'    If $__g_hImGuiDll = -1 Then Return SetError(1, 0, False)\n'
        f'    If $sLabel = "" Then $sLabel = $sId\n'
        f'    Local $aRet = DllCall($__g_hImGuiDll, "int:cdecl", "{c.autoit_create}", _\n'
        f'        "wstr", $sId, "wstr", $sLabel, _\n'
        f'        {defaults_call}, _\n'
        f'        "int", $iFlags)\n'
        f'    If @error Then Return SetError(2, @error, False)\n'
        f'    Return ($aRet[0] = 0)\n'
        f'EndFunc\n\n'
    )


def emit_color_header() -> str:
    return COLOR_HEADER_PROLOG + "".join(_color_struct(c) for c in COLOR)


def emit_color_impl() -> str:
    return COLOR_IMPL_PROLOG + "".join(_color_render(c) for c in COLOR)


def emit_color_api() -> str:
    return COLOR_API_PROLOG + "".join(_color_api(c) for c in COLOR)


def emit_color_au3() -> str:
    return "; --- color ---\n\n" + "".join(_color_au3(c) for c in COLOR)


# =============================================================================
# AutoIt wrapper aggregation
# =============================================================================

AU3_PROLOG = """\
#include-once
; =============================================================================
; imgui_generated.au3
; Auto-generated by tools/generate.py â€” DO NOT EDIT BY HAND.
;
; Assumes imgui_retained.au3 has been #include'd so $__g_hImGuiDll is defined.
; Generic getters/setters (_ImGui_GetValueBool, _ImGui_SetValueBool,
; _ImGui_HasChanged, _ImGui_WasClicked, â€¦) are hand-written in
; imgui_retained.au3 â€” only Create* wrappers are generated here, one block
; per widget category.
; =============================================================================

"""


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

def main() -> int:
    if not IMGUI_H.exists():
        print(f"ERROR: cannot find imgui.h at {IMGUI_H}", file=sys.stderr)
        return 1

    decls = parse_imgui_h(IMGUI_H)
    print(f"Parsed {len(decls)} IMGUI_API declarations from {IMGUI_H.name}")

    # Sanity check: every widget we intend to generate must exist in imgui.h.
    missing: list[str] = []
    for c in CLICKABLE:
        if not find_decl(decls, c.imgui_name): missing.append(c.imgui_name)
    for c in VALUE_BOOL:
        if not find_decl(decls, c.imgui_name): missing.append(c.imgui_name)
    for c in SLIDER + DRAG + INPUT:
        if not find_decl(decls, c.imgui_name): missing.append(c.imgui_name)
    for c in DISPLAY:
        if not find_decl(decls, c.imgui_name): missing.append(c.imgui_name)
    for c in CONFIG:
        if not find_decl(decls, c.imgui_check): missing.append(c.imgui_check)
    for c in CONTAINER:
        if not find_decl(decls, c.imgui_check): missing.append(c.imgui_check)
    for c in TEXT:
        if not find_decl(decls, c.imgui_check): missing.append(c.imgui_check)
    for c in COLOR:
        if not find_decl(decls, c.imgui_name): missing.append(c.imgui_name)
    if missing:
        print(f"ERROR: missing in imgui.h: {missing}", file=sys.stderr)
        return 2

    SRC_GEN.mkdir(parents=True, exist_ok=True)

    # --- clickable ---
    (SRC_GEN / "widgets_clickable.h"  ).write_text(emit_clickable_header(CLICKABLE), encoding="utf-8")
    (SRC_GEN / "widgets_clickable.cpp").write_text(emit_clickable_impl  (CLICKABLE), encoding="utf-8")
    (SRC_GEN / "dll_api_clickable.cpp").write_text(emit_clickable_api   (CLICKABLE), encoding="utf-8")
    print(f"  -> {SRC_GEN / 'widgets_clickable.h'}")
    print(f"  -> {SRC_GEN / 'widgets_clickable.cpp'}")
    print(f"  -> {SRC_GEN / 'dll_api_clickable.cpp'}")

    # --- value_bool ---
    (SRC_GEN / "widgets_value_bool.h"  ).write_text(emit_value_bool_header(VALUE_BOOL), encoding="utf-8")
    (SRC_GEN / "widgets_value_bool.cpp").write_text(emit_value_bool_impl  (VALUE_BOOL), encoding="utf-8")
    (SRC_GEN / "dll_api_value_bool.cpp").write_text(emit_value_bool_api   (VALUE_BOOL), encoding="utf-8")
    print(f"  -> {SRC_GEN / 'widgets_value_bool.h'}")
    print(f"  -> {SRC_GEN / 'widgets_value_bool.cpp'}")
    print(f"  -> {SRC_GEN / 'dll_api_value_bool.cpp'}")

    # --- value_numeric ---
    (SRC_GEN / "widgets_value_numeric.h"  ).write_text(emit_value_numeric_header(), encoding="utf-8")
    (SRC_GEN / "widgets_value_numeric.cpp").write_text(emit_value_numeric_impl  (), encoding="utf-8")
    (SRC_GEN / "dll_api_value_numeric.cpp").write_text(emit_value_numeric_api   (), encoding="utf-8")
    print(f"  -> {SRC_GEN / 'widgets_value_numeric.h'}")
    print(f"  -> {SRC_GEN / 'widgets_value_numeric.cpp'}")
    print(f"  -> {SRC_GEN / 'dll_api_value_numeric.cpp'}")

    # --- display ---
    (SRC_GEN / "widgets_display.h"  ).write_text(emit_display_header(), encoding="utf-8")
    (SRC_GEN / "widgets_display.cpp").write_text(emit_display_impl  (), encoding="utf-8")
    (SRC_GEN / "dll_api_display.cpp").write_text(emit_display_api   (), encoding="utf-8")
    print(f"  -> {SRC_GEN / 'widgets_display.h'}")
    print(f"  -> {SRC_GEN / 'widgets_display.cpp'}")
    print(f"  -> {SRC_GEN / 'dll_api_display.cpp'}")

    # --- config ---
    (SRC_GEN / "widgets_config.h"  ).write_text(emit_config_header(), encoding="utf-8")
    (SRC_GEN / "widgets_config.cpp").write_text(emit_config_impl  (), encoding="utf-8")
    (SRC_GEN / "dll_api_config.cpp").write_text(emit_config_api   (), encoding="utf-8")
    print(f"  -> {SRC_GEN / 'widgets_config.h'}")
    print(f"  -> {SRC_GEN / 'widgets_config.cpp'}")
    print(f"  -> {SRC_GEN / 'dll_api_config.cpp'}")

    # --- container ---
    (SRC_GEN / "widgets_container.h"  ).write_text(emit_container_header(), encoding="utf-8")
    (SRC_GEN / "widgets_container.cpp").write_text(emit_container_impl  (), encoding="utf-8")
    (SRC_GEN / "dll_api_container.cpp").write_text(emit_container_api   (), encoding="utf-8")
    print(f"  -> {SRC_GEN / 'widgets_container.h'}")
    print(f"  -> {SRC_GEN / 'widgets_container.cpp'}")
    print(f"  -> {SRC_GEN / 'dll_api_container.cpp'}")

    # --- text ---
    (SRC_GEN / "widgets_text.h"  ).write_text(emit_text_header(), encoding="utf-8")
    (SRC_GEN / "widgets_text.cpp").write_text(emit_text_impl  (), encoding="utf-8")
    (SRC_GEN / "dll_api_text.cpp").write_text(emit_text_api   (), encoding="utf-8")
    print(f"  -> {SRC_GEN / 'widgets_text.h'}")
    print(f"  -> {SRC_GEN / 'widgets_text.cpp'}")
    print(f"  -> {SRC_GEN / 'dll_api_text.cpp'}")

    # --- color ---
    (SRC_GEN / "widgets_color.h"  ).write_text(emit_color_header(), encoding="utf-8")
    (SRC_GEN / "widgets_color.cpp").write_text(emit_color_impl  (), encoding="utf-8")
    (SRC_GEN / "dll_api_color.cpp").write_text(emit_color_api   (), encoding="utf-8")
    print(f"  -> {SRC_GEN / 'widgets_color.h'}")
    print(f"  -> {SRC_GEN / 'widgets_color.cpp'}")
    print(f"  -> {SRC_GEN / 'dll_api_color.cpp'}")

    # --- aggregated AutoIt wrappers ---
    au3 = (AU3_PROLOG
           + emit_clickable_au3(CLICKABLE)
           + emit_value_bool_au3(VALUE_BOOL)
           + emit_value_numeric_au3()
           + emit_display_au3()
           + emit_config_au3()
           + emit_container_au3()
           + emit_text_au3()
           + emit_color_au3())
    WRAPPER.write_text(au3, encoding="utf-8")
    print(f"  -> {WRAPPER}")

    total = (len(CLICKABLE) + len(VALUE_BOOL)
             + len(SLIDER) + len(DRAG) + len(INPUT)
             + len(DISPLAY) + len(CONFIG) + len(CONTAINER)
             + len(TEXT) + len(COLOR))
    print(f"Generated {total} widgets across 8 categories.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
