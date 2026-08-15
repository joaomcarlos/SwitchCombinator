---
title: Factorio Modding — Performance & Multiplayer
description: Performance and multiplayer safety skill. Event filters, caching, determinism, on_nth_tick, batch operations, and rendering cleanup.
---

# Factorio Modding — Performance & Multiplayer

Use this skill when optimizing mod code, writing multiplayer-safe logic, or avoiding common performance pitfalls.

When performance work depends on prototype properties or vanilla definitions, use the official [Factorio Data repository](https://github.com/wube/factorio-data) as the versioned source of truth and inspect the target branch, tag, or release. Use the official API docs for runtime method costs, event contracts, and lifecycle behavior; do not infer runtime API shape from prototype data.

---

## Performance Rules

### 1. Never Use `on_tick` for Everything
Use `script.on_nth_tick(n, handler)` with the largest `n` that meets your requirements:

```lua
-- Bad: runs every tick
script.on_event(defines.events.on_tick, function()
  -- expensive work
end)

-- Good: runs every 6 ticks (~10Hz)
script.on_nth_tick(6, function()
  -- work
end)

-- Better: dynamic enable/disable
local function enable_processing()
  script.on_nth_tick(UPDATE_INTERVAL, on_process)
end
local function disable_processing()
  script.on_nth_tick(UPDATE_INTERVAL, nil)
end
```

Prime-number intervals are preferred to avoid regularly colliding with even-numbered system events. Example: `17`, `13`, `7`.

### 2. Cache Prototype Lookups
Look up prototypes once at module scope or in `on_init`, never every tick:

```lua
-- Bad
for _, entity in pairs(entities) do
  local proto = game.entity_prototypes[entity.name]
  -- use proto
end

-- Good
local cached_protos = {}
local function cache_prototypes()
  for name, proto in pairs(game.entity_prototypes) do
    cached_protos[name] = proto
  end
end
script.on_init(cache_prototypes)
script.on_configuration_changed(cache_prototypes)
```

### 3. Avoid Per-Tick Surface Scans
Maintain entity registries in `storage` and update on build/mined events:

```lua
-- Register on build/mined
script.on_event(defines.events.on_built_entity, on_entity_built)
script.on_event(defines.events.on_player_mined_entity, on_entity_removed)
script.on_event(defines.events.on_robot_mined_entity, on_entity_removed)
script.on_event(defines.events.on_entity_died, on_entity_removed)

-- Periodic work only iterates registry
script.on_nth_tick(30, function()
  for un, entry in pairs(storage.my_entities) do
    if entry.entity and entry.entity.valid then
      -- do work
    else
      storage.my_entities[un] = nil
    end
  end
end)
```

### 4. Use Event Filters
Event filters reduce overhead. Use them whenever possible:

```lua
script.on_event(defines.events.on_built_entity, on_entity_built,
  {{filter = "name", name = "my-entity"}})

script.on_event(defines.events.on_player_mined_entity, on_entity_removed,
  {{filter = "name", name = "my-entity"}})
```

Available filters vary by event. Check the API docs for the specific event.

### 5. Limit Rendering Objects
Rendering handles are not free. Destroy them when no longer needed:

```lua
-- Store IDs per player or globally
local render_ids = {}

-- Create
render_ids[player.index] = rendering.draw_sprite{...}

-- Cleanup
if render_ids[player.index] then
  rendering.destroy(render_ids[player.index])
  render_ids[player.index] = nil
end
```

Use `time_to_live` for temporary visuals so they auto-destroy.

### 6. Batch Operations
Group `set_tiles`, `create_entity` calls when possible:

```lua
-- Better than one-by-one
surface.set_tiles({
  {position = {1, 1}, name = "grass-1"},
  {position = {2, 1}, name = "grass-1"},
  {position = {3, 1}, name = "grass-1"},
}, true)
```

### 7. Avoid `pairs`/`ipairs` on Large Tables Every Tick
If you must iterate many entities every tick, consider splitting work across multiple ticks or increasing the interval.

---

## Multiplayer Safety

### Determinism is Sacred
All gameplay-affecting logic must produce the same result on all clients.

- **`math.random()` is NOT synchronized in multiplayer**. Use it only for cosmetic effects (rendering, particles, smoke). The game handles its own deterministic randomness for combat/projectiles.
- **Never use `os.time()`, `os.clock()`, or any real-time source**.
- **Storage is the only synchronized state**. Local variables are NOT synced across clients.

### Force Isolation
When creating entities via script, always specify `force`:

```lua
surface.create_entity{
  name = "my-entity",
  position = pos,
  force = "player", -- or a specific LuaForce object
}
```

### Player Checks
`player_index` may be nil (server console / RCON):

```lua
local player = cmd.player_index and game.players[cmd.player_index]
if player then
  player.print("Hello")
else
  log("Hello (from console)")
end
```

### Event Order
Mods receive events in load order (dependency depth, then natural sort of mod names). Don't depend on another mod's handler running before/after yours unless you declare a dependency.

### Script Events Can't Be Raised
`script.raise_event()` can only raise custom events, not built-in ones:

```lua
-- This does NOT work:
-- script.raise_event(defines.events.on_built_entity, {entity = entity})

-- Instead, create the entity with raise_built = true:
surface.create_entity{..., raise_built = true}
```

---

## Safe Patterns Checklist

- [ ] Using `script.on_nth_tick` instead of `on_tick`
- [ ] Prototype lookups cached at init time
- [ ] Entity registry maintained via build/mined events, not per-tick scans
- [ ] Event filters applied where possible
- [ ] Rendering handles cleaned up or using `time_to_live`
- [ ] No `math.random()` used for gameplay logic
- [ ] No real-time functions used
- [ ] `force` explicitly set on `create_entity`
- [ ] `player_index` validated before use
- [ ] `storage` is the only mutated global state
