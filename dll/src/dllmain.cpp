#include <Windows.h>
#include "render_thread.h"

BOOL APIENTRY DllMain(HMODULE /*hModule*/, DWORD reason, LPVOID /*reserved*/)
{
    switch (reason) {
    case DLL_PROCESS_ATTACH:
        // Nothing to do: render thread is started lazily by ImGui_Init.
        break;
    case DLL_PROCESS_DETACH:
        // Safety net only — the AutoIt wrapper should call ImGui_Shutdown
        // from OnAutoItExitRegister. Running Stop() here would deadlock if
        // the loader lock is held, so we deliberately do nothing.
        break;
    }
    return TRUE;
}
