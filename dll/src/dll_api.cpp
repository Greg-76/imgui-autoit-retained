// C-ABI exports consumed by AutoIt via DllCall().
//
// Conventions:
//   - All strings are UTF-16 (AutoIt's native wstr). Converted to UTF-8
//     internally before being handed to ImGui.
//   - Booleans are returned as int (0 or 1) for predictable DllCall marshalling.
//   - Functions never throw across the ABI boundary. Errors are signalled
//     via the return value (0 = ok, non-zero = error).
//
// Threading: every function below runs on the AutoIt thread. The render
// thread never enters this file. Mutations and reads of the widget tree
// are serialised with g_tree.mtx.

#include <Windows.h>

#include "imgui.h"
#include "render_thread.h"
#include "widget_tree.h"
#include "utf.h"

#define IMGUI_API_EXPORT extern "C" __declspec(dllexport)

IMGUI_API_EXPORT int __cdecl ImGui_Init(const wchar_t* title, int width, int height)
{
    if (!title) title = L"ImGui";
    if (width  <= 0) width  = 800;
    if (height <= 0) height = 600;
    if (g_renderThread.IsRunning()) return 1; // already running
    return g_renderThread.Start(title, width, height) ? 0 : 2;
}

IMGUI_API_EXPORT int __cdecl ImGui_Shutdown()
{
    g_renderThread.Stop();
    return 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsRunning()
{
    return g_renderThread.IsRunning() ? 1 : 0;
}

// Global config setters â€” apply to ImGui::GetIO() under g_tree.mtx. The render
// thread holds the same mutex around NewFrame â†’ Render â†’ Present, so writes
// from the AutoIt thread are serialised with frame production. Picked up at
// the start of the next frame.
// Must be called AFTER ImGui_Init (otherwise no ImGuiContext exists yet).
IMGUI_API_EXPORT int __cdecl ImGui_SetConfigFlags(int flags)
{
    if (!g_renderThread.IsRunning()) return 1;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    ImGui::GetIO().ConfigFlags = flags;
    return 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_SetFontGlobalScale(float scale)
{
    if (!g_renderThread.IsRunning()) return 1;
    if (scale <= 0.0f) return 2;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    ImGui::GetIO().FontGlobalScale = scale;
    return 0;
}

// Caps the render thread's frame rate when the host window doesn't have
// keyboard/mouse focus. Clamped to [1, 60] inside the render thread. Default
// is 20 fps â€” sensible middle ground in the framing doc's 10-30 range, drops
// CPU/GPU enough that 6-8 idle panels coexist comfortably.
// Returns: 0 = OK. The call is always accepted (no init required) â€” the
// render thread reads the atomic on the next loop iteration.
namespace render_thread {
    void SetUnfocusedFps(int fps);
    bool AnyItemHovered();
    bool AnyItemActive();
    bool AnyItemFocused();

    void SetShowDemoWindow(bool v);
    void SetShowMetricsWindow(bool v);
    void SetShowDebugLogWindow(bool v);
    void SetShowIDStackToolWindow(bool v);
    void SetShowAboutWindow(bool v);

    bool IsShowingDemoWindow();
    bool IsShowingMetricsWindow();
    bool IsShowingDebugLogWindow();
    bool IsShowingIDStackToolWindow();
    bool IsShowingAboutWindow();
}

IMGUI_API_EXPORT int __cdecl ImGui_SetUnfocusedFps(int fps)
{
    render_thread::SetUnfocusedFps(fps);
    return 0;
}

// Debug-window toggles (D.2). The render thread checks the corresponding
// atomic each frame and renders ImGui's built-in debug window if true.
// Each window has its own X close button â€” clicking it writes false back
// to the atomic, which IsShowing* below reflects.
//
// Returns: 0 = OK (always). No init check : the atomic is harmless to flip
// even before ImGui_Init ; the render thread only acts on it once initialised.
IMGUI_API_EXPORT int __cdecl ImGui_ShowDemoWindow(int show)
{
    render_thread::SetShowDemoWindow(show != 0);
    return 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_ShowMetricsWindow(int show)
{
    render_thread::SetShowMetricsWindow(show != 0);
    return 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_ShowDebugLogWindow(int show)
{
    render_thread::SetShowDebugLogWindow(show != 0);
    return 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_ShowIDStackToolWindow(int show)
{
    render_thread::SetShowIDStackToolWindow(show != 0);
    return 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_ShowAboutWindow(int show)
{
    render_thread::SetShowAboutWindow(show != 0);
    return 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsShowingDemoWindow()
{
    return render_thread::IsShowingDemoWindow() ? 1 : 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsShowingMetricsWindow()
{
    return render_thread::IsShowingMetricsWindow() ? 1 : 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsShowingDebugLogWindow()
{
    return render_thread::IsShowingDebugLogWindow() ? 1 : 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsShowingIDStackToolWindow()
{
    return render_thread::IsShowingIDStackToolWindow() ? 1 : 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsShowingAboutWindow()
{
    return render_thread::IsShowingAboutWindow() ? 1 : 0;
}

// Writes the ImGui version string ("1.92.8" or similar) as UTF-16 into the
// caller-allocated buffer. Returns:
//   0 = ok (out written, null-terminated)
//   1 = out is null OR cap <= 0
//   4 = truncated (still null-terminated within cap, but the full version
//       string was longer â€” should never happen in practice with cap >= 16)
IMGUI_API_EXPORT int __cdecl ImGui_GetVersion(wchar_t* out, int cap)
{
    if (!out || cap <= 0) return 1;
    std::wstring ver = Utf8ToWide(IMGUI_VERSION);
    const size_t need = ver.size() + 1;
    const size_t copy_n = (need <= (size_t)cap) ? ver.size() : (size_t)(cap - 1);
    for (size_t i = 0; i < copy_n; ++i) out[i] = ver[i];
    out[copy_n] = L'\0';
    return (need <= (size_t)cap) ? 0 : 4;
}

// Settings persistence (D.4) â€” explicit opt-in helpers around ImGui's
// LoadIniSettingsFromDisk / SaveIniSettingsToDisk. `io.IniFilename = nullptr`
// stays in the init so there's no auto-save next to the AutoIt script ; callers
// pick when to load/save and to which path.
//
// Load semantics: the loaded settings populate ImGui's internal cache and
// are applied to windows on their NEXT Begin() (first appearance after the
// load). So the canonical call order is:
//   _ImGui_Init() â†’ _ImGui_LoadSettings($path) â†’ _ImGui_CreateWindow(...)
// Loading AFTER windows are already created won't retroactively move them ;
// the user must explicitly `_ImGui_SetWindowPos` for those.
//
// Thread safety: we hold g_tree.mtx around the ImGui call. The render
// thread's only point of settings access is inside Begin()/End() of the
// widget tree walk, which is also under that mutex. NewFrame doesn't touch
// the settings cache materially in our usage. Returns: 0 = OK (always â€”
// missing file on Load is a silent no-op, matching ImGui's own behavior),
// 1 = not initialized, 2 = path null/empty.
IMGUI_API_EXPORT int __cdecl ImGui_LoadSettings(const wchar_t* path)
{
    if (!g_renderThread.IsRunning()) return 1;
    if (!path || !*path) return 2;
    std::string utf8 = WideToUtf8(path);
    if (utf8.empty()) return 2;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    ImGui::LoadIniSettingsFromDisk(utf8.c_str());
    return 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_SaveSettings(const wchar_t* path)
{
    if (!g_renderThread.IsRunning()) return 1;
    if (!path || !*path) return 2;
    std::string utf8 = WideToUtf8(path);
    if (utf8.empty()) return 2;
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    ImGui::SaveIniSettingsToDisk(utf8.c_str());
    return 0;
}

// Visibility / enabled flags â€” generic for any Widget. Hidden widgets early-
// return from Render() (and a hidden container hides its whole subtree).
// Returns: 0 = ok, 1 = id invalid, 2 = unknown.
IMGUI_API_EXPORT int __cdecl ImGui_SetVisible(const wchar_t* id, int value)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    w->visible = (value != 0);
    return 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_SetEnabled(const wchar_t* id, int value)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    w->enabled = (value != 0);
    return 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_GetVisible(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->visible ? 1 : 0;
}

// Moves an existing widget under a different parent. Empty parent_id puts the
// widget back at root (under the host). Returns:
//   0 = ok
//   1 = id invalid (null/empty)
//   2 = unknown child
//   3 = unknown parent (and non-empty)
//   4 = cycle attempt / self-parent
IMGUI_API_EXPORT int __cdecl ImGui_SetParent(const wchar_t* child_id, const wchar_t* parent_id)
{
    if (!child_id || !*child_id) return 1;
    std::string uc = WideToUtf8(child_id);
    std::string up = WideToUtf8(parent_id ? parent_id : L"");
    if (uc.empty()) return 1;

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    if (!g_tree.Find(uc)) return 2;
    if (!up.empty() && !g_tree.Find(up)) return 3;
    return g_tree.SetParent(uc, up) ? 0 : 4;
}

// --- Item query exports ------------------------------------------------------
// All read the per-widget flags latched at the end of RenderAndQueryState().
// "Hovered" = mouse is currently over the widget. "Active" = widget is being
// interacted with (mouse held / dragging). "Focused" = widget has keyboard
// focus.  Returns 0 for unknown ids â€” same convention as WasClicked, so the
// AutoIt wrapper turns it into a False without raising @error.
IMGUI_API_EXPORT int __cdecl ImGui_IsHovered(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->is_hovered ? 1 : 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsActive(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->is_active ? 1 : 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsFocused(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->is_focused ? 1 : 0;
}

// Extended frame-state item queries (D.1). All read-only, frame-state:
// they return the value latched during the widget's last RenderAndQueryState()
// call without consuming it. Distinct from WasClicked / HasChanged which
// consume on read. Unknown id returns 0 (same convention as IsHovered).
IMGUI_API_EXPORT int __cdecl ImGui_IsClicked(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->is_clicked ? 1 : 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsEdited(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->is_edited ? 1 : 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsActivated(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->is_activated ? 1 : 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsDeactivated(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->is_deactivated ? 1 : 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsDeactivatedAfterEdit(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->is_deactivated_after_edit ? 1 : 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsVisible(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->is_visible ? 1 : 0;
}

// Rect getters â€” write 2 floats (x, y) to the caller's buffer. Returns:
// 0=ok (out written), 1=id/out null, 2=unknown id. Caller allocates via
// DllStructCreate("float buf[2]") on the AutoIt side. Coordinates are
// ImGui screen-space (same origin as ImGui::GetCursorScreenPos).
IMGUI_API_EXPORT int __cdecl ImGui_GetItemRectMin(const wchar_t* id, float* out_xy)
{
    if (!id || !*id || !out_xy) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    out_xy[0] = w->rect_min_x;
    out_xy[1] = w->rect_min_y;
    return 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_GetItemRectMax(const wchar_t* id, float* out_xy)
{
    if (!id || !*id || !out_xy) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    out_xy[0] = w->rect_max_x;
    out_xy[1] = w->rect_max_y;
    return 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_GetItemRectSize(const wchar_t* id, float* out_xy)
{
    if (!id || !*id || !out_xy) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    // Derived rather than stored â€” ImGui::GetItemRectSize() is itself (max-min).
    out_xy[0] = w->rect_max_x - w->rect_min_x;
    out_xy[1] = w->rect_max_y - w->rect_min_y;
    return 0;
}

// Global "any item" queries â€” OR-merged across both render passes in
// render_thread::RenderHostWindow. Atomics, no mutex needed.
IMGUI_API_EXPORT int __cdecl ImGui_IsAnyItemHovered()
{
    return render_thread::AnyItemHovered() ? 1 : 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsAnyItemActive()
{
    return render_thread::AnyItemActive() ? 1 : 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_IsAnyItemFocused()
{
    return render_thread::AnyItemFocused() ? 1 : 0;
}

// Set the tooltip string for any widget. Empty string disables the tooltip.
// Tooltip rendering happens automatically when the widget is hovered (see
// Widget::RenderAndQueryState()).  Returns: 0=ok, 1=id invalid, 2=unknown.
IMGUI_API_EXPORT int __cdecl ImGui_SetTooltip(const wchar_t* id, const wchar_t* text)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string utxt = WideToUtf8(text ? text : L"");

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    w->tooltip = utxt;
    return 0;
}

// Generic for any widget that latches a click flag (Button, SmallButton,
// Selectable, MenuItem, ...). Dispatch via virtual ConsumeClick().
IMGUI_API_EXPORT int __cdecl ImGui_WasClicked(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->ConsumeClick() ? 1 : 0;
}

// Companion to ImGui_WasClicked : consumes a separate double-click latch
// set by widgets that support the AllowDoubleClick flag (Selectable today,
// other clickables later). Detection happens on the render thread at the
// exact frame the user double-clicks, so it is reliable regardless of the
// AutoIt-side polling cadence (unlike a script-side ImGui_IsMouseDoubleClicked
// query, which races against the single-frame IO state).
IMGUI_API_EXPORT int __cdecl ImGui_WasDoubleClicked(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->ConsumeDoubleClick() ? 1 : 0;
}

// Generic for any widget exposing a bool value (Checkbox today; later anything
// derived from BoolValueWidget). Returns -1 if the id is unknown OR the widget
// is not bool-valued â€” AutoIt wrapper turns that into SetError(3).
IMGUI_API_EXPORT int __cdecl ImGui_GetValueBool(const wchar_t* id)
{
    if (!id || !*id) return -1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return -1;
    return w->GetValueBool();
}

// 0 = ok, 1 = id invalid, 2 = unknown id, 3 = widget not bool-valued.
IMGUI_API_EXPORT int __cdecl ImGui_SetValueBool(const wchar_t* id, int value)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    return w->SetValueBool(value != 0) ? 0 : 3;
}

// Generic float-value accessors â€” work for any FloatValueWidget (SliderFloat,
// DragFloat, InputFloat today). Out-param pattern because float has no valid
// sentinel for "wrong type". Return: 0=ok, 1=id invalid, 2=unknown, 3=type.
IMGUI_API_EXPORT int __cdecl ImGui_GetValueFloat(const wchar_t* id, float* out)
{
    if (!id || !*id || !out) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    return w->GetValueFloat(out) ? 0 : 3;
}

IMGUI_API_EXPORT int __cdecl ImGui_SetValueFloat(const wchar_t* id, float value)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    return w->SetValueFloat(value) ? 0 : 3;
}

// Same shape for int. Same status codes.
IMGUI_API_EXPORT int __cdecl ImGui_GetValueInt(const wchar_t* id, int* out)
{
    if (!id || !*id || !out) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    return w->GetValueInt(out) ? 0 : 3;
}

IMGUI_API_EXPORT int __cdecl ImGui_SetValueInt(const wchar_t* id, int value)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    return w->SetValueInt(value) ? 0 : 3;
}

// Vector value accessors â€” used by SliderFloat2/3/4, DragInt3, InputFloat4, etc.
// `out_buffer` is a caller-allocated array of `capacity` floats/ints. The DLL
// writes up to N components (the widget's arity) and returns N. Returns 0 if
// the widget isn't a vector of that type, or if `capacity < N`.
IMGUI_API_EXPORT int __cdecl ImGui_GetValueFloatN(const wchar_t* id, float* out_buffer, int capacity)
{
    if (!id || !*id || !out_buffer || capacity <= 0) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->GetValueFloatN(out_buffer, capacity);
}

// Returns: 0=ok, 1=id/buf invalid, 2=unknown, 3=widget is not a FloatVec of
// that arity (e.g. trying to set 3 floats on a 2-component widget).
IMGUI_API_EXPORT int __cdecl ImGui_SetValueFloatN(const wchar_t* id, const float* in_buffer, int n)
{
    if (!id || !*id || !in_buffer || n <= 0) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    return w->SetValueFloatN(in_buffer, n) ? 0 : 3;
}

IMGUI_API_EXPORT int __cdecl ImGui_GetValueIntN(const wchar_t* id, int* out_buffer, int capacity)
{
    if (!id || !*id || !out_buffer || capacity <= 0) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->GetValueIntN(out_buffer, capacity);
}

IMGUI_API_EXPORT int __cdecl ImGui_SetValueIntN(const wchar_t* id, const int* in_buffer, int n)
{
    if (!id || !*id || !in_buffer || n <= 0) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    return w->SetValueIntN(in_buffer, n) ? 0 : 3;
}

// Generic "value changed since last poll" â€” works for any widget whose
// Render() latches `changed` (BoolValueWidget, FloatValueWidget, IntValueWidget).
// Read+reset under the same lock, mirroring ImGui_WasClicked semantics.
IMGUI_API_EXPORT int __cdecl ImGui_HasChanged(const wchar_t* id)
{
    if (!id || !*id) return 0;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 0;
    return w->ConsumeChanged() ? 1 : 0;
}

IMGUI_API_EXPORT int __cdecl ImGui_CreateText(const wchar_t* id, const wchar_t* text)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string utxt = WideToUtf8(text ? text : L"");
    if (uid.empty()) return 1;

    auto t = std::make_unique<TextWidget>();
    t->id    = uid;
    t->label = utxt;

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(t)) ? 0 : 2;
}

// Applies to any widget that displays a label (text, button label, etc.).
IMGUI_API_EXPORT int __cdecl ImGui_SetText(const wchar_t* id, const wchar_t* text)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string utxt = WideToUtf8(text ? text : L"");

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2; // unknown id
    w->label = utxt;
    return 0;
}

// --- Dynamic List ------------------------------------------------------------
// Hand-written: a single widget with bespoke marshalling. See list_widget.cpp
// for the rendering / by-content selection-remap logic.

IMGUI_API_EXPORT int __cdecl ImGui_CreateList(const wchar_t* id, const wchar_t* label,
                                              float w, float h)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;

    auto widget = std::make_unique<ListWidget>();
    widget->id     = uid;
    widget->label  = ulbl;
    widget->size_x = w;
    widget->size_y = h;

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

// Splits a UTF-8 string on a separator. Empty input â†’ empty vector. Empty
// separator â†’ single-item vector containing the whole input.
static std::vector<std::string> SplitOnSep(const std::string& joined, const std::string& sep)
{
    std::vector<std::string> out;
    if (joined.empty()) return out;
    if (sep.empty()) { out.push_back(joined); return out; }
    size_t start = 0;
    while (true) {
        size_t pos = joined.find(sep, start);
        if (pos == std::string::npos) {
            out.push_back(joined.substr(start));
            break;
        }
        out.push_back(joined.substr(start, pos - start));
        start = pos + sep.size();
    }
    return out;
}

// items are passed as a single UTF-16 string joined with `sep` (default "|"
// on the AutoIt side). The wrapper validates that no individual item contains
// the separator before calling here. Returns: 0=ok, 1=id invalid, 2=unknown
// id, 3=widget is not a list.
IMGUI_API_EXPORT int __cdecl ImGui_SetListItems(const wchar_t* id, const wchar_t* joined,
                                                const wchar_t* sep)
{
    if (!id || !*id) return 1;
    std::string uid    = WideToUtf8(id);
    std::string ujoin  = WideToUtf8(joined ? joined : L"");
    std::string usep   = WideToUtf8((sep && *sep) ? sep : L"|");

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    auto* lw = dynamic_cast<ListWidget*>(w);
    if (!lw) return 3;

    lw->ApplyItems(SplitOnSep(ujoin, usep));
    return 0;
}

// Returns the selected index, or -1 if no selection / unknown id / widget is
// not a selectable (List or Combo). Works on any IndexedSelectionWidget subclass.
IMGUI_API_EXPORT int __cdecl ImGui_GetListSelection(const wchar_t* id)
{
    if (!id || !*id) return -1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return -1;
    auto* sw = dynamic_cast<IndexedSelectionWidget*>(w);
    if (!sw) return -1;
    return sw->selected_index;
}

// Programmatic selection â€” no `changed` latch. -1 clears. Out-of-range index
// also clears (defensive). Returns: 0=ok, 1=id invalid, 2=unknown,
// 3=not an indexed-selection widget (List or Combo).
IMGUI_API_EXPORT int __cdecl ImGui_SetListSelection(const wchar_t* id, int index)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    auto* sw = dynamic_cast<IndexedSelectionWidget*>(w);
    if (!sw) return 3;
    sw->SetValueInt(index);
    return 0;
}

// --- InputText / InputTextMultiline ------------------------------------------
// Two creators (same model, distinct ImGui functions). Buffer is allocated
// once at creation and never resized â€” ImGui::InputText writes in-place up to
// `max_length` bytes. Mirror the strict-changed pattern: programmatic
// SetValueString does NOT latch `changed`.

static int CreateStringWidget(std::unique_ptr<StringValueWidget> widget,
                              const wchar_t* id, const wchar_t* label,
                              const wchar_t* default_value, int max_length, int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    std::string udef = WideToUtf8(default_value ? default_value : L"");
    if (uid.empty()) return 1;
    if (max_length < 1) max_length = 1;          // need at least the null
    // Cap unreasonable sizes â€” a UI panel rarely needs a 16 MB buffer.
    if (max_length > 64 * 1024 * 1024) max_length = 64 * 1024 * 1024;

    widget->id    = uid;
    widget->label = ulbl;
    widget->flags = flags;
    widget->buffer.assign(static_cast<size_t>(max_length) + 1, '\0');
    if (!udef.empty()) {
        const size_t n = (udef.size() >= widget->buffer.size())
                         ? widget->buffer.size() - 1
                         : udef.size();
        std::memcpy(widget->buffer.data(), udef.data(), n);
    }

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

IMGUI_API_EXPORT int __cdecl ImGui_CreateInputText(const wchar_t* id, const wchar_t* label,
                                                   const wchar_t* default_value,
                                                   int max_length, int flags)
{
    return CreateStringWidget(std::make_unique<InputTextWidget>(),
                              id, label, default_value, max_length, flags);
}

IMGUI_API_EXPORT int __cdecl ImGui_CreateInputTextMultiline(const wchar_t* id, const wchar_t* label,
                                                            const wchar_t* default_value,
                                                            int max_length, int flags,
                                                            float w, float h)
{
    auto widget = std::make_unique<InputTextMultilineWidget>();
    widget->size_x = w;
    widget->size_y = h;
    return CreateStringWidget(std::move(widget),
                              id, label, default_value, max_length, flags);
}

// Reads the current buffer contents into the caller-supplied wide-char buffer.
// Returns:
//   0 = ok
//   1 = id null/empty or out_buffer null or capacity <= 0
//   2 = unknown id
//   3 = widget is not string-valued
//   4 = the value didn't fit â€” buffer was filled and null-terminated, contents
//       may be truncated (and possibly torn at a surrogate boundary).
IMGUI_API_EXPORT int __cdecl ImGui_GetValueString(const wchar_t* id, wchar_t* out_buffer,
                                                  int buffer_capacity)
{
    if (!id || !*id || !out_buffer || buffer_capacity <= 0) return 1;
    out_buffer[0] = L'\0';  // safe default

    std::string uid = WideToUtf8(id);
    std::string current;
    {
        std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
        Widget* w = g_tree.Find(uid);
        if (!w) return 2;
        if (!w->GetValueString(current)) return 3;
    }
    if (current.empty()) return 0;

    // Convert outside the lock â€” the conversion is a pure function of the
    // local std::string copy.
    std::wstring wide = Utf8ToWide(current.c_str());
    const size_t cap  = static_cast<size_t>(buffer_capacity);
    const bool   fits = wide.size() + 1 <= cap;
    const size_t copy = fits ? wide.size() : cap - 1;
    std::memcpy(out_buffer, wide.data(), copy * sizeof(wchar_t));
    out_buffer[copy] = L'\0';
    return fits ? 0 : 4;
}

// Programmatic set â€” truncates to (max_length - 1) chars. Never latches.
// Returns: 0=ok, 1=id invalid, 2=unknown, 3=not a string-valued widget.
IMGUI_API_EXPORT int __cdecl ImGui_SetValueString(const wchar_t* id, const wchar_t* value)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::string uval = WideToUtf8(value ? value : L"");

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    return w->SetValueString(uval) ? 0 : 3;
}

// --- Combo -------------------------------------------------------------------
// Shares IndexedSelectionWidget with List (items + selected_index + by-content
// preservation). Selection is read via the generic ImGui_GetListSelection /
// ImGui_GetValueInt / ImGui_HasChanged â€” no Combo-specific accessor needed.
// SetComboItems mirrors SetListItems exactly except for the dynamic_cast target.
// The SplitOnSep helper is already in scope (defined above for SetListItems).

IMGUI_API_EXPORT int __cdecl ImGui_CreateCombo(const wchar_t* id, const wchar_t* label, int flags)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;

    auto widget = std::make_unique<ComboWidget>();
    widget->id    = uid;
    widget->label = ulbl;
    widget->flags = flags;

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}

// items passed as a single UTF-16 string joined with `sep` (default "|" on the
// AutoIt side). Returns: 0=ok, 1=id invalid, 2=unknown id, 3=widget is not a
// Combo.
IMGUI_API_EXPORT int __cdecl ImGui_SetComboItems(const wchar_t* id, const wchar_t* joined,
                                                 const wchar_t* sep)
{
    if (!id || !*id) return 1;
    std::string uid    = WideToUtf8(id);
    std::string ujoin  = WideToUtf8(joined ? joined : L"");
    std::string usep   = WideToUtf8((sep && *sep) ? sep : L"|");

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    auto* cw = dynamic_cast<ComboWidget*>(w);
    if (!cw) return 3;

    cw->ApplyItems(SplitOnSep(ujoin, usep));
    return 0;
}

// --- Plot widgets ------------------------------------------------------------
// PlotLines and PlotHistogram â€” display only. The script pushes new values
// via ImGui_SetPlotValues at its own cadence. scale_min/scale_max are stored
// at creation but can be overridden with ImGui_SetPlotScale.

template<class W>
static int CreatePlotImpl(const wchar_t* id, const wchar_t* label,
                          const wchar_t* overlay, float w, float h,
                          float scale_min, float scale_max)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    std::string uov  = WideToUtf8(overlay ? overlay : L"");
    if (uid.empty()) return 1;

    auto p = std::make_unique<W>();
    p->id        = uid;
    p->label     = ulbl;
    p->overlay   = uov;
    p->size_x    = w;
    p->size_y    = h;
    p->scale_min = scale_min;
    p->scale_max = scale_max;

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(p)) ? 0 : 2;
}

IMGUI_API_EXPORT int __cdecl ImGui_CreatePlotLines(const wchar_t* id, const wchar_t* label,
                                                   const wchar_t* overlay, float w, float h,
                                                   float scale_min, float scale_max)
{
    return CreatePlotImpl<PlotLinesWidget>(id, label, overlay, w, h, scale_min, scale_max);
}

IMGUI_API_EXPORT int __cdecl ImGui_CreatePlotHistogram(const wchar_t* id, const wchar_t* label,
                                                       const wchar_t* overlay, float w, float h,
                                                       float scale_min, float scale_max)
{
    return CreatePlotImpl<PlotHistogramWidget>(id, label, overlay, w, h, scale_min, scale_max);
}

// Push a new array of float values into the plot. Replaces the previous set
// entirely. Caller passes a float* buffer + count (DllStructCreate pattern
// on the AutoIt side, like SetValueFloatN).
// Returns: 0=ok, 1=id/buf invalid, 2=unknown, 3=widget is not a plot.
IMGUI_API_EXPORT int __cdecl ImGui_SetPlotValues(const wchar_t* id, const float* in_buffer, int n)
{
    if (!id || !*id || !in_buffer || n < 0) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    auto* p = dynamic_cast<PlotBaseWidget*>(w);
    if (!p) return 3;
    p->values.assign(in_buffer, in_buffer + n);
    return 0;
}

// Update the y-axis scale at runtime. Pass FLT_MAX (3.402823466e+38) on
// either bound for auto-scale on that side.
IMGUI_API_EXPORT int __cdecl ImGui_SetPlotScale(const wchar_t* id, float scale_min, float scale_max)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    auto* p = dynamic_cast<PlotBaseWidget*>(w);
    if (!p) return 3;
    p->scale_min = scale_min;
    p->scale_max = scale_max;
    return 0;
}

// --- ProgressBar -------------------------------------------------------------
// Hand-written. Value (0..1 fraction) settable via _ImGui_SetValueFloat ;
// overlay string settable via _ImGui_SetProgressBarOverlay.
IMGUI_API_EXPORT int __cdecl ImGui_CreateProgressBar(const wchar_t* id, float default_value,
                                                     const wchar_t* overlay, float w, float h)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::string uov = WideToUtf8(overlay ? overlay : L"");
    if (uid.empty()) return 1;

    auto pb = std::make_unique<ProgressBarWidget>();
    pb->id      = uid;
    pb->value   = default_value;
    pb->overlay = uov;
    pb->size_x  = w;
    pb->size_y  = h;

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(pb)) ? 0 : 2;
}

// Updates the overlay text shown over the progress bar. Empty = ImGui default
// ("XX%"). Returns 0=ok, 1=id invalid, 2=unknown, 3=not a ProgressBar.
IMGUI_API_EXPORT int __cdecl ImGui_SetProgressBarOverlay(const wchar_t* id, const wchar_t* overlay)
{
    if (!id || !*id) return 1;
    std::string uid = WideToUtf8(id);
    std::string uov = WideToUtf8(overlay ? overlay : L"");
    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    Widget* w = g_tree.Find(uid);
    if (!w) return 2;
    auto* pb = dynamic_cast<ProgressBarWidget*>(w);
    if (!pb) return 3;
    pb->overlay = uov;
    return 0;
}

// --- RadioButton -------------------------------------------------------------
// Hand-written : the active state is exposed via _ImGui_GetValueBool /
// _ImGui_SetValueBool. The user script handles exclusivity (when a click is
// detected, unset the other radios in the group).
IMGUI_API_EXPORT int __cdecl ImGui_CreateRadioButton(const wchar_t* id, const wchar_t* label,
                                                     int default_active)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;

    auto w = std::make_unique<RadioButtonWidget>();
    w->id     = uid;
    w->label  = ulbl;
    w->active = (default_active != 0);

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

// --- CheckboxFlags -----------------------------------------------------------
// Toggles a single bit (or combination) of an int mask. The full mask is read
// via _ImGui_GetValueInt ; whether THIS box is checked via _ImGui_GetValueBool
// (returns true iff all the bits in flags_value are set in value).
IMGUI_API_EXPORT int __cdecl ImGui_CreateCheckboxFlags(const wchar_t* id, const wchar_t* label,
                                                       int default_value, int flags_value)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;

    auto w = std::make_unique<CheckboxFlagsWidget>();
    w->id          = uid;
    w->label       = ulbl;
    w->value       = default_value;
    w->flags_value = flags_value;

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(w)) ? 0 : 2;
}

// --- Selectable --------------------------------------------------------------
// Hand-written. Reads/writes via the generic bool-value exports
// (ImGui_GetValueBool/SetValueBool/HasChanged) plus ImGui_WasClicked.
IMGUI_API_EXPORT int __cdecl ImGui_CreateSelectable(const wchar_t* id, const wchar_t* label,
                                                    int default_selected, int flags,
                                                    float w, float h)
{
    if (!id || !*id) return 1;
    std::string uid  = WideToUtf8(id);
    std::string ulbl = WideToUtf8(label ? label : L"");
    if (uid.empty()) return 1;

    auto widget = std::make_unique<SelectableWidget>();
    widget->id     = uid;
    widget->label  = ulbl;
    widget->value  = (default_selected != 0);
    widget->flags  = flags;
    widget->size_x = w;
    widget->size_y = h;

    std::lock_guard<std::recursive_mutex> lk(g_tree.mtx);
    return g_tree.Add(std::move(widget)) ? 0 : 2;
}
