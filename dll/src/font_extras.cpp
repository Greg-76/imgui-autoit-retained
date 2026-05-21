// H.3 — Font management.
//
// Architecture :
//   - g_fonts (anon ns)         : append-only list of ImFont* — index 0 is
//                                  the default font registered by render_thread
//                                  at init, indices 1+ come from _ImGui_LoadFont.
//   - font_registry::Add/Get    : registry accessors used by the marker widgets
//                                  and render_thread.cpp.
//   - PushFontWidget::Render()  : ImGui::PushFont(font) with the registered ptr.
//   - PopFontWidget::Render()   : ImGui::PopFont().
//   - ImGui_LoadFont            : C-ABI export, runs on the AutoIt thread under
//                                  the recursive frame lock. Calls AddFontFromFileTTF
//                                  which is safe between frames (the frame lock
//                                  guarantees the render thread is not mid-NewFrame).
//                                  ImGui 1.92 + RendererHasTextures (set by the
//                                  DX11 backend) → atlas is incrementally updated
//                                  on the next NewFrame, no manual rebuild.

#include "font_extras.h"

#include <Windows.h>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

// Shutdown guard — same shape as the one in utils_extras.cpp. Defined here
// locally so font_extras.cpp doesn't depend on utils_extras' translation unit.
#define BAIL_IF_NO_IMGUI_CTX(safe_return) \
    do { if (!ImGui::GetCurrentContext()) { return safe_return; } } while (0)

namespace {
    std::vector<ImFont*> g_fonts;
}

namespace font_registry {

int Add(ImFont* font)
{
    g_fonts.push_back(font);
    return static_cast<int>(g_fonts.size()) - 1;
}

ImFont* Get(int id)
{
    if (id < 0 || id >= static_cast<int>(g_fonts.size())) return nullptr;
    return g_fonts[id];
}

int Count()
{
    return static_cast<int>(g_fonts.size());
}

void Reset()
{
    // The ImFont* pointers belong to ImGui's ImFontAtlas — DestroyContext
    // frees them. We just drop our copy of the index → pointer map.
    g_fonts.clear();
}

} // namespace font_registry

// ---- Marker widgets --------------------------------------------------------

void PushFontWidget::Render()
{
    if (!visible) return;
    ImFont* f = font_registry::Get(font_id);
    if (!f) {
        // Unknown id : push the default font (index 0) as a safe fallback so
        // the matching PopFont still has something to pop. Avoids stack
        // imbalance assertions if the user passed a bad id.
        f = font_registry::Get(0);
        if (!f) return;   // no default loaded either — give up silently
    }
    ImGui::PushFont(f, 0.0f);   // size 0 = use the font's native pixel size
}

void PopFontWidget::Render()
{
    if (!visible) return;
    ImGui::PopFont();
}

// ---- C-ABI exports ---------------------------------------------------------

// _ImGui_LoadFont($sPath, $fSize) → returns 0 = OK with font_id written to
// out_font_id ; non-zero error code = no font registered. Errors :
//   1 = bad args (path null/empty, size <= 0, out_font_id null)
//   2 = AddFontFromFileTTF returned null (file missing, invalid TTF, ...)
//   6 = ImGui context destroyed (shutting down)
API_EXPORT int __cdecl ImGui_LoadFont(const wchar_t* path, float size_px, int* out_font_id)
{
    if (!path || !*path || size_px <= 0.0f || !out_font_id) return 1;
    std::string utf8_path = WideToUtf8(path);
    if (utf8_path.empty()) return 1;

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);

    ImGuiIO& io = ImGui::GetIO();
    // AddFontFromFileTTF without explicit glyph range = ImGui default (Latin).
    // Sufficient for typical UI panels ; non-Latin scripts can be added later
    // via a glyph-range variant if needed.
    ImFont* font = io.Fonts->AddFontFromFileTTF(utf8_path.c_str(), size_px);
    if (!font) return 2;
    *out_font_id = font_registry::Add(font);
    return 0;
}

API_EXPORT int __cdecl ImGui_GetFontCount(void)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return font_registry::Count();
}

// ---- K.3 — Font extras -----------------------------------------------------

// K.3 — LoadFontEx with explicit glyph range selection. $iGlyphRange follows
// the wrapper-side ImGuiFontGlyphRange_ enum (0=Default Latin .. 8=Thai).
// Same return shape as ImGui_LoadFont.
API_EXPORT int __cdecl ImGui_LoadFontEx(const wchar_t* path, float size_px,
                                          int glyph_range, int* out_font_id)
{
    if (!path || !*path || size_px <= 0.0f || !out_font_id) return 1;
    std::string utf8_path = WideToUtf8(path);
    if (utf8_path.empty()) return 1;

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);

    ImGuiIO& io = ImGui::GetIO();
    const ImWchar* range = nullptr;   // null = default Latin (AddFontFromFileTTF
                                       // picks ImGui's built-in default when no
                                       // glyph range is passed).
    switch (glyph_range) {
        case 0: range = nullptr; break;                                       // Default
        case 1: range = io.Fonts->GetGlyphRangesVietnamese();         break;
        case 2: range = io.Fonts->GetGlyphRangesCyrillic();           break;
        case 3: range = io.Fonts->GetGlyphRangesGreek();              break;
        case 4: range = io.Fonts->GetGlyphRangesChineseFull();        break;
        case 5: range = io.Fonts->GetGlyphRangesChineseSimplifiedCommon(); break;
        case 6: range = io.Fonts->GetGlyphRangesJapanese();           break;
        case 7: range = io.Fonts->GetGlyphRangesKorean();             break;
        case 8: range = io.Fonts->GetGlyphRangesThai();               break;
        default: return 1;   // unknown range id
    }
    ImFont* font = io.Fonts->AddFontFromFileTTF(utf8_path.c_str(), size_px,
                                                  nullptr, range);
    if (!font) return 2;
    *out_font_id = font_registry::Add(font);
    return 0;
}

// K.3 — Load a TTF from a memory buffer. The buffer is COPIED by ImGui
// (FontDataOwnedByAtlas=true by default) so AutoIt is free to free its
// DllStruct right after the call. $iSize is the byte count.
API_EXPORT int __cdecl ImGui_LoadFontFromMemory(const unsigned char* data, int size,
                                                  float size_px, int* out_font_id)
{
    if (!data || size <= 0 || size_px <= 0.0f || !out_font_id) return 1;

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);

    ImGuiIO& io = ImGui::GetIO();
    // AddFontFromMemoryTTF expects a non-const buffer because by default it
    // takes ownership (FontDataOwnedByAtlas=true) and will eventually free it
    // via IM_FREE. We want ImGui to OWN A COPY, not the caller's buffer ;
    // pass an ImFontConfig with FontDataOwnedByAtlas=false would make ImGui
    // NOT free our pointer — but it would also keep referencing it, requiring
    // the AutoIt struct to outlive the atlas (annoying). Simpler : copy the
    // buffer ourselves into an IM_ALLOC, hand it over, and let ImGui own it.
    void* owned = IM_ALLOC(static_cast<size_t>(size));
    if (!owned) return 2;
    std::memcpy(owned, data, static_cast<size_t>(size));
    ImFont* font = io.Fonts->AddFontFromMemoryTTF(owned, size, size_px);
    if (!font) {
        // ImGui didn't take ownership in the failure path — free our copy.
        IM_FREE(owned);
        return 2;
    }
    *out_font_id = font_registry::Add(font);
    return 0;
}

// K.3 — Read the current font's pixel size. Distinct from the size passed to
// LoadFont : if no PushFont is active the result is the default font size ;
// inside a PushFont scope (e.g. from a marker widget render) it reflects the
// stacked font. Useful for laying out elements relative to text height.
API_EXPORT int __cdecl ImGui_GetFontSize(float* out)
{
    if (!out) return 1;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    *out = ImGui::GetFontSize();
    return 0;
}

// PushFont marker widget — id is the user-stable key (PushID), font_id is the
// registry index returned by _ImGui_LoadFont. Returns 0 = OK, 1 = bad args,
// 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreatePushFont(const wchar_t* id, int font_id)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto w = std::make_unique<PushFontWidget>();
    w->id = uid;
    w->font_id = font_id;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

// PopFont marker — no params. Returns 0 = OK, 1 = bad args, 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreatePopFont(const wchar_t* id)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto w = std::make_unique<PopFontWidget>();
    w->id = uid;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}
