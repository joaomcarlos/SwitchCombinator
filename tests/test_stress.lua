-- Stress/scale tests for Switch Combinator
-- Validates performance and correctness with many groups, conditions, and outputs.

local test_framework = require("tests.test_framework")
local state_manager = require("scripts.logic.state_manager")

local tests = {}

local function create_test_entity(surface, position)
  local entity = surface.create_entity{
    name = "switch-combinator",
    position = position,
    force = "player"
  }
  if entity then
    state_manager.init_entity(entity.unit_number)
  end
  return entity
end

-- ============================================================================
-- Tests
-- ============================================================================

function tests.test_many_groups()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 400, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  for i = 1, 20 do
    state_manager.add_group(entity.unit_number)
  end

  local groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 21, "21 groups total")

  -- Verify all group names are correct
  for i = 1, 21 do
    test_framework.assert_equal(groups[i].name, "Match " .. i, "Group " .. i .. " name")
  end

  entity.destroy()
end

function tests.test_many_conditions_per_group()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 401, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  for i = 1, 15 do
    state_manager.add_condition(entity.unit_number, 1)
  end

  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.conditions, 16, "16 conditions")

  -- Verify first has no logic, rest have default "or"
  test_framework.assert_nil(g.conditions[1].logic, "First logic nil")
  for i = 2, 16 do
    test_framework.assert_equal(g.conditions[i].logic, "or", "Condition " .. i .. " logic is or")
  end

  entity.destroy()
end

function tests.test_many_outputs_per_group()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 402, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  for i = 1, 15 do
    state_manager.add_output(entity.unit_number, 1)
  end

  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.outputs, 16, "16 outputs")

  entity.destroy()
end

function tests.test_rapid_add_remove_cycles()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 403, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  -- Rapidly add and remove groups
  for i = 1, 10 do
    state_manager.add_group(entity.unit_number)
    state_manager.remove_group(entity.unit_number, 2)
  end

  local groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 1, "Back to 1 group after cycles")

  -- Rapidly add and remove conditions
  for i = 1, 10 do
    state_manager.add_condition(entity.unit_number, 1)
    state_manager.remove_condition(entity.unit_number, 1, 2)
  end

  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.conditions, 1, "Back to 1 condition after cycles")

  entity.destroy()
end

function tests.test_multiple_entities_scale()
  local surface = game.surfaces[1]
  local entities = {}

  for i = 1, 10 do
    local e = create_test_entity(surface, {x = 404 + i, y = 0})
    test_framework.assert_not_nil(e, "Entity " .. i .. " created")
    entities[i] = e

    -- Add a group and condition to each
    state_manager.add_group(e.unit_number)
    state_manager.set_condition_constant(e.unit_number, 1, 1, i * 10)
  end

  -- Verify isolation
  for i = 1, 10 do
    local g = state_manager.get_group(entities[i].unit_number, 1)
    test_framework.assert_equal(g.conditions[1].constant, i * 10, "Entity " .. i .. " constant")
  end

  for _, e in ipairs(entities) do
    if e.valid then e.destroy() end
  end
end

-- ============================================================================
-- Run all
-- ============================================================================

function tests.run_all()
  local pf = test_framework._print_func or game.print
  pf("[TEST] Running Stress Tests...")

  test_framework.run_test("Many Groups (20)", tests.test_many_groups)
  test_framework.run_test("Many Conditions Per Group (16)", tests.test_many_conditions_per_group)
  test_framework.run_test("Many Outputs Per Group (16)", tests.test_many_outputs_per_group)
  test_framework.run_test("Rapid Add/Remove Cycles", tests.test_rapid_add_remove_cycles)
  test_framework.run_test("Multiple Entities Scale (10)", tests.test_multiple_entities_scale)

  pf("[TEST] Stress: Passed=" .. test_framework.passed .. " Failed=" .. test_framework.failed)
end

return tests
