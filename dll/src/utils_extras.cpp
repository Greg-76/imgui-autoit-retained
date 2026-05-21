// Phase E.3 + E.4 â€” free-function helpers (no new widgets).
//
// E.3 : mouse position / drag delta / clipboard get-set.
// E.4 : color conversion U32â†”Float4 + RGBâ†”HSV.
//
// Mouse / clipboard read ImGui global state, so they take g_tree.mtx for
// safety (no other state is touched, but the render thread might be inside
// NewFrame mid-mutation). Color conversion is pure math â€” no mutex needed.

#include <Windows.h>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>

#include "imgui.h"
#include "widget_tree.h"
#include "utf.h"

#define API_EXPORT extern "C" __declspec(dllexport)

// Accessors implemented in render_thread.cpp. Declared here so the G.2/G.4
// exports below can route through them without dragging in render_thread.h's
// std::thread dependency.
namespace render_thread {
    void SetShowStyleEditor(bool v);
    bool IsShowingStyleEditor();
    void SetPendingMouseCursor(int c);
    int  GetPendingMouseCursor();
}

// Shutdown guard : ImGui::DestroyContext() (called by render thread cleanup)
// nulls GImGui. Any AutoIt-thread helper that calls into ImGui must check
// this first, otherwise the call dereferences a null context and segfaults.
// Use AFTER taking the recursive lock, so cleanup and the helper serialize :
// the helper either runs entirely before DestroyContext (context valid) or
// entirely after (context null, return early). Status code 6 = "shutting down".
#define BAIL_IF_NO_IMGUI_CTX(safe_return) \
    do { if (!ImGui::GetCurrentContext()) { return safe_return; } } while (0)

// ---- E.3 â€” Mouse helpers ----------------------------------------------------

// Returns: 0 = OK, 1 = out null.
API_EXPORT int __cdecl ImGui_GetMousePos(float* out_xy)
{
    if (!out_xy) return 1;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    const ImVec2 p = ImGui::GetMousePos();
    out_xy[0] = p.x;
    out_xy[1] = p.y;
    return 0;
}

// button : 0=Left, 1=Right, 2=Middle. Returns 0=OK / 1=out null / 2=invalid button.
// Out_xy is (0,0) when not currently dragging that button.
API_EXPORT int __cdecl ImGui_GetMouseDragDelta(int button, float* out_xy)
{
    if (!out_xy) return 1;
    if (button < 0 || button > 2) return 2;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    const ImVec2 d = ImGui::GetMouseDragDelta(button);
    out_xy[0] = d.x;
    out_xy[1] = d.y;
    return 0;
}

// ---- E.3 â€” Clipboard helpers ------------------------------------------------

// Fills out[capacity] with UTF-16. Returns : 0 = OK, 1 = out null / cap < 1,
// 4 = truncated (out still null-terminated, but content > capacity-1 wchars).
API_EXPORT int __cdecl ImGui_GetClipboardText(wchar_t* out, int capacity)
{
    if (!out || capacity < 1) return 1;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    const char* utf8 = ImGui::GetClipboardText();
    if (!utf8) {
        out[0] = L'\0';
        return 0;
    }
    std::wstring wide = Utf8ToWide(utf8);
    bool truncated = false;
    if (static_cast<int>(wide.size()) > capacity - 1) {
        wide.resize(capacity - 1);
        truncated = true;
    }
    std::memcpy(out, wide.data(), wide.size() * sizeof(wchar_t));
    out[wide.size()] = L'\0';
    return truncated ? 4 : 0;
}

// Returns 0=OK / 1=text null. Empty text clears the clipboard.
API_EXPORT int __cdecl ImGui_SetClipboardText(const wchar_t* text)
{
    if (!text) return 1;
    std::string utf8 = WideToUtf8(text);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    ImGui::SetClipboardText(utf8.c_str());
    return 0;
}

// ---- E.2.x â€” Global color-edit defaults -------------------------------------

// One-shot global setter â€” applies to every subsequent ColorEdit/Picker call
// (default display format, picker style, etc.). Mutex held because the call
// writes to ImGui's global state and the render thread might be mid-frame.
// Returns 0=OK (no possible error â€” out-of-range bits are silently ignored
// by ImGui).
API_EXPORT int __cdecl ImGui_SetColorEditOptions(int flags)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    ImGui::SetColorEditOptions(static_cast<ImGuiColorEditFlags>(flags));
    return 0;
}

// ---- E.4 â€” Color conversion (pure math, no mutex) ---------------------------

// Decode a U32 packed color (ImGui's native byte order : 0xAABBGGRR) into
// 4 floats in [0..1]. Out is float[4] = (r, g, b, a). Returns 0=OK / 1=null.
API_EXPORT int __cdecl ImGui_ColorConvertU32ToFloat4(unsigned int u32, float* out_rgba)
{
    if (!out_rgba) return 1;
    const ImVec4 c = ImGui::ColorConvertU32ToFloat4(static_cast<ImU32>(u32));
    out_rgba[0] = c.x;
    out_rgba[1] = c.y;
    out_rgba[2] = c.z;
    out_rgba[3] = c.w;
    return 0;
}

// Encode 4 floats in [0..1] into a packed U32 (0xAABBGGRR).
// Returns the U32 directly (no error code possible â€” pure math).
API_EXPORT unsigned int __cdecl ImGui_ColorConvertFloat4ToU32(float r, float g, float b, float a)
{
    return static_cast<unsigned int>(ImGui::ColorConvertFloat4ToU32(ImVec4(r, g, b, a)));
}

// RGB â†’ HSV. All inputs in [0..1]. Out is float[3] = (h, s, v) also in [0..1].
// Returns 0=OK / 1=null.
API_EXPORT int __cdecl ImGui_ColorConvertRGBtoHSV(float r, float g, float b, float* out_hsv)
{
    if (!out_hsv) return 1;
    float h, s, v;
    ImGui::ColorConvertRGBtoHSV(r, g, b, h, s, v);
    out_hsv[0] = h; out_hsv[1] = s; out_hsv[2] = v;
    return 0;
}

// HSV â†’ RGB. All inputs in [0..1]. Out is float[3].
API_EXPORT int __cdecl ImGui_ColorConvertHSVtoRGB(float h, float s, float v, float* out_rgb)
{
    if (!out_rgb) return 1;
    float r, g, b;
    ImGui::ColorConvertHSVtoRGB(h, s, v, r, g, b);
    out_rgb[0] = r; out_rgb[1] = g; out_rgb[2] = b;
    return 0;
}

// ---- F.2 â€” Misc helpers -----------------------------------------------------

// Global setter â€” show/hide the keyboard nav focus highlight ring. b=0 hides,
// non-zero shows. Useful when the script wants to start mouse-driven and only
// reveal the nav ring on first key press.
API_EXPORT int __cdecl ImGui_SetNavCursorVisible(int b)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    ImGui::SetNavCursorVisible(b != 0);
    return 0;
}

// ImGui's internal monotonic time, seconds. Distinct from AutoIt's TimerInit/
// TimerDiff â€” this clock advances by io.DeltaTime each frame and matches what
// ImGui itself uses for animations / blink phase / popup timing. Out is double.
API_EXPORT int __cdecl ImGui_GetTime(double* out)
{
    if (!out) return 1;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    *out = ImGui::GetTime();
    return 0;
}

// Frame counter â€” increments by 1 each NewFrame(). Wraps at INT_MAX (after
// ~2 years at 60fps), no practical concern.
API_EXPORT int __cdecl ImGui_GetFrameCount(void)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);   // 0 frames returned post-shutdown
    return ImGui::GetFrameCount();
}

// Look up the human-readable name of an ImGuiCol_ slot (e.g. 0 â†’ "Text",
// 22 â†’ "Button"). Fills out[capacity] with UTF-16. Returns 0=OK, 1=null/cap<1,
// 2=index out of range (out is set to "" on this error too). 4=truncated.
API_EXPORT int __cdecl ImGui_GetStyleColorName(int idx, wchar_t* out, int capacity)
{
    if (!out || capacity < 1) return 1;
    if (idx < 0 || idx >= ImGuiCol_COUNT) {
        out[0] = L'\0';
        return 2;
    }
    // GetStyleColorName returns a static C string ; no mutex strictly needed
    // (data is immutable post-init), but we follow the same convention as the
    // other ImGui:: callers in this file for safety.
    const char* name = nullptr;
    {
        std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
        BAIL_IF_NO_IMGUI_CTX(6);
        name = ImGui::GetStyleColorName(static_cast<ImGuiCol>(idx));
    }
    if (!name) name = "";
    std::wstring wide = Utf8ToWide(name);
    bool truncated = false;
    if (static_cast<int>(wide.size()) > capacity - 1) {
        wide.resize(capacity - 1);
        truncated = true;
    }
    std::memcpy(out, wide.data(), wide.size() * sizeof(wchar_t));
    out[wide.size()] = L'\0';
    return truncated ? 4 : 0;
}

// Theme switcher : 0 = Dark (default), 1 = Light, 2 = Classic. The function
// also re-applies the multi-viewport tweak (opaque WindowBg, zero rounding)
// because StyleColors* overwrites both â€” keeps dragged-out windows looking
// right after a theme change.
// Returns 0=OK / 2=bad theme id (no-op on bad id).
API_EXPORT int __cdecl ImGui_SetStyleTheme(int theme)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    switch (theme) {
        case 0: ImGui::StyleColorsDark();    break;
        case 1: ImGui::StyleColorsLight();   break;
        case 2: ImGui::StyleColorsClassic(); break;
        default: return 2;
    }
    // Re-apply the viewport-friendly overrides (see render_thread.cpp init).
    ImGuiIO& io = ImGui::GetIO();
    if (io.ConfigFlags & ImGuiConfigFlags_ViewportsEnable) {
        ImGuiStyle& vstyle = ImGui::GetStyle();
        vstyle.WindowRounding = 0.0f;
        vstyle.Colors[ImGuiCol_WindowBg].w = 1.0f;
    }
    return 0;
}

// =============================================================================
// Phase G â€” Finition mix (TextLink + SetMouseCursor + IsKey* + ShowStyleEditor
// + Set/GetCursorPos + CalcTextSize). TextLink and Set*CursorPos* live in the
// generator (clickable / display categories) ; everything below is hand-written
// because it needs either render-thread state (sticky cursor, debug window
// round-trip) or a custom widget (GetCursorPosWidget latch).
// =============================================================================

// ---- G.2 â€” SetMouseCursor (sticky override) ---------------------------------

// Set the desired cursor shape. The override is sticky : the render thread
// applies it after every NewFrame so it survives ImGui's per-frame reset.
// Pass -1 (= $ImGuiMouseCursor_None) to release â€” ImGui then resumes its
// usual per-widget behaviour (I-beam on InputText, resize arrows on splitters,
// etc.). Returns 0 always.
API_EXPORT int __cdecl ImGui_SetMouseCursor(int cursor_type)
{
    render_thread::SetPendingMouseCursor(cursor_type);
    return 0;
}

// ---- G.3 â€” Keyboard query helpers -------------------------------------------
//
// These read ImGui's input state, which is captured per-frame by the platform
// backend. Distinct semantics from AutoIt's _IsPressed : these return true
// only when the input was routed through ImGui (window has focus AND the key
// isn't consumed by a Shortcut or InputText). Useful to gate shortcuts so
// they only fire when our panel is focused, not while the user is in-game.

API_EXPORT int __cdecl ImGui_IsKeyDown(int key)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::IsKeyDown(static_cast<ImGuiKey>(key)) ? 1 : 0;
}

// `repeat` : when non-zero (default), returns true on the initial press AND
// on repeats driven by io.KeyRepeatDelay/Rate. Zero = initial press only.
API_EXPORT int __cdecl ImGui_IsKeyPressed(int key, int repeat)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::IsKeyPressed(static_cast<ImGuiKey>(key), repeat != 0) ? 1 : 0;
}

API_EXPORT int __cdecl ImGui_IsKeyReleased(int key)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::IsKeyReleased(static_cast<ImGuiKey>(key)) ? 1 : 0;
}

// ---- G.4 â€” ShowStyleEditor toggle -------------------------------------------

API_EXPORT int __cdecl ImGui_ShowStyleEditor(int show)
{
    render_thread::SetShowStyleEditor(show != 0);
    return 0;
}

API_EXPORT int __cdecl ImGui_IsShowingStyleEditor(void)
{
    return render_thread::IsShowingStyleEditor() ? 1 : 0;
}

// ---- G.5 â€” GetCursorPos marker + query --------------------------------------
//
// SetCursorPos / SetCursorPosX / SetCursorPosY live in the display generator
// (zero-state markers). GetCursorPos can't be a free function because the
// cursor only has a meaningful value DURING a Begin/End block â€” so we model
// it as a marker widget : create it as a child of the Window/Child/Group where
// the position matters, and it latches ImGui::GetCursorPos() in its Render().
// Then ImGui_GetCursorPos reads the latched value.

struct GetCursorPosWidget : Widget {
    float pos_x = 0.0f;
    float pos_y = 0.0f;
    void Render() override {
        if (!visible) return;
        const ImVec2 p = ImGui::GetCursorPos();
        pos_x = p.x;
        pos_y = p.y;
    }
};

API_EXPORT int __cdecl ImGui_CreateGetCursorPos(const wchar_t* id)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    if (uid.empty()) return 1;
    auto w = std::make_unique<GetCursorPosWidget>();
    w->id = uid;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

// out_xy[0]=x, out_xy[1]=y in window-local coords. Returns 0=OK / 1=arg null /
// 2=unknown id / 3=widget is not a GetCursorPos marker.
API_EXPORT int __cdecl ImGui_GetCursorPos(const wchar_t* id, float* out_xy)
{
    if (!id || !*id || !out_xy) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    auto* gcp = dynamic_cast<GetCursorPosWidget*>(w);
    if (!gcp) return 3;
    out_xy[0] = gcp->pos_x;
    out_xy[1] = gcp->pos_y;
    return 0;
}

// ---- G.6 â€” CalcTextSize -----------------------------------------------------
//
// Thread-safety : ImGui::CalcTextSize reads GImGui->Font and ->FontSize, both
// stable post-NewFrame. Our build doesn't define IMGUI_USE_BX_THREAD_LOCAL_CONTEXT,
// so GImGui is a plain global â€” visible from the AutoIt thread. The mutex
// serialises us with the render thread's NewFrame/Render cycle.
//
// `wrap_width` follows ImGui semantics : <= 0 = no wrap ; > 0 = wrap at this
// pixel width. `hide_double_hash` is hardcoded false (we always render the
// full string ; "##" hash handling is for ID stripping, not display measuring).
API_EXPORT int __cdecl ImGui_CalcTextSize(const wchar_t* text, float wrap_width,
                                          float* out_xy)
{
    if (!text || !out_xy) return 1;
    std::string utxt = WideToUtf8(text);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    const ImVec2 sz = ImGui::CalcTextSize(utxt.c_str(), nullptr, false, wrap_width);
    out_xy[0] = sz.x;
    out_xy[1] = sz.y;
    return 0;
}

// =============================================================================
// Phase J.1 — Mouse helpers (complete set, mirror IsKey* shape from G.3).
// Each takes the frame lock + BAIL_IF_NO_IMGUI_CTX. Buttons are 0=Left/1=Right/2=Middle.
// =============================================================================

API_EXPORT int __cdecl ImGui_IsMouseDown(int button)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::IsMouseDown(button) ? 1 : 0;
}

API_EXPORT int __cdecl ImGui_IsMouseClicked(int button, int repeat)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::IsMouseClicked(button, repeat != 0) ? 1 : 0;
}

API_EXPORT int __cdecl ImGui_IsMouseReleased(int button)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::IsMouseReleased(button) ? 1 : 0;
}

API_EXPORT int __cdecl ImGui_IsMouseDoubleClicked(int button)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::IsMouseDoubleClicked(button) ? 1 : 0;
}

// threshold < 0 = use default (io.MouseDragThreshold). > 0 = pixel threshold.
API_EXPORT int __cdecl ImGui_IsMouseDragging(int button, float threshold)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::IsMouseDragging(button, threshold) ? 1 : 0;
}

API_EXPORT int __cdecl ImGui_ResetMouseDragDelta(int button)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    ImGui::ResetMouseDragDelta(button);
    return 0;
}

// ImGui::IsMouseHoveringRect(..., clip=true) dereferences g.CurrentWindow,
// which is null between frames — and the AutoIt thread is always between
// frames (we hold the frame mutex outside the render thread's NewFrame→End
// window). Force clip=false here ; if the user needs window-local clipping
// they can intersect with _ImGui_GetWindowPos/Size manually.
API_EXPORT int __cdecl ImGui_IsMouseHoveringRect(float min_x, float min_y,
                                                  float max_x, float max_y, int /*clip*/)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::IsMouseHoveringRect(ImVec2(min_x, min_y), ImVec2(max_x, max_y),
                                       false) ? 1 : 0;
}

// No-arg : checks last io.MousePos was inside any viewport. Returns 0/1.
API_EXPORT int __cdecl ImGui_IsMousePosValid(void)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::IsMousePosValid(nullptr) ? 1 : 0;
}

API_EXPORT int __cdecl ImGui_IsAnyMouseDown(void)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::IsAnyMouseDown() ? 1 : 0;
}

// Number of clicks accumulated within io.MouseDoubleClickTime (typically 0/1/2/3).
API_EXPORT int __cdecl ImGui_GetMouseClickedCount(int button)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::GetMouseClickedCount(button);
}

// Returns the current ImGuiMouseCursor_ enum value (-1 = None).
API_EXPORT int __cdecl ImGui_GetMouseCursor(void)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::GetMouseCursor();
}

// Force-set io.WantCaptureMouse for the next frame (overrides ImGui's auto-
// decision). Useful when AutoIt wants to swallow a click that hit the host
// background and not a widget.
API_EXPORT int __cdecl ImGui_SetNextFrameWantCaptureMouse(int want)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    ImGui::SetNextFrameWantCaptureMouse(want != 0);
    return 0;
}

// =============================================================================
// Phase M.4 — Mouse niches.
// =============================================================================

// Delayed mouse release : returns true on the frame the release event fired
// AND the prior down-event was at least `delay` seconds ago. Per the ImGui
// docs, intended for the "click then wait, then act" idiom (Windows Explorer
// single-click rename, etc.) — pair with delay >= io.MouseDoubleClickTime to
// avoid colliding with double-click detection.
API_EXPORT int __cdecl ImGui_IsMouseReleasedWithDelay(int button, float delay)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::IsMouseReleasedWithDelay(button, delay) ? 1 : 0;
}

// NOTE — GetMousePosOnOpeningCurrentPopup is exposed via a marker widget
// PopupOpenMousePosWidget (popup_extras.{h,cpp}) instead of a free function :
// the ImGui implementation returns g.IO.MousePos when g.BeginPopupStack is
// empty (i.e. when called outside a BeginPopup body), and the AutoIt thread
// is ALWAYS outside that scope (we hold the frame lock between frames). So
// only a widget rendered as a child of a popup can latch the frozen open-pos
// correctly. See popup_extras.cpp for PopupOpenMousePosWidget::Render.

// =============================================================================
// Phase J.2 — Keyboard helpers (complete set).
// =============================================================================

// $iKeyChord = $ImGuiMod_Ctrl + $ImGuiKey_S etc. Plain keys without modifier work too.
API_EXPORT int __cdecl ImGui_IsKeyChordPressed(int key_chord)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::IsKeyChordPressed(static_cast<ImGuiKeyChord>(key_chord)) ? 1 : 0;
}

// Returns how many times the key fired during this frame (initial press + repeats
// inside the repeat_delay/rate window). Useful for "Page Down held = scroll N rows".
API_EXPORT int __cdecl ImGui_GetKeyPressedAmount(int key, float repeat_delay, float rate)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(0);
    return ImGui::GetKeyPressedAmount(static_cast<ImGuiKey>(key), repeat_delay, rate);
}

// Human-readable key name (e.g. 512 → "Tab", 546 → "A"). Fills out[capacity] with
// UTF-16. Returns 0=OK, 1=null/cap<1, 4=truncated, 6=shutting down.
API_EXPORT int __cdecl ImGui_GetKeyName(int key, wchar_t* out, int capacity)
{
    if (!out || capacity < 1) return 1;
    const char* name = nullptr;
    {
        std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
        BAIL_IF_NO_IMGUI_CTX(6);
        name = ImGui::GetKeyName(static_cast<ImGuiKey>(key));
    }
    if (!name) name = "";
    std::wstring wide = Utf8ToWide(name);
    bool truncated = false;
    if (static_cast<int>(wide.size()) > capacity - 1) {
        wide.resize(capacity - 1);
        truncated = true;
    }
    std::memcpy(out, wide.data(), wide.size() * sizeof(wchar_t));
    out[wide.size()] = L'\0';
    return truncated ? 4 : 0;
}

// Force io.WantCaptureKeyboard for the next frame. Same use case as the mouse
// counterpart : let AutoIt steal keyboard input from ImGui for one frame.
API_EXPORT int __cdecl ImGui_SetNextFrameWantCaptureKeyboard(int want)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    ImGui::SetNextFrameWantCaptureKeyboard(want != 0);
    return 0;
}

// =============================================================================
// Phase J.4 — Settings memory variants.
//
// SaveIniSettingsToMemory returns a pointer into GImGui->SettingsIniData
// (valid until the next ImGui call), plus the byte count via out_size. We
// copy into the caller's wchar_t buffer with UTF-8 → UTF-16 conversion.
// Load takes an UTF-16 string (AutoIt-natural) ; we convert to UTF-8 first.
// =============================================================================

API_EXPORT int __cdecl ImGui_LoadSettingsFromMemory(const wchar_t* ini_data)
{
    if (!ini_data) return 1;
    std::string utf8 = WideToUtf8(ini_data);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    ImGui::LoadIniSettingsFromMemory(utf8.c_str(), utf8.size());
    return 0;
}

// =============================================================================
// Phase K.5 â€” Logging API.
//
// ImGui's logging stream captures rendered text into a sink (file / clipboard /
// stdout) until LogFinish is called. Useful for debug screenshots of a panel
// state in text form, or to feed a panel's content into an external pipeline.
// $iAutoOpenDepth controls auto-opening of TreeNode/CollapsingHeader children
// during the capture (-1 = use the global default, 0 = no auto-open, >0 = depth
// to auto-open up to).
//
// IMPORTANT (AutoIt thread between frames) : ImGui::LogToClipboard/File/TTY
// internally call LogBegin which dereferences `g.CurrentWindow->DC.TreeDepth`.
// CurrentWindow is null between frames on the AutoIt thread (same class of
// bug as IsMouseHoveringRect with clip=true in J.1), so we queue a pending
// "log start" request and apply it at the next NewFrame's start, when the
// render thread is inside a window scope. Status 7 = "queued, not applied yet".
// =============================================================================

namespace {
    // Pending log-start request set by LogTo* from the AutoIt thread, consumed
    // by the next ImGui::LogTo* call we issue from within the render thread
    // (it's the render thread's TickFrame that pulls and runs these). Simple
    // single-slot queue ; successive calls coalesce on the latest.
    enum PendingLogKind { PLK_None = 0, PLK_File, PLK_Clipboard, PLK_TTY, PLK_Finish };
    PendingLogKind g_pending_log_kind  = PLK_None;
    int            g_pending_log_depth = -1;
    std::string    g_pending_log_path;
}

// Accessor used by render_thread::TickFrame to drain the queue at the right
// time (inside the host's Begin/End, so g.CurrentWindow is valid).
namespace logging_pending {
    // Returns true and clears the pending slot if a request was queued.
    // out_kind/depth/path receive the dequeued values. Called UNDER g_tree.mtx
    // by the render thread.
    bool Drain(int& out_kind, int& out_depth, std::string& out_path)
    {
        if (g_pending_log_kind == PLK_None) return false;
        out_kind  = g_pending_log_kind;
        out_depth = g_pending_log_depth;
        out_path  = g_pending_log_path;
        g_pending_log_kind = PLK_None;
        g_pending_log_path.clear();
        return true;
    }
}

API_EXPORT int __cdecl ImGui_LogToFile(int auto_open_depth, const wchar_t* filename)
{
    std::string path = filename ? WideToUtf8(filename) : std::string();
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    g_pending_log_kind  = PLK_File;
    g_pending_log_depth = auto_open_depth;
    g_pending_log_path  = path;
    return 0;
}

API_EXPORT int __cdecl ImGui_LogToClipboard(int auto_open_depth)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    g_pending_log_kind  = PLK_Clipboard;
    g_pending_log_depth = auto_open_depth;
    g_pending_log_path.clear();
    return 0;
}

API_EXPORT int __cdecl ImGui_LogToTTY(int auto_open_depth)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    g_pending_log_kind  = PLK_TTY;
    g_pending_log_depth = auto_open_depth;
    g_pending_log_path.clear();
    return 0;
}

API_EXPORT int __cdecl ImGui_LogFinish(void)
{
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    // LogFinish doesn't deref CurrentWindow, so it's safe to call directly.
    // But we still queue it so a LogTo* followed by LogFinish back-to-back
    // produces a deterministic order (start then finish at the next frame).
    g_pending_log_kind  = PLK_Finish;
    g_pending_log_depth = 0;
    g_pending_log_path.clear();
    return 0;
}

// Append literal text to the active log sink (no-op if no log is active). Sent
// through ImGui::LogText with a "%s" format so embedded % characters in the
// caller's payload stay literal. LogText does NOT touch g.CurrentWindow (only
// writes to g.LogBuffer if g.LogEnabled), so it's safe to call between frames.
API_EXPORT int __cdecl ImGui_LogText(const wchar_t* text)
{
    if (!text) return 1;
    std::string utf8 = WideToUtf8(text);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    BAIL_IF_NO_IMGUI_CTX(6);
    ImGui::LogText("%s", utf8.c_str());
    return 0;
}

// Fills out[capacity] with the ini data as UTF-16 (typically pure-ASCII). The
// underlying string is internal to ImGui ; we snapshot under the lock so the
// buffer doesn't move under us. Returns 0=OK, 1=null/cap<1, 4=truncated.
API_EXPORT int __cdecl ImGui_SaveSettingsToMemory(wchar_t* out, int capacity)
{
    if (!out || capacity < 1) return 1;
    std::string snapshot;
    {
        std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
        BAIL_IF_NO_IMGUI_CTX(6);
        size_t sz = 0;
        const char* data = ImGui::SaveIniSettingsToMemory(&sz);
        if (data && sz > 0) snapshot.assign(data, sz);
    }
    std::wstring wide = Utf8ToWide(snapshot.c_str());
    bool truncated = false;
    if (static_cast<int>(wide.size()) > capacity - 1) {
        wide.resize(capacity - 1);
        truncated = true;
    }
    std::memcpy(out, wide.data(), wide.size() * sizeof(wchar_t));
    out[wide.size()] = L'\0';
    return truncated ? 4 : 0;
}
