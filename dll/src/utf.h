#pragma once
#include <string>

// AutoIt passes strings as UTF-16 (wstr). ImGui expects UTF-8.
// These helpers convert between the two at the DLL boundary.

std::string WideToUtf8(const wchar_t* w);
std::wstring Utf8ToWide(const char* s);
