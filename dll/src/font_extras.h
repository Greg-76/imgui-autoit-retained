#pragma once
#include "widget.h"

struct ImFont;   // forward decl — avoid pulling imgui.h here

// H.3 — Font management : runtime load + PushFont/PopFont markers.
//
// Fonts are stored in a process-wide registry (font_extras.cpp anon namespace).
// Index 0 is the default font registered by render_thread::ThreadProc right
// after AddFontFromFileTTF(calibri). Index 1+ are user-loaded fonts via
// _ImGui_LoadFont. The registry is append-only — no FreeFont in the MVP
// because ImFontAtlas can't shrink without invalidating every previously
// returned ImFont*.
//
// Atlas updates : ImGui 1.92 + the DX11 backend's ImGuiBackendFlags_Renderer-
// HasTextures cause AddFontFromFileTTF to update the atlas incrementally on
// the next NewFrame. No manual io.Fonts->Build() or texture rebuild is needed.

namespace font_registry {
    // Register a font at the next index. Returns the assigned id.
    // Caller is responsible for taking g_tree.mtx if called outside init.
    int      Add(ImFont* font);
    // Look up a font by id. Returns nullptr on out-of-range id.
    ImFont*  Get(int id);
    // Total number of registered fonts (includes index 0 = default).
    int      Count();
    // Reset the registry — called only by render_thread::Stop() during teardown
    // so a subsequent Init() starts fresh. Caller must hold g_tree.mtx.
    void     Reset();
}

// Marker widget : pushes a font onto the ImGui stack before subsequent siblings
// render. Pair with a PopFontWidget later in the same parent's children list.
// Unbalanced Push/Pop = ImGui asserts at end-of-frame.
struct PushFontWidget : Widget {
    int font_id = 0;   // index into the font registry
    void Render() override;
};

// Marker widget : pops the top of the font stack. No params.
struct PopFontWidget : Widget {
    void Render() override;
};
