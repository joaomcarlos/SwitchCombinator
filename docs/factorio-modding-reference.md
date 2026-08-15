---
title: Factorio Modding Reference
description: Practical guide to building and maintaining Factorio 2.0 mods
---

# Factorio Modding Reference

_Compiled from the official [Factorio API docs](https://lua-api.factorio.com/latest/) (v2.0.75) and supporting wiki resources._

## 1. Mod Fundamentals
- **Language/runtime**: Lua 5.2 with Factorio-specific globals. Standard libraries mostly available; sandbox forbids OS/filesystem access.
- **Distribution**: Mods live under `%APPDATA%/Factorio/mods` and are shared via the [Mod Portal](https://mods.factorio.com/). Packaged mods follow `{name}_{version}.zip` naming.
- **Required files**: `info.json` (identifier, version, dependencies, optional settings), `control.lua` (runtime scripts), `data.lua` set (prototypes), `settings.lua` set (configuration), `changelog.txt` (strict format), `thumbnail.png` (144×144 recommended). @docs/mod-structure#1-70
- **Optional folders**: `locale/`, `migrations/`, `tutorials/`, `campaigns/`, `scenarios/`. @docs/mod-structure#70-109

## 2. Data Lifecycle (Game Startup → Save Startup)
Factorio loads mods via three sequential stages that reset Lua state between each stage. Understanding the lifecycle prevents invalid API usage. @docs/data-lifecycle#1-79

| Stage | Files | Notes |
| --- | --- | --- |
| **Settings** | `settings.lua`, `settings-updates.lua`, `settings-final-fixes.lua` | Define startup/map/player settings. Runtime settings object not yet available. |
| **Prototype (Data)** | `data.lua`, `data-updates.lua`, `data-final-fixes.lua` | Create/modify prototypes via `data:extend{...}` with access to `data`, `mods`, and read-only `settings.startup`. No runtime API. |
| **Runtime (Control)** | `control.lua` (plus required modules) | Real game world exists. Access runtime globals (`game`, `script`, `remote`, `rendering`, `commands`, `storage`, etc.). |

Save startup loads `control.lua`, then runs registered `script.on_init`, `on_configuration_changed`, and `on_load`. `storage` is rehydrated just before `on_load` and cannot be mutated inside `on_load`. @docs/storage#1-78

## 3. Mod Structure & Packaging
1. **info.json**: Specifies `name`, `version`, `title`, `author`, `factorio_version`, `dependencies`, `description`. Dependencies support `>=`, `<=`, `!`, `?`, `~`. This file controls load order and compatibility gates.
2. **changelog.txt**: Each release entry begins with `Version: <semver>` and `Date: YYYY-MM-DD`. Required for mod portal uploads.
3. **Thumbnail**: PNG shown in UI/portal; keep small file size.
4. **Locale**: Each language folder (e.g., `locale/en/`) contains `.cfg` files grouped by section (`[mod-name]`). Keys map to `{'some-key'}` references in prototypes.
5. **Migrations**: Add Lua migration files when changing prototype names or persistent data structure to keep saves functional. Use `game.remove_path`/`game.create_force` only in migrations.

## 4. Settings Stage Essentials
- Settings types: **startup** (apply on game load, available in prototype stage), **map** (shared per save, accessible runtime via `settings.global`), **per-player** (per user via `settings.get_player_settings(player)`), **runtime-global/player** for immediate effect.
- Use `data:extend` with `type = "bool-setting" | "int-setting" | "double-setting" | "string-setting"` etc. Provide `setting_type`, default `value`, locale keys.
- `settings-updates.lua`/`settings-final-fixes.lua` let you react to other mods’ settings without hard dependencies.

## 5. Prototype (Data) Stage Patterns
- The `data` global contains all prototypes; mutate via `data.raw["type"]["name"]` or `data:extend`. Missing required fields raise errors; unknown fields ignored.
- Prototype files run in three passes letting mods override earlier definitions. Use `data-updates.lua` to patch dependencies that loaded before you; `data-final-fixes.lua` as a fallback for late overrides.
- Use `mods` table (map of mod name → version) to guard compatibility shims.
- `settings.startup` is read-only in this stage.
- No runtime objects (no `game`, `script`, `storage`).

### Common Prototype Workflows
1. **Cloning and modifying entities**:
   ```lua
   local base = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
   base.name = "super-assembler"
   base.energy_usage = "300kW"
   data:extend{base}
   ```
2. **Using `util.by_pixel` and helpers**: Require `__core__/lualib/util` for alignment helpers.
3. **Disable/enable recipes** by toggling `enabled` or editing technologies via `data.raw.technology`.

## 6. Runtime Stage & Global Objects
Main globals (all read-only references except `storage`):
- `script` (`LuaBootstrap`): register events, remote interfaces, GUIs, custom inputs, migrations, and set up `script.on_event`, `script.on_init`, `script.on_configuration_changed`.
- `game` (`LuaGameScript`): entry point for forces, surfaces, players, entities, print/log, permissions, pollution, etc. Available except in `on_load`.
- `rendering` (`LuaRendering`): draw sprites/shapes with handles you must destroy when no longer needed.
- `remote`: register functions for other mods (`remote.add_interface`) and call their APIs (`remote.call`).
- `commands`: create console commands (`commands.add_command`).
- `prototypes`: read-only view of prototype data at runtime.
- `settings`: runtime view (`settings.global`, `settings.player`).
- `helpers`: assorted utilities (e.g., bounding boxes, position math).
- `storage`: serialized table for persistent state (replaces `global`).

### Event Flow
- **Initialization**: `script.on_init` runs once per save after mod is added. Initialize `storage`, build lookup tables.
- **Configuration changes**: `script.on_configuration_changed` fires on mod updates or dependency changes; migrate data here.
- **Load**: `script.on_load` runs after a save is loaded; reattach metatables/event handlers but never mutate `storage`.
- **Per-tick**: Register deterministic logic via `script.on_event(defines.events.on_tick, handler)` or use `script.on_nth_tick(n, handler)` for periodic work.
- **Entity & player events**: Use `defines.events` constants (e.g., `on_built_entity`, `on_robot_mined_entity`, `on_gui_click`). Avoid raising built-in events manually with `script.raise_event`; only raise custom events.

### Persistent Data Rules
- Only store serializable data in `storage`: primitives, tables, registered metatables, Factorio LuaObjects. No functions or coroutines. Trying to save functions triggers errors. @docs/storage#1-78
- Never access `storage` in `control.lua` before `on_init`/`on_load`; Factorio warns that data is not ready yet during first pass.
- Use module-level locals for ephemeral caches or closures; they persist across save/load because modules stay loaded.
- Register metatables you need to persist via `script.register_metatable(name, table)` (runtime) and reapply after load.

## 7. Script Organization Tips
- **Entry point**: `control.lua` can `require` modules (e.g., `require("scripts.logic.state_manager")`). Module scope is shared across saves; avoid storing dynamic per-save data in locals unless reinitialized in `on_init/on_configuration_changed`.
- **State managers**: Keep deterministic logic pure; push side effects to event handlers so autosaves remain stable.
- **Error handling**: Allow errors to surface (Factorio halts with stack trace). Prefer assertions over silent failure.
- **Performance**: Use `script.on_nth_tick` for periodic tasks, cache frequently used prototypes (`game.entity_prototypes[...]`), and avoid iterating entire surfaces each tick.

## 8. GUI Programming (Factorio 2.0 specifics)
- Construct GUIs via `LuaGuiElement.add{type=..., name=...}`. Always address children with `parent["child-name"]`; dot syntax is invalid. (Memory note.)
- Styles: Factorio 2.0 reuses `frame_action_button`, `sprite-button` close icons (`sprite="utility/close"`), `inside_shallow_frame_with_padding`, `deep_frame_in_shallow_frame`, `draggable_space_header`, `frame_title`, `caption_label`, `bold_label`, `mini_button`, `slot_button`, `confirm_button`, `green_button`, `red_button`. (Memory note.)
- Dropdown `selected_index` is 1-based. (Memory note.)
- Use `player.gui.screen` for draggable windows; call `element.force_auto_center()` or set `location` explicitly.
- Store GUI references in `storage.players[player_index].gui = { ... }` or rebuild on demand using tags. Never keep raw LuaObjects in `storage` after they become invalid; check `element.valid` before use.

## 9. Remote Interfaces & Commands
- **Remote**: `remote.add_interface("your-mod", {do_thing = function(args) ... end})`. Document parameters and return values. Use `remote.call("other-mod", "fn", ...)` carefully—wrap in `pcall` if optional dependency.
- **Command registration**: `commands.add_command("switch", "Toggle state", function(cmd) ... end)`. Validate `cmd.player_index` (nil means server/RCON). Commands run with cheat privileges disabled.
- **RCON**: `commands.add_command` outputs to console; `rcon.print` to remote clients.

## 10. Custom Inputs & Hotkeys
- Define custom inputs during prototype stage (`type = "custom-input"`) pointing to named actions. At runtime, register handlers for `defines.events.on_lua_shortcut` or `on_custom_input`.
- For toggles, store player preference in `storage.players[player_index]` and update GUIs accordingly.

## 11. Rendering & Visualization
- Use `rendering.draw_text`, `draw_sprite`, `draw_circle`, etc. Store returned IDs in per-player tables for cleanup via `rendering.destroy(id)`.
- Rendering primitives have `surface`, `target`, `time_to_live`, and `forces` filters. Keep TTL small to avoid leaks.

## 12. Logging, Debugging, Testing
- `game.print` (requires at least one argument) shows messages to all players; prefer `log()` for console-only output. (Memory note.)
- Use `/sc` console for quick snippets during testing.
- For automated checks, leverage the community [`factorio-test`](https://github.com/justarandomgeek/vscode-factoriomod-debug) frameworks or stand-alone Lua test harnesses (as in `tests/` of this repo). Run Lua syntax checks outside the game to catch obvious errors early.
- Keep assertions enabled; let the game crash fast if invariants break.

## 13. Migrations & Save Compatibility
- Prototype migrations: create JSON or Lua migration files under `migrations/`. Use `data.raw` adjustments for renamed items, recipes, technologies.
- Runtime migrations: in `control.lua`, handle `script.on_configuration_changed` with `data.mod_changes["your-mod"]`. Update `storage` version numbers and evolve structures there.
- Perform `game.forces`/`game.players` adjustments inside configuration change handler (e.g., unlocking research, updating GUIs).

## 14. Packaging & Publishing Checklist
1. Update `info.json` version and dependencies.
2. Add release entry to `changelog.txt`.
3. Run automated Lua tests + in-game smoke test.
4. Ensure `thumbnail.png` and `README` reflect latest features.
5. Zip folder as `{name}_{version}.zip` with correct structure.
6. Upload to mod portal; fill release notes from changelog entry.

## 15. Quick Reference Links
- [API Index](https://lua-api.factorio.com/latest/)
- [Data Lifecycle](https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html)
- [Mod Structure](https://lua-api.factorio.com/latest/auxiliary/mod-structure.html)
- [Storage](https://lua-api.factorio.com/latest/auxiliary/storage.html)
- [Runtime Classes](https://lua-api.factorio.com/latest/classes.html)
- [Events](https://lua-api.factorio.com/latest/events.html)
- [Defines](https://lua-api.factorio.com/latest/defines.html)
- [Prototype Reference](https://lua-api.factorio.com/latest/index-prototype.html)
- [Mod Settings Tutorial](https://wiki.factorio.com/Tutorial:Mod_settings)
- [Localisation Tutorial](https://wiki.factorio.com/Tutorial:Localisation)
- [Migrations Guide](https://lua-api.factorio.com/latest/auxiliary/migrations.html)

## 16. Gotchas Highlighted During Factorio 2.0 Transition
- Persistent data lives in `storage`, not `global`.
- `game.print` is a read-only function and requires ≥1 arg.
- `require()` cannot run inside `script.on_load` (no `game` there either).
- Built-in events (e.g., `on_tick`) cannot be raised via `script.raise_event`.
- Constant combinators now use `control_behavior.sections` instead of `parameters`.
- Dropdown indices are 1-based; GUI elements are addressed via bracket notation.
- Entity name for lamps is `"small-lamp"`.
- `game.tick` is read-only; don’t attempt to assign.
- Lua modules stay loaded between saves, so treat module locals as static singletons.
- Never store Lua functions/coroutines in `storage`—the save will fail.

Use this reference as a living document—add module-specific patterns or pitfalls as they surface.
