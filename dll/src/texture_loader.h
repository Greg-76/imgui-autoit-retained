#pragma once

// H.4 — Image / texture loader.
//
// Uses the Windows Imaging Component (WIC) to decode PNG/JPG/BMP/TIFF/GIF
// from a file path into a 32bpp PRGBA pixel buffer, then creates a DX11
// shader resource view (SRV) usable as an ImTextureID.
//
// SRVs are stored in a process-wide append-only registry (texture_loader.cpp
// anon namespace). LoadTexture takes the recursive frame lock so it's safe
// to call at any time from the AutoIt thread.
//
// Teardown : render_thread::Stop() calls texture_registry::Reset() under the
// teardown lock (right before ImGui::DestroyContext) to Release every SRV ;
// a subsequent Init() starts with an empty registry.

struct ID3D11Device;
struct ID3D11ShaderResourceView;

namespace texture_registry {

    // Load an image file via WIC, create a DX11 SRV, return the new tex_id.
    // Returns >= 0 on success, -1 on error (file missing, decode failed,
    // D3D resource creation failed, ImGui context not initialised).
    // Caller must hold g_tree.mtx (frame lock).
    int  LoadFromFile(ID3D11Device* device, const wchar_t* path);

    // Look up the SRV for a tex_id. Returns nullptr if id is out of range.
    ID3D11ShaderResourceView* GetSRV(int tex_id);

    // Width/height of the source image. Returns false if id out of range
    // (out_w/h then untouched).
    bool GetSize(int tex_id, int* out_w, int* out_h);

    // Number of registered textures.
    int  Count();

    // Release every SRV. Called by render_thread::Stop() during teardown,
    // BEFORE ImGui::DestroyContext. Caller must hold g_tree.mtx.
    void Reset();

} // namespace texture_registry
