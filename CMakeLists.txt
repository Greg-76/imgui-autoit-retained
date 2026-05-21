cmake_minimum_required(VERSION 3.20)
project(imgui_autoit_retained LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Static C/C++ runtime so the DLL has no MSVCP redist dependency
# (cf. doc §9 "Robustesse de chargement").
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set(IMGUI_DIR "${CMAKE_SOURCE_DIR}/dll/imgui-docking" CACHE PATH "Path to Dear ImGui source tree (docking branch — multi-viewport enabled by default)")

if(NOT EXISTS "${IMGUI_DIR}/imgui.h")
    message(FATAL_ERROR "Dear ImGui not found at ${IMGUI_DIR}. Set IMGUI_DIR.")
endif()

set(IMGUI_SOURCES
    ${IMGUI_DIR}/imgui.cpp
    ${IMGUI_DIR}/imgui_draw.cpp
    ${IMGUI_DIR}/imgui_tables.cpp
    ${IMGUI_DIR}/imgui_widgets.cpp
    ${IMGUI_DIR}/imgui_demo.cpp   # defines ImGui::ShowDemoWindow + ShowAboutWindow (D.2)
    ${IMGUI_DIR}/backends/imgui_impl_win32.cpp
    ${IMGUI_DIR}/backends/imgui_impl_dx11.cpp
)

set(DLL_SOURCES
    dll/src/dllmain.cpp
    dll/src/dll_api.cpp
    dll/src/utf.cpp
    dll/src/widget.cpp
    dll/src/widget_tree.cpp
    dll/src/list_widget.cpp
    dll/src/combo_widget.cpp
    dll/src/selectable_widget.cpp
    dll/src/bool_extras.cpp
    dll/src/progress_bar.cpp
    dll/src/plot_widget.cpp
    dll/src/input_text.cpp
    dll/src/render_thread.cpp
    dll/src/window_widget.cpp
    dll/src/tree_extras.cpp
    dll/src/tab_extras.cpp
    dll/src/popup_extras.cpp
    dll/src/e2_extras.cpp
    dll/src/utils_extras.cpp
    dll/src/tooltip_extras.cpp
    dll/src/font_extras.cpp
    dll/src/texture_loader.cpp
    dll/src/image_extras.cpp
    dll/src/table_extras.cpp
    dll/src/hover_extras.cpp          # K.1
    dll/src/radio_group_extras.cpp    # K.2
    dll/src/input_double_extras.cpp   # K.2
    dll/src/debug_inline_extras.cpp   # L.1 + L.4
    dll/src/text_link_extras.cpp      # L.2
)

# Auto-generated sources (produced by dll/tools/generate.py). Listed explicitly
# rather than via file(GLOB) so CMake re-runs when the file set changes.
set(GENERATED_SOURCES
    dll/src/generated/widgets_clickable.cpp
    dll/src/generated/dll_api_clickable.cpp
    dll/src/generated/widgets_value_bool.cpp
    dll/src/generated/dll_api_value_bool.cpp
    dll/src/generated/widgets_value_numeric.cpp
    dll/src/generated/dll_api_value_numeric.cpp
    dll/src/generated/widgets_display.cpp
    dll/src/generated/dll_api_display.cpp
    dll/src/generated/widgets_config.cpp
    dll/src/generated/dll_api_config.cpp
    dll/src/generated/widgets_container.cpp
    dll/src/generated/dll_api_container.cpp
    dll/src/generated/widgets_text.cpp
    dll/src/generated/dll_api_text.cpp
    dll/src/generated/widgets_color.cpp
    dll/src/generated/dll_api_color.cpp
)

add_library(imgui_autoit SHARED
    ${DLL_SOURCES}
    ${GENERATED_SOURCES}
    ${IMGUI_SOURCES}
)

target_include_directories(imgui_autoit PRIVATE
    dll/src
    ${IMGUI_DIR}
    ${IMGUI_DIR}/backends
)

target_link_libraries(imgui_autoit PRIVATE
    d3d11
    dxgi
    windowscodecs   # H.4 — WIC for PNG/JPG decoding in texture_loader.cpp
    shell32         # L.2 — ShellExecuteW in text_link_extras.cpp
)

# Same canonical name (imgui_autoit.dll) for both architectures — the arch
# lives in the parent directory (dll/bin/x86/ vs dll/bin/x64/). The AutoIt
# wrapper selects the right folder based on @AutoItX64.
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(IMGUI_AUTOIT_ARCH "x64")
else()
    set(IMGUI_AUTOIT_ARCH "x86")
endif()

set(IMGUI_AUTOIT_OUTDIR "${CMAKE_SOURCE_DIR}/dll/bin/${IMGUI_AUTOIT_ARCH}")

set_target_properties(imgui_autoit PROPERTIES
    OUTPUT_NAME "imgui_autoit"
    PREFIX ""
    # The trailing _<CONFIG> form disables CMake's per-config subdirectory
    # under multi-config generators (Visual Studio), so the DLL lands
    # directly in bin/<arch>/ rather than bin/<arch>/Release/.
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${IMGUI_AUTOIT_OUTDIR}"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG   "${IMGUI_AUTOIT_OUTDIR}"
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${IMGUI_AUTOIT_OUTDIR}"
    RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL     "${IMGUI_AUTOIT_OUTDIR}"
)

if(MSVC)
    target_compile_definitions(imgui_autoit PRIVATE
        _CRT_SECURE_NO_WARNINGS
        UNICODE
        _UNICODE
        WIN32_LEAN_AND_MEAN
        NOMINMAX
    )
    target_compile_options(imgui_autoit PRIVATE /W4 /wd4100 /wd4127 /MP)
endif()

message(STATUS "imgui_autoit will be built as: dll/bin/${IMGUI_AUTOIT_ARCH}/imgui_autoit.dll")
message(STATUS "ImGui source dir: ${IMGUI_DIR}")
