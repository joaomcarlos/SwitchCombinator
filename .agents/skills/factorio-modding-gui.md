---
title: Factorio Modding — GUI Programming
description: GUI skill for Factorio 2.0. Frames, styles, close buttons, drag handles, event handling, and verified working patterns.
---

# Factorio Modding — GUI Programming

Use this skill when building or modifying in-game GUIs: entity custom UIs, configuration windows, tool windows, or any screen overlay.

For GUI-related prototype definitions, styles, sprites, and version-sensitive names, use the official [Factorio Data repository](https://github.com/wube/factorio-data) as the source of truth for the target branch, tag, or release. Use the official API docs for `LuaGuiElement` methods, GUI events, and runtime behavior.

---

## Core GUI Rules

- **Access children by name using brackets**: `parent["child-name"]`, NEVER `parent.child_name`
- **Dropdown `selected_index` is 1-based**, not 0-based
- **Check `element.valid` before using stored GUI references**
- **Never store Lua functions in `storage` for GUI callbacks**
- Use `player.gui.screen` for draggable windows
- `player.opened = frame` opens the GUI without blocking the entity

---

## Correct Close Button Pattern

```lua
{
  type = "sprite-button",
  name = "my_prefix_close",
  sprite = "utility/close",
  style = "frame_action_button",
  mouse_button_filter = {"left"}
}
```

---

## Complete Window Frame Pattern

```lua
local frame = player.gui.screen.add{
  type = "frame",
  name = "my_prefix_main_frame",
  direction = "vertical"
}
frame.style.width = 600

-- Title bar with drag handle
local titlebar = frame.add{ type = "flow", direction = "horizontal" }
titlebar.style.horizontal_spacing = 8
titlebar.drag_target = frame
titlebar.add{ type = "label", caption = "Title", style = "frame_title" }
local drag = titlebar.add{ type = "empty-widget", style = "draggable_space_header" }
drag.style.horizontally_stretchable = true
drag.style.height = 24
drag.drag_target = frame
titlebar.add{
  type = "sprite-button",
  name = "my_prefix_close",
  sprite = "utility/close",
  style = "frame_action_button",
  mouse_button_filter = {"left"}
}

-- Inner content frame
local inner = frame.add{
  type = "frame",
  name = "my_prefix_inner",
  style = "inside_shallow_frame_with_padding",
  direction = "vertical"
}

frame.force_auto_center()
```

---

## Verified Factorio 2.0 Styles

| Style | Use For |
|-------|---------|
| `frame_action_button` | Close/X sprite-buttons |
| `sprite="utility/close"` | Close icon sprite |
| `inside_shallow_frame_with_padding` | Inner content frame |
| `deep_frame_in_shallow_frame` | Nested dark content frame |
| `draggable_space_header` | Drag handle in title bar |
| `frame_title` | Window title text |
| `caption_label` | Section headers |
| `bold_label` | Emphasized labels |
| `mini_button` | Small normal buttons (NOT for sprite-buttons) |
| `slot_button` | Sprite-buttons ONLY |
| `confirm_button` | Primary action buttons |
| `green_button` | Positive action buttons |
| `red_button` | Destructive action buttons |

---

## GUI Event Handling

Register all GUI event handlers in `control.lua` and delegate to a GUI module:

```lua
local gui_main = require("scripts.gui.main")

script.on_event(defines.events.on_gui_opened, function(event)
  local entity = event.entity
  if not entity or not entity.valid or entity.name ~= "my-entity" then return end
  local player = game.players[event.player_index]
  gui_main.open(player, entity)
  player.opened = player.gui.screen["my_prefix_main_frame"]
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local player = game.players[event.player_index]
  gui_main.close(player)
end)

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not element or not element.valid then return end
  local player = game.players[event.player_index]
  gui_main.on_click(player, element)
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
  local element = event.element
  if not element or not element.valid then return end
  local player = game.players[event.player_index]
  gui_main.on_text_changed(player, element)
end)

script.on_event(defines.events.on_gui_elem_changed, function(event)
  local element = event.element
  if not element or not element.valid then return end
  local player = game.players[event.player_index]
  gui_main.on_elem_changed(player, element)
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
  local element = event.element
  if not element or not element.valid then return end
  local player = game.players[event.player_index]
  gui_main.on_selection_changed(player, element)
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(event)
  local element = event.element
  if not element or not element.valid then return end
  local player = game.players[event.player_index]
  gui_main.on_checked_changed(player, element)
end)
```

---

## GUI Module Pattern

Keep GUI construction and event handling in `scripts/gui/main.lua`:

```lua
local GUI_PREFIX = "my_"
local gui_main = {}

function gui_main.open(player, entity)
  gui_main.close(player)
  local frame = player.gui.screen.add{
    type = "frame",
    name = GUI_PREFIX .. "main_frame",
    direction = "vertical"
  }
  -- build content...
  frame.force_auto_center()
end

function gui_main.close(player)
  local frame = player.gui.screen[GUI_PREFIX .. "main_frame"]
  if frame and frame.valid then frame.destroy() end
end

function gui_main.on_click(player, element)
  if element.name == GUI_PREFIX .. "close" then
    gui_main.close(player)
  end
end

return gui_main
```

---

## Common GUI Element Types

| Type | Purpose | Key Properties |
|------|---------|--------------|
| `frame` | Window container | `direction`, `style` |
| `flow` | Layout container | `direction` ("horizontal"/"vertical") |
| `table` | Grid layout | `column_count` |
| `label` | Text display | `caption`, `style` |
| `button` | Action button | `caption`, `style` |
| `sprite-button` | Icon button | `sprite`, `style`, `mouse_button_filter` |
| `checkbox` | Toggle | `state`, `caption` |
| `textfield` | Text input | `text`, `numeric` |
| `dropdown` | Selection list | `items`, `selected_index` (1-based!) |
| `slider` | Range input | `minimum_value`, `maximum_value`, `value` |
| `progressbar` | Progress display | `value` (0-1) |
| `line` | Horizontal separator | |
| `empty-widget` | Spacer/filler | `style` for stretch |
| `choose-elem-button` | Signal/item/entity picker | `elem_type`, `signal` |

---

## Styling Tips

```lua
-- Make element stretch horizontally
element.style.horizontally_stretchable = true

-- Set fixed width
element.style.width = 200

-- Set margins
element.style.top_margin = 4
element.style.left_margin = 8

-- Align
element.style.vertical_align = "center"
element.style.horizontal_align = "center"

-- Font color
label.style.font_color = {r = 1, g = 0.2, b = 0.2}
```
