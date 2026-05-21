#include "render_thread.h"
#include "widget_tree.h"
#include "utf.h"
#include "font_extras.h"          // H.3 — register the default font in the registry
#include "texture_loader.h"       // H.4 — release textures on teardown
#include "radio_group_extras.h"   // K.2 — reset radio group state on teardown

// K.5 — Pending logging-start drain. Set from the AutoIt thread by the
// LogTo*/LogFinish C-ABI exports ; consumed here once per frame, inside the
// host window's Begin scope where g.CurrentWindow is valid (LogBegin would
// segfault otherwise — same class as the IsMouseHoveringRect issue in J.1).
namespace logging_pending {
    bool Drain(int& out_kind, int& out_depth, std::string& out_path);
}

#include <Windows.h>
#include <d3d11.h>
#include <tchar.h>
#include <string>

#include "imgui.h"
#include "imgui_internal.h"   // BeginViewportSideBar for the custom title bar (D.5 fix)
#include "imgui_impl_win32.h"
#include "imgui_impl_dx11.h"

RenderThread g_renderThread;

// All DX state lives in the render thread only.
namespace {
    ID3D11Device*           g_pd3dDevice = nullptr;
    ID3D11DeviceContext*    g_pd3dDeviceContext = nullptr;
    IDXGISwapChain*         g_pSwapChain = nullptr;
    ID3D11RenderTargetView* g_mainRTV = nullptr;
    HWND                    g_hwnd = nullptr;
    bool                    g_swapChainOccluded = false;
    UINT                    g_resizeW = 0, g_resizeH = 0;

    // Title displayed in the ImGui-rendered title bar. Only ever read/written
    // by the render thread (set once in ThreadProc init, never afterwards).
    std::string             g_titleUtf8;

    // Collapse state (only touched by the render thread).
    bool                    g_collapsed = false;
    int                     g_expandedHeight = 0;  // saved height to restore on un-collapse

    // --- Frame rate limiter (focus-aware) ---
    // When the window doesn't have focus we drop the cadence to save CPU/GPU,
    // important when 6-8 bots run in parallel each with their own DX device
    // (cf. framing doc Â§5/Â§9). Focus is tracked via WM_ACTIVATE. The unfocused
    // FPS is configurable from AutoIt via ImGui_SetUnfocusedFps.
    std::atomic<bool>       g_hasFocus{true};
    std::atomic<int>        g_unfocusedFps{20};   // sensible default in the 10-30 range

    // Global item-state queries (D.1). OR-merged across both render passes
    // (pass 1 = roots inside host, pass 2 = top-level Windows) so they reflect
    // the whole tree. Reset to false at the start of each frame, set after
    // each pass via ImGui::IsAnyItem*() reads. Atomics so dll_api.cpp can read
    // them without taking g_tree.mtx.
    std::atomic<bool>       g_anyItemHovered{false};
    std::atomic<bool>       g_anyItemActive{false};
    std::atomic<bool>       g_anyItemFocused{false};

    // Debug-window toggles (D.2). The render thread checks these atomics each
    // frame and calls ImGui::Show*Window with a local bool pointer so the X
    // close button propagates back to the atomic â€” the AutoIt side can then
    // poll IsShowing*() to detect a manual close.
    std::atomic<bool>       g_showDemoWindow{false};
    std::atomic<bool>       g_showMetricsWindow{false};
    std::atomic<bool>       g_showDebugLogWindow{false};
    std::atomic<bool>       g_showIDStackToolWindow{false};
    std::atomic<bool>       g_showAboutWindow{false};

    // G.4 â€” Style editor window. ShowStyleEditor() itself is a content block
    // (not a window), so we wrap it in our own Begin/End â€” same round-trip
    // pattern as the D.2 debug windows.
    std::atomic<bool>       g_showStyleEditor{false};

    // G.2 â€” sticky mouse-cursor override. -1 = no override (ImGui picks its
    // own per-frame cursor based on hover/active state). When >= 0, the
    // render loop applies it right after NewFrame so it survives ImGui's
    // per-frame reset. Set to a $ImGuiMouseCursor_* value from AutoIt
    // (e.g. on hover) and back to -1 to release.
    std::atomic<int>        g_pendingMouseCursor{-1};

    bool CreateDeviceD3D(HWND hWnd);
    void CleanupDeviceD3D();
    void CreateRenderTarget();
    void CleanupRenderTarget();
    LRESULT WINAPI WndProc(HWND, UINT, WPARAM, LPARAM);
    void RenderHostWindow();
}

// Exposed via dll_api.cpp (declared there as well).
namespace render_thread {
    void SetUnfocusedFps(int fps) {
        if (fps < 1)  fps = 1;
        if (fps > 60) fps = 60;
        g_unfocusedFps.store(fps);
    }
    int GetUnfocusedFps() { return g_unfocusedFps.load(); }
    bool HasFocus()       { return g_hasFocus.load(); }

    bool AnyItemHovered() { return g_anyItemHovered.load(); }
    bool AnyItemActive()  { return g_anyItemActive.load(); }
    bool AnyItemFocused() { return g_anyItemFocused.load(); }

    void SetShowDemoWindow        (bool v) { g_showDemoWindow        .store(v); }
    void SetShowMetricsWindow     (bool v) { g_showMetricsWindow     .store(v); }
    void SetShowDebugLogWindow    (bool v) { g_showDebugLogWindow    .store(v); }
    void SetShowIDStackToolWindow (bool v) { g_showIDStackToolWindow .store(v); }
    void SetShowAboutWindow       (bool v) { g_showAboutWindow       .store(v); }

    bool IsShowingDemoWindow        () { return g_showDemoWindow        .load(); }
    bool IsShowingMetricsWindow     () { return g_showMetricsWindow     .load(); }
    bool IsShowingDebugLogWindow    () { return g_showDebugLogWindow    .load(); }
    bool IsShowingIDStackToolWindow () { return g_showIDStackToolWindow .load(); }
    bool IsShowingAboutWindow       () { return g_showAboutWindow       .load(); }

    // G.4
    void SetShowStyleEditor   (bool v) { g_showStyleEditor.store(v); }
    bool IsShowingStyleEditor ()       { return g_showStyleEditor.load(); }

    // G.2
    void SetPendingMouseCursor(int c)  { g_pendingMouseCursor.store(c); }
    int  GetPendingMouseCursor()       { return g_pendingMouseCursor.load(); }

    // H.4 — expose the DX11 device so texture_loader.cpp can create SRVs.
    // Returns nullptr before Init / after Shutdown. Caller must hold the
    // frame lock (g_tree.mtx) before calling CreateTexture2D etc.
    ID3D11Device* GetD3DDevice() { return g_pd3dDevice; }
}

extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND, UINT, WPARAM, LPARAM);

bool RenderThread::Start(const std::wstring& title, int width, int height)
{
    if (m_running.load()) return false;
    m_stop.store(false);
    m_initDone.store(false);
    m_initOk.store(false);
    m_thread = std::thread(&RenderThread::ThreadProc, this, title, width, height);

    // Wait until the thread has either succeeded or failed initialisation.
    while (!m_initDone.load()) {
        ::Sleep(1);
    }
    if (!m_initOk.load()) {
        if (m_thread.joinable()) m_thread.join();
        return false;
    }
    return true; // m_running was set by the thread itself, just before m_initDone
}

void RenderThread::Stop()
{
    // Always best-effort: even if the thread already exited on its own
    // (user closed the window), we still need to join it and clear state.
    m_stop.store(true);
    if (g_hwnd) ::PostMessageW(g_hwnd, WM_NULL, 0, 0);
    if (m_thread.joinable()) m_thread.join();

    {
        std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
        g_tree.Clear();
    }
}

void RenderThread::ThreadProc(std::wstring title, int width, int height)
{
    // Make rendering DPI-aware (Win10 1703+, Per-Monitor V2). The OS no
    // longer scales our swap chain bitmap, so the UI stays crisp at any
    // DPI â€” including during window drag. We try process-wide first
    // because it's the only setting that actually sticks under AutoIt on
    // some configurations; if that fails (already set elsewhere) we fall
    // back to the thread-scoped API.
    if (HMODULE user32 = ::GetModuleHandleW(L"user32.dll")) {
        typedef intptr_t (WINAPI *PFN_STDAC)(intptr_t);
        typedef int      (WINAPI *PFN_SPDAC)(intptr_t);
        auto pSetProc   = (PFN_SPDAC)::GetProcAddress(user32, "SetProcessDpiAwarenessContext");
        auto pSetThread = (PFN_STDAC)::GetProcAddress(user32, "SetThreadDpiAwarenessContext");
        // -4 == DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
        bool ok = false;
        if (pSetProc && pSetProc((intptr_t)-4)) ok = true;
        if (!ok && pSetThread && pSetThread((intptr_t)-4) != 0) ok = true;
        (void)ok;
    }

    // ---- Window ----
    WNDCLASSEXW wc = { sizeof(wc), CS_CLASSDC, WndProc, 0L, 0L,
                      ::GetModuleHandleW(nullptr), nullptr,
                      ::LoadCursorW(nullptr, IDC_ARROW), nullptr, nullptr,
                      L"ImGuiAutoItRetained", nullptr };
    ::RegisterClassExW(&wc);
    // Borderless host window â€” the title bar and chrome are drawn by ImGui
    // inside the client area (see RenderHostWindow()).
    g_hwnd = ::CreateWindowW(wc.lpszClassName, title.c_str(),
                             WS_POPUP, 100, 100, width, height,
                             nullptr, nullptr, wc.hInstance, nullptr);
    if (!g_hwnd) {
        ::UnregisterClassW(wc.lpszClassName, wc.hInstance);
        m_initOk.store(false);
        m_initDone.store(true);
        return;
    }

    // ---- D3D11 ----
    if (!CreateDeviceD3D(g_hwnd)) {
        CleanupDeviceD3D();
        ::DestroyWindow(g_hwnd); g_hwnd = nullptr;
        ::UnregisterClassW(wc.lpszClassName, wc.hInstance);
        m_initOk.store(false);
        m_initDone.store(true);
        return;
    }
    ::ShowWindow(g_hwnd, SW_SHOWDEFAULT);
    ::UpdateWindow(g_hwnd);

    // ---- ImGui ----
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    // Multi-viewport: allow windows (top-level WindowWidget instances, debug
    // windows, future Popups) to be dragged outside the host OS window and
    // become their own OS-level windows. Backend support is built into
    // imgui_impl_win32 + imgui_impl_dx11 on the docking branch.
    io.ConfigFlags |= ImGuiConfigFlags_ViewportsEnable;
    io.IniFilename = nullptr; // don't write imgui.ini next to the AutoIt script
    ImGui::StyleColorsDark();

    // When viewports are enabled, ImGui recommends opaque window backgrounds
    // and 0 rounding â€” otherwise dragged-out windows look broken (rounding
    // would extend past the OS window edge ; alpha would let the desktop
    // show through). Match the official sample's tweak.
    {
        ImGuiStyle& vstyle = ImGui::GetStyle();
        if (io.ConfigFlags & ImGuiConfigFlags_ViewportsEnable) {
            vstyle.WindowRounding = 0.0f;
            vstyle.Colors[ImGuiCol_WindowBg].w = 1.0f;
        }
    }

    // Apply DPI scale to the style + font rasterization size. This is what
    // makes the UI crisp instead of OS-scaled-blur on >100% DPI monitors.
    const float dpi_scale = ImGui_ImplWin32_GetDpiScaleForHwnd(g_hwnd);
    ImGuiStyle& style = ImGui::GetStyle();
    style.ScaleAllSizes(dpi_scale);
    style.FontScaleDpi = dpi_scale;

    // Default font: Calibri 15.5pt with Vietnamese glyph range. Falls back
    // to ImGui's embedded default if Calibri is missing (e.g. trimmed
    // Windows install).
    io.Fonts->Clear();
    const ImWchar* glyph_range = io.Fonts->GetGlyphRangesVietnamese();
    if (!io.Fonts->AddFontFromFileTTF(R"(C:\Windows\Fonts\calibri.ttf)",
                                      15.5f, nullptr, glyph_range)) {
        io.Fonts->AddFontDefault();
    }
    // H.3 — register the default font as index 0 so _ImGui_LoadFont can return
    // sequential ids starting at 1. PushFontWidget falls back to index 0 when
    // given an unknown id, so a stable index 0 is part of the contract.
    font_registry::Add(io.Fonts->Fonts.back());

    ImGui_ImplWin32_Init(g_hwnd);
    ImGui_ImplDX11_Init(g_pd3dDevice, g_pd3dDeviceContext);

    g_titleUtf8 = WideToUtf8(title.c_str());
    g_collapsed = false;
    g_expandedHeight = 0;

    // Pre-tick : run one empty NewFrame/EndFrame cycle so global ImGui state
    // (most importantly g.Font, set by NewFrame's SetCurrentFont call) is
    // populated before we hand control back to AutoIt. Without this, the
    // AutoIt thread can call ImGui_CalcTextSize / GetFont-like helpers between
    // Init returning and the render loop's first frame, hitting a null
    // GImGui->Font and segfaulting. The frame-wide lock below isn't strictly
    // needed here (no AutoIt thread exists yet) but stays for consistency
    // with the loop body.
    {
        std::lock_guard<std::recursive_mutex> pretick_lk(g_tree.mtx);
        ImGui_ImplDX11_NewFrame();
        ImGui_ImplWin32_NewFrame();
        ImGui::NewFrame();
        ImGui::EndFrame();
    }

    m_initOk.store(true);
    m_running.store(true);
    m_initDone.store(true);

    // ---- Loop ----
    const ImVec4 clear_color(0.10f, 0.12f, 0.14f, 1.00f);
    while (!m_stop.load())
    {
        MSG msg;
        while (::PeekMessageW(&msg, nullptr, 0U, 0U, PM_REMOVE)) {
            ::TranslateMessage(&msg);
            ::DispatchMessageW(&msg);
            if (msg.message == WM_QUIT) {
                m_stop.store(true);
            }
        }
        if (m_stop.load()) break;

        if (g_swapChainOccluded &&
            g_pSwapChain->Present(0, DXGI_PRESENT_TEST) == DXGI_STATUS_OCCLUDED) {
            ::Sleep(10);
            continue;
        }
        g_swapChainOccluded = false;

        if (g_resizeW != 0 && g_resizeH != 0) {
            CleanupRenderTarget();
            g_pSwapChain->ResizeBuffers(0, g_resizeW, g_resizeH, DXGI_FORMAT_UNKNOWN, 0);
            g_resizeW = g_resizeH = 0;
            CreateRenderTarget();
        }

        // Frame-wide lock : serializes the entire ImGui pipeline (NewFrame to
        // platform-render) against AutoIt-thread readers (CalcTextSize,
        // IsKeyDown, GetMousePos, ...). Without it, those readers can race
        // with NewFrame's font-atlas / IO mutations and dereference torn
        // pointers (segfault observed in Phase G interactive testing).
        // g_tree.mtx is std::recursive_mutex (Phase G), so the internal
        // lock_guards inside RenderHostWindow nest safely. Present() is
        // intentionally OUTSIDE the lock (pure DX swapchain op, doesn't
        // touch ImGui state) so a slow vsync wait doesn't block AutoIt-thread
        // mutations for the full frame.
        {
            std::lock_guard<std::recursive_mutex> frame_lk(g_tree.mtx);
            ImGui_ImplDX11_NewFrame();
            ImGui_ImplWin32_NewFrame();
            ImGui::NewFrame();

            // G.2 â€” apply the AutoIt-side sticky mouse-cursor override (if any).
        // Done right after NewFrame so it survives ImGui's per-frame reset to
        // Arrow. ImGui's own per-widget cursor logic (e.g. TextInput â†’ I-beam)
        // still runs later in widget rendering ; setting the cursor here is
        // overridden by any widget that calls SetMouseCursor itself.
        {
            const int c = g_pendingMouseCursor.load();
            if (c >= 0) ImGui::SetMouseCursor(c);
        }

        RenderHostWindow();

        ImGui::Render();
        const float clear_rgba[4] = {
            clear_color.x * clear_color.w,
            clear_color.y * clear_color.w,
            clear_color.z * clear_color.w,
            clear_color.w };
        g_pd3dDeviceContext->OMSetRenderTargets(1, &g_mainRTV, nullptr);
        g_pd3dDeviceContext->ClearRenderTargetView(g_mainRTV, clear_rgba);
        ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());

        // Multi-viewport: walk the platform windows (= windows that were
        // dragged outside the main host viewport) and render+present each
        // one to its own backbuffer. Must be called AFTER RenderDrawData
        // for the main viewport and BEFORE the main viewport's Present.
        if (ImGui::GetIO().ConfigFlags & ImGuiConfigFlags_ViewportsEnable) {
            ImGui::UpdatePlatformWindows();
            ImGui::RenderPlatformWindowsDefault();
        }
        }  // frame_lk released here — Present runs unlocked

        HRESULT hr = g_pSwapChain->Present(1, 0); // vsync caps the frame rate
        g_swapChainOccluded = (hr == DXGI_STATUS_OCCLUDED);

        // Out-of-focus throttle. Present(1,0) already gave us ~16ms of vsync
        // wait ; we add the remaining budget to hit the target fps. Cheap and
        // avoids tearing (vsync stays on).
        if (!g_hasFocus.load()) {
            const int fps = g_unfocusedFps.load();
            if (fps > 0 && fps < 60) {
                const int target_ms = 1000 / fps;
                constexpr int kVsyncBudgetMs = 17;  // one frame @ 60 Hz, rounded up
                const int extra = target_ms - kVsyncBudgetMs;
                if (extra > 0) ::Sleep(static_cast<DWORD>(extra));
            }
        }
    }

    // ---- Cleanup ----
    // Take the frame-wide lock around ImGui teardown so any in-flight
    // AutoIt-thread helper (CalcTextSize / IsKeyDown / GetMousePos / ...)
    // either completes BEFORE the context is destroyed (it already holds the
    // lock, we wait), or sees a destroyed context AFTER the lock is released
    // and bails out via its ImGui::GetCurrentContext() guard (cf. helpers in
    // utils_extras.cpp). Without this, the X-close path raced with AutoIt's
    // loop and crashed exit 139 inside ImGui code after DestroyContext.
    {
        std::lock_guard<std::recursive_mutex> teardown_lk(g_tree.mtx);
        // H.4 — release every user-loaded texture SRV BEFORE we drop the DX
        // device below ; CleanupDeviceD3D would invalidate the device but
        // leave dangling COM refs in the registry.
        texture_registry::Reset();
        ImGui_ImplDX11_Shutdown();
        ImGui_ImplWin32_Shutdown();
        ImGui::DestroyContext();   // GImGui becomes nullptr ; helpers must guard
        // H.3 — DestroyContext freed the ImFontAtlas backing every ImFont* we
        // had stashed in the registry. Drop our copies so a subsequent Init
        // starts with an empty registry (the new ThreadProc init will re-Add
        // the default font at index 0).
        font_registry::Reset();
        // K.2 — RadioGroup state is process-wide ; reset it so a subsequent
        // Init starts fresh (no leaked group values from the previous session).
        radio_group_state::Reset();
    }
    CleanupDeviceD3D();
    if (g_hwnd) { ::DestroyWindow(g_hwnd); g_hwnd = nullptr; }
    ::UnregisterClassW(wc.lpszClassName, wc.hInstance);

    // Thread is about to return : IsRunning() must reflect that immediately so
    // AutoIt's While _ImGui_IsRunning() loop exits when the user closes the UI.
    m_running.store(false);
}

// ---- Helpers (lifted from imgui example_win32_directx11/main.cpp) ----
namespace {

bool CreateDeviceD3D(HWND hWnd)
{
    DXGI_SWAP_CHAIN_DESC sd{};
    sd.BufferCount = 2;
    sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate.Numerator = 60;
    sd.BufferDesc.RefreshRate.Denominator = 1;
    sd.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.OutputWindow = hWnd;
    sd.SampleDesc.Count = 1;
    sd.Windowed = TRUE;
    sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

    D3D_FEATURE_LEVEL featureLevel;
    const D3D_FEATURE_LEVEL fls[] = {
        D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_1,
        D3D_FEATURE_LEVEL_10_0, D3D_FEATURE_LEVEL_9_3 };
    HRESULT hr = D3D11CreateDeviceAndSwapChain(
        nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, 0, fls, _countof(fls),
        D3D11_SDK_VERSION, &sd, &g_pSwapChain, &g_pd3dDevice, &featureLevel,
        &g_pd3dDeviceContext);
    if (hr == DXGI_ERROR_UNSUPPORTED) {
        hr = D3D11CreateDeviceAndSwapChain(
            nullptr, D3D_DRIVER_TYPE_WARP, nullptr, 0, fls, _countof(fls),
            D3D11_SDK_VERSION, &sd, &g_pSwapChain, &g_pd3dDevice, &featureLevel,
            &g_pd3dDeviceContext);
    }
    if (FAILED(hr)) return false;
    CreateRenderTarget();
    return true;
}

void CleanupDeviceD3D()
{
    CleanupRenderTarget();
    if (g_pSwapChain)        { g_pSwapChain->Release();        g_pSwapChain = nullptr; }
    if (g_pd3dDeviceContext) { g_pd3dDeviceContext->Release(); g_pd3dDeviceContext = nullptr; }
    if (g_pd3dDevice)        { g_pd3dDevice->Release();        g_pd3dDevice = nullptr; }
}

void CreateRenderTarget()
{
    ID3D11Texture2D* pBackBuffer = nullptr;
    g_pSwapChain->GetBuffer(0, IID_PPV_ARGS(&pBackBuffer));
    if (pBackBuffer) {
        g_pd3dDevice->CreateRenderTargetView(pBackBuffer, nullptr, &g_mainRTV);
        pBackBuffer->Release();
    }
}

void CleanupRenderTarget()
{
    if (g_mainRTV) { g_mainRTV->Release(); g_mainRTV = nullptr; }
}

LRESULT WINAPI WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    // Track focus state for the frame-rate limiter. Done BEFORE the ImGui
    // handler so we read every WM_ACTIVATE â€” the handler doesn't consume it
    // (returns 0) in current imgui_impl_win32, but staying robust to that.
    if (msg == WM_ACTIVATE) {
        g_hasFocus.store(LOWORD(wParam) != WA_INACTIVE);
    }

    if (ImGui_ImplWin32_WndProcHandler(hWnd, msg, wParam, lParam))
        return true;

    // Multi-viewport fix: the docking-branch ImGui_ImplWin32_WndProcHandler
    // does NOT handle WM_MOVE / WM_SIZE for the main viewport (those are
    // only routed through its separate WndProc_PlatformWindow for secondary
    // viewports). Without this, when we manually SetWindowPos on g_hwnd
    // (custom title-bar drag, resize grip), ImGui's main viewport->Pos /
    // ->Size stay stale, the render coordinates desync from the HWND, and
    // the user sees a "ghost" black window moving while the real UI stays
    // fixed. Forwarding PlatformRequestMove/Resize for the main viewport
    // makes ImGui re-read the HWND via Platform_GetWindowPos next frame.
    if (ImGuiContext* ctx = ImGui::GetCurrentContext()) {
        (void)ctx;  // ensure we don't deref before init
        if (ImGuiViewport* vp = ImGui::FindViewportByPlatformHandle((void*)hWnd)) {
            if (msg == WM_MOVE) vp->PlatformRequestMove   = true;
            if (msg == WM_SIZE) vp->PlatformRequestResize = true;
        }
    }

    switch (msg) {
    case WM_SIZE:
        if (wParam == SIZE_MINIMIZED) return 0;
        g_resizeW = (UINT)LOWORD(lParam);
        g_resizeH = (UINT)HIWORD(lParam);
        return 0;
    case WM_SYSCOMMAND:
        if ((wParam & 0xfff0) == SC_KEYMENU) return 0;
        break;
    case WM_DESTROY:
        ::PostQuitMessage(0);
        return 0;
    }
    return ::DefWindowProcW(hWnd, msg, wParam, lParam);
}

// Draws the borderless host: ImGui title bar (collapse arrow + title + drag
// area + minimize + close) and a bottom-right resize grip when expanded.
// The widget tree renders inside the body when expanded.
void RenderHostWindow()
{
    constexpr float TITLEBAR_H = 28.0f;
    constexpr float BTN_W      = 38.0f;
    constexpr float PAD        = 8.0f;
    constexpr float GRIP       = 16.0f;

    const ImGuiViewport* main_viewport = ImGui::GetMainViewport();

    // --- PRE-PASS A : custom title bar as a viewport side bar (top edge) ----
    // Rendered FIRST so it reserves the top axis_size pixels of the viewport
    // via BuildWorkInsetMin. The MainMenuBar pre-pass right after stacks below
    // it naturally (BeginViewportSideBar's GetBuildWorkRect honors the inset).
    // The host then begins at viewport->WorkPos = below both. Net effect:
    // [title bar] â†’ [menu bar, if any] â†’ [host content].
    {
        ImGui::PushStyleVar(ImGuiStyleVar_WindowRounding,   0.0f);
        ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);
        ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding,    ImVec2(0.0f, 0.0f));
        const ImGuiWindowFlags tb_flags =
            ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoSavedSettings |
            ImGuiWindowFlags_NoDocking   | ImGuiWindowFlags_NoBringToFrontOnFocus;
        if (ImGui::BeginViewportSideBar("##host_titlebar",
                                         const_cast<ImGuiViewport*>(main_viewport),
                                         ImGuiDir_Up, TITLEBAR_H, tb_flags)) {
            const ImVec2 tb_origin = ImGui::GetCursorScreenPos();
            const ImVec2 tb_size   = ImGui::GetWindowSize();
            ImDrawList*  tb_dl     = ImGui::GetWindowDrawList();

            // --- Title bar background ---
            tb_dl->AddRectFilled(
                tb_origin,
                ImVec2(tb_origin.x + tb_size.x, tb_origin.y + TITLEBAR_H),
                ImGui::GetColorU32(ImGuiCol_TitleBgActive));

            // --- Collapse arrow (left) ---
            ImGui::PushStyleColor(ImGuiCol_Button,        ImVec4(0, 0, 0, 0));
            ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.30f, 0.30f, 0.35f, 1.0f));
            ImGui::PushStyleColor(ImGuiCol_ButtonActive,  ImVec4(0.50f, 0.50f, 0.55f, 1.0f));
            ImGui::SetCursorScreenPos(tb_origin);
            if (ImGui::Button("##collapse", ImVec2(TITLEBAR_H, TITLEBAR_H))) {
                g_collapsed = !g_collapsed;
                RECT wr; ::GetWindowRect(g_hwnd, &wr);
                const int w = wr.right - wr.left;
                if (g_collapsed) {
                    g_expandedHeight = wr.bottom - wr.top;
                    ::SetWindowPos(g_hwnd, nullptr, 0, 0, w, (int)TITLEBAR_H,
                                   SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
                } else {
                    const int restoreH = (g_expandedHeight > 0) ? g_expandedHeight : 320;
                    ::SetWindowPos(g_hwnd, nullptr, 0, 0, w, restoreH,
                                   SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
                }
            }
            ImGui::PopStyleColor(3);

            // Arrow glyph drawn on top of the invisible button
            {
                const float cx = tb_origin.x + TITLEBAR_H * 0.5f;
                const float cy = tb_origin.y + TITLEBAR_H * 0.5f;
                const float s  = 4.5f;
                const ImU32 col = ImGui::GetColorU32(ImGuiCol_Text);
                if (g_collapsed) {
                    tb_dl->AddTriangleFilled(
                        ImVec2(cx - s * 0.6f, cy - s),
                        ImVec2(cx - s * 0.6f, cy + s),
                        ImVec2(cx + s,        cy),
                        col);
                } else {
                    tb_dl->AddTriangleFilled(
                        ImVec2(cx - s, cy - s * 0.6f),
                        ImVec2(cx + s, cy - s * 0.6f),
                        ImVec2(cx,     cy + s),
                        col);
                }
            }

            // --- Title text (shifted right to clear the arrow) ---
            {
                const float text_y = tb_origin.y + (TITLEBAR_H - ImGui::GetTextLineHeight()) * 0.5f;
                tb_dl->AddText(ImVec2(tb_origin.x + TITLEBAR_H + 2.0f, text_y),
                            ImGui::GetColorU32(ImGuiCol_Text),
                            g_titleUtf8.c_str());
            }

            // --- Drag area (snapshot screen-coords + g_hwnd rect at activation) ---
            static POINT s_dragCursor0 = {};
            static RECT  s_dragRect0   = {};
            const float  buttons_reserved = BTN_W * 2.0f;
            ImGui::SetCursorScreenPos(ImVec2(tb_origin.x + TITLEBAR_H, tb_origin.y));
            const float drag_w = tb_size.x - TITLEBAR_H - buttons_reserved;
            if (drag_w > 0.0f) {
                ImGui::InvisibleButton("##drag", ImVec2(drag_w, TITLEBAR_H));
                if (ImGui::IsItemActivated()) {
                    ::GetCursorPos(&s_dragCursor0);
                    ::GetWindowRect(g_hwnd, &s_dragRect0);
                }
                if (ImGui::IsItemActive()) {
                    POINT pt; ::GetCursorPos(&pt);
                    ::SetWindowPos(g_hwnd, nullptr,
                                   s_dragRect0.left + (pt.x - s_dragCursor0.x),
                                   s_dragRect0.top  + (pt.y - s_dragCursor0.y),
                                   0, 0,
                                   SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
                }
            }

            // --- Minimize ---
            ImGui::PushStyleColor(ImGuiCol_Button,        ImVec4(0, 0, 0, 0));
            ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.30f, 0.30f, 0.35f, 1.0f));
            ImGui::PushStyleColor(ImGuiCol_ButtonActive,  ImVec4(0.50f, 0.50f, 0.55f, 1.0f));
            ImGui::SetCursorScreenPos(ImVec2(tb_origin.x + tb_size.x - BTN_W * 2.0f, tb_origin.y));
            if (ImGui::Button("_##min", ImVec2(BTN_W, TITLEBAR_H))) {
                ::ShowWindow(g_hwnd, SW_MINIMIZE);
            }
            ImGui::PopStyleColor(3);

            // --- Close ---
            ImGui::PushStyleColor(ImGuiCol_Button,        ImVec4(0, 0, 0, 0));
            ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.75f, 0.20f, 0.20f, 1.0f));
            ImGui::PushStyleColor(ImGuiCol_ButtonActive,  ImVec4(0.90f, 0.30f, 0.30f, 1.0f));
            ImGui::SetCursorScreenPos(ImVec2(tb_origin.x + tb_size.x - BTN_W, tb_origin.y));
            if (ImGui::Button("X##close", ImVec2(BTN_W, TITLEBAR_H))) {
                ::PostMessageW(g_hwnd, WM_CLOSE, 0, 0);
            }
            ImGui::PopStyleColor(3);
        }
        ImGui::End();
        ImGui::PopStyleVar(3);
    }

    // --- PRE-PASS B : MainMenuBar (auto-stacks below the title bar) ---------
    // BeginMainMenuBar internally uses BeginViewportSideBar(ImGuiDir_Up,
    // frame_height) which positions at avail_rect.Min â€” accounting for the
    // title bar's already-claimed inset. End result: menu bar appears right
    // below the title bar.
    {
        std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
        for (auto& w : g_tree.roots) {
            if (w->IsMainMenuBar()) w->RenderAndQueryState();
        }
    }

    ImGui::PushStyleVar(ImGuiStyleVar_WindowRounding,   0.0f);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0.0f);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding,    ImVec2(0.0f, 0.0f));

    // --- Host body (no title bar inside anymore â€” moved to PRE-PASS A) -----
    // WorkPos already reflects both the title bar side bar's offset AND the
    // MainMenuBar's offset, so the host slots naturally below them.
    const ImVec2 size = main_viewport->WorkSize;
    ImGui::SetNextWindowPos(main_viewport->WorkPos);
    ImGui::SetNextWindowSize(size);
    ImGui::SetNextWindowViewport(main_viewport->ID);
    ImGui::Begin("##host", nullptr,
        ImGuiWindowFlags_NoTitleBar       | ImGuiWindowFlags_NoResize          |
        ImGuiWindowFlags_NoMove           | ImGuiWindowFlags_NoCollapse        |
        ImGuiWindowFlags_NoBringToFrontOnFocus | ImGuiWindowFlags_NoScrollbar  |
        ImGuiWindowFlags_NoSavedSettings);

    // K.5 — Drain any pending LogTo*/LogFinish requests queued by AutoIt's
    // thread (the LogTo* C-ABI helpers can't call ImGui::LogTo* directly —
    // they deref g.CurrentWindow which is null between frames). We do it
    // INSIDE the host's Begin/End so CurrentWindow is valid.
    {
        std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
        int kind = 0, depth = 0;
        std::string path;
        if (logging_pending::Drain(kind, depth, path)) {
            switch (kind) {
                case 1: ImGui::LogToFile(depth, path.empty() ? nullptr : path.c_str()); break; // PLK_File
                case 2: ImGui::LogToClipboard(depth); break;                                   // PLK_Clipboard
                case 3: ImGui::LogToTTY(depth);       break;                                   // PLK_TTY
                case 4: ImGui::LogFinish();           break;                                   // PLK_Finish
                default: break;
            }
        }
    }

    const ImVec2 origin = ImGui::GetCursorScreenPos();
    ImDrawList* dl = ImGui::GetWindowDrawList();

    // --- Body + resize grip only when expanded ---
    // Pass 1 IsAnyItem* sampling â€” declared at function scope so the values
    // survive the `if (!g_collapsed)` block all the way to the OR-merge below.
    // When collapsed, no body is rendered â†’ values stay false â†’ only Pass 2
    // contributes to the final state.
    bool any_hovered_p1 = false, any_active_p1 = false, any_focused_p1 = false;
    if (!g_collapsed) {
        // Body starts at origin + PAD (no more + TITLEBAR_H â€” the title bar
        // lives in its own viewport side bar now, see PRE-PASS A above).
        ImGui::SetCursorScreenPos(ImVec2(origin.x + PAD, origin.y + PAD));
        ImGui::BeginGroup();
        {
            std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
            // Pass 1 â€” non-top-level, non-MainMenuBar roots are rendered
            // INSIDE the host's Begin/End. MainMenuBar was already rendered
            // in the pre-pass at top of RenderHostWindow ; top-level Windows
            // go to Pass 2 below. Recursive descent into containers is
            // handled by each Widget::Render() (it walks its own `children`
            // via RenderAndQueryState() so item queries latch correctly).
            for (auto& w : g_tree.roots) {
                if (!w->IsTopLevelWindow() && !w->IsMainMenuBar()) w->RenderAndQueryState();
            }
            // Sample IsAnyItem*() while still inside the host's Begin/End,
            // before EndGroup ends the visible item flow.
            any_hovered_p1 = ImGui::IsAnyItemHovered();
            any_active_p1  = ImGui::IsAnyItemActive();
            any_focused_p1 = ImGui::IsAnyItemFocused();
        }
        ImGui::EndGroup();

        // Same trick as the drag area: snapshot at IsItemActivated, then
        // compute size from the cursor's screen-space delta to that origin.
        static POINT s_resizeCursor0 = {};
        static RECT  s_resizeRect0   = {};

        ImGui::SetCursorScreenPos(ImVec2(origin.x + size.x - GRIP, origin.y + size.y - GRIP));
        ImGui::InvisibleButton("##grip", ImVec2(GRIP, GRIP));
        if (ImGui::IsItemActivated()) {
            ::GetCursorPos(&s_resizeCursor0);
            ::GetWindowRect(g_hwnd, &s_resizeRect0);
        }
        if (ImGui::IsItemActive()) {
            POINT pt; ::GetCursorPos(&pt);
            int nw = (s_resizeRect0.right  - s_resizeRect0.left) + (pt.x - s_resizeCursor0.x);
            int nh = (s_resizeRect0.bottom - s_resizeRect0.top)  + (pt.y - s_resizeCursor0.y);
            if (nw < 240) nw = 240;
            if (nh < 140) nh = 140;
            ::SetWindowPos(g_hwnd, nullptr, 0, 0, nw, nh,
                           SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
        }
        {
            const ImU32 col = ImGui::GetColorU32(ImGuiCol_ResizeGrip);
            const ImVec2 br(origin.x + size.x, origin.y + size.y);
            dl->AddTriangleFilled(
                ImVec2(br.x - GRIP, br.y),
                ImVec2(br.x, br.y - GRIP),
                br,
                col);
        }
    }

    ImGui::End();
    ImGui::PopStyleVar(3);

    // Pass 2 â€” top-level Window widgets render as separate ImGui windows,
    // outside the host's Begin/End. Each WindowWidget::Render() does its
    // own ImGui::Begin/End. New lock_guard (the one above expired with the
    // BeginGroup scope): brief inconsistency window vs Pass 1 is harmless â€”
    // worst case a widget add/move is reflected on the next frame.
    bool any_hovered_p2 = false, any_active_p2 = false, any_focused_p2 = false;
    {
        std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
        for (auto& w : g_tree.roots) {
            if (w->IsTopLevelWindow()) w->RenderAndQueryState();
        }
        any_hovered_p2 = ImGui::IsAnyItemHovered();
        any_active_p2  = ImGui::IsAnyItemActive();
        any_focused_p2 = ImGui::IsAnyItemFocused();
    }

    // OR-merge both passes â€” a widget hovered in a top-level Window must
    // count just as much as one in the host area.
    g_anyItemHovered.store(any_hovered_p1 || any_hovered_p2);
    g_anyItemActive .store(any_active_p1  || any_active_p2);
    g_anyItemFocused.store(any_focused_p1 || any_focused_p2);

    // Debug windows (D.2). Each is gated on its atomic; we pass &local so
    // that clicking the window's X close button writes back to the atomic
    // (the AutoIt side then sees IsShowing*() flip to false on the next poll).
    // Called AFTER the host's End() and the widget-tree pass 2, so they appear
    // as sibling top-level windows to our WindowWidget instances.
    if (g_showDemoWindow.load()) {
        bool open = true;
        ImGui::ShowDemoWindow(&open);
        if (!open) g_showDemoWindow.store(false);
    }
    if (g_showMetricsWindow.load()) {
        bool open = true;
        ImGui::ShowMetricsWindow(&open);
        if (!open) g_showMetricsWindow.store(false);
    }
    if (g_showDebugLogWindow.load()) {
        bool open = true;
        ImGui::ShowDebugLogWindow(&open);
        if (!open) g_showDebugLogWindow.store(false);
    }
    if (g_showIDStackToolWindow.load()) {
        bool open = true;
        ImGui::ShowIDStackToolWindow(&open);
        if (!open) g_showIDStackToolWindow.store(false);
    }
    if (g_showAboutWindow.load()) {
        bool open = true;
        ImGui::ShowAboutWindow(&open);
        if (!open) g_showAboutWindow.store(false);
    }
    // G.4 â€” ShowStyleEditor() is a content block (not a window), so we wrap
    // it in our own Begin/End. Same X-close round-trip as the D.2 windows.
    if (g_showStyleEditor.load()) {
        bool open = true;
        ImGui::SetNextWindowSize(ImVec2(400, 500), ImGuiCond_FirstUseEver);
        if (ImGui::Begin("Style Editor", &open)) {
            ImGui::ShowStyleEditor();
        }
        ImGui::End();
        if (!open) g_showStyleEditor.store(false);
    }
}

} // namespace
