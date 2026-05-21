#pragma once
#include "widget.h"
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

// Persistent tree of widgets.
// Mutated by the AutoIt thread (Create*/Set*/Get* exports), read+written by
// the render thread each frame. Every access must hold WidgetTree::mtx.
//
// Hierarchy: `roots` are the top-level widgets (rendered inside the host
// window in order). Each Widget owns its own children (see Widget::children).
// `byId` is a flat lookup across the entire tree — every widget, no matter
// how deeply nested, is registered here so Find/SetParent/Get/Set are O(1).
class WidgetTree {
public:
    // Recursive on purpose : the render thread takes the mutex around the
    // entire frame body (NewFrame -> RenderHostWindow -> Render -> Present)
    // to serialize ImGui state with AutoIt-thread readers (CalcTextSize,
    // IsKeyDown, GetMousePos, ...). RenderHostWindow internally re-takes
    // the same lock around widget tree walks ; recursive_mutex lets those
    // nest cleanly without deadlock. Race fixed in Phase G — without it,
    // ImGui_CalcTextSize could read GImGui->Font mid-NewFrame and crash.
    std::recursive_mutex mtx;
    std::vector<std::unique_ptr<Widget>> roots;        // top-level render order
    std::unordered_map<std::string, Widget*> byId;     // flat lookup

    Widget* Find(const std::string& id);
    // Creates the widget at root level. Returns false on duplicate id.
    bool    Add(std::unique_ptr<Widget> w);
    // Moves an existing widget to a different parent (or back to root when
    // parent_id is empty). Returns false on unknown ids or cycle attempts.
    bool    SetParent(const std::string& child_id, const std::string& parent_id);
    void    Clear();
};

extern WidgetTree g_tree;
