-- UI Integration Tests for Switch Combinator
-- Exercises all GUI buttons and verifies state changes through the UI

local test_framework = require("tests.test_framework")
local state_manager = require("scripts.logic.state_manager")
local gui_main = require("scripts.gui.main")

local tests = {}

-- Helper: simulate clicking a named button
local function click(player, button_name)
  local element = nil
  -- Search all screen elements recursively
  local function find(el)
    if element then return end
    if el.name == button_name then
      element = el
      return
    end
    if el.children then
      for _, child in pairs(el.children) do
        find(child)
      end
    end
  end
  find(player.gui.screen)
  if not element then
    error("UI test: button '" .. button_name .. "' not found")
  end
  gui_main.on_click(player, element, storage)
end

-- Helper: simulate changing a dropdown
local function set_dropdown(player, dropdown_name, index)
  local element = nil
  local function find(el)
    if element then return end
    if el.name == dropdown_name then element = el; return end
    if el.children then
      for _, child in pairs(el.children) do find(child) end
    end
  end
  find(player.gui.screen)
  if not element then error("UI test: dropdown '" .. dropdown_name .. "' not found") end
  element.selected_index = index
  gui_main.on_selection_changed(player, element, storage)
end

-- Helper: simulate changing a textfield
local function set_text(player, field_name, text)
  local element = nil
  local function find(el)
    if element then return end
    if el.name == field_name then element = el; return end
    if el.children then
      for _, child in pairs(el.children) do find(child) end
    end
  end
  find(player.gui.screen)
  if not element then error("UI test: textfield '" .. field_name .. "' not found") end
  element.text = text
  gui_main.on_text_changed(player, element, storage)
end

-- Helper: simulate choosing a signal
local function set_signal(player, elem_name, signal)
  local element = nil
  local function find(el)
    if element then return end
    if el.name == elem_name then element = el; return end
    if el.children then
      for _, child in pairs(el.children) do find(child) end
    end
  end
  find(player.gui.screen)
  if not element then error("UI test: choose-elem '" .. elem_name .. "' not found") end
  element.elem_value = signal
  gui_main.on_elem_changed(player, element, storage)
end

-- Helper: simulate toggling a checkbox
local function set_checkbox(player, checkbox_name, state)
  local element = nil
  local function find(el)
    if element then return end
    if el.name == checkbox_name then element = el; return end
    if el.children then
      for _, child in pairs(el.children) do find(child) end
    end
  end
  find(player.gui.screen)
  if not element then error("UI test: checkbox '" .. checkbox_name .. "' not found") end
  element.state = state
  gui_main.on_checked_changed(player, element, storage)
end

-- Helper: check if a named element exists in the GUI
local function element_exists(player, name)
  local found = false
  local function find(el)
    if found then return end
    if el.name == name then found = true; return end
    if el.children then
      for _, child in pairs(el.children) do find(child) end
    end
  end
  find(player.gui.screen)
  return found
end

-- ============================================================================
-- Tests
-- ============================================================================

function tests.test_open_close()
  local player = game.players[1]
  local surface = game.surfaces[1]

  local entity = surface.create_entity{
    name = "switch-combinator",
    position = {x = -20, y = -20},
    force = "player"
  }
  state_manager.init_entity(entity.unit_number)

  -- Open GUI
  gui_main.open(player, entity, storage)
  test_framework.assert_true(
    player.gui.screen["sc_main_frame"] ~= nil,
    "Main frame should exist after open"
  )

  -- Close via button
  click(player, "sc_close")
  test_framework.assert_true(
    player.gui.screen["sc_main_frame"] == nil,
    "Main frame should be gone after close"
  )

  entity.destroy()
end

function tests.test_default_group_exists()
  local player = game.players[1]
  local surface = game.surfaces[1]

  local entity = surface.create_entity{
    name = "switch-combinator",
    position = {x = -20, y = -15},
    force = "player"
  }
  state_manager.init_entity(entity.unit_number)

  local groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 1, "Should start with 1 default group")
  test_framework.assert_equal(groups[1].name, "Match 1", "Default group name")

  -- Open and verify GUI shows the group
  gui_main.open(player, entity, storage)
  test_framework.assert_true(
    element_exists(player, "sc_add_cond_1"),
    "Add condition button for group 1 should exist"
  )
  test_framework.assert_true(
    element_exists(player, "sc_add_out_1"),
    "Add output button for group 1 should exist"
  )

  gui_main.close(player, storage)
  entity.destroy()
end

function tests.test_add_remove_groups()
  local player = game.players[1]
  local surface = game.surfaces[1]

  local entity = surface.create_entity{
    name = "switch-combinator",
    position = {x = -20, y = -10},
    force = "player"
  }
  state_manager.init_entity(entity.unit_number)
  gui_main.open(player, entity, storage)

  -- Should start with 1 group
  local groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 1, "Start with 1 group")

  -- Add a second group via UI
  click(player, "sc_add_group")
  groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 2, "Should have 2 groups after add")
  test_framework.assert_equal(groups[2].name, "Match 2", "Second group name")

  -- Add a third group
  click(player, "sc_add_group")
  groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 3, "Should have 3 groups after second add")

  -- Delete group 2
  click(player, "sc_del_group_2")
  groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 2, "Should have 2 groups after delete")

  gui_main.close(player, storage)
  entity.destroy()
end

function tests.test_add_remove_conditions()
  local player = game.players[1]
  local surface = game.surfaces[1]

  local entity = surface.create_entity{
    name = "switch-combinator",
    position = {x = -20, y = -5},
    force = "player"
  }
  state_manager.init_entity(entity.unit_number)
  gui_main.open(player, entity, storage)

  -- Add condition to group 1
  click(player, "sc_add_cond_1")
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.conditions, 2, "Should have 2 conditions")

  -- Set left signal on condition (new element name: sc_cond_lsig_)
  set_signal(player, "sc_cond_lsig_1_1", {type = "virtual", name = "signal-A"})
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.conditions[1].left_signal.name, "signal-A", "Condition left signal set")

  -- Set operator
  set_dropdown(player, "sc_cond_op_1_1", 3) -- "="
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.conditions[1].operator, "=", "Condition operator set")

  -- Set constant value (default is already constant)
  set_text(player, "sc_cond_const_1_1", "42")
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.conditions[1].constant, 42, "Condition constant set")

  -- Add second condition
  click(player, "sc_add_cond_1")
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.conditions, 3, "Should have 3 conditions")

  -- Delete first condition
  click(player, "sc_del_cond_1_1")
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.conditions, 2, "Should have 2 conditions after delete")

  gui_main.close(player, storage)
  entity.destroy()
end

function tests.test_add_remove_outputs()
  local player = game.players[1]
  local surface = game.surfaces[1]

  local entity = surface.create_entity{
    name = "switch-combinator",
    position = {x = -20, y = 0},
    force = "player"
  }
  state_manager.init_entity(entity.unit_number)
  gui_main.open(player, entity, storage)

  -- Add output to group 1
  click(player, "sc_add_out_1")
  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.outputs, 2, "Should have 2 outputs")
  test_framework.assert_equal(g.outputs[1].use_input_count, false, "Default use_input_count false")

  -- Set output signal
  set_signal(player, "sc_out_sig_1_1", {type = "virtual", name = "signal-B"})
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.outputs[1].signal.name, "signal-B", "Output signal set")

  -- Set output count
  set_text(player, "sc_out_count_1_1", "5")
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.outputs[1].count, 5, "Output count set")

  -- Set input count via radiobutton
  set_checkbox(player, "sc_out_radio_input_1_1", true)
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.outputs[1].use_input_count, true, "Output use_input_count set")

  -- Switch back to fixed count via radiobutton
  set_checkbox(player, "sc_out_radio_count_1_1", true)
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(g.outputs[1].use_input_count, false, "Output use_input_count unset")

  -- Add second output and delete first
  click(player, "sc_add_out_1")
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.outputs, 3, "Should have 3 outputs")

  click(player, "sc_del_out_1_1")
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.outputs, 2, "Should have 2 outputs after delete")

  gui_main.close(player, storage)
  entity.destroy()
end

function tests.test_mode_switch()
  local player = game.players[1]
  local surface = game.surfaces[1]

  local entity = surface.create_entity{
    name = "switch-combinator",
    position = {x = -20, y = 5},
    force = "player"
  }
  state_manager.init_entity(entity.unit_number)
  gui_main.open(player, entity, storage)

  -- Default mode
  test_framework.assert_equal(state_manager.get_mode(entity.unit_number), "first_match", "Default mode")

  -- Switch to multi_match using radio button
  set_checkbox(player, "sc_mode_multi", true)
  test_framework.assert_equal(state_manager.get_mode(entity.unit_number), "multi_match", "Mode changed to multi_match")

  -- Switch back using radio button
  set_checkbox(player, "sc_mode_first", true)
  test_framework.assert_equal(state_manager.get_mode(entity.unit_number), "first_match", "Mode changed back")

  gui_main.close(player, storage)
  entity.destroy()
end

function tests.test_full_workflow()
  local player = game.players[1]
  local surface = game.surfaces[1]

  local entity = surface.create_entity{
    name = "switch-combinator",
    position = {x = -20, y = 10},
    force = "player"
  }
  state_manager.init_entity(entity.unit_number)
  gui_main.open(player, entity, storage)

  -- Configure group 1: iron-plate > 100 → signal-A count 1
  set_signal(player, "sc_cond_lsig_1_1", {type = "item", name = "iron-plate"})
  set_dropdown(player, "sc_cond_op_1_1", 1) -- ">"
  set_text(player, "sc_cond_const_1_1", "100")

  set_signal(player, "sc_out_sig_1_1", {type = "virtual", name = "signal-A"})
  set_text(player, "sc_out_count_1_1", "1")

  -- Add group 2: copper-plate >= 50 → signal-B count 3
  click(player, "sc_add_group")
  set_signal(player, "sc_cond_lsig_2_1", {type = "item", name = "copper-plate"})
  set_dropdown(player, "sc_cond_op_2_1", 4) -- ">="
  set_text(player, "sc_cond_const_2_1", "50")

  set_signal(player, "sc_out_sig_2_1", {type = "virtual", name = "signal-B"})
  set_text(player, "sc_out_count_2_1", "3")

  -- Verify stored data
  local groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 2, "Should have 2 groups")

  test_framework.assert_equal(groups[1].conditions[1].left_signal.name, "iron-plate", "G1 cond signal")
  test_framework.assert_equal(groups[1].conditions[1].operator, ">", "G1 cond operator")
  test_framework.assert_equal(groups[1].conditions[1].compare_type, "constant", "G1 cond compare type")
  test_framework.assert_equal(groups[1].conditions[1].constant, 100, "G1 cond constant")
  test_framework.assert_equal(groups[1].outputs[1].signal.name, "signal-A", "G1 out signal")
  test_framework.assert_equal(groups[1].outputs[1].count, 1, "G1 out count")

  test_framework.assert_equal(groups[2].conditions[1].left_signal.name, "copper-plate", "G2 cond signal")
  test_framework.assert_equal(groups[2].conditions[1].operator, ">=", "G2 cond operator")
  test_framework.assert_equal(groups[2].conditions[1].compare_type, "constant", "G2 cond compare type")
  test_framework.assert_equal(groups[2].conditions[1].constant, 50, "G2 cond constant")
  test_framework.assert_equal(groups[2].outputs[1].signal.name, "signal-B", "G2 out signal")
  test_framework.assert_equal(groups[2].outputs[1].count, 3, "G2 out count")

  -- Switch mode to multi_match and back
  set_checkbox(player, "sc_mode_multi", true)
  test_framework.assert_equal(state_manager.get_mode(entity.unit_number), "multi_match", "Mode multi_match")
  set_checkbox(player, "sc_mode_first", true)

  -- Delete group 1, verify group 2 becomes group 1
  click(player, "sc_del_group_1")
  groups = state_manager.get_groups(entity.unit_number)
  test_framework.assert_equal(#groups, 1, "1 group after delete")
  test_framework.assert_equal(groups[1].conditions[1].left_signal.name, "copper-plate", "Remaining group has copper condition")

  gui_main.close(player, storage)
  entity.destroy()
end

function tests.test_multiple_conditions_per_group()
  local player = game.players[1]
  local surface = game.surfaces[1]

  local entity = surface.create_entity{
    name = "switch-combinator",
    position = {x = -20, y = 15},
    force = "player"
  }
  state_manager.init_entity(entity.unit_number)
  gui_main.open(player, entity, storage)

  -- Add 2 conditions to group 1 (1 exists by default)
  click(player, "sc_add_cond_1")
  click(player, "sc_add_cond_1")

  set_signal(player, "sc_cond_lsig_1_1", {type = "item", name = "iron-plate"})
  set_dropdown(player, "sc_cond_op_1_1", 1) -- ">"
  set_text(player, "sc_cond_const_1_1", "0")

  set_signal(player, "sc_cond_lsig_1_2", {type = "item", name = "copper-plate"})
  set_dropdown(player, "sc_cond_op_1_2", 1) -- ">"
  set_text(player, "sc_cond_const_1_2", "0")

  set_signal(player, "sc_cond_lsig_1_3", {type = "virtual", name = "signal-A"})
  set_dropdown(player, "sc_cond_op_1_3", 3) -- "="
  set_text(player, "sc_cond_const_1_3", "1")

  local g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.conditions, 3, "Should have 3 conditions")
  test_framework.assert_equal(g.conditions[1].left_signal.name, "iron-plate", "Cond 1")
  test_framework.assert_equal(g.conditions[2].left_signal.name, "copper-plate", "Cond 2")
  test_framework.assert_equal(g.conditions[3].left_signal.name, "signal-A", "Cond 3")
  test_framework.assert_equal(g.conditions[3].operator, "=", "Cond 3 operator")
  test_framework.assert_equal(g.conditions[3].constant, 1, "Cond 3 constant")

  -- Verify OR/AND logic defaults
  test_framework.assert_equal(g.conditions[1].logic, nil, "First cond has no logic")
  test_framework.assert_equal(g.conditions[2].logic, "or", "Second cond defaults to or")
  test_framework.assert_equal(g.conditions[3].logic, "or", "Third cond defaults to or")

  -- Delete middle condition
  click(player, "sc_del_cond_1_2")
  g = state_manager.get_group(entity.unit_number, 1)
  test_framework.assert_equal(#g.conditions, 2, "2 conditions after delete")
  test_framework.assert_equal(g.conditions[1].left_signal.name, "iron-plate", "First still iron")
  test_framework.assert_equal(g.conditions[2].left_signal.name, "signal-A", "Second now signal-A")

  gui_main.close(player, storage)
  entity.destroy()
end

-- ============================================================================
-- Run all
-- ============================================================================

function tests.run_all()
  local pf = test_framework._print_func or game.print
  pf("[TEST] Running UI Integration Tests...")

  test_framework.run_test("Open/Close GUI", tests.test_open_close)
  test_framework.run_test("Default Group Exists", tests.test_default_group_exists)
  test_framework.run_test("Add/Remove Groups", tests.test_add_remove_groups)
  test_framework.run_test("Add/Remove Conditions", tests.test_add_remove_conditions)
  test_framework.run_test("Add/Remove Outputs", tests.test_add_remove_outputs)
  test_framework.run_test("Mode Switch", tests.test_mode_switch)
  test_framework.run_test("Full Workflow", tests.test_full_workflow)
  test_framework.run_test("Multiple Conditions Per Group", tests.test_multiple_conditions_per_group)

  pf("[TEST] UI Tests: Passed=" .. test_framework.passed .. " Failed=" .. test_framework.failed)
end

return tests
