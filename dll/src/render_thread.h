#pragma once
#include <atomic>
#include <string>
#include <thread>

// Owns the Win32 window, the DX11 device, the ImGui context and the
// per-frame loop. Lives in its own native thread so AutoIt's single thread
// remains free to run the script's own loop.
class RenderThread {
public:
    // Spawns the thread, waits for it to finish creating the window+device,
    // and returns true on success.
    bool Start(const std::wstring& title, int width, int height);

    // Signals the loop to exit, joins the thread, and tears down DX/ImGui.
    void Stop();

    bool IsRunning() const { return m_running.load(); }

private:
    void ThreadProc(std::wstring title, int width, int height);

    std::thread       m_thread;
    std::atomic<bool> m_running{false};
    std::atomic<bool> m_stop{false};
    std::atomic<bool> m_initDone{false};
    std::atomic<bool> m_initOk{false};
};

extern RenderThread g_renderThread;
