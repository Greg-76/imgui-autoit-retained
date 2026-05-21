#cs
================================================================================
 Example 171 : _ImGui_LoadFontFromMemory
================================================================================
 Covers 1 export of imgui_autoit.dll :

   _ImGui_LoadFontFromMemory   Load a TTF from a memory buffer
                               (pointer + size) instead of a disk path

 Use case : the TTF lives somewhere other than a regular file --
 embedded as a binary resource, downloaded over the network,
 generated at runtime, decrypted from an obfuscated container, ...

 The DLL makes its OWN internal copy of the bytes, so the caller's
 buffer can be freed / reused right after the call. font_id behaves
 exactly like LoadFont's (exemple170).

 The marshalling pattern (Win32 / AutoIt) is verbose but mechanical :
   1. Open the file in binary mode (FileOpen, flag 16)
   2. Read all bytes into a Binary value (FileRead)
   3. Create a DllStruct sized to the byte count
   4. Stuff the Binary into the struct (DllStructSetData)
   5. Get the struct pointer (DllStructGetPtr)
   6. Call LoadFontFromMemory with (pointer, size, pixel_size)

 The same pattern works with bytes from any source (InetRead,
 BinaryString, etc.). FileRead is just the most familiar.

 Borrowed widgets : PushFont + PopFont (exemple86 / 87), Button,
 Text + Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple171_font_loadfrom_memory.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple171_font_loadfrom_memory.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 171 : _ImGui_LoadFontFromMemory", 720, 480) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; _ImGui_LoadFontFromMemory  --  doc block
; ==============================================================================
; Signature : _ImGui_LoadFontFromMemory($pBuffer, $iSize, $fSize)
;
;   $pBuffer : pointer to a binary buffer holding TTF/OTF bytes.
;              Build via DllStructCreate + DllStructSetData (canonical
;              pattern below) or any other source of a valid pointer.
;
;   $iSize   : buffer size in bytes.
;
;   $fSize   : pixel size at which to bake the glyphs.
;
;   ImGui COPIES the bytes internally -- the caller's buffer is no
;   longer needed once LoadFontFromMemory returns.
;
;   Return : font_id (>= 1) on success, -1 with @error / @extended
;            (same codes as LoadFont).


; ==============================================================================
; Read a TTF off disk into a memory buffer, then hand the buffer to ImGui
; ==============================================================================
Global Const $g_sFontPath = @ScriptDir & "\..\..\dll\imgui-docking\misc\fonts\Cousine-Regular.ttf"
Global $g_iFont = -1
Global $g_iBytes = 0

If FileExists($g_sFontPath) Then
    ; Step 1 : open the TTF in binary mode (flag 16) and read all bytes.
    Local $hFile = FileOpen($g_sFontPath, 16)
    If $hFile <> -1 Then
        Local $bData = FileRead($hFile)
        FileClose($hFile)
        $g_iBytes = BinaryLen($bData)
        If $g_iBytes > 0 Then
            ; Step 2 : copy the Binary into a DllStruct-sized buffer.
            Local $tBuf = DllStructCreate("byte data[" & $g_iBytes & "]")
            DllStructSetData($tBuf, "data", $bData)
            ; Step 3 : hand the pointer to LoadFontFromMemory.
            ; ImGui makes its own internal copy ; $tBuf can be freed right after.
            $g_iFont = _ImGui_LoadFontFromMemory(DllStructGetPtr($tBuf), $g_iBytes, 18.0)
        EndIf
    EndIf
EndIf


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "LoadFontFromMemory  --  TTF read into a buffer + handed to ImGui as (ptr, size)")
_ImGui_CreateText("t_path",   "Source : " & $g_sFontPath)
_ImGui_CreateText("t_status", StringFormat("Read %d bytes from file ; font_id = %d   (-1 = read or load failed)", $g_iBytes, $g_iFont))
_ImGui_CreateText("t_count",  "Total fonts in atlas : (waiting)")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Render the same line in default + memory-loaded font
; ==============================================================================
_ImGui_CreateText("t_def_hdr", "Default font (font_id = 0, Calibri 15.5pt) :")
_ImGui_CreateText("t_def",     "  The quick brown fox jumps over the lazy dog.")
_ImGui_CreateSeparator("sep1")

If $g_iFont >= 0 Then
    _ImGui_CreateText("t_mem_hdr", "Cousine-Regular 18pt loaded from MEMORY :")
    _ImGui_CreatePushFont("pf_mem", $g_iFont)
    _ImGui_CreateText("t_mem", "  The quick brown fox jumps over the lazy dog.  (mono-looking font)")
    _ImGui_CreatePopFont("pop_mem")
    _ImGui_CreateSeparator("sep2")
EndIf

_ImGui_CreateButton("btn_quit", "Quit")


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_quit", "_OnQuit")
_ImGui_SetOnTick("_OnPollCount", 300)


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnPollCount()
    _ImGui_SetText("t_count", "Total fonts in atlas : " & _ImGui_GetFontCount())
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc
