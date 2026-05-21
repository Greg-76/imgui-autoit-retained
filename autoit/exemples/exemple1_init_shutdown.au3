#cs
================================================================================
 Example : Init / Shutdown / IsRunning / GetVersion
================================================================================
 Covers 4 exports of imgui_autoit.dll. These four are inseparable :

   _ImGui_Init        Starts the render thread and creates the window
   _ImGui_Shutdown    Cleans up (frees DX11 + ImGui context + DLL)
   _ImGui_IsRunning   True while the window is open ; used as loop predicate
   _ImGui_GetVersion  Returns the embedded Dear ImGui version string

 You can't really demonstrate any of them on its own : Init has no visible
 output, IsRunning needs a window, Shutdown is the pair of Init, GetVersion
 is the trivial first call after Init.

 A few extra widgets (Text, Separator) are used here without explanation --
 each of them has its own example file. They only serve as visual support.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     example_init_shutdown.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" example_init_shutdown.au3

 The same script works under both interpreters : the wrapper picks
 dll/bin/x86 or dll/bin/x64 automatically based on @AutoItX64.
================================================================================
#ce

#include "..\imgui_retained.au3"


; ==============================================================================
; 1. _ImGui_Init  --  start the render thread and create the Win32 window
; ==============================================================================
; Signature : _ImGui_Init($sTitle, $iWidth = 800, $iHeight = 600)
;
;   Spawns a native thread that owns : the OS window, the DirectX 11 device,
;   the ImGui context and the render loop (NewFrame -> render widgets ->
;   Render -> Present).
;
;   The AutoIt script keeps running on ITS own thread : the two never block
;   each other. That is the whole point of "retained" mode -- a Sleep(200)
;   in the script will NEVER freeze the UI.
;
;   Return : True if the window is ready, False otherwise (@error tells why :
;     1 = already initialised   2 = DLL not found
;     3 = DllOpen failed        4 = DllCall failed
;     5 = ImGui_Init returned non-zero on the DLL side)
;
;   _ImGui_Init also registers _ImGui_Shutdown via OnAutoItExitRegister,
;   so even if the script crashes the DLL is released cleanly.
;
If Not _ImGui_Init("Example : init / shutdown / running / version", 560, 280) Then
    MsgBox(16, "Initialisation error", _
        "_ImGui_Init failed (@error = " & @error & ")." & @CRLF & @CRLF & _
        "Check that dll\bin\x" & (@AutoItX64 ? "64" : "86") & "\imgui_autoit.dll exists.")
    Exit 1
EndIf


; ==============================================================================
; 2. _ImGui_GetVersion  --  read the compiled Dear ImGui version
; ==============================================================================
; Signature : _ImGui_GetVersion()
;
;   Returns the version as a plain string (e.g. "1.92.9 WIP"). The wrapper
;   hides the wchar-buffer + capacity marshalling -- you get back a string.
;
;   On failure : returns "" with @error set
;     1 = DLL not loaded   2 = DllCall failed   3 = non-zero DLL status
;
Global Const $g_sImGuiVersion = _ImGui_GetVersion()


; ==============================================================================
; 3. Demo widgets  --  visual support only, detailed in their own files
; ==============================================================================
_ImGui_CreateText("t_title",    "Lifecycle demo")
_ImGui_CreateSeparator("sep1")
_ImGui_CreateText("t_version",  "Dear ImGui version : " & $g_sImGuiVersion)
_ImGui_CreateText("t_arch",     "Interpreter arch    : " & (@AutoItX64 ? "x64" : "x86"))
_ImGui_CreateText("t_status",   "Status : running (_ImGui_IsRunning = True)")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateText("t_hint",     "Close this window via the OS [X] button to exit the loop.")


; ==============================================================================
; 4. _ImGui_IsRunning  --  loop predicate
; ==============================================================================
; Signature : _ImGui_IsRunning()
;
;   Returns True as long as the window is open and the render thread is
;   processing frames. Flips to False when :
;     - the user clicks the OS [X] close button on the window
;     - the AutoIt script calls _ImGui_Shutdown
;     - the DLL crashes (in which case @error from the DllCall is non-zero
;       but the wrapper still returns False)
;
;   On the typical main loop pattern, the script does nothing per-frame --
;   the render thread takes care of NewFrame/Render/Present. Sleep(50) just
;   throttles how often the AutoIt side polls for changes ; it does NOT
;   throttle the UI.
;
While _ImGui_IsRunning()
    Sleep(50)
WEnd


; ==============================================================================
; 5. _ImGui_Shutdown  --  clean teardown
; ==============================================================================
; Signature : _ImGui_Shutdown()
;
;   Stops the render thread, frees the DX11 device, destroys the ImGui
;   context, closes the DLL handle.
;
;   Idempotent : safe to call multiple times. _ImGui_Init already registers
;   this Shutdown via OnAutoItExitRegister, so it will run at script exit
;   anyway -- we still call it explicitly here for pedagogical symmetry
;   with _ImGui_Init.
;
_ImGui_Shutdown()
