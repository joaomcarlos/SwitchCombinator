---
title: Factorio Modding — Runtime & Control Phase
description: Runtime stage skill. Event handlers, storage, entity management, surface/force/player API, rendering, commands, remote interfaces. For Factorio 2.0.
---

# Factorio Modding — Runtime & Control Phase

This skill covers the **Runtime (Control) Stage**: `control.lua` and required modules. Use this when writing game logic that reacts to events and manipulates the world.

Consult https://lua-api.factorio.com/latest/index-runtime.html for exact class methods and event fields.

## Prototype and Runtime API Boundary

For prototype definitions and versioned properties exposed through `data.raw` or `prototypes`, treat the official [Factorio Data repository](https://github.com/wube/factorio-data) as the source of truth and inspect the branch, tag, or release matching the target game version. Keep using the official runtime API docs for LuaObject methods, event fields, and lifecycle behavior; prototype data is not a substitute for runtime API documentation.

---

## Event Lifecycle

```lua
script.on_init(function()
  storage.my_data = {}
  -- Initialize everything once when mod is first added to a save.
end)

script.on_load(function()
  -- Reattach metatables, register callbacks.
  -- NEVER mutate storage here.
  -- NEVER require() here.
end)

script.on_configuration_changed(function(event)
  -- Migrate data on mod updates or dependency changes.
  -- event.mod_changes["your-mod"] contains old_version / new_version.
end)
```

---

## Persistent Data (`storage`)

- **Use `storage` in Factorio 2.0** (replaces old `global`).
- Only store: primitives, tables, registered metatables, Factorio LuaObjects.
- **NEVER store Lua functions or coroutines in `storage`** — causes "Cannot serialise lua functions" on save.
- Use module-level local variables for transient caches, closures, print functions.
- Do not access `storage` at the top level of `control.lua` before events fire.

### Register Metatables for Persistence
```lua
script.register_metatable("my_metatable", my_metatable)
-- On load, tables with this metatable will be automatically relinked.
```

---

## Complete Event Reference

Organized by category. All events under `defines.events`.

### Entity Lifecycle
- `on_built_entity` — player builds. Filter: `name`, `type`, `ghost_name`, `ghost_type`
- `on_robot_built_entity` — robot builds
- `on_entity_cloned` — cloned via blueprint or editor
- `on_entity_died` — entity destroyed
- `on_post_entity_died` — after entity dies (ghost may exist)
- `on_player_mined_entity` — player mines
- `on_robot_mined_entity` — robot mines
- `on_marked_for_deconstruction` — marked with deconstruction planner
- `on_cancelled_deconstruction` — mark cancelled
- `on_marked_for_upgrade` — marked for upgrade
- `on_cancelled_upgrade` — upgrade cancelled
- `on_entity_renamed`, `on_entity_settings_pasted`
- `on_entity_spawned`, `on_entity_damaged`
- `on_resource_depleted` — resource fully mined

### GUI Events
- `on_gui_opened`, `on_gui_closed`
- `on_gui_click`, `on_gui_checked_state_changed`, `on_gui_elem_changed`
- `on_gui_selection_state_changed`, `on_gui_selected_tab_changed`
- `on_gui_switch_state_changed`, `on_gui_confirmed`
- `on_gui_text_changed`, `on_gui_value_changed`
- `on_gui_location_changed`, `on_gui_hover`, `on_gui_leave`

### Player Events
- `on_player_created`, `on_player_joined_game`, `on_player_left_game`
- `on_player_died`, `on_player_respawned`
- `on_player_changed_position`, `on_player_changed_surface`
- `on_player_crafted_item`, `on_player_mined_item`, `on_player_mined_tile`
- `on_player_built_tile`, `on_player_deconstructed_area`
- `on_player_cursor_stack_changed`, `on_player_main_inventory_changed`
- `on_player_driving_changed_state`, `on_player_used_capsule`
- `on_player_setup_blueprint`, `on_player_configured_blueprint`
- `on_player_rotated_entity`, `on_player_flipped_entity`

### Train Events
- `on_train_changed_state`, `on_train_created`, `on_train_schedule_changed`

### Research Events
- `on_research_started`, `on_research_finished`, `on_research_cancelled`
- `on_research_reversed`, `on_research_moved`, `on_research_queued`
- `on_technology_effects_reset`

### Surface / Planet / Space Events
- `on_surface_created`, `on_surface_deleted`, `on_surface_cleared`, `on_surface_renamed`, `on_surface_imported`
- `on_chunk_generated`, `on_chunk_deleted`, `on_chunk_charted`
- `on_cargo_pod_delivered_cargo`, `on_cargo_pod_finished_ascending`, `on_cargo_pod_finished_descending`
- `on_space_platform_changed_state`, `on_space_platform_built_entity`, `on_space_platform_mined_entity`

### Script / Effect Events
- `on_script_trigger_effect` — ammo/explosion with `type = "script"` effect triggered
- `on_trigger_created_entity` — entity created by trigger (e.g. land mine)
- `on_sector_scanned` — radar scanned a sector

### Input Events
- `on_lua_shortcut` — custom shortcut clicked

### Tick Events
- `on_tick` — every tick (AVOID if possible)
- `script.on_nth_tick(n, handler)` — preferred periodic approach

---

## Entity Management

### Track Custom Entities by `unit_number`
```lua
script.on_event(defines.events.on_built_entity, function(event)
  local entity = event.created_entity or event.entity
  if not entity or not entity.valid then return end
  if entity.name ~= "my-entity" then return end
  storage.my_entities[entity.unit_number] = { entity = entity }
end)

script.on_event(defines.events.on_player_mined_entity, function(event)
  local entity = event.entity
  if not entity or not entity.valid then return end
  if entity.name ~= "my-entity" then return end
  storage.my_entities[entity.unit_number] = nil
end)
```

### Safe Entity Iteration
Always validate `.valid` before use:
```lua
for un, entry in pairs(storage.my_entities) do
  if entry.entity and entry.entity.valid then
    -- safe to use
  else
    storage.my_entities[un] = nil
  end
end
```

### `create_entity` Full Reference
```lua
local entity = surface.create_entity{
  name = "my-entity",
  position = {x, y},
  direction = defines.direction.north,
  force = "player",
  player = player,
  fast_replace = false,
  spill = true,
  raise_built = true,
  create_build_effect_smoke = true,
  -- For items-on-ground:
  stack = {name = "iron-plate", count = 1},
  -- For ghosts:
  inner_name = "assembling-machine-1",
}
```

### Entity Properties (Runtime)
- `entity.name`, `entity.type`, `entity.prototype`
- `entity.position`, `entity.direction`, `entity.orientation`
- `entity.health`, `entity.max_health`, `entity.destructible`, `entity.minable`, `entity.rotatable`
- `entity.active`, `entity.operable`
- `entity.force`, `entity.surface`, `entity.unit_number`
- `entity.get_inventory(defines.inventory.chest)` — LuaInventory
- `entity.get_fluidbox()` — array of fluidbox contents
- `entity.circuit_connected_entities`

---

## Periodic Logic

Use `script.on_nth_tick(n, handler)` instead of `on_tick`:
```lua
script.on_nth_tick(6, function()
  -- runs every 6 ticks (~10Hz)
end)
```

Conditionally disable when not needed:
```lua
local function enable_processing()
  script.on_nth_tick(UPDATE_INTERVAL, on_process)
end
local function disable_processing()
  script.on_nth_tick(UPDATE_INTERVAL, nil)
end
```

---

## Commands

```lua
commands.add_command("my-cmd", "Description", function(command)
  local player = command.player_index and game.players[command.player_index]
  -- player may be nil (server/RCON)
end)
```

---

## Remote Interfaces

```lua
remote.add_interface("my_mod", {
  get_data = function() return storage.my_data end
})
-- Call from another mod: remote.call("my_mod", "get_data")
```

---

## Surface, Force & Player API

### Surface
```lua
local surface = game.surfaces["nauvis"]
surface.find_entities_filtered{area = area, name = "my-entity"}
surface.find_entities_filtered{area = area, type = "assembling-machine"}
surface.find_tiles_filtered{area = area, name = "water"}
surface.set_tiles({{position = {x, y}, name = "grass-1"}}, true)
surface.create_entity{...}
surface.spill_item_stack(position, stack, true, nil, false)
surface.create_trivial_smoke{name = "smoke-fast", position = pos}
surface.pollute(position, amount)
```

### Force
```lua
local force = game.forces["player"]
force.research_queue_enabled = true
force.set_friend("other-force", true)
force.reset_technology_effects()
force.chart(surface, area)
force.clear_chart(surface)
```

### Player
```lua
local player = game.players[event.player_index]
player.insert({name = "iron-plate", count = 10})
player.remove_item({name = "iron-plate", count = 10})
player.get_main_inventory()
player.opened = entity
player.opened = nil
player.cursor_stack     -- LuaItemStack currently held
player.character        -- LuaEntity of the character
player.surface
player.position
player.teleport({x, y}, surface)
player.create_local_flying_text{text = "Hello", position = pos}
```

---

## Recipe, Technology & Research (Runtime)

```lua
local force = game.forces["player"]
force.recipes["my-recipe"].enabled = true
force.recipes["my-recipe"].reload()

local tech = force.technologies["my-tech"]
tech.researched = true
tech.level = 2 -- for infinite technologies
```

Prototype access:
```lua
local recipe_proto = prototypes.recipe["my-recipe"]
local item_proto = prototypes.item["iron-plate"]
local entity_proto = prototypes.get_entity_filtered{{filter="type", type="assembling-machine"}}
```

---

## Rendering & Visualization

```lua
-- Sprite
local id = rendering.draw_sprite{
  sprite = "utility/close",
  surface = surface,
  target = entity,
  time_to_live = 60,
  forces = {force},
  color = {r = 1, g = 0, b = 0},
}

-- Text
local id = rendering.draw_text{
  text = "Hello",
  surface = surface,
  target = position,
  color = {r = 1, g = 1, b = 1},
  scale = 1,
  time_to_live = 120,
}

-- Line
local id = rendering.draw_line{
  color = {r = 1, g = 0, b = 0},
  width = 2,
  from = entity1,
  to = entity2,
  surface = surface,
  time_to_live = 60,
}

-- Destroy when done
rendering.destroy(id)
```

---

## Inter-mod Compatibility

### Check if mod is active
```lua
if script.active_mods["other-mod"] then
  -- other-mod is present
end
```

### Safe Remote Calls
```lua
local ok, result = pcall(remote.call, "other-mod", "get_data")
if ok then
  -- use result
end
```

---

## Factorio 2.0 Modern Systems

### Quality
```lua
local quality = entity.quality  -- LuaQualityPrototype
local quality_name = quality.name  -- "normal", "uncommon", "rare", "epic", "legendary"
```

### Planets & Surfaces
```lua
for name, surface in pairs(game.surfaces) do
  -- surface.name
end
local surface = game.surfaces["nauvis"]
if surface and surface.valid then ... end
```

### Space Platforms
```lua
script.on_event(defines.events.on_space_platform_changed_state, function(event)
  local platform = event.space_platform
end)
```

### Asteroid Collector & Agricultural Tower
Clone from vanilla prototypes:
```lua
local collector = table.deepcopy(data.raw["asteroid-collector"]["asteroid-collector"])
```
