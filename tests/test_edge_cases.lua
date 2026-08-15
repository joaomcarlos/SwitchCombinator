-- Edge-case tests for Switch Combinator
-- Covers nil signals, empty structures, boundary values, and mode behavior.

local test_framework = require("tests.test_framework")
local state_manager = require("scripts.logic.state_manager")
local signal_utils = require("scripts.utils.signal_utils")

local tests = {}

-- ============================================================================
-- Helpers
-- ============================================================================

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

local function make_cond(left_sig, op, compare_type, const, right_sig, logic)
  return {
    left_signal = left_sig,
    operator = op or ">",
    compare_type = compare_type or "constant",
    constant = const or 0,
    right_signal = right_sig,
    left_red = true, left_green = true,
    right_red = true, right_green = true,
    logic = logic
  }
end

-- ============================================================================
-- Signal utility edge cases
-- ============================================================================

function tests.test_signal_key_edge_cases()
  test_framework.assert_nil(signal_utils.signal_key(nil), "Nil signal key")
  test_framework.assert_nil(signal_utils.signal_key({}), "Empty signal key")
  test_framework.assert_equal(signal_utils.signal_key({name = "foo"}), "item/foo", "Missing type defaults to item")
  test_framework.assert_nil(signal_utils.signal_key({type = "item"}), "Missing name")

  -- Valid signal
  local key = signal_utils.signal_key({type = "virtual", name = "signal-A"})
  test_framework.assert_equal(key, "virtual/signal-A", "Valid signal key")
end

function tests.test_signals_equal_edge_cases()
  test_framework.assert_false(signal_utils.signals_equal(nil, {type = "item", name = "a"}), "nil vs valid")
  test_framework.assert_false(signal_utils.signals_equal({type = "item", name = "a"}, nil), "valid vs nil")
  test_framework.assert_false(
    signal_utils.signals_equal({type = "item", name = "a"}, {type = "item", name = "b"}),
    "Same type different name"
  )
  test_framework.assert_false(
    signal_utils.signals_equal({type = "item", name = "a"}, {type = "fluid", name = "a"}),
    "Same name different type"
  )
end

-- ============================================================================
-- State manager edge cases
-- ============================================================================

function tests.test_empty_group_evaluation()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 200, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  -- Default group has 1 condition and 1 output
  local groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 1, "Default group exists")
  test_framework.assert_equal(#groups[1].conditions, 1, "Default 1 condition")
  test_framework.assert_equal(#groups[1].outputs, 1, "Default 1 output")

  -- Condition has no left_signal → evaluating it returns false
  test_framework.assert_nil(groups[1].conditions[1].left_signal, "Default left_signal is nil")

  entity.destroy()
end

function tests.test_remove_all_conditions()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 201, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  -- Remove the default condition
  state_manager.remove_condition(entity.unit_number, 1, 1)
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.conditions, 0, "All conditions removed")

  entity.destroy()
end

function tests.test_remove_all_outputs()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 202, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  -- Remove the default output
  state_manager.remove_output(entity.unit_number, 1, 1)
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.outputs, 0, "All outputs removed")

  entity.destroy()
end

function tests.test_add_remove_group_boundary()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 203, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  -- Remove the only group
  state_manager.remove_group(entity.unit_number, 1)
  local groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 0, "All groups removed")

  -- Add a group back
  state_manager.add_group(entity.unit_number)
  groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 1, "Group added back")
  test_framework.assert_equal(groups[1].name, "Match 1", "New group named Match 1")

  entity.destroy()
end

function tests.test_invalid_group_access()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 204, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  local g = state_manager.get_group(entity.unit_number, 99)
  test_framework.assert_nil(g, "Invalid group index returns nil")

  entity.destroy()
end

function tests.test_condition_operator_boundary()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 205, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  -- Test all operators with 0 values
  state_manager.set_condition_left_signal(entity.unit_number, 1, 1, {type = "virtual", name = "signal-A"})
  state_manager.set_condition_constant(entity.unit_number, 1, 1, 0)

  state_manager.set_condition_operator(entity.unit_number, 1, 1, "=")
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.conditions[1].operator, "=", "Operator set to =")

  state_manager.set_condition_operator(entity.unit_number, 1, 1, "!=")
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.conditions[1].operator, "!=", "Operator set to !=")

  entity.destroy()
end

function tests.test_output_signal_incomplete()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 206, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  -- Set output signal missing type (simulates bad GUI state)
  state_manager.set_output_signal(entity.unit_number, 1, 1, {name = "signal-A"})
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_not_nil(g.outputs[1].signal, "Signal object exists")
  test_framework.assert_nil(g.outputs[1].signal.type, "Signal type is nil")
  test_framework.assert_equal(g.outputs[1].signal.name, "signal-A", "Signal name preserved")

  entity.destroy()
end

function tests.test_mode_switch_boundary()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 207, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  -- Default
  test_framework.assert_equal(state_manager.get_mode(entity.unit_number), "first_match", "Default mode")

  -- Switch to multi
  state_manager.set_mode(entity.unit_number, "multi_match")
  test_framework.assert_equal(state_manager.get_mode(entity.unit_number), "multi_match", "Mode multi")

  -- Switch back
  state_manager.set_mode(entity.unit_number, "first_match")
  test_framework.assert_equal(state_manager.get_mode(entity.unit_number), "first_match", "Mode first")

  -- Invalid mode (should store anyway, but return something)
  state_manager.set_mode(entity.unit_number, "bogus_mode")
  test_framework.assert_equal(state_manager.get_mode(entity.unit_number), "bogus_mode", "Invalid mode stored")

  -- Reset to valid
  state_manager.set_mode(entity.unit_number, "first_match")
  test_framework.assert_equal(state_manager.get_mode(entity.unit_number), "first_match", "Mode reset")

  entity.destroy()
end

function tests.test_wire_filter_isolation()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 208, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  -- Default: both wires true
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_true(g.conditions[1].left_red, "Default left_red true")
  test_framework.assert_true(g.conditions[1].left_green, "Default left_green true")
  test_framework.assert_true(g.outputs[1].red_wire, "Default red_wire true")
  test_framework.assert_true(g.outputs[1].green_wire, "Default green_wire true")

  -- Toggle wires (left side for conditions)
  state_manager.set_condition_wire(entity.unit_number, 1, 1, "left", "red", false)
  state_manager.set_condition_wire(entity.unit_number, 1, 1, "left", "green", false)
  state_manager.set_output_wire(entity.unit_number, 1, 1, "red", false)
  state_manager.set_output_wire(entity.unit_number, 1, 1, "green", false)

  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_false(g.conditions[1].left_red, "left_red false")
  test_framework.assert_false(g.conditions[1].left_green, "left_green false")
  test_framework.assert_false(g.outputs[1].red_wire, "red_wire false")
  test_framework.assert_false(g.outputs[1].green_wire, "green_wire false")

  entity.destroy()
end

-- ============================================================================
-- Condition logic edge cases
-- ============================================================================

function tests.test_condition_logic_chaining()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 209, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  -- Add multiple conditions and verify logic chain
  state_manager.add_condition(entity.unit_number, 1)
  state_manager.add_condition(entity.unit_number, 1)
  state_manager.add_condition(entity.unit_number, 1)

  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.conditions, 4, "4 conditions")
  test_framework.assert_nil(g.conditions[1].logic, "First has no logic")
  test_framework.assert_equal(g.conditions[2].logic, "or", "Second defaults to or")
  test_framework.assert_equal(g.conditions[3].logic, "or", "Third defaults to or")
  test_framework.assert_equal(g.conditions[4].logic, "or", "Fourth defaults to or")

  -- Change to AND
  state_manager.set_condition_logic(entity.unit_number, 1, 2, "and")
  state_manager.set_condition_logic(entity.unit_number, 1, 3, "and")
  state_manager.set_condition_logic(entity.unit_number, 1, 4, "and")

  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.conditions[2].logic, "and", "Logic changed to and")
  test_framework.assert_equal(g.conditions[3].logic, "and", "Logic changed to and")
  test_framework.assert_equal(g.conditions[4].logic, "and", "Logic changed to and")

  entity.destroy()
end

function tests.test_empty_description()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 210, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  local data = state_manager.get_entity_data(entity.unit_number)
  test_framework.assert_equal(data.description, "", "Default empty description")

  state_manager.set_description(entity.unit_number, "Test desc")
  data = state_manager.get_entity_data(entity.unit_number)
  test_framework.assert_equal(data.description, "Test desc", "Description set")

  state_manager.set_description(entity.unit_number, "")
  data = state_manager.get_entity_data(entity.unit_number)
  test_framework.assert_equal(data.description, "", "Description cleared")

  entity.destroy()
end

function tests.test_nil_entity_data_graceful()
  -- Accessing functions before init_entity should not crash
  local mode = state_manager.get_mode(999999)
  test_framework.assert_equal(mode, "first_match", "Missing entity returns default mode")

  local groups = state_manager.get_groups(999999)
  test_framework.assert_equal(#groups, 0, "Missing entity returns empty groups")

  local g = state_manager.get_group(999999, 1)
  test_framework.assert_nil(g, "Missing entity returns nil group")
end

function tests.test_add_group_preserves_existing()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 211, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  -- Configure group 1
  state_manager.set_condition_constant(entity.unit_number, 1, 1, 42)

  -- Add group 2
  state_manager.add_group(entity.unit_number)

  -- Group 1 should still have its config
  local g1 = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g1.conditions[1].constant, 42, "Group 1 preserved after add")

  -- Group 2 should be fresh
  local g2 = state_manager.get_group(entity.unit_number, 2)
  test_framework.assert_equal(g2.conditions[1].constant, 0, "Group 2 is fresh")

  entity.destroy()
end

function tests.test_remove_last_then_add_condition()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 212, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  -- Remove all conditions
  state_manager.remove_condition(entity.unit_number, 1, 1)
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.conditions, 0, "All conditions removed")

  -- Add a new one
  state_manager.add_condition(entity.unit_number, 1)
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.conditions, 1, "1 condition added back")
  test_framework.assert_nil(g.conditions[1].logic, "New first condition has nil logic")

  entity.destroy()
end

function tests.test_constant_boundary_values()
  local surface = game.surfaces[1]
  local entity = create_test_entity(surface, {x = 213, y = 0})
  test_framework.assert_not_nil(entity, "Entity created")

  state_manager.set_condition_constant(entity.unit_number, 1, 1, -2147483648)
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.conditions[1].constant, -2147483648, "Min int constant")

  state_manager.set_condition_constant(entity.unit_number, 1, 1, 2147483647)
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.conditions[1].constant, 2147483647, "Max int constant")

  entity.destroy()
end

-- ============================================================================
-- Run all
-- ============================================================================

function tests.run_all()
  local pf = test_framework._print_func or game.print
  pf("[TEST] Running Edge Case Tests...")

  test_framework.run_test("Signal Key Edge Cases", tests.test_signal_key_edge_cases)
  test_framework.run_test("Signals Equal Edge Cases", tests.test_signals_equal_edge_cases)
  test_framework.run_test("Empty Group Evaluation", tests.test_empty_group_evaluation)
  test_framework.run_test("Remove All Conditions", tests.test_remove_all_conditions)
  test_framework.run_test("Remove All Outputs", tests.test_remove_all_outputs)
  test_framework.run_test("Add/Remove Group Boundary", tests.test_add_remove_group_boundary)
  test_framework.run_test("Invalid Group Access", tests.test_invalid_group_access)
  test_framework.run_test("Condition Operator Boundary", tests.test_condition_operator_boundary)
  test_framework.run_test("Output Signal Incomplete", tests.test_output_signal_incomplete)
  test_framework.run_test("Mode Switch Boundary", tests.test_mode_switch_boundary)
  test_framework.run_test("Wire Filter Isolation", tests.test_wire_filter_isolation)
  test_framework.run_test("Condition Logic Chaining", tests.test_condition_logic_chaining)
  test_framework.run_test("Empty Description", tests.test_empty_description)
  test_framework.run_test("Nil Entity Data Graceful", tests.test_nil_entity_data_graceful)
  test_framework.run_test("Add Group Preserves Existing", tests.test_add_group_preserves_existing)
  test_framework.run_test("Remove Last Then Add Condition", tests.test_remove_last_then_add_condition)
  test_framework.run_test("Constant Boundary Values", tests.test_constant_boundary_values)

  pf("[TEST] Edge Cases: Passed=" .. test_framework.passed .. " Failed=" .. test_framework.failed)
end

return tests
