-- Integration tests for Switch Combinator
-- Tests state_manager API and entity placement

local test_framework = require("tests.test_framework")
local state_manager = require("scripts.logic.state_manager")

local tests = {}

-- Helper: create entity and init state (plus output entity)
local function create_test_entity(surface, position)
  local entities = {}

  local entity = surface.create_entity{
    name = "switch-combinator",
    position = position,
    force = "player"
  }
  if not entity then
    test_framework.assert_true(false, "Failed to create switch combinator")
    return nil, nil
  end
  entities[#entities + 1] = entity

  -- Init state
  state_manager.init_entity(entity.unit_number)

  -- Create matching output entity (on_built_entity may not fire in test context)
  local output = surface.create_entity{
    name = "switch-combinator-output",
    position = {x = position.x, y = position.y + 1},
    force = entity.force,
    create_build_effect_smoke = false
  }
  if not output then
    output = surface.create_entity{
      name = "switch-combinator-output",
      position = {x = position.x, y = position.y},
      force = entity.force,
      create_build_effect_smoke = false
    }
  end
  if output and output.valid then
    output.destructible = false
    output.operable = false
    output.minable = false
    if not storage.sc_entities then storage.sc_entities = {} end
    storage.sc_entities[entity.unit_number] = { entity = entity, output_entity = output }
    entities[#entities + 1] = output
  end

  return entity, entities
end

-- ============================================================================
-- Tests
-- ============================================================================

function tests.test_add_groups()
  local surface = game.surfaces[1]
  local entity, entities = create_test_entity(surface, {x = 0, y = 0})
  if not entity then return end

  -- init_entity already creates "Match 1"
  local g2 = state_manager.add_group(entity.unit_number)

  local groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 2, "Should have 2 groups")
  test_framework.assert_equal(groups[1].name, "Match 1", "First group name")
  test_framework.assert_equal(groups[2].name, "Match 2", "Second group name")

  for _, e in ipairs(entities) do if e.valid then e.destroy() end end
end

function tests.test_remove_group()
  local surface = game.surfaces[1]
  local entity, entities = create_test_entity(surface, {x = 5, y = 0})
  if not entity then return end

  -- init_entity already creates "Match 1"
  state_manager.add_group(entity.unit_number)
  state_manager.add_group(entity.unit_number)

  -- Now have: Match 1, Match 2, Match 3
  state_manager.remove_group(entity.unit_number, 2)
  local groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 2, "Should have 2 groups after removal")
  test_framework.assert_equal(groups[1].name, "Match 1", "First group unchanged")
  test_framework.assert_equal(groups[2].name, "Match 3", "Third group shifted to index 2")

  for _, e in ipairs(entities) do if e.valid then e.destroy() end end
end

function tests.test_conditions()
  local surface = game.surfaces[1]
  local entity, entities = create_test_entity(surface, {x = 10, y = 0})
  if not entity then return end

  local gi = 1
  state_manager.add_condition(entity.unit_number, gi)
  state_manager.add_condition(entity.unit_number, gi)

  local g = state_manager.get_group(entity.unit_number, gi)
  test_framework.assert_equal(#g.conditions, 3, "Should have 3 conditions")

  -- Set condition values (new two-operand model)
  state_manager.set_condition_left_signal(entity.unit_number, gi, 1, {type = "item", name = "iron-plate"})
  state_manager.set_condition_operator(entity.unit_number, gi, 1, ">=")
  state_manager.set_condition_constant(entity.unit_number, gi, 1, 100)

  g = state_manager.get_group(entity.unit_number, gi)
  test_framework.assert_equal(g.conditions[1].left_signal.name, "iron-plate", "Condition left signal name")
  test_framework.assert_equal(g.conditions[1].operator, ">=", "Condition operator")
  test_framework.assert_equal(g.conditions[1].constant, 100, "Condition constant")
  test_framework.assert_equal(g.conditions[1].compare_type, "constant", "Default compare type")

  -- Test signal compare type
  state_manager.set_condition_compare_type(entity.unit_number, gi, 1, "signal")
  state_manager.set_condition_right_signal(entity.unit_number, gi, 1, {type = "virtual", name = "signal-A"})
  g = state_manager.get_group(entity.unit_number, gi)
  test_framework.assert_equal(g.conditions[1].compare_type, "signal", "Compare type signal")
  test_framework.assert_equal(g.conditions[1].right_signal.name, "signal-A", "Right signal name")

  -- Test OR/AND logic
  test_framework.assert_equal(g.conditions[1].logic, nil, "First condition has no logic")
  test_framework.assert_equal(g.conditions[2].logic, "or", "Second condition defaults to or")
  state_manager.set_condition_logic(entity.unit_number, gi, 2, "and")
  g = state_manager.get_group(entity.unit_number, gi)
  test_framework.assert_equal(g.conditions[2].logic, "and", "Logic changed to and")

  -- Remove first condition
  state_manager.remove_condition(entity.unit_number, gi, 1)
  g = state_manager.get_group(entity.unit_number, gi)
  test_framework.assert_equal(#g.conditions, 2, "Should have 2 conditions after removal")
  test_framework.assert_equal(g.conditions[1].logic, nil, "New first condition has no logic")

  for _, e in ipairs(entities) do if e.valid then e.destroy() end end
end

function tests.test_outputs()
  local surface = game.surfaces[1]
  local entity, entities = create_test_entity(surface, {x = 15, y = 0})
  if not entity then return end

  -- Use the default group (index 1)
  local gi = 1
  state_manager.add_output(entity.unit_number, gi)
  state_manager.add_output(entity.unit_number, gi)

  local g = state_manager.get_group(entity.unit_number, gi)
  test_framework.assert_equal(#g.outputs, 3, "Should have 3 outputs")
  test_framework.assert_equal(g.outputs[1].count, 1, "Default count is 1")
  test_framework.assert_equal(g.outputs[1].use_input_count, false, "Default use_input_count is false")
  test_framework.assert_equal(g.outputs[1].red_wire, true, "Default red_wire is true")
  test_framework.assert_equal(g.outputs[1].green_wire, true, "Default green_wire is true")

  -- Set output values
  state_manager.set_output_signal(entity.unit_number, gi, 1, {type = "virtual", name = "signal-A"})
  state_manager.set_output_count(entity.unit_number, gi, 1, 5)
  state_manager.set_output_use_input_count(entity.unit_number, gi, 1, true)

  g = state_manager.get_group(entity.unit_number, gi)
  test_framework.assert_equal(g.outputs[1].signal.name, "signal-A", "Output signal name")
  test_framework.assert_equal(g.outputs[1].count, 5, "Output count")
  test_framework.assert_equal(g.outputs[1].use_input_count, true, "Output use_input_count")

  -- Remove output
  state_manager.remove_output(entity.unit_number, gi, 1)
  g = state_manager.get_group(entity.unit_number, gi)
  test_framework.assert_equal(#g.outputs, 2, "Should have 2 outputs after removal")

  for _, e in ipairs(entities) do if e.valid then e.destroy() end end
end

function tests.test_mode()
  local surface = game.surfaces[1]
  local entity, entities = create_test_entity(surface, {x = 20, y = 0})
  if not entity then return end

  test_framework.assert_equal(state_manager.get_mode(entity.unit_number), "first_match", "Default mode")

  state_manager.set_mode(entity.unit_number, "multi_match")
  test_framework.assert_equal(state_manager.get_mode(entity.unit_number), "multi_match", "Changed mode")

  for _, e in ipairs(entities) do if e.valid then e.destroy() end end
end

function tests.test_output_combinator_write()
  local surface = game.surfaces[1]
  local entity, entities = create_test_entity(surface, {x = 25, y = 0})
  if not entity then return end

  -- Find the output entity
  local output = surface.find_entity("switch-combinator-output", {entity.position.x, entity.position.y + 1})
    or surface.find_entity("switch-combinator-output", {entity.position.x, entity.position.y})
  test_framework.assert_not_nil(output, "Output entity should exist")

  -- Set up a condition and output
  state_manager.set_condition_left_signal(entity.unit_number, 1, 1, {type = "virtual", name = "signal-A"})
  state_manager.set_condition_operator(entity.unit_number, 1, 1, ">=")
  state_manager.set_condition_constant(entity.unit_number, 1, 1, 0)
  state_manager.set_output_signal(entity.unit_number, 1, 1, {type = "virtual", name = "signal-B"})
  state_manager.set_output_count(entity.unit_number, 1, 1, 7)

  -- Trigger evaluation manually by simulating the evaluate_entity path
  -- We can't easily inject signals without wiring, but we can verify the
  -- control behavior exists and is structurally sound.
  local cb = output.get_or_create_control_behavior()
  test_framework.assert_not_nil(cb, "Control behavior should exist")

  if cb.sections_count == 0 then cb.add_section() end
  local section = cb.get_section(1)
  test_framework.assert_not_nil(section, "Section should exist")

  -- Manually write a slot to verify the output entity accepts writes
  section.set_slot(1, {
    value = {type = "virtual", name = "signal-B"},
    min = 7
  })

  local slot = section.get_slot(1)
  test_framework.assert_not_nil(slot, "Slot should exist after write")
  test_framework.assert_equal(slot.value.name, "signal-B", "Slot signal name")
  test_framework.assert_equal(slot.min, 7, "Slot min value")

  for _, e in ipairs(entities) do if e.valid then e.destroy() end end
end

function tests.test_multi_match_mode_behavior()
  local surface = game.surfaces[1]
  local entity, entities = create_test_entity(surface, {x = 30, y = 0})
  if not entity then return end

  -- Set multi_match mode
  state_manager.set_mode(entity.unit_number, "multi_match")

  -- Add second group
  state_manager.add_group(entity.unit_number)

  -- Configure both groups with outputs
  state_manager.set_condition_left_signal(entity.unit_number, 1, 1, {type = "virtual", name = "signal-A"})
  state_manager.set_condition_operator(entity.unit_number, 1, 1, ">=")
  state_manager.set_condition_constant(entity.unit_number, 1, 1, 0)
  state_manager.set_output_signal(entity.unit_number, 1, 1, {type = "virtual", name = "signal-X"})
  state_manager.set_output_count(entity.unit_number, 1, 1, 1)

  state_manager.set_condition_left_signal(entity.unit_number, 2, 1, {type = "virtual", name = "signal-B"})
  state_manager.set_condition_operator(entity.unit_number, 2, 1, ">=")
  state_manager.set_condition_constant(entity.unit_number, 2, 1, 0)
  state_manager.set_output_signal(entity.unit_number, 2, 1, {type = "virtual", name = "signal-Y"})
  state_manager.set_output_count(entity.unit_number, 2, 1, 2)

  -- Verify both groups exist and have outputs
  local groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 2, "2 groups for multi_match test")
  test_framework.assert_equal(groups[1].outputs[1].signal.name, "signal-X", "G1 output signal")
  test_framework.assert_equal(groups[2].outputs[1].signal.name, "signal-Y", "G2 output signal")

  for _, e in ipairs(entities) do if e.valid then e.destroy() end end
end

function tests.test_condition_right_signal_and_compare_type()
  local surface = game.surfaces[1]
  local entity, entities = create_test_entity(surface, {x = 35, y = 0})
  if not entity then return end

  state_manager.set_condition_compare_type(entity.unit_number, 1, 1, "signal")
  state_manager.set_condition_right_signal(entity.unit_number, 1, 1, {type = "virtual", name = "signal-Z"})

  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.conditions[1].compare_type, "signal", "Compare type set to signal")
  test_framework.assert_equal(g.conditions[1].right_signal.name, "signal-Z", "Right signal set")

  state_manager.set_condition_compare_type(entity.unit_number, 1, 1, "constant")
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.conditions[1].compare_type, "constant", "Compare type back to constant")

  for _, e in ipairs(entities) do if e.valid then e.destroy() end end
end

function tests.test_output_use_input_count_and_wire()
  local surface = game.surfaces[1]
  local entity, entities = create_test_entity(surface, {x = 40, y = 0})
  if not entity then return end

  state_manager.set_output_use_input_count(entity.unit_number, 1, 1, true)
  state_manager.set_output_wire(entity.unit_number, 1, 1, "red", false)

  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_true(g.outputs[1].use_input_count, "use_input_count true")
  test_framework.assert_false(g.outputs[1].red_wire, "red_wire false")
  test_framework.assert_true(g.outputs[1].green_wire, "green_wire still true")

  for _, e in ipairs(entities) do if e.valid then e.destroy() end end
end

-- ============================================================================
-- Run all
-- ============================================================================

function tests.run_all()
  local pf = test_framework._print_func or game.print
  pf("[TEST] Running Integration Tests...")

  test_framework.run_test("Add Groups", tests.test_add_groups)
  test_framework.run_test("Remove Group", tests.test_remove_group)
  test_framework.run_test("Conditions", tests.test_conditions)
  test_framework.run_test("Outputs", tests.test_outputs)
  test_framework.run_test("Mode", tests.test_mode)
  test_framework.run_test("Output Combinator Write", tests.test_output_combinator_write)
  test_framework.run_test("Multi Match Mode Behavior", tests.test_multi_match_mode_behavior)
  test_framework.run_test("Condition Right Signal And Compare Type", tests.test_condition_right_signal_and_compare_type)
  test_framework.run_test("Output Use Input Count And Wire", tests.test_output_use_input_count_and_wire)

  pf("[TEST] Integration: Passed=" .. test_framework.passed .. " Failed=" .. test_framework.failed)
end

return tests
