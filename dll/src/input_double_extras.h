#pragma once
#include "widget.h"
#include <string>

// K.2 — InputDouble : double-precision numeric input. Mirrors InputFloat
// (in the value_numeric generator) but stores a `double` so AutoIt scripts
// can preserve > 7-digit precision (game coordinates, money totals,
// timestamps in seconds since epoch, …).
//
// Hand-written rather than generated because the value_numeric generator's
// template assumes float-backed storage ; double is the only non-float scalar
// we surface, so plumbing it through the generator would be net more code.
struct InputDoubleWidget : DoubleValueWidget {
    double      step      = 0.0;   // 0 = no step buttons
    double      step_fast = 0.0;
    std::string format;            // "%.6f" if empty
    int         flags     = 0;     // ImGuiInputTextFlags_
    void Render() override;
};
