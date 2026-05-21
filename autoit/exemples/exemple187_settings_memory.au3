#cs
================================================================================
 Example 187 : Settings (memory)  --  LoadSettingsFromMemory + SaveSettingsToMemory
================================================================================
 Covers 2 exports of imgui_autoit.dll (inseparable cluster) :

   _ImGui_SaveSettingsToMemory   Snapshot current window state as a string
   _ImGui_LoadSettingsFromMemory Apply an ini blob previously saved

 Same payload format as the disk variants (exemple186) -- but the
 SCRIPT owns the buffer. Use case : carry ImGui settings inside a
 larger user-defined save file (game profile, encrypted vault, JSON
 wrapper, ...) without writing a temp .ini next to the script.

 Same first-Begin caveat as exemple186 :
   LoadSettingsFromMemory populates ImGui's cache. The cache is
   consulted only on each window's FIRST Begin(). To re-apply
   to live windows, use SetWindowPos / SetWindowSize per window.

 Buffer sizing for SaveSettingsToMemory :
   Default $iBufSize = 8192 wchars. Typical 3-window layout : ~200-400
   bytes -- huge slack. With many windows or docking layout, raise it.
   The slider below lets you see truncation in action :

     small buffer (e.g. 256) -> the returned blob is clipped silently.
     The wrapper currently drops the DLL's status 4 "truncated" flag
     on the floor, so detection is OBSERVATIONAL :
       * compare returned StringLen to (buffer - 1) : if equal, likely
         truncated.
       * compare blob count at small buffer vs blob count at 16384 :
         if different, the small one was truncated.

 Round-trip via custom save file :
   The last section writes the blob into @ScriptDir\settings_memory_demo.dat
   prefixed with a custom header line "; my-app v1.0 [timestamp]". The
   reader strips the header, then feeds the rest to LoadSettingsFromMemory.
   Generalisable to any "embed settings in a larger save" use case.

 Borrowed widgets : CreateWindow + SetParent (exemple100), SliderInt
 (exemple17), InputTextMultiline (exemple148), Button, Text, Separator.

 How to run :
   "C:\Program Files (x86)\AutoIt3\AutoIt3.exe"     exemple187_settings_memory.au3
   "C:\Program Files (x86)\AutoIt3\AutoIt3_x64.exe" exemple187_settings_memory.au3
================================================================================
#ce

#include "..\imgui_retained.au3"


; --- Init --------------------------------------------------------------------
If Not _ImGui_Init("Example 187 : Settings (memory)", 880, 720) Then
    MsgBox(16, "Initialisation error", "_ImGui_Init failed (@error = " & @error & ").")
    Exit 1
EndIf


; ==============================================================================
; Doc block  --  the 2-export cluster
; ==============================================================================
; _ImGui_SaveSettingsToMemory([$iBufSize = 8192])   -> String
;
;   Returns the current settings as a UTF-8 ini-format string. Empty
;   string with @error on failure (1 DLL not loaded, 2 DllCall failed,
;   3 DLL status non-zero AND not truncation). Note : truncation (DLL
;   status 4) is currently SILENTLY accepted by the wrapper -- the
;   returned data is valid up to (capacity - 1) but missing late
;   entries. Bump $iBufSize and retry to be sure.
;
; _ImGui_LoadSettingsFromMemory($sIniData)   -> Bool
;
;   Feeds the blob into ImGui's cache. Returns True on success, False
;   otherwise. Same first-Begin caveat as LoadSettings on disk : only
;   applied at each window's first appearance.


; ==============================================================================
; Two persistent sub-windows  --  enough to fill an ini snapshot
; ==============================================================================
_ImGui_CreateWindow("win_a", "Window A", 0)
_ImGui_SetWindowPos ("win_a", 40,  60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_a", 220, 130, $ImGuiCond_FirstUseEver)
_ImGui_SetVisible("win_a", True)
_ImGui_CreateText("t_a1", "Move me around then snapshot")
_ImGui_SetParent("t_a1", "win_a")
_ImGui_CreateText("t_a2", "below to see my (x,y,w,h)")
_ImGui_SetParent("t_a2", "win_a")
_ImGui_CreateText("t_a3", "embedded in the ini blob.")
_ImGui_SetParent("t_a3", "win_a")

_ImGui_CreateWindow("win_b", "Window B", 0)
_ImGui_SetWindowPos ("win_b", 280, 60,  $ImGuiCond_FirstUseEver)
_ImGui_SetWindowSize("win_b", 220, 130, $ImGuiCond_FirstUseEver)
_ImGui_SetVisible("win_b", True)
_ImGui_CreateText("t_b1", "Second window.")
_ImGui_SetParent("t_b1", "win_b")
_ImGui_CreateText("t_b2", "Two windows = ~300 bytes ini.")
_ImGui_SetParent("t_b2", "win_b")


; ==============================================================================
; Host header
; ==============================================================================
_ImGui_CreateText("t_title", "Settings (memory) demo  --  SaveSettingsToMemory + LoadSettingsFromMemory")
_ImGui_CreateText("t_hint",  "Drag the two windows, snapshot below, mutate the slider, restore -- watch them snap back.")
_ImGui_CreateSeparator("sep0")


; ==============================================================================
; Section 1  --  Snapshot to memory
; ==============================================================================
_ImGui_CreateText("t_s1_hdr", "Section 1  --  Snapshot the current layout into a string :")
_ImGui_CreateSliderInt("sl_bufsize", "##bufsize", 128, 16384, 8192, "$iBufSize = %d wchars")
_ImGui_CreateButton("btn_snapshot", "Take snapshot (SaveSettingsToMemory)")
_ImGui_CreateInputTextMultiline("in_blob", "##blob", "(no snapshot yet)", 16384, $ImGuiInputTextFlags_WordWrap, 800, 140)
_ImGui_CreateText("t_blob_info", "  blob length : 0 chars  (buffer was 0, fit margin : --)")
_ImGui_CreateSeparator("sep1")


; ==============================================================================
; Section 2  --  Restore from memory
; ==============================================================================
_ImGui_CreateText("t_s2_hdr", "Section 2  --  Restore the layout from the captured blob :")
_ImGui_CreateButton("btn_restore", "Restore from snapshot (LoadSettingsFromMemory)")
_ImGui_CreateText("t_restore_note",  _
    "  Note : Restore writes to ImGui's cache. To make the existing windows snap to the snapshot,")
_ImGui_CreateText("t_restore_note2", _
    "  we ALSO call SetWindowPos/Size per window after restore  --  the first-Begin caveat from exemple186.")
_ImGui_CreateSeparator("sep2")


; ==============================================================================
; Section 3  --  Round-trip via a custom save file
; ==============================================================================
_ImGui_CreateText("t_s3_hdr", "Section 3  --  Embed the blob inside a custom save file :")
_ImGui_CreateText("t_s3_path", "  Target file : " & @ScriptDir & "\settings_memory_demo.dat")
_ImGui_CreateButton("btn_savefile",  "Write blob + custom header to .dat")
_ImGui_CreateButton("btn_loadfile",  "Read .dat + restore (skips the header line)")
_ImGui_CreateSeparator("sep3")


; ==============================================================================
; Status
; ==============================================================================
_ImGui_CreateText("t_status", "Status : ready. Drag the two windows above, then take a snapshot.")
_ImGui_CreateSeparator("sep4")

_ImGui_CreateButton("btn_quit", "Quit")


; --- Globals -----------------------------------------------------------------
Global Const $g_sDatPath = @ScriptDir & "\settings_memory_demo.dat"
Global Const $g_sDatHeader = "; settings_memory_demo v1.0"
Global $g_sLastBlob = ""        ; what's currently shown in the InputTextMultiline
Global $g_iBufLastSnapshot = 0  ; for diagnosing truncation


; --- Bind --------------------------------------------------------------------
_ImGui_SetOnClick("btn_snapshot", "_OnSnapshot")
_ImGui_SetOnClick("btn_restore",  "_OnRestore")
_ImGui_SetOnClick("btn_savefile", "_OnSaveFile")
_ImGui_SetOnClick("btn_loadfile", "_OnLoadFile")
_ImGui_SetOnClick("btn_quit",     "_OnQuit")


; --- Main loop ---------------------------------------------------------------
While _ImGui_IsRunning()
    Sleep(50)
WEnd

_ImGui_Shutdown()


; --- Handlers ----------------------------------------------------------------

Func _OnSnapshot($sId)
    Local $iBuf = _ImGui_GetValueInt("sl_bufsize")
    Local $sBlob = _ImGui_SaveSettingsToMemory($iBuf)
    If @error Then
        _ImGui_SetText("t_status", StringFormat( _
            "Status : SaveSettingsToMemory FAILED  (@error = %d, @extended = %d).", @error, @extended))
        Return
    EndIf
    $g_sLastBlob = $sBlob
    $g_iBufLastSnapshot = $iBuf
    _ImGui_SetValueString("in_blob", $sBlob)
    Local $iLen = StringLen($sBlob)
    Local $sFit
    If $iLen >= ($iBuf - 1) Then
        $sFit = StringFormat("FULL / likely TRUNCATED -- raise buffer (currently %d).", $iBuf)
    Else
        $sFit = StringFormat("%d unused chars left (%.1f%% fit).", $iBuf - $iLen, ($iLen * 100.0) / $iBuf)
    EndIf
    _ImGui_SetText("t_blob_info", StringFormat( _
        "  blob length : %d chars  (buffer was %d, %s)", $iLen, $iBuf, $sFit))
    _ImGui_SetText("t_status", "Status : snapshot captured. Now drag the windows somewhere else, then click Restore.")
EndFunc

Func _OnRestore($sId)
    ; Read whatever is currently in the InputTextMultiline -- lets the user
    ; hand-edit the blob if they want to play.
    Local $sBlob = _ImGui_GetValueString("in_blob", 16384)
    If $sBlob = "" Or $sBlob = "(no snapshot yet)" Then
        _ImGui_SetText("t_status", "Status : Restore ignored -- take a snapshot first (or paste a valid ini in the box).")
        Return
    EndIf
    Local $bOk = _ImGui_LoadSettingsFromMemory($sBlob)
    If Not $bOk Then
        _ImGui_SetText("t_status", StringFormat( _
            "Status : LoadSettingsFromMemory FAILED  (@error = %d).", @error))
        Return
    EndIf
    ; First-Begin caveat : the cache is set but live windows won't move
    ; unless we coerce them. Parse the captured Pos / Size out of the ini
    ; and apply via SetWindowPos / SetWindowSize.
    _ApplyIniToLiveWindows($sBlob)
    _ImGui_SetText("t_status", "Status : restored from snapshot (+ live SetWindowPos/Size applied).")
EndFunc

Func _OnSaveFile($sId)
    If $g_sLastBlob = "" Then
        _ImGui_SetText("t_status", "Status : take a snapshot first -- nothing to write.")
        Return
    EndIf
    Local $sHeader = $g_sDatHeader & " [" & _DateTimeNowIso() & "]" & @CRLF
    Local $hFile = FileOpen($g_sDatPath, 2 + 8 + 256)  ; overwrite + create dir + UTF-8
    If $hFile = -1 Then
        _ImGui_SetText("t_status", "Status : FileOpen FAILED for " & $g_sDatPath)
        Return
    EndIf
    FileWrite($hFile, $sHeader)
    FileWrite($hFile, $g_sLastBlob)
    FileClose($hFile)
    Local $iSize = FileGetSize($g_sDatPath)
    _ImGui_SetText("t_status", StringFormat( _
        "Status : wrote %d bytes to %s (1 header line + blob).", $iSize, $g_sDatPath))
EndFunc

Func _OnLoadFile($sId)
    If Not FileExists($g_sDatPath) Then
        _ImGui_SetText("t_status", "Status : " & $g_sDatPath & " does not exist. Click 'Write blob' first.")
        Return
    EndIf
    Local $hFile = FileOpen($g_sDatPath, 256)  ; UTF-8 read
    If $hFile = -1 Then
        _ImGui_SetText("t_status", "Status : FileOpen FAILED for " & $g_sDatPath)
        Return
    EndIf
    Local $sAll = FileRead($hFile)
    FileClose($hFile)
    ; Strip the first line (our custom header) ; everything after is the ini blob.
    Local $iNewline = StringInStr($sAll, @CRLF)
    If $iNewline = 0 Then $iNewline = StringInStr($sAll, @LF)
    Local $sBlob = (($iNewline > 0) ? StringMid($sAll, $iNewline + 2) : $sAll)
    Local $bOk = _ImGui_LoadSettingsFromMemory($sBlob)
    If Not $bOk Then
        _ImGui_SetText("t_status", StringFormat( _
            "Status : LoadSettingsFromMemory FAILED (@error = %d).", @error))
        Return
    EndIf
    _ImGui_SetValueString("in_blob", $sBlob)
    $g_sLastBlob = $sBlob
    _ApplyIniToLiveWindows($sBlob)
    _ImGui_SetText("t_status", "Status : .dat loaded, header stripped, blob applied (live windows coerced).")
EndFunc

Func _OnQuit($sId)
    _ImGui_Shutdown()
EndFunc


; Helper : ISO-ish timestamp for the custom header.
Func _DateTimeNowIso()
    Return StringFormat("%04d-%02d-%02d %02d:%02d:%02d", _
        @YEAR, @MON, @MDAY, @HOUR, @MIN, @SEC)
EndFunc


; Helper : parse an ImGui ini blob and SetWindowPos/Size for our two
; live windows. ImGui's format is sections like :
;   [Window][Window A]
;   Pos=40,60
;   Size=220,130
;   Collapsed=0
; We grep each section by name. Naive but sufficient for the demo --
; production code would use a real parser.
Func _ApplyIniToLiveWindows($sBlob)
    _ApplyIniSection($sBlob, "Window A", "win_a")
    _ApplyIniSection($sBlob, "Window B", "win_b")
EndFunc

Func _ApplyIniSection($sBlob, $sWinTitle, $sWidgetId)
    Local $sMarker = "[Window][" & $sWinTitle & "]"
    Local $iStart = StringInStr($sBlob, $sMarker)
    If $iStart = 0 Then Return
    ; Limit search to the current section (until the next [) so a later
    ; window's Pos= doesn't bleed in.
    Local $sTail = StringMid($sBlob, $iStart + StringLen($sMarker))
    Local $iNextSection = StringInStr($sTail, @LF & "[")
    If $iNextSection > 0 Then $sTail = StringLeft($sTail, $iNextSection - 1)

    Local $aPos  = StringRegExp($sTail, "Pos=(-?\d+),(-?\d+)", 1)
    Local $aSize = StringRegExp($sTail, "Size=(-?\d+),(-?\d+)", 1)
    If IsArray($aPos) Then
        _ImGui_SetWindowPos($sWidgetId, Number($aPos[0]), Number($aPos[1]), $ImGuiCond_Always)
    EndIf
    If IsArray($aSize) Then
        _ImGui_SetWindowSize($sWidgetId, Number($aSize[0]), Number($aSize[1]), $ImGuiCond_Always)
    EndIf
EndFunc
