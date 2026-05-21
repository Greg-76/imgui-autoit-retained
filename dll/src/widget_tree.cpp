#include "widget_tree.h"

WidgetTree g_tree;

Widget* WidgetTree::Find(const std::string& id)
{
    auto it = byId.find(id);
    return it == byId.end() ? nullptr : it->second;
}

bool WidgetTree::Add(std::unique_ptr<Widget> w)
{
    if (!w) return false;
    if (byId.count(w->id)) return false; // duplicate id rejected
    Widget* raw = w.get();
    raw->parent = nullptr;
    roots.push_back(std::move(w));
    byId.emplace(raw->id, raw);
    return true;
}

bool WidgetTree::SetParent(const std::string& child_id, const std::string& parent_id)
{
    Widget* child = Find(child_id);
    if (!child) return false;

    Widget* new_parent = nullptr;
    if (!parent_id.empty()) {
        new_parent = Find(parent_id);
        if (!new_parent) return false;
        if (new_parent == child) return false; // self-parent
        // Cycle prevention: walking up from new_parent must not hit child.
        for (Widget* w = new_parent->parent; w; w = w->parent) {
            if (w == child) return false;
        }
    }

    if (child->parent == new_parent) return true; // already correct

    // Extract from current owner list (own_list owns the unique_ptr).
    auto& own_list = child->parent ? child->parent->children : roots;
    std::unique_ptr<Widget> owned;
    for (auto it = own_list.begin(); it != own_list.end(); ++it) {
        if (it->get() == child) {
            owned = std::move(*it);
            own_list.erase(it);
            break;
        }
    }
    if (!owned) return false; // tree corrupted — child not in its parent's list

    child->parent = new_parent;
    auto& new_list = new_parent ? new_parent->children : roots;
    new_list.push_back(std::move(owned));
    return true;
}

void WidgetTree::Clear()
{
    // Clear byId first so we never observe a dangling pointer during the
    // cascading destruction of root → children → grandchildren.
    byId.clear();
    roots.clear();
}
