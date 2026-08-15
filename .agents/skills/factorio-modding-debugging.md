---
title: Factorio Modding — Debugging & Error Handling
description: Debugging skill for Factorio 2.0. pcall, logging, console commands, flying text, inspecting state, and fail-fast philosophy.
---

# Factorio Modding — Debugging & Error Handling

Use this skill when a mod is broken, when you need to inspect runtime state, or when adding debug infrastructure.

When a failure involves a prototype type, field, entity name, or version-sensitive definition, treat the official [Factorio Data repository](https://github.com/wube/factorio-data) as the source of truth and inspect the branch, tag, or release matching the target game version. Use the official runtime API docs for LuaObject shapes and event fields, then confirm save-specific behavior in-game.

---

## Error Handling Philosophy

Factorio crashes with stack traces on Lua errors. **This is desirable during development.** Do not suppress errors with blanket `pcall` wrappers. Let them surface so you can fix the root cause.

Use `pcall` only around genuinely risky operations that might fail due to invalid game state:

```lua
-- Good: pcall around API calls that might fail if entity becomes invalid
local ok, behavior = pcall(function()
  return entity.get_or_create_control_behavior()
end)
if ok and behavior then
  -- safe to use
end
```

```lua
-- Bad: suppressing all errors hides bugs
pcall(function()
  -- lots of logic here
end)
```

---

## Logging

### Console Logging
```lua
log("Debug: storage has " .. tostring(#storage.my_entities) .. " entries")
```

Logs appear in `factorio-current.log` in the game directory.

### Game Print
```lua
game.print({"my-mod.message", param1, param2})
```

- `game.print` requires at least 1 argument.
- `game.print` is read-only; do not try to override it.

### Table Inspection with serpent
Factorio includes `serpent` for table serialization:

```lua
log(serpent.block(storage.my_data))
log(serpent.line(entity.position))
```

---

## Inspection Commands

Add console commands for quick state inspection:

```lua
commands.add_command("my-mod-debug", "Dump mod state", function(cmd)
  local player = cmd.player_index and game.players[cmd.player_index]
  local msg = serpent.block(storage)
  if player then
    player.print(msg)
  else
    log(msg)
  end
end)
```

```lua
commands.add_command("my-mod-list", "List tracked entities", function(cmd)
  local player = cmd.player_index and game.players[cmd.player_index]
  if not player then return end
  local count = 0
  for un, entry in pairs(storage.my_entities or {}) do
    count = count + 1
    if count <= 20 then
      player.print("UN " .. un .. ": " .. (entry.entity and entry.entity.valid and "valid" or "INVALID"))
    end
  end
  player.print("Total: " .. count)
end)
```

---

## Flying Text

Display temporary floating text at a position for visual debugging:

```lua
player.create_local_flying_text{
  text = "Debug: " .. tostring(value),
  position = entity.position,
  color = {r = 1, g = 0, b = 0},
}
```

This is local to the player and great for showing state at entity locations.

---

## Debugging GUI Events

When a GUI button doesn't respond, verify:
1. The event handler is registered: `script.on_event(defines.events.on_gui_click, handler)`
2. The element name matches exactly (case-sensitive)
3. You're checking `element.valid` before use
4. Access by bracket notation: `element.name == "my_prefix_close"`

```lua
script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not element or not element.valid then return end
  log("Clicked: " .. tostring(element.name))  -- Add this to debug
  if element.name == "my_prefix_close" then
    -- handle
  end
end)
```

---

## Debugging Event Filters

If an entity event isn't firing, check the filter:

```lua
-- Correct filter syntax
script.on_event(defines.events.on_built_entity, handler,
  {{filter = "name", name = "my-entity"}})

-- The filter table is an array of filter objects
```

Filters are checked by the engine before calling your handler. If the filter doesn't match, your handler never runs.

---

## Common Crash Causes & Fixes

| Crash | Likely Cause | Fix |
|-------|-------------|-----|
| `Cannot serialise lua functions` | Stored a function in `storage` | Move functions to module-level locals |
| `attempt to index field '?' (a nil value)` | Accessing `storage` before `on_init` | Initialize in `on_init`, guard with `or {}` |
| `attempt to call method 'valid' (a nil value)` | Entity was destroyed | Check `entity and entity.valid` |
| `attempt to index a nil value` | GUI element not found | Use bracket notation `parent["name"]` |
| `Expected property to be of type uint` | Passing float where int expected | Use `math.floor()` or check API types |
| `serialise lua function` in save | `storage` contains closures/functions | Audit all `storage` writes |
| Game hangs on load | Infinite loop in `on_init` or `on_load` | Check for `while true` without breaks |
| GUI doesn't open | Missing `player.opened = frame` or frame destroyed | Ensure frame is created before assignment |

---

## Fast Development Workflow

1. Keep `control.lua` as a thin router; logic in required modules.
2. Use `/c` or `/sc` console for quick testing during gameplay.
3. Enable `log()` calls liberally during development; remove or reduce before release.
4. After fixing a crash, reload the save to verify — do not just restart the game.
5. Use `serpent.block()` to inspect `storage` shape when adding new features.
