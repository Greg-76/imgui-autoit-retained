#cs
================================================================================
 Example 186 : Settings (disk)  --  LoadSettings + SaveSettings
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_LoadSettings   Read an .ini file into ImGui's internal cache
   _ImGui_SaveSettings   Write the current window state to an .ini file

 What ImGui's "settings" actually persists :
   * Top-level window positions
   * Top-level window sizes
   * Top-level window collapsed flag
   * (with the docking branch : dock layout -- we don't ship that)

 What it does NOT persist : widget values (slider positions, checkbox
 states, edited text). Those live in the AutoIt-side state OR in the
 widget tree -- if you want them across runs, save them yourself via
 IniWrite / FileWrite.

 Why opt-in : the DLL clears `io.IniFilename = nullptr` at init, so
 ImGui's automatic save-on-shutdown is DISABLED. Otherwise a stray
 `imgui.ini` would appear next to every script that uses the wrapper.
 LoadSettings / SaveSettings are how scripts persist layout when they
 want to -- and only then.

 The CRITICAL caveat (new Decisions log entry) :
   * LoadSettings populates ImGui's internal cache.
   * The cache is consulted ONLY at each window's FIRST Begin().
   * Loading AFTER _ImGui_CreateWindow has run does NOT retroactively
     move existing windows.
 Canonical order is therefore :
   _ImGui_Init(...)
   _ImGui_LoadSettings(...)        <-- BEFORE any CreateWindow
   _ImGui_CreateWindow("a", ...)
   _ImGui_CreateWindow("b", ...)
   ...
   _ImGui_SaveSettings(...)        <-- on exit or on a button click

 For the "live re-apply" case (script wants to reset positions while
 windows already exist), parse the ini yourself OR call SetWindowPos /
 SetWindowSize per window. The "Reset via SetWindowPos" button below
 demonstrates the escape hatch.

 Missing file on Load is a SILENT NO-OP (returns True) -- safe to
 call unconditionally at startup before the first save has happened.

 Borrowed widgets : CreateWindow + SetParent + SetWindowPos/Size
 (exemples 100, 108, 109), Button, Text, Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple186_settings_disk.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple186_settings_disk.au3

 Try it :
   1. Drag / resize the three sub-windows wherever you like.
   2. Click "Save Now" -- the .ini is written next to the script.
   3. Quit, then re-launch -- the LoadSettings call at the top of this
      script reapplies your layout on each window's first Begin().
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 186 : Settings (disk)", 820, 560) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 2-export cluster
; ==============================================================================
; _ImGui_LoadSettings($sPath)   -> Bool
; _ImGui_SaveSettings($sPath)   -> Bool
;
;   $sPath : path to the .ini file (UTF-8). LoadSettings : missing file
;            is a silent no-op (returns True). SaveSettings : overwrites
;            unconditionally.
;
;   Returns : True on success, False otherwise. @error :
;     1 = DLL not loaded
;     2 = DllCall failed OR empty path (@extended = 2 for empty path)
;     3 = DLL not initialized (call _ImGui_Init first)


; ==============================================================================
; CRITICAL : LoadSettings BEFORE any _ImGui_CreateWindow call
; ==============================================================================
; The next 4 lines are the canonical "restore layout on startup" pattern.
; Order matters : populate the cache, THEN create the windows. The cache
; is consulted by each window's first Begin() and never again.
Global Const $g_sIniPath = @ScriptDir & "\settings_disk_demo.ini"
Global $g_iSaveCount = 0
Global $g_iLoadCount = 0
_ImGui_LoadSettings($g_sIniPath)   ; silent no-op on first run (file absent)
$g_iLoadCount += 1


; ==============================================================================
; Three persistent sub-windows  --  positions/sizes survive Save/Reload
; ==============================================================================
_ImGui_CreateWindow("win_a", "Window A  --  drag me", 0)
_ImGui_SetWindowPos ("win_a", 40,  60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_a", 220, 140, $ImGuiCond_FirstUseEver)
_ImGui_SetVisible("win_a", True)

_ImGui_CreateText("t_a1", "Move / resize me freely.")
_ImGui_SetParent("t_a1", "win_a")
_ImGui_CreateText("t_a2", "My position is persisted")
_ImGui_SetParent("t_a2", "win_a")
_ImGui_CreateText("t_a3", "to settings_disk_demo.ini.")
_ImGui_SetParent("t_a3", "win_a")


_ImGui_CreateWindow("win_b", "Window B  --  resize me", 0)
_ImGui_SetWindowPos ("win_b", 280, 60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_b", 220, 140, $ImGuiCond_FirstUseEver)
_ImGui_SetVisible("win_b", True)

_ImGui_CreateText("t_b1", "Try collapsing me")
_ImGui_SetParent("t_b1", "win_b")
_ImGui_CreateText("t_b2", "via the title-bar caret  --")
_ImGui_SetParent("t_b2", "win_b")
_ImGui_CreateText("t_b3", "the collapsed state persists too.")
_ImGui_SetParent("t_b3", "win_b")


_ImGui_CreateWindow("win_c", "Window C  --  collapse me", 0)
_ImGui_SetWindowPos ("win_c", 520, 60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_c", 240, 140, $ImGuiCond_FirstUseEver)
_ImGui_SetVisible("win_c", True)

_ImGui_CreateText("t_c1", "Third window.")
_ImGui_SetParent("t_c1", "win_c")
_ImGui_CreateText("t_c2", "ImGui stores my (x,y,w,h)")
_ImGui_SetParent("t_c2", "win_c")
_ImGui_CreateText("t_c3", "and my collapsed flag.")
_ImGui_SetParent("t_c3", "win_c")


; ==============================================================================
; Host header + controls (rendered in the main viewport)
; ==============================================================================
_ImGui_CreateText("t_title", "Settings (disk) demo  --  LoadSettings / SaveSettings")
_ImGui_CreateText("t_hint",  "Drag / resize the sub-windows, click Save, then re-launch the script.")
_ImGui_CreateSeparator("sep0")

_ImGui_CreateText("t_path",  "Settings file : " & $g_sIniPath)
_ImGui_CreateText("t_size",  "  Current size : (not yet written)")
_ImGui_CreateSeparator("sep1")

_ImGui_CreateText("t_act_hdr", "Actions :")
_ImGui_CreateButton("btn_save",     "Save Now  (SaveSettings -> disk)")
_ImGui_CreateButton("btn_load",     "Load Now  (LoadSettings -- see caveat below)")
_ImGui_CreateButton("btn_reset",    "Reset via SetWindowPos  (live escape hatch)")
_ImGui_CreateButton("btn_refresh",  "Refresh file size readout")
_ImGui_CreateSeparator("sep2")

_ImGui_CreateText("t_caveat_hdr", "The first-Begin caveat :")
_ImGui_CreateTextWrapped("t_caveat",  _
    "LoadSettings populates ImGui's internal cache. The cache is applied to each window only on its FIRST Begin() -- " & _
    "so 'Load Now' AFTER startup will NOT retroactively move the three sub-windows. " & _
    "To reset their positions live, use the 'Reset via SetWindowPos' button below (the manual escape hatch).")
_ImGui_CreateSeparator("sep3")

_ImGui_CreateText("t_status",  "Status : ready. (Loads on this run: 1)")
_ImGui_CreateSeparator("sep4")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_save",    "_OnSave")
_ImGui_SetOnClick("btn_load",    "_OnLoad")
_ImGui_SetOnClick("btn_reset",   "_OnReset")
_ImGui_SetOnClick("btn_refresh", "_OnRefresh")
_ImGui_SetOnClick("btn_quit",    "_OnQuit")
_ImGui_SetOnTick("_OnRefresh", 2000)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

; Persist on exit -- canonical pattern. (User can disable by deleting the line
; if they prefer "no auto-save".)
_ImGui_SaveSettings($g_sIniPath)
$g_iSaveCount += 1

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnSave($sId)
    Local $bOk = _ImGui_SaveSettings($g_sIniPath)
    If Not $bOk Then
        _ImGui_SetText("t_status", StringFormat( _
            "Status : SaveSettings FAILED  (@error = %d, @extended = %d).", @error, @extended))
        Return
    EndIf
    $g_iSaveCount += 1
    Local $iSize = FileGetSize($g_sIniPath)
    If $iSize = "" Then $iSize = -1
    _ImGui_SetText("t_size", StringFormat("  Current size : %d bytes", $iSize))
    _ImGui_SetText("t_status", StringFormat( _
        "Status : saved (saves this run : %d). Re-launch the script to see the layout restored.", _
        $g_iSaveCount))
EndFunc

Func _OnLoad($sId)
    Local $bOk = _ImGui_LoadSettings($g_sIniPath)
    If Not $bOk Then
        _ImGui_SetText("t_status", StringFormat( _
            "Status : LoadSettings FAILED  (@error = %d, @extended = %d).", @error, @extended))
        Return
    EndIf
    $g_iLoadCount += 1
    _ImGui_SetText("t_status", StringFormat( _
        "Status : LoadSettings OK (loads this run : %d) -- but the THREE sub-windows did NOT move. " & _
        "First-Begin caveat : the cache only applies to fresh windows. " & _
        "Use 'Reset via SetWindowPos' for live re-application.", _
        $g_iLoadCount))
EndFunc

Func _OnReset($sId)
    ; Escape hatch : LoadSettings can't move existing windows, but
    ; SetWindowPos/Size with $ImGuiCond_Always can. This is what the
    ; script must do per-window when it wants to re-apply layout to
    ; live windows.
    _ImGui_SetWindowPos ("win_a", 40,  60,  $ImGuiCond_Always)
    _ImGui_SetWindowSize("win_a", 220, 140, $ImGuiCond_Always)
    _ImGui_SetWindowPos ("win_b", 280, 60,  $ImGuiCond_Always)
    _ImGui_SetWindowSize("win_b", 220, 140, $ImGuiCond_Always)
    _ImGui_SetWindowPos ("win_c", 520, 60,  $ImGuiCond_Always)
    _ImGui_SetWindowSize("win_c", 240, 140, $ImGuiCond_Always)
    _ImGui_SetText("t_status", "Status : positions reset via SetWindowPos (live, no LoadSettings needed).")
EndFunc

Func _OnRefresh($sId = "")
    Local $iSize = FileGetSize($g_sIniPath)
    If @error Or $iSize = "" Then
        _ImGui_SetText("t_size", "  Current size : (not yet written)")
    Else
        _ImGui_SetText("t_size", StringFormat("  Current size : %d bytes", $iSize))
    EndIf
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
