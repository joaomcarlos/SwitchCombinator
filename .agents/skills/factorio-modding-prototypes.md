---
title: Factorio Modding — Prototypes & Data Phase
description: Prototype stage skill. Defining entities, items, recipes, technologies, fluids, tiles, graphics, sounds, custom inputs, and settings. For Factorio 2.0.
---

# Factorio Modding — Prototypes & Data Phase

This skill covers the **Prototype (Data) Stage**: `data.lua`, `data-updates.lua`, `data-final-fixes.lua`. Use this when defining or modifying any game content.

Consult https://lua-api.factorio.com/latest/index-prototype.html for exact prototype fields.

## Versioned Prototype Source of Truth

Treat the official [Factorio Data repository](https://github.com/wube/factorio-data) as the source of truth for Lua prototype definitions across Factorio versions. Before relying on a prototype type, field, default, or vanilla name, inspect the branch, tag, or release matching the target game version and compare versions when compatibility matters. Use the API docs for stage/lifecycle rules and runtime contracts, and validate behavior in the target Factorio version.

---

## Core Patterns

### Cloning and Extending
Use `table.deepcopy()` to clone base prototypes, then mutate and `data:extend{}`:
```lua
local base = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
base.name = "super-assembler"
base.energy_usage = "300kW"
data:extend{base}
```

### Patching Other Mods
Use `data-updates.lua` to patch prototypes loaded before yours:
```lua
if data.raw.ammo["firearm-magazine"] then
  local ammo = data.raw.ammo["firearm-magazine"]
  -- modify ammo properties
end
```

### Accessing `data.raw`
Always use bracket notation: `data.raw["type"]["name"]`.

---

## Entity Prototype Encyclopedia

Common required fields for all entities: `type`, `name`, `icon` or `icons`, `flags`, `collision_box`, `selection_box`.

**assembling-machine**: `crafting_categories`, `crafting_speed`, `energy_source`, `energy_usage`, `module_slots`, `allowed_effects`.

**furnace**: Similar to assembling-machine but with `result_inventory_size`, `source_inventory_size`.

**mining-drill**: `resource_categories`, `mining_speed`, `energy_source`, `energy_usage`, `resource_searching_radius`, `vector_to_place_result`.

**inserter**: `pickup_position`, `insert_position`, `energy_source`, `energy_per_movement`, `energy_per_rotation`, `extension_speed`, `rotation_speed`, `hand_size`.

**transport-belt / splitter / underground-belt**: `speed` (tiles per tick, e.g. 0.03125 for yellow), `belt_animation_set`, `animations` (splitter).

**container / logistic-container**: `inventory_size`, `picture` or `animations`.

**electric-pole**: `supply_area_distance`, `wire_reach`, `connection_points`.

**turret (ammo-turret / electric-turret / fluid-turret)**: `attack_parameters`, `call_for_help_radius`.

**radar**: `max_distance_of_sector_revealed`, `max_distance_of_nearby_sector_revealed`, `energy_source`, `energy_usage`.

**lamp**: `energy_source`, `energy_usage_per_tick`, `light`.

**programmable-speaker**: `energy_source`, `energy_usage_per_tick`, `instruments`.

**simple-entity / simple-entity-with-owner**: Minimal entities for decorative or script-controlled objects. `pictures` or `picture`.

**character**: Do NOT define custom characters unless absolutely necessary. Very complex.

### Hidden/Invisible Entities
For hidden companion entities (e.g. output combinators):
```lua
flags = {
  "placeable-neutral", "not-on-map", "not-deconstructable",
  "not-blueprintable", "hide-alt-info", "not-flammable",
  "not-upgradable", "not-in-kill-statistics",
},
selectable_in_game = false,
collision_mask = {layers = {}},
collision_box = {{-0.01, -0.01}, {0.01, 0.01}},
selection_box = {{-0.01, -0.01}, {0.01, 0.01}},
draw_circuit_wires = false,
-- sprites = util.empty_sprite()  -- if util is available
```

---

## Item Prototypes

Required: `type`, `name`, `icon`/`icons`, `subgroup`, `order`, `stack_size`.

**item** (generic): Intermediates, parts.
**tool** (science packs): `durability` (deprecated), `durability_description_key`.
**ammo**: `ammo_type` with `category`, `target_type`, `action` (trigger with action_delivery).
**gun**: `attack_parameters`.
**armor**: `resistances`, `equipment_grid`, `inventory_size_bonus`.
**module**: `category`, `tier`, `effect` (productivity/speed/consumption/pollution/quality bonuses).
**capsule**: `capsule_action` ("throw", "use-on-self", "activate", "remote", "artillery-remote").
**selection-tool / copy-paste-tool / deconstruction-item / upgrade-item**: `selection_mode_flags`, `alt_selection_mode_flags`, `selection_cursor_box_type`.

---

## Recipe Prototype

```lua
{
  type = "recipe",
  name = "advanced-circuit",
  enabled = false,
  energy_required = 6,
  ingredients = {
    {type = "item", name = "electronic-circuit", amount = 2},
    {type = "item", name = "plastic-bar", amount = 2},
  },
  results = {
    {type = "item", name = "advanced-circuit", amount = 1},
  },
}
```

**Recipe `results` format (Factorio 2.0)**: Array of `{type = "item"|"fluid", name = "...", amount = N}`. Use `main_product` for tooltip when multiple results.

---

## Technology Prototype

Required: `type = "technology"`, `name`, `icon`/`icons`, `effects`, `unit` (count, ingredients, time), `prerequisites`.

```lua
{
  type = "technology",
  name = "my-tech",
  icon = "__my-mod__/graphics/tech.png",
  icon_size = 256,
  effects = {
    {type = "unlock-recipe", recipe = "my-recipe"},
  },
  prerequisites = {"automation"},
  unit = {
    count = 100,
    ingredients = {{"automation-science-pack", 1}},
    time = 30,
  },
}
```

---

## Fluid Prototype

Required: `type = "fluid"`, `name`, `icon`/`icons`, `subgroup`, `order`, `default_temperature`, `max_temperature`, `heat_capacity`, `base_color`, `flow_color`.

---

## Tile Prototype

Required: `type = "tile"`, `name`, `layer` (uint32, higher = drawn on top), `map_color`.

---

## Effect Prototypes

**explosion**: `animations`, `light`, `smoke`, `smoke_count`, `smoke_slow_down_factor`. Can be used as bullet trails.

**projectile**: `acceleration`, `action` (trigger), `animation`, `hit_at_collision_position`.

**beam**: `head`, `tail`, `body` sprite definitions.

**fire / sticker**: Flame and status effect prototypes.

---

## Graphics, Animation & Sound

### Sprite Definitions
```lua
{
  filename = "__my-mod__/graphics/entity/my-entity.png",
  priority = "extra-high",
  width = 64,
  height = 64,
  shift = util.by_pixel(0, 0),
  hr_version = {
    filename = "__my-mod__/graphics/entity/hr-my-entity.png",
    width = 128,
    height = 128,
    scale = 0.5,
  }
}
```

### Animation Definitions
```lua
{
  filename = "__my-mod__/graphics/entity/animation.png",
  width = 64,
  height = 64,
  frame_count = 8,
  line_length = 4,
  animation_speed = 0.5,
  shift = {0, 0},
}
```

### Working Visualisations
```lua
working_visualisations = {
  {
    animation = { ... },
    light = { intensity = 0.5, size = 8 },
  }
}
```

### Sound
```lua
{
  filename = "__my-mod__/sound/my-sound.ogg",
  volume = 0.5,
  audible_distance_modifier = 0.5,
}
```

For entity `working_sound`:
```lua
working_sound = {
  sound = { filename = "__base__/sound/assembling-machine-t1-1.ogg", volume = 0.5 },
  audible_distance_modifier = 0.5,
  fade_in_ticks = 4,
  fade_out_ticks = 20,
}
```

---

## Custom Input & Shortcuts

### Custom Input (Hotkeys)
```lua
{
  type = "custom-input",
  name = "my-hotkey",
  key_sequence = "SHIFT + F",
  consuming = "game-only",
}
```

### Shortcut Prototype
```lua
{
  type = "shortcut",
  name = "my-shortcut",
  order = "a",
  action = "lua",
  icon = "__my-mod__/graphics/shortcut.png",
  icon_size = 32,
  small_icon = "__my-mod__/graphics/shortcut-24.png",
  small_icon_size = 24,
}
```

---

## Settings Prototypes

Defined in `settings.lua`:
```lua
data:extend({
  {
    type = "double-setting", -- "bool-setting" | "int-setting" | "string-setting"
    name = "my-setting",
    setting_type = "runtime-global", -- "startup" | "runtime-global" | "runtime-per-user"
    default_value = 1.0,
    minimum_value = 0,
    maximum_value = 100,
    order = "a-a"
  }
})
```

At runtime, access via: `settings.global["my-setting"].value`.

---

## Localization

Files under `locale/en/*.cfg`:
```ini
[mod-name]
my-mod=My Mod Title

[entity-name]
my-entity=Custom Entity

[technology-name]
my-tech=Advanced Tech
```

Reference in prototypes: `localised_name = {"entity-name.my-entity"}`.
