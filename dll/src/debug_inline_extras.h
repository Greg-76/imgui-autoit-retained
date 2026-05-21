#pragma once
#include "widget.h"
#include <string>

// L.1 + L.4 — Inline debug / informational helpers. Lumped together because
// they share the "static label + ImGui side-effect inside Render()" shape ;
// each is one or two lines of C++. Hand-written rather than generator-emitted
// because the generator's display category doesn't support string parameters
// (only int/float/bool today).

// L.1 — ImGui::ShowStyleSelector(label) : renders a combo that switches
// between the three built-in styles (Dark/Light/Classic) when the user picks
// one. Pure ImGui side-effect — no AutoIt callback needed.
struct ShowStyleSelectorWidget : Widget {
    void Render() override;
};

// L.1 — ImGui::ShowFontSelector(label) : renders a combo that PushFont's the
// selected font for all subsequent rendering this frame. Useful as a debug
// toggle but persistence across frames requires the user to make the choice
// stick via ImGui's own state (no AutoIt-side persistence needed).
struct ShowFontSelectorWidget : Widget {
    void Render() override;
};

// L.1 — ImGui::ShowUserGuide() : static block of keyboard-shortcut hints.
// Zero-arg.
struct ShowUserGuideWidget : Widget {
    void Render() override;
};

// L.4 — Value(prefix, bool) helper. Bool stored on the widget ; updated via
// _ImGui_SetValueBool (inherited routing through the polymorphic virtual).
struct ValueBoolWidget : BoolValueWidget {
    void Render() override;
};

// L.4 — Value(prefix, int) helper.
struct ValueIntWidget : IntValueWidget {
    void Render() override;
};

// L.4 — Value(prefix, float, format). Format default "%.3f" if empty.
struct ValueFloatWidget : FloatValueWidget {
    std::string fmt;
    void Render() override;
};
