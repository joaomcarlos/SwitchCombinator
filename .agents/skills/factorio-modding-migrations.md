---
title: Factorio Modding — Migrations & Save Compatibility
description: Migrations skill for Factorio 2.0. Prototype renames, storage schema changes, JSON migrations, Lua migrations, version tracking.
---

# Factorio Modding — Migrations & Save Compatibility

Use this skill when updating an existing mod and ensuring old saves continue to work.

Treat the official [Factorio Data repository](https://github.com/wube/factorio-data) as the source of truth when comparing prototype names, types, and fields between the old and new Factorio versions while designing migrations. Select the matching branch, tag, or release; use the official API docs for migration lifecycle and runtime contracts.

---

## JSON Migrations (Prototype Changes)

Place JSON files under `migrations/` for simple prototype renames. The game applies these automatically.

```json
{
  "entity": {
    "old-entity-name": "new-entity-name"
  },
  "item": {
    "old-item-name": "new-item-name"
  },
  "recipe": {
    "old-recipe": "new-recipe"
  },
  "technology": {
    "old-tech": "new-tech"
  }
}
```

These handle: placed entities in the world, items in inventories, recipes in assemblers, researched technologies, and blueprint contents.

---

## Lua Migrations (Runtime Data)

For `storage` schema changes, use `script.on_configuration_changed` in `control.lua`:

```lua
script.on_configuration_changed(function(event)
  if event.mod_changes["my-mod"] then
    local old_version = event.mod_changes["my-mod"].old_version
    local new_version = event.mod_changes["my-mod"].new_version

    -- Initialize version tracking if missing
    if not storage.version then storage.version = "0.1.0" end

    -- Migrate from 0.1.0 to 0.2.0
    if storage.version == "0.1.0" then
      -- Rename field
      for un, data in pairs(storage.entity_data or {}) do
        if data.old_field and not data.new_field then
          data.new_field = data.old_field
          data.old_field = nil
        end
      end
      storage.version = "0.2.0"
    end

    -- Migrate from 0.2.0 to 0.3.0
    if storage.version == "0.2.0" then
      -- Add new required field with default
      for un, data in pairs(storage.entity_data or {}) do
        if data.mode == nil then
          data.mode = "first_match"
        end
      end
      storage.version = "0.3.0"
    end

    log("Migrated my-mod from " .. tostring(old_version) .. " to " .. storage.version)
  end
end)
```

---

## Safe Migration Patterns

### Always Check Before Assuming
```lua
-- Safe
for un, data in pairs(storage.entity_data or {}) do
  -- data might be missing fields
end

-- Unsafe
for un, data in pairs(storage.entity_data) do
  -- crashes if storage.entity_data is nil
end
```

### Handle Invalid Entities
During migrations, previously stored entities may no longer exist:

```lua
for un, entry in pairs(storage.my_entities or {}) do
  if entry.entity and entry.entity.valid then
    -- still exists
  else
    -- entity was removed; clean up
    storage.my_entities[un] = nil
  end
end
```

### Rebuild Registries
If your entity tracking is complex, it may be simpler to rebuild from the world:

```lua
local function rebuild_entity_registry()
  storage.my_entities = {}
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name = "my-entity"}) do
      if entity.valid then
        storage.my_entities[entity.unit_number] = { entity = entity }
      end
    end
  end
end

script.on_configuration_changed(function()
  rebuild_entity_registry()
end)
```

### Add Defaults for New Settings
```lua
script.on_configuration_changed(function()
  if not storage.configured then
    storage.configured = {
      mode = "first_match",
      enabled = true,
    }
  end
end)
```

---

## Migrations File Naming Convention

Lua migration filenames should be sortable:
```
migrations/my-mod_0.2.0.lua
migrations/my-mod_0.3.0.lua
```

These run in order when loading a save. However, for runtime data changes, `on_configuration_changed` is generally preferred because it has access to `game` and `storage`.

---

## Breaking Changes Checklist

Before releasing a mod update:
- [ ] Did any entity names change? Add JSON migration.
- [ ] Did any item names change? Add JSON migration.
- [ ] Did any recipe names change? Add JSON migration.
- [ ] Did `storage` schema change? Add Lua migration in `on_configuration_changed`.
- [ ] Did you add new required `storage` fields? Provide defaults in migration.
- [ ] Do old saves need entity registry rebuilt? Add rebuild logic.
- [ ] Test by loading an old save with the new mod version.
