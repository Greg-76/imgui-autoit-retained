// H.4 — Image / ImageButton widgets + LoadTexture / GetTextureSize C-ABI.
//
// The widget Render() functions look up the SRV from texture_registry by
// tex_id and cast the pointer to ImTextureID (DX11 backend convention :
// (ImTextureID)(intptr_t)pSRV). ImGui's ImTextureRef has an implicit
// constructor from ImTextureID so we pass the cast value directly.

#include "image_extras.h"
#include "texture_loader.h"

#include <Windows.h>
#include <d3d11.h>
#include <memory>
#include <mutex>
#include <string>
#include <cstdint>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

// Re-declare the render_thread accessor to avoid pulling render_thread.h
// (which includes <thread> + std::wstring).
namespace render_thread {
    ID3D11Device* GetD3DDevice();
}

// ---- Widget render -----------------------------------------------------------

static void DrawImagePlaceholder(const char* prefix, int tex_id, float w, float h)
{
    // Visible marker so the user notices the bad id ; sized like a small
    // button so it doesn't collapse to nothing.
    const ImVec2 sz((w > 0.0f) ? w : 60.0f, (h > 0.0f) ? h : 20.0f);
    ImGui::Dummy(sz);
    if (ImGui::IsItemHovered()) {
        ImGui::SetTooltip("%s: invalid tex_id %d", prefix, tex_id);
    }
    ImGui::TextDisabled("[%s: bad tex_id %d]", prefix, tex_id);
}

void ImageWidget::Render()
{
    if (!visible) return;
    ID3D11ShaderResourceView* srv = texture_registry::GetSRV(tex_id);
    if (!srv) { DrawImagePlaceholder("Image", tex_id, w, h); return; }
    // Size 0 → fall back to the texture's native dimensions (more intuitive
    // than ImGui's default 0×0 which renders nothing).
    float rw = w, rh = h;
    if (rw <= 0.0f || rh <= 0.0f) {
        int nw = 0, nh = 0;
        texture_registry::GetSize(tex_id, &nw, &nh);
        if (rw <= 0.0f) rw = (float)nw;
        if (rh <= 0.0f) rh = (float)nh;
    }
    ImGui::Image((ImTextureID)(intptr_t)srv, ImVec2(rw, rh));
}

void ImageWithBgWidget::Render()
{
    if (!visible) return;
    ID3D11ShaderResourceView* srv = texture_registry::GetSRV(tex_id);
    if (!srv) { DrawImagePlaceholder("ImageWithBg", tex_id, w, h); return; }
    float rw = w, rh = h;
    if (rw <= 0.0f || rh <= 0.0f) {
        int nw = 0, nh = 0;
        texture_registry::GetSize(tex_id, &nw, &nh);
        if (rw <= 0.0f) rw = (float)nw;
        if (rh <= 0.0f) rh = (float)nh;
    }
    ImGui::ImageWithBg((ImTextureID)(intptr_t)srv,
                        ImVec2(rw, rh),
                        ImVec2(0, 0), ImVec2(1, 1),
                        ImVec4(bg_r, bg_g, bg_b, bg_a),
                        ImVec4(tint_r, tint_g, tint_b, tint_a));
}

void ImageButtonWidget::Render()
{
    if (!visible) return;
    if (!enabled) ImGui::BeginDisabled();
    ID3D11ShaderResourceView* srv = texture_registry::GetSRV(tex_id);
    if (!srv) {
        DrawImagePlaceholder("ImageButton", tex_id, w, h);
        if (!enabled) ImGui::EndDisabled();
        return;
    }
    float rw = w, rh = h;
    if (rw <= 0.0f || rh <= 0.0f) {
        int nw = 0, nh = 0;
        texture_registry::GetSize(tex_id, &nw, &nh);
        if (rw <= 0.0f) rw = (float)nw;
        if (rh <= 0.0f) rh = (float)nh;
    }
    ImGui::PushID(id.c_str());
    const char* shown = label.empty() ? id.c_str() : label.c_str();
    if (ImGui::ImageButton(shown, (ImTextureID)(intptr_t)srv, ImVec2(rw, rh))) {
        clicked = true;
    }
    ImGui::PopID();
    if (!enabled) ImGui::EndDisabled();
}

// ---- C-ABI : texture loader exports ----------------------------------------

// Returns tex_id (>= 0) on success, -1 on error. Writes width/height into the
// optional out params (caller may pass nullptr to ignore).
// @extended in AutoIt carries 1=bad args, 2=device not ready, 3=load failed,
// 6=shutting down.
API_EXPORT int __cdecl ImGui_LoadTexture(const wchar_t* path, int* out_w, int* out_h, int* out_err)
{
    if (!path || !*path) { if (out_err) *out_err = 1; return -1; }
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    if (!ImGui::GetCurrentContext()) { if (out_err) *out_err = 6; return -1; }
    ID3D11Device* device = render_thread::GetD3DDevice();
    if (!device) { if (out_err) *out_err = 2; return -1; }
    int id = texture_registry::LoadFromFile(device, path);
    if (id < 0) { if (out_err) *out_err = 3; return -1; }
    if (out_w || out_h) {
        int nw = 0, nh = 0;
        texture_registry::GetSize(id, &nw, &nh);
        if (out_w) *out_w = nw;
        if (out_h) *out_h = nh;
    }
    if (out_err) *out_err = 0;
    return id;
}

// Out-param version : 0=OK, 1=bad args, 2=unknown id. out_wh[0]=w, [1]=h.
API_EXPORT int __cdecl ImGui_GetTextureSize(int tex_id, int* out_wh)
{
    if (!out_wh) return 1;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    int w = 0, h = 0;
    if (!texture_registry::GetSize(tex_id, &w, &h)) {
        out_wh[0] = 0;
        out_wh[1] = 0;
        return 2;
    }
    out_wh[0] = w;
    out_wh[1] = h;
    return 0;
}

// ---- C-ABI : widget create exports -----------------------------------------

// Returns: 0 = OK, 1 = id invalid, 2 = duplicate id.
API_EXPORT int __cdecl ImGui_CreateImage(const wchar_t* id, int tex_id, float w, float h)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto widget = std::make_unique<ImageWidget>();
    widget->id     = uid;
    widget->tex_id = tex_id;
    widget->w      = w;
    widget->h      = h;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

API_EXPORT int __cdecl ImGui_CreateImageButton(const wchar_t* id, const wchar_t* label,
                                                int tex_id, float w, float h)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;
    auto widget = std::make_unique<ImageButtonWidget>();
    widget->id     = uid;
    widget->label  = ulbl;
    widget->tex_id = tex_id;
    widget->w      = w;
    widget->h      = h;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

// M.2 — bg_col drawn under the texture (visible through transparent pixels) ;
// tint_col multiplied with the texture. Defaults (0,0,0,0)+(1,1,1,1) reproduce
// the look of plain Image(). Returns 0=OK, 1=bad args, 2=duplicate id.
API_EXPORT int __cdecl ImGui_CreateImageWithBg(const wchar_t* id, int tex_id,
                                                 float w, float h,
                                                 float bg_r, float bg_g, float bg_b, float bg_a,
                                                 float tint_r, float tint_g, float tint_b, float tint_a)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto widget = std::make_unique<ImageWithBgWidget>();
    widget->id     = uid;
    widget->tex_id = tex_id;
    widget->w      = w;
    widget->h      = h;
    widget->bg_r   = bg_r;   widget->bg_g   = bg_g;   widget->bg_b   = bg_b;   widget->bg_a   = bg_a;
    widget->tint_r = tint_r; widget->tint_g = tint_g; widget->tint_b = tint_b; widget->tint_a = tint_a;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}
