// H.4 — WIC + DX11 texture loader.
//
// WIC pipeline (per LoadFromFile call) :
//   1. CoCreateInstance(WICImagingFactory)
//   2. WICImagingFactory::CreateDecoderFromFilename(path)
//   3. IWICBitmapDecoder::GetFrame(0)
//   4. WICImagingFactory::CreateFormatConverter -> 32bppPRGBA
//   5. IWICFormatConverter::CopyPixels into a heap buffer
//   6. ID3D11Device::CreateTexture2D(R8G8B8A8_UNORM)
//   7. ID3D11Device::CreateShaderResourceView
//   8. Release the Texture2D (SRV holds its own ref) ; store SRV in registry
//
// The WIC factory is created lazily on first LoadFromFile and held until
// Reset() ; CoInitialize is called once per call (idempotent).

#include "texture_loader.h"

#include <Windows.h>
#include <wincodec.h>
#include <d3d11.h>
#include <vector>

#pragma comment(lib, "windowscodecs.lib")

namespace {

struct TextureEntry {
    ID3D11ShaderResourceView* srv = nullptr;
    int width = 0;
    int height = 0;
};

std::vector<TextureEntry> g_textures;
IWICImagingFactory*       g_wicFactory = nullptr;

// Lazily create the WIC factory. Returns nullptr on COM failure.
IWICImagingFactory* GetOrCreateWICFactory()
{
    if (g_wicFactory) return g_wicFactory;
    // CoInitializeEx is idempotent ; calling it from a render-thread-adjacent
    // path is safe (we're under the recursive frame lock, no concurrent COM).
    HRESULT hr = ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    (void)hr;   // S_FALSE = already initialised, both are fine
    IWICImagingFactory* factory = nullptr;
    hr = ::CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER,
                            IID_PPV_ARGS(&factory));
    if (FAILED(hr)) return nullptr;
    g_wicFactory = factory;
    return g_wicFactory;
}

// Decode the file at `path` into a heap buffer of 32-bit pre-multiplied RGBA
// (matches DXGI_FORMAT_R8G8B8A8_UNORM with straight alpha for ImGui's blend).
// Returns false on any failure. On success fills out_pixels (caller frees with
// delete[]) + out_w + out_h.
bool DecodeFile(IWICImagingFactory* factory, const wchar_t* path,
                unsigned char** out_pixels, int* out_w, int* out_h)
{
    *out_pixels = nullptr;
    *out_w = *out_h = 0;

    IWICBitmapDecoder* decoder = nullptr;
    HRESULT hr = factory->CreateDecoderFromFilename(
        path, nullptr, GENERIC_READ, WICDecodeMetadataCacheOnLoad, &decoder);
    if (FAILED(hr) || !decoder) return false;

    IWICBitmapFrameDecode* frame = nullptr;
    hr = decoder->GetFrame(0, &frame);
    decoder->Release();
    if (FAILED(hr) || !frame) return false;

    IWICFormatConverter* converter = nullptr;
    hr = factory->CreateFormatConverter(&converter);
    if (FAILED(hr) || !converter) { frame->Release(); return false; }

    // Target : 32bppRGBA (NOT PRGBA — ImGui expects straight alpha,
    // the DX11 backend's blend state assumes non-premultiplied).
    hr = converter->Initialize(frame, GUID_WICPixelFormat32bppRGBA,
                                WICBitmapDitherTypeNone, nullptr, 0.0,
                                WICBitmapPaletteTypeMedianCut);
    frame->Release();
    if (FAILED(hr)) { converter->Release(); return false; }

    UINT w = 0, h = 0;
    converter->GetSize(&w, &h);
    if (w == 0 || h == 0) { converter->Release(); return false; }

    const UINT stride = w * 4;
    const UINT total  = stride * h;
    unsigned char* buf = new (std::nothrow) unsigned char[total];
    if (!buf) { converter->Release(); return false; }

    hr = converter->CopyPixels(nullptr, stride, total, buf);
    converter->Release();
    if (FAILED(hr)) { delete[] buf; return false; }

    *out_pixels = buf;
    *out_w = (int)w;
    *out_h = (int)h;
    return true;
}

// Create a DX11 Texture2D + ShaderResourceView from a 32bpp RGBA buffer.
// On success returns the SRV (caller owns its ref) ; on failure returns
// nullptr and releases any partial resources.
ID3D11ShaderResourceView* MakeSRV(ID3D11Device* device, const unsigned char* pixels,
                                   int w, int h)
{
    D3D11_TEXTURE2D_DESC desc{};
    desc.Width            = (UINT)w;
    desc.Height           = (UINT)h;
    desc.MipLevels        = 1;
    desc.ArraySize        = 1;
    desc.Format           = DXGI_FORMAT_R8G8B8A8_UNORM;
    desc.SampleDesc.Count = 1;
    desc.Usage            = D3D11_USAGE_DEFAULT;
    desc.BindFlags        = D3D11_BIND_SHADER_RESOURCE;
    desc.CPUAccessFlags   = 0;

    D3D11_SUBRESOURCE_DATA initData{};
    initData.pSysMem     = pixels;
    initData.SysMemPitch = (UINT)w * 4;

    ID3D11Texture2D* tex = nullptr;
    if (FAILED(device->CreateTexture2D(&desc, &initData, &tex)) || !tex) return nullptr;

    D3D11_SHADER_RESOURCE_VIEW_DESC srvDesc{};
    srvDesc.Format                    = desc.Format;
    srvDesc.ViewDimension             = D3D11_SRV_DIMENSION_TEXTURE2D;
    srvDesc.Texture2D.MipLevels       = desc.MipLevels;
    srvDesc.Texture2D.MostDetailedMip = 0;

    ID3D11ShaderResourceView* srv = nullptr;
    HRESULT hr = device->CreateShaderResourceView(tex, &srvDesc, &srv);
    tex->Release();   // SRV holds its own ref ; we don't need the Texture2D handle
    return SUCCEEDED(hr) ? srv : nullptr;
}

} // namespace

namespace texture_registry {

int LoadFromFile(ID3D11Device* device, const wchar_t* path)
{
    if (!device || !path || !*path) return -1;

    IWICImagingFactory* factory = GetOrCreateWICFactory();
    if (!factory) return -1;

    unsigned char* pixels = nullptr;
    int w = 0, h = 0;
    if (!DecodeFile(factory, path, &pixels, &w, &h)) return -1;

    ID3D11ShaderResourceView* srv = MakeSRV(device, pixels, w, h);
    delete[] pixels;
    if (!srv) return -1;

    TextureEntry entry{};
    entry.srv    = srv;
    entry.width  = w;
    entry.height = h;
    g_textures.push_back(entry);
    return (int)g_textures.size() - 1;
}

ID3D11ShaderResourceView* GetSRV(int tex_id)
{
    if (tex_id < 0 || tex_id >= (int)g_textures.size()) return nullptr;
    return g_textures[tex_id].srv;
}

bool GetSize(int tex_id, int* out_w, int* out_h)
{
    if (tex_id < 0 || tex_id >= (int)g_textures.size()) return false;
    if (out_w) *out_w = g_textures[tex_id].width;
    if (out_h) *out_h = g_textures[tex_id].height;
    return true;
}

int Count()
{
    return (int)g_textures.size();
}

void Reset()
{
    for (auto& t : g_textures) {
        if (t.srv) t.srv->Release();
    }
    g_textures.clear();
    // The WIC factory can be reused on the next Init — but we release it
    // anyway to be tidy (CoUninitialize is NOT called here because we don't
    // own the COM apartment lifetime ; AutoIt may still be using COM).
    if (g_wicFactory) {
        g_wicFactory->Release();
        g_wicFactory = nullptr;
    }
}

} // namespace texture_registry
