---
title: Factorio Modding Skill Book (Base)
description: Router skill for Factorio 2.0 mod development. Load sub-skills as needed for the specific task at hand.
---

# Factorio Modding Skill Book — Base

You are a Factorio 2.0 mod developer. **This is the base skill.** It contains universal knowledge every modder needs. For topic-specific depth, load the matching sub-skill from the Skill Book below.

Consult the official API at https://lua-api.factorio.com/latest/ whenever exact field names or class methods are needed.

## Versioned Prototype Source of Truth

Treat the official [Factorio Data repository](https://github.com/wube/factorio-data) as the source of truth for versioned Lua prototype definitions. Select the branch, tag, or release matching the target Factorio version and compare versions when prototype types, fields, defaults, or vanilla names may have changed. Use the official API documentation for runtime classes, methods, events, and lifecycle contracts; `factorio-data` complements those docs rather than replacing them.

---

## Data Lifecycle (Universal)

Factorio loads mods through three sequential stages with **reset Lua state** between each:

| Stage | Files | Available Globals |
|-------|-------|-----------------|
| **Settings** | `settings.lua`, `settings-updates.lua`, `settings-final-fixes.lua` | `data`, `mods`, read-only `settings.startup` |
| **Prototype (Data)** | `data.lua`, `data-updates.lua`, `data-final-fixes.lua` | `data`, `mods`, read-only `settings.startup` |
| **Runtime (Control)** | `control.lua` + required modules | `game`, `script`, `storage`, `remote`, `rendering`, `commands`, `prototypes`, `settings` |

**Rules that apply everywhere:**
- `require()` at top level in `control.lua` persists across save/load. Never call `require()` inside `script.on_load()`.
- `game` is unavailable during `script.on_load()`.
- Factorio Lua is sandboxed — no filesystem/OS access.

---

## Skill Book — Load the Right Skill for the Task

| Sub-skill | Load When... |
|-----------|-------------|
| `factorio-modding-prototypes` | Defining or modifying prototypes: entities, items, recipes, technologies, fluids, tiles, explosions, projectiles, graphics, sounds, custom inputs, shortcuts, settings. |
| `factorio-modding-runtime` | Writing runtime scripts: event handlers, storage, entity management, surface/force/player API, recipe/tech manipulation, rendering, commands, remote interfaces. |
| `factorio-modding-gui` | Building or modifying GUIs: frames, close buttons, styles, drag handles, checkbox/dropdown/text events, window management. |
| `factorio-modding-circuit-network` | Working with circuit networks: wire connectors, combinators, signals, inserter control behavior. |
| `factorio-modding-ammo-effects` | Working with ammo, bullets, projectiles, explosions, trails, ricochets, script effects, on_script_trigger_effect. |
| `factorio-modding-performance` | Optimizing or writing multiplayer-safe code: event filters, caching, determinism, on_nth_tick, batch operations. |
| `factorio-modding-migrations` | Updating an existing mod and keeping old saves working: prototype renames, storage schema changes, version tracking. |
| `factorio-modding-debugging` | Debugging a broken mod: pcall, logging, console commands, flying text, inspecting state. |
| `factorio-modding-vanilla-reference` | Looking up vanilla names: entities, items, technologies, fluids, resources. |

---

## Universal Gotchas

- **`storage` replaces `global`** in Factorio 2.0. `global` still works but `storage` is correct.
- **NEVER store Lua functions or coroutines in `storage`** — causes "Cannot serialise lua functions" on save.
- **`game.print` is read-only** and requires at least 1 argument.
- **`game.tick` is read-only**.
- **`script.raise_event()` cannot raise built-in events** like `on_tick` or `on_built_entity`.
- **Entity name for lamps is `"small-lamp"`**, not `"lamp"`.
- **`require()` returns `true`** if the module doesn't have an explicit `return`.
- **GUI children accessed by brackets**: `parent["child-name"]`, NEVER `parent.child_name`.
- **Dropdown `selected_index` is 1-based**, not 0-based.
- **`event.entity` vs `event.created_entity`**: `on_built_entity` uses `event.created_entity`; `on_robot_built_entity` also uses `event.created_entity`. Check event docs.
- **`math.random()` is NOT synchronized in multiplayer**. Use only for cosmetic effects.
- **`prototypes` is read-only** at runtime.
- **`entity.unit_number` is nil for some entities** (ghosts, items-on-ground).

---

## When Implementing

1. Load the matching sub-skill for your current task.
2. Clone vanilla prototypes rather than defining from scratch.
3. Keep `control.lua` as an event router; put logic in required modules.
4. Use `script.on_configuration_changed` for migrations.
5. Let errors surface with stack traces during development.
6. Validate all LuaObjects with `.valid` before use.
7. Cache prototype lookups; never look them up every tick.
8. When unsure about exact fields, consult `https://lua-api.factorio.com/latest/` immediately.

---

## Quick API Links

- [API Index](https://lua-api.factorio.com/latest/)
- [Data Lifecycle](https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html)
- [Mod Structure](https://lua-api.factorio.com/latest/auxiliary/mod-structure.html)
- [Storage](https://lua-api.factorio.com/latest/auxiliary/storage.html)
- [Runtime Classes](https://lua-api.factorio.com/latest/classes.html)
- [Events](https://lua-api.factorio.com/latest/events.html)
- [Defines](https://lua-api.factorio.com/latest/defines.html)
- [Prototype Reference](https://lua-api.factorio.com/latest/index-prototype.html)
