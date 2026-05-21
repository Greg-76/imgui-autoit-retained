#pragma once
#include "widget.h"

// Phase E.2 — Numeric / Color extras. Six widgets that don't cleanly fit the
// generator templates :
//   - DragFloatRange2 / DragIntRange2 : two values (min, max) tracked together
//     with their own bounds and speed. Distinct from the existing FloatVec2 /
//     IntVec2 mixins which carry a single ImGui call but not range bounds.
//   - SliderAngle : SliderFloat with degree↔radian conversion. Value stored
//     in radians ; min/max bounds expressed in degrees.
//   - VSliderFloat / VSliderInt : vertical slider variants with a size param.
//   - InputTextWithHint : InputText with a placeholder string visible when
//     the buffer is empty.
//   - ColorButton : display-only clickable color swatch.

struct DragFloatRange2Widget : Widget {
    float values[2] = {0.0f, 0.0f};  // [0] = current_min, [1] = current_max
    float v_min     = 0.0f;
    float v_max     = 0.0f;
    float v_speed   = 1.0f;
    std::string format;              // default "%.3f"
    std::string format_max;          // empty = use `format` for both
    int  flags   = 0;                // ImGuiSliderFlags
    bool changed = false;

    int  GetValueFloatN(float* out, int max_n) const override {
        if (!out || max_n < 2) return 0;
        out[0] = values[0]; out[1] = values[1];
        return 2;
    }
    bool SetValueFloatN(const float* in, int n) override {
        if (!in || n != 2) return false;
        values[0] = in[0]; values[1] = in[1];
        return true;
    }
    bool ConsumeChanged() override {
        const bool c = changed;
        changed = false;
        return c;
    }
    void Render() override;
};

struct DragIntRange2Widget : Widget {
    int values[2] = {0, 0};
    int v_min     = 0;
    int v_max     = 0;
    float v_speed = 1.0f;
    std::string format;              // default "%d"
    std::string format_max;
    int  flags   = 0;
    bool changed = false;

    int  GetValueIntN(int* out, int max_n) const override {
        if (!out || max_n < 2) return 0;
        out[0] = values[0]; out[1] = values[1];
        return 2;
    }
    bool SetValueIntN(const int* in, int n) override {
        if (!in || n != 2) return false;
        values[0] = in[0]; values[1] = in[1];
        return true;
    }
    bool ConsumeChanged() override {
        const bool c = changed;
        changed = false;
        return c;
    }
    void Render() override;
};

// Stored value is in radians ; bounds expressed in degrees (ImGui converts).
struct SliderAngleWidget : FloatValueWidget {
    float v_degrees_min = -360.0f;
    float v_degrees_max = +360.0f;
    std::string format;              // default "%.0f deg"
    int  flags = 0;
    void Render() override;
};

struct VSliderFloatWidget : FloatValueWidget {
    float v_min  = 0.0f;
    float v_max  = 1.0f;
    float size_x = 18.0f;            // typical ImGui demo VSlider width
    float size_y = 160.0f;
    std::string format;              // default "%.3f"
    int  flags = 0;
    void Render() override;
};

struct VSliderIntWidget : IntValueWidget {
    int   v_min  = 0;
    int   v_max  = 100;
    float size_x = 18.0f;
    float size_y = 160.0f;
    std::string format;              // default "%d"
    int  flags = 0;
    void Render() override;
};

// Same buffer model as InputTextWidget (allocated at creation, contract on
// ImGui's side). Adds a hint shown when the buffer is empty.
struct InputTextWithHintWidget : StringValueWidget {
    std::string hint;
    void Render() override;
};

// Display-only color swatch with a click event. Stores 4 floats (RGBA).
// Inherits ClickableWidget for the standard click latch ; exposes Get/SetValueFloatN
// so the script can mutate the color via the same FloatN helpers used by
// ColorEdit/Picker. ColorButton itself never writes the color back from ImGui —
// the only user interaction is the click.
struct ColorButtonWidget : ClickableWidget {
    float color[4] = {1.0f, 0.0f, 0.0f, 1.0f};   // default red, opaque
    int   flags = 0;                              // ImGuiColorEditFlags
    float size_x = 0.0f;                          // 0 = ImGui default square
    float size_y = 0.0f;

    int  GetValueFloatN(float* out, int max_n) const override {
        if (!out || max_n < 4) return 0;
        for (int i = 0; i < 4; ++i) out[i] = color[i];
        return 4;
    }
    bool SetValueFloatN(const float* in, int n) override {
        if (!in || n != 4) return false;
        for (int i = 0; i < 4; ++i) color[i] = in[i];
        return true;
    }
    void Render() override;
};
