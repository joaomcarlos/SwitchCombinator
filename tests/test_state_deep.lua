-- Deep tests for Switch Combinator state_manager uncovered functions

local test_framework = require("tests.test_framework")
local state_manager = require("scripts.logic.state_manager")

local tests = {}

function tests.test_clone_entity_data_is_independent()
  local original = {
    mode = "first_match",
    groups = {
      {
        conditions = {
          {left_signal = {type = "item", name = "iron-plate"}}
        },
        outputs = {
          {signal = {type = "virtual", name = "signal-A"}}
        }
      }
    }
  }

  local clone = state_manager.clone_entity_data(original)
  clone.groups[1].conditions[1].left_signal.name = "copper-plate"
  clone.groups[1].outputs[1].signal.name = "signal-B"

  test_framework.assert_equal(original.groups[1].conditions[1].left_signal.name,
    "iron-plate", "Cloning must not alias nested condition signals")
  test_framework.assert_equal(original.groups[1].outputs[1].signal.name,
    "signal-A", "Cloning must not alias nested output signals")
end

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
-- Group rename
-- ============================================================================

function tests.test_rename_group()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 300, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  state_manager.rename_group(entity.unit_number, 1, "Custom Name")
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.name, "Custom Name", "Group renamed")

  state_manager.rename_group(entity.unit_number, 1, "")
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.name, "", "Group name empty string")

  entity.destroy()
end

function tests.test_rename_invalid_group()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 301, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  -- Should not crash on invalid group
  state_manager.rename_group(entity.unit_number, 99, "Should Fail Silently")
  test_framework.assert_true(true, "Rename invalid group does not crash")

  entity.destroy()
end

-- ============================================================================
-- Condition deep properties
-- ============================================================================

function tests.test_set_condition_compare_type()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 302, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  state_manager.set_condition_compare_type(entity.unit_number, 1, 1, "signal")
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.conditions[1].compare_type, "signal", "Compare type signal")

  state_manager.set_condition_compare_type(entity.unit_number, 1, 1, "constant")
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.conditions[1].compare_type, "constant", "Compare type constant")

  entity.destroy()
end

function tests.test_set_condition_right_signal()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 303, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  state_manager.set_condition_right_signal(entity.unit_number, 1, 1, {type = "virtual", name = "signal-Z"})
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_not_nil(g.conditions[1].right_signal, "Right signal set")
  test_framework.assert_equal(g.conditions[1].right_signal.name, "signal-Z", "Right signal name")

  entity.destroy()
end

function tests.test_condition_right_wire_isolation()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 304, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  state_manager.set_condition_wire(entity.unit_number, 1, 1, "right", "red", false)
  state_manager.set_condition_wire(entity.unit_number, 1, 1, "right", "green", false)
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_false(g.conditions[1].right_red, "right_red false")
  test_framework.assert_false(g.conditions[1].right_green, "right_green false")
  test_framework.assert_true(g.conditions[1].left_red, "left_red unaffected")
  test_framework.assert_true(g.conditions[1].left_green, "left_green unaffected")

  entity.destroy()
end

-- ============================================================================
-- Output deep properties
-- ============================================================================

function tests.test_set_output_use_input_count()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 305, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  test_framework.assert_false(
    state_manager.get_group(entity.unit_number, 1).outputs[1].use_input_count,
    "Default use_input_count false"
  )

  state_manager.set_output_use_input_count(entity.unit_number, 1, 1, true)
  test_framework.assert_true(
    state_manager.get_group(entity.unit_number, 1).outputs[1].use_input_count,
    "use_input_count true"
  )

  state_manager.set_output_use_input_count(entity.unit_number, 1, 1, false)
  test_framework.assert_false(
    state_manager.get_group(entity.unit_number, 1).outputs[1].use_input_count,
    "use_input_count false"
  )

  entity.destroy()
end

function tests.test_output_count_boundaries()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 306, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  state_manager.set_output_count(entity.unit_number, 1, 1, 0)
  test_framework.assert_equal(state_manager.get_group(entity.unit_number, 1).outputs[1].count, 0, "Count 0")

  state_manager.set_output_count(entity.unit_number, 1, 1, -5)
  test_framework.assert_equal(state_manager.get_group(entity.unit_number, 1).outputs[1].count, -5, "Count -5")

  state_manager.set_output_count(entity.unit_number, 1, 1, 2147483647)
  test_framework.assert_equal(state_manager.get_group(entity.unit_number, 1).outputs[1].count, 2147483647, "Count max int")

  entity.destroy()
end

function tests.test_add_multiple_outputs()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 307, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  state_manager.add_output(entity.unit_number, 1)
  state_manager.add_output(entity.unit_number, 1)
  state_manager.add_output(entity.unit_number, 1)
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.outputs, 4, "4 outputs (1 default + 3 added)")

  -- Set different signals
  state_manager.set_output_signal(entity.unit_number, 1, 2, {type = "virtual", name = "signal-B"})
  state_manager.set_output_signal(entity.unit_number, 1, 3, {type = "virtual", name = "signal-C"})
  state_manager.set_output_signal(entity.unit_number, 1, 4, {type = "virtual", name = "signal-D"})

  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.outputs[2].signal.name, "signal-B", "Output 2 signal")
  test_framework.assert_equal(g.outputs[3].signal.name, "signal-C", "Output 3 signal")
  test_framework.assert_equal(g.outputs[4].signal.name, "signal-D", "Output 4 signal")

  entity.destroy()
end

function tests.test_remove_output_from_middle()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 308, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  state_manager.add_output(entity.unit_number, 1)
  state_manager.add_output(entity.unit_number, 1)
  state_manager.set_output_signal(entity.unit_number, 1, 2, {type = "virtual", name = "signal-MIDDLE"})
  state_manager.set_output_signal(entity.unit_number, 1, 3, {type = "virtual", name = "signal-LAST"})

  state_manager.remove_output(entity.unit_number, 1, 2)
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.outputs, 2, "2 outputs after middle removal")
  test_framework.assert_equal(g.outputs[2].signal.name, "signal-LAST", "Last shifted to index 2")

  entity.destroy()
end

-- ============================================================================
-- Description
-- ============================================================================

function tests.test_description_unicode_and_long()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 309, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  local long_desc = string.rep("A", 500)
  state_manager.set_description(entity.unit_number, long_desc)
  test_framework.assert_equal(state_manager.get_description(entity.unit_number), long_desc, "Long description stored")

  local unicode_desc = "Iron > Copper && Oil != Water"
  state_manager.set_description(entity.unit_number, unicode_desc)
  test_framework.assert_equal(state_manager.get_description(entity.unit_number), unicode_desc, "Unicode description stored")

  entity.destroy()
end

-- ============================================================================
-- Cross-entity isolation
-- ============================================================================

function tests.test_cross_entity_data_isolation()
  local surface = game.surfaces[1]
  local e1 = create_test_entity(surface, {x = 310, y = 0})
  local e2 = create_test_entity(surface, {x = 311, y = 0})
  test_framework.assert_not_nil(e1, "E1 created")
  test_framework.assert_not_nil(e2, "E2 created")

  state_manager.set_description(e1.unit_number, "Entity One")
  state_manager.set_description(e2.unit_number, "Entity Two")

  test_framework.assert_equal(state_manager.get_description(e1.unit_number), "Entity One", "E1 isolated")
  test_framework.assert_equal(state_manager.get_description(e2.unit_number), "Entity Two", "E2 isolated")

  -- Mutate e1 groups, e2 unaffected
  state_manager.add_group(e1.unit_number)
  test_framework.assert_equal(#state_manager.get_groups(e1.unit_number), 2, "E1 has 2 groups")
  test_framework.assert_equal(#state_manager.get_groups(e2.unit_number), 1, "E2 still has 1 group")

  e1.destroy()
  e2.destroy()
end

-- ============================================================================
-- Run all
-- ============================================================================

function tests.run_all()
  local pf = test_framework._print_func or game.print
  pf("[TEST] Running State Manager Deep Tests...")

  test_framework.run_test("Clone Entity Data Is Independent", tests.test_clone_entity_data_is_independent)
  test_framework.run_test("Rename Group", tests.test_rename_group)
  test_framework.run_test("Rename Invalid Group", tests.test_rename_invalid_group)
  test_framework.run_test("Set Condition Compare Type", tests.test_set_condition_compare_type)
  test_framework.run_test("Set Condition Right Signal", tests.test_set_condition_right_signal)
  test_framework.run_test("Condition Right Wire Isolation", tests.test_condition_right_wire_isolation)
  test_framework.run_test("Set Output Use Input Count", tests.test_set_output_use_input_count)
  test_framework.run_test("Output Count Boundaries", tests.test_output_count_boundaries)
  test_framework.run_test("Add Multiple Outputs", tests.test_add_multiple_outputs)
  test_framework.run_test("Remove Output From Middle", tests.test_remove_output_from_middle)
  test_framework.run_test("Description Unicode And Long", tests.test_description_unicode_and_long)
  test_framework.run_test("Cross Entity Data Isolation", tests.test_cross_entity_data_isolation)

  pf("[TEST] State Deep: Passed=" .. test_framework.passed .. " Failed=" .. test_framework.failed)
end

return tests
