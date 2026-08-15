---
title: Factorio Modding — Ammo, Bullets & Effects
description: Ammo and projectile effects skill. Script effects, ammo patching, bullet trails, penetration, ricochets, and projectile creation. Patterns from RealisticBullets.
---

# Factorio Modding — Ammo, Bullets & Effects

Use this skill when working with ammo, bullets, projectiles, explosions, trails, ricochets, or any on-impact script behavior.

For ammo, projectile, explosion, and effect prototype definitions, use the official [Factorio Data repository](https://github.com/wube/factorio-data) as the versioned source of truth. Inspect the branch, tag, or release matching the target Factorio version before relying on fields or action shapes; use the official API docs for runtime event fields and methods.

---

## Script Effect Pattern

The most powerful way to intercept bullet/projectile impacts in Factorio is the `script` effect type.

### Step 1: Attach Script Effect to Ammo
In `data-updates.lua`, patch ammo prototypes to add a script effect:

```lua
local RB_SCRIPT_EFFECT_ID = "rb-bullet-impact"

local function ensure_target_effects(action_delivery)
  if not action_delivery.target_effects then action_delivery.target_effects = {} end
  if (not action_delivery.target_effects[1]) and action_delivery.target_effects.type then
    action_delivery.target_effects = {action_delivery.target_effects}
  end
  return action_delivery.target_effects
end

local function add_script_effect(action_delivery)
  local target_effects = ensure_target_effects(action_delivery)
  for _, effect in pairs(target_effects) do
    if effect.type == "script" and effect.effect_id == RB_SCRIPT_EFFECT_ID then
      return
    end
  end
  table.insert(target_effects, { type = "script", effect_id = RB_SCRIPT_EFFECT_ID })
end

-- Patch all bullet ammo
for ammo_name, ammo in pairs(data.raw.ammo) do
  if ammo.ammo_type and ammo.ammo_type.category and ammo.ammo_type.category == "bullet" then
    local action1 = ammo.ammo_type.action[1] or ammo.ammo_type.action
    if action1 and action1.action_delivery then
      local ad = action1.action_delivery[1] or action1.action_delivery
      if ad then add_script_effect(ad) end
    end
  end
end
```

### Step 2: Handle the Event at Runtime
In `control.lua`:

```lua
local EFFECT_ID = "rb-bullet-impact"

script.on_event(defines.events.on_script_trigger_effect, function(event)
  if event.effect_id ~= EFFECT_ID then return end
  if not (event.surface and event.target_position and event.source_position) then return end

  local surface = event.surface
  local source = event.source_position
  local impact = event.target_position
  local force = event.source_entity and event.source_entity.force

  -- Your logic here: penetration, ricochet, trail, etc.
end)
```

**Event fields available:**
- `event.effect_id` — the string ID you assigned
- `event.surface` — LuaSurface
- `event.source_position` — where the projectile was fired from
- `event.target_position` — where it hit
- `event.source_entity` — the entity that fired it (may be nil)

---

## Bullet Trail Explosions

Create invisible explosions that animate as bullet trails:

```lua
data:extend({
  {
    type = "explosion",
    name = "bullet-beam-white-faint",
    flags = {"not-on-map", "placeable-off-grid"},
    hidden = true,
    random_target_offset = true,
    target_offset_y = -0.3,
    animation_speed = 1,
    rotate = true,
    beam = true,
    animations = {
      {
        filename = "__my-mod__/graphics/entity/projectile/bullet-beam-white-faint.png",
        priority = "extra-high",
        width = 7,
        height = 90,
        frame_count = 5,
      }
    },
    light = {intensity = 0.1, size = 2},
    smoke = "smoke-fast",
    smoke_count = 1,
    smoke_slow_down_factor = 1
  }
})
```

Attach to ammo as a `create-explosion` target effect:
```lua
table.insert(target_effects, { type = "create-explosion", entity_name = "bullet-beam-white-faint" })
```

---

## Projectile Creation at Runtime

Create follow-up projectiles for penetration/ricochet:

```lua
local function offset_pos(pos, angle, distance)
  return {
    x = pos.x + math.cos(angle) * distance,
    y = pos.y + math.sin(angle) * distance,
  }
end

-- Penetration projectile
surface.create_entity({
  name = "rb-penetration-projectile",
  position = impact,
  target = exit_target,
  speed = 0.8,
  force = force,
})

-- Ricochet projectile (arcing with negative acceleration)
surface.create_entity({
  name = "rb-ricochet-projectile",
  position = impact,
  target = bounce_target,
  speed = 0.1,
  force = "neutral",
})
```

---

## Projectile Prototypes

Clone from vanilla and modify:

```lua
local base = data.raw.projectile["piercing-shotgun-pellet"] or data.raw.projectile["shotgun-pellet"]
if base then
  local penetration = util.table.deepcopy(base)
  penetration.name = "rb-penetration-projectile"
  penetration.acceleration = (penetration.acceleration or 0) * 0.8
  penetration.action = {
    {
      type = "direct",
      action_delivery = {
        type = "instant",
        target_effects = {
          {type = "damage", damage = {amount = 4, type = "physical"}}
        }
      }
    }
  }

  local ricochet = util.table.deepcopy(base)
  ricochet.name = "rb-ricochet-projectile"
  ricochet.acceleration = -0.004  -- arcs downward
  ricochet.action = nil  -- no damage, just visual
  ricochet.hit_at_collision_position = false

  data:extend({penetration, ricochet})
end
```

---

## Smoke & Visual Effects

```lua
-- Fast smoke puff at impact
surface.create_trivial_smoke({name = "smoke-fast", position = impact})

-- Create explosion
surface.create_entity({name = "explosion", position = impact})
```

---

## Penetration/Ricochet Patterns (from RealisticBullets)

```lua
local function chance_by_distance(distance, assumed_max)
  local ratio = distance / math.max(assumed_max, 1)
  if ratio <= 0.25 then return 0.8
  elseif ratio <= 0.5 then return 0.5
  elseif ratio <= 0.75 then return 0.3
  end
  return 0.1
end

local heading = math.atan(impact.y - source.y, impact.x - source.x)

-- Penetration
if math.random() < chance_by_distance(distance, 36) then
  local angle = heading + math.rad(2) * (math.random() - 0.5)
  local exit = offset_pos(impact, angle, distance * 0.4)
  surface.create_entity({
    name = "rb-penetration-projectile",
    position = impact,
    target = exit,
    speed = 0.8,
    force = force,
  })
else
  -- Ground bounce/ricochet
  if math.random() < 0.6 then
    local bounce_angle = heading + math.rad(12) * (math.random() - 0.5)
    local bounce = offset_pos(impact, bounce_angle, distance * 0.2)
    surface.create_entity({
      name = "rb-ricochet-projectile",
      position = impact,
      target = bounce,
      speed = 0.1,
      force = "neutral",
    })
  end
end
```

---

## Settings for Ammo Mods

Use runtime-global settings so players can tune behavior in-game:

```lua
data:extend({
  {
    type = "double-setting",
    name = "rb-penetration-chance",
    setting_type = "runtime-global",
    default_value = 0.5,
    minimum_value = 0,
    maximum_value = 1,
    order = "a-a"
  },
  {
    type = "double-setting",
    name = "rb-spread-deg-max",
    setting_type = "runtime-global",
    default_value = 0.5,
    minimum_value = 0,
    maximum_value = 5,
    order = "a-b"
  },
})
```

Access at runtime: `settings.global["rb-penetration-chance"].value`
