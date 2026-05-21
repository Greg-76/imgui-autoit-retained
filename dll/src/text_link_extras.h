#pragma once
#include "widget.h"
#include <string>

// L.2 — TextLink that opens an URL on click via ShellExecuteW. SECURITY :
// the URL is checked against a strict whitelist (http://, https:// only).
// Any other scheme (file://, javascript:, mailto:, ftp://, custom protocols,
// …) is silently ignored. This matters because the script may construct
// URLs dynamically from external data ; allowing file:// would let a poisoned
// payload trigger arbitrary local executions via "file://C:/Windows/System32/cmd.exe".
//
// ClickableWidget base gives us the standard `clicked` latch + ConsumeClick
// via _ImGui_WasClicked — useful when the script wants to react to the click
// independently from the URL launch (e.g. logging analytics).
struct TextLinkOpenURLWidget : ClickableWidget {
    std::string url;
    void Render() override;
};
