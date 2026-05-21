#cs
================================================================================
 Example 166 : _ImGui_LoadTexture (+ _ImGui_GetTextureSize)
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_LoadTexture     Load a PNG / JPG / BMP into a DX11 SRV ;
                          returns a tex_id (>= 0) and ByRef out (w, h)
   _ImGui_GetTextureSize  Read native (width, height) for an existing
                          tex_id  --  cross-check / late lookup

 The DLL uses Windows Imaging Component (WIC) under the hood, so any
 codec WIC supports works (PNG, JPG, BMP, TIFF, GIF, ...). The
 texture lives on the GPU as a D3D11 ShaderResourceView until
 _ImGui_Shutdown -- there is intentionally no FreeTexture API in the
 MVP, so don't load thousands of textures in a session.

 The asset paths below point at files in the sibling `tests\` folder
 (images.png and Superman-Logo.jpg). If they are missing, LoadTexture
 returns -1 and the example renders a status line saying so.

 GetTextureSize is the canonical way to size derived widgets : you
 might display the image at half its native dims, or compute aspect-
 ratio constraints, ... GetTextureSize returns (0, 0) on unknown
 tex_id without crashing.

 Borrowed widgets : Text + Separator + Button.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple166_texture_load.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple166_texture_load.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 166 : LoadTexture + GetTextureSize", 720, 460) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 2-export cluster
; ==============================================================================
; LoadTexture($sPath, ByRef $iW, ByRef $iH) -> int tex_id (>= 0) or -1
;   $iW, $iH : ByRef out params, receive the texture's native pixel
;              size on success. Untouched on failure.
;   @error / @extended on failure : 1=DLL not loaded, 2=DllCall failed,
;     3=DLL error -- @extended = 1=bad args / 2=device not ready /
;                     3=WIC or D3D load failed / 6=shutting down.
;
; GetTextureSize($iTexId) -> array[2] = (w, h)
;   Returns (0, 0) with @error = 3 on unknown tex_id.


; ==============================================================================
; Load two assets shipped with the repo's tests/ folder
; ==============================================================================
Global $g_iWPng,  $g_iHPng
Global $g_iWJpg,  $g_iHJpg
Global $g_iTexPng = _ImGui_LoadTexture(@ScriptDir & "\images.png",        $g_iWPng, $g_iHPng)
Global $g_iTexJpg = _ImGui_LoadTexture(@ScriptDir & "\images.jpg", $g_iWJpg, $g_iHJpg)


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "LoadTexture + GetTextureSize  --  load PNG + JPG from sibling tests\ folder")
_ImGui_CreateText("t_hint",  "tex_id values below : >=0 on success, -1 if the file is missing.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; LoadTexture results (ByRef out params)
; ==============================================================================
_ImGui_CreateText("t_load_hdr", "LoadTexture ByRef out params (filled at load time) :")
_ImGui_CreateText("t_load_png", StringFormat("  images.png         : tex_id = %d   native (W, H) = (%d, %d)", $g_iTexPng, $g_iWPng, $g_iHPng))
_ImGui_CreateText("t_load_jpg", StringFormat("  Superman-Logo.jpg  : tex_id = %d   native (W, H) = (%d, %d)", $g_iTexJpg, $g_iWJpg, $g_iHJpg))
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; GetTextureSize  --  independent read-back path (validate / late lookup)
; ==============================================================================
_ImGui_CreateText("t_get_hdr", "GetTextureSize live readback (independent of ByRef path) :")
_ImGui_CreateText("t_get_png", "  images.png         : (waiting)")
_ImGui_CreateText("t_get_jpg", "  Superman-Logo.jpg  : (waiting)")
_ImGui_CreateText("t_get_bad", "  unknown id 999     : (waiting)  -- expected (0, 0) + @error = 3")
_ImGui_CreateSeparator("sep2")
_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPoll", 200)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPoll()
    Local $aPng = _ImGui_GetTextureSize($g_iTexPng)
    Local $aJpg = _ImGui_GetTextureSize($g_iTexJpg)
    Local $aBad = _ImGui_GetTextureSize(999)
    If IsArray($aPng) Then _ImGui_SetText("t_get_png", StringFormat("  images.png         : (%d, %d)", $aPng[0], $aPng[1]))
    If IsArray($aJpg) Then _ImGui_SetText("t_get_jpg", StringFormat("  Superman-Logo.jpg  : (%d, %d)", $aJpg[0], $aJpg[1]))
    If IsArray($aBad) Then _ImGui_SetText("t_get_bad", StringFormat("  unknown id 999     : (%d, %d)  -- expected (0, 0) + @error = 3", $aBad[0], $aBad[1]))
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
