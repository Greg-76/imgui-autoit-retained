#pragma once
#include "widget.h"

// H.4 — Image / ImageButton widgets, backed by texture_registry SRVs.
//
// ImageWidget is display-only ; ImageButtonWidget inherits ClickableWidget so
// _ImGui_WasClicked / _ImGui_IsClicked / _ImGui_IsHovered work as expected.
// Both render an ImGui::TextDisabled placeholder when given an invalid tex_id
// (e.g. file failed to load and the caller didn't check) — never crash.

struct ImageWidget : Widget {
    int   tex_id = 0;     // index into texture_registry ; -1 = invalid / placeholder
    float w      = 0.0f;  // rendered size in pixels (0 = use texture's native dims)
    float h      = 0.0f;
    void Render() override;
};

struct ImageButtonWidget : ClickableWidget {
    int   tex_id = 0;
    float w      = 0.0f;
    float h      = 0.0f;
    void Render() override;
};

// M.2 — Image variant with bg_col (drawn UNDER the texture, so visible through
// transparent pixels) + tint_col (multiplicative tint, default (1,1,1,1) = no
// tint). Distinct from ImageWidget because the overload signature is wide
// (4+4 floats) and the underlying ImGui::ImageWithBg lives on its own. uv0/uv1
// are fixed to (0,0)/(1,1) — the full texture — same simplification as
// ImageWidget. Placeholder fallback (Dummy + TextDisabled) when tex_id is
// invalid, mirroring ImageWidget.
struct ImageWithBgWidget : Widget {
    int   tex_id  = 0;
    float w       = 0.0f, h      = 0.0f;
    // bg_col = (0,0,0,0) → fully transparent background = same look as Image().
    float bg_r    = 0.0f, bg_g   = 0.0f, bg_b   = 0.0f, bg_a   = 0.0f;
    // tint_col = (1,1,1,1) → no tint.
    float tint_r  = 1.0f, tint_g = 1.0f, tint_b = 1.0f, tint_a = 1.0f;
    void Render() override;
};
