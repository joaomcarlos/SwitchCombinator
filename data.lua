-- Switch Combinator - Data Phase
-- Defines entity prototype, item, recipe, and technology
--
-- Architecture:
--   Visible entity: decider-combinator type (has input/output wire connectors, correct visuals)
--   Hidden entity:  constant-combinator (for writing output signals via script)
--   The decider's built-in behavior is left empty (no conditions set).
--   We intercept the GUI, read input signals from the input connectors,
--   evaluate our custom logic, and write outputs to the hidden constant-combinator
--   which is wired to the visible entity's output connectors.

require("util")

local decider = data.raw["decider-combinator"]["decider-combinator"]

-- ============================================================================
-- Main visible entity - based on decider-combinator
-- ============================================================================
local entity = table.deepcopy(decider)
entity.name = "switch-combinator"
entity.minable.result = "switch-combinator"
entity.icon = "__switch-combinator__/graphics/icons/switch-combinator.png"
entity.icon_size = 64

-- ============================================================================
-- Hidden output entity - constant-combinator for scriptable signal output
-- Placed at the same position, invisible, connected to the visible entity's
-- output wire connectors via script.
-- ============================================================================
local output_entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
output_entity.name = "switch-combinator-output"
output_entity.flags = {
  "placeable-neutral",
  "not-on-map",
  "not-deconstructable",
  "not-blueprintable",
  "hide-alt-info",
  "not-flammable",
  "not-upgradable",
  "not-in-kill-statistics",
}
output_entity.hidden = true
output_entity.selectable_in_game = false
output_entity.collision_mask = {layers = {}}
output_entity.collision_box = {{-0.01, -0.01}, {0.01, 0.01}}
output_entity.selection_box = {{-0.01, -0.01}, {0.01, 0.01}}
output_entity.draw_circuit_wires = false
-- Make invisible: override sprite fields that exist on the base prototype
if output_entity.sprites then
  output_entity.sprites = util.empty_sprite()
end
if output_entity.activity_led_sprites then
  output_entity.activity_led_sprites = util.empty_sprite()
end
if output_entity.activity_led_light_offsets then
  output_entity.activity_led_light_offsets = {{0, 0}, {0, 0}, {0, 0}, {0, 0}}
end

-- ============================================================================
-- Item
-- ============================================================================
local item = table.deepcopy(data.raw.item["decider-combinator"])
item.name = "switch-combinator"
item.place_result = "switch-combinator"
item.icon = "__switch-combinator__/graphics/icons/switch-combinator.png"
item.icon_size = 64
item.order = "c[combinators]-e[switch-combinator]"
item.subgroup = "circuit-network"

-- ============================================================================
-- Recipe - same cost as decider combinator
-- ============================================================================
local recipe = {
  type = "recipe",
  name = "switch-combinator",
  enabled = false,
  energy_required = 0.5,
  ingredients = {
    {type = "item", name = "copper-cable", amount = 5},
    {type = "item", name = "electronic-circuit", amount = 5},
  },
  results = {
    {type = "item", name = "switch-combinator", amount = 1},
  },
}

-- ============================================================================
-- Technology - add to circuit-network
-- ============================================================================
local tech_effect = {
  type = "unlock-recipe",
  recipe = "switch-combinator",
}

data:extend{entity, output_entity, item, recipe}

if data.raw.technology["circuit-network"] then
  table.insert(data.raw.technology["circuit-network"].effects, tech_effect)
end
