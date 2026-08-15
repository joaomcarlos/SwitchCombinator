-- Switch Combinator Control
-- Evaluates conditions in Lua, writes outputs to hidden constant combinator

local GUI_PREFIX = "sc_"
local state_manager = require("scripts.logic.state_manager")
local signal_utils = require("scripts.utils.signal_utils")
local evaluation = require("scripts.logic.evaluation")

-- Load test runner at top level only in debug mode
local DEBUG_TESTS = false
local test_runner = nil
if DEBUG_TESTS then
  test_runner = require("tests.test_runner")
end

-- ============================================================================
-- Storage Initialization
-- ============================================================================

script.on_init(function()
  storage.entity_data = {}
  storage.gui_data = {}
  storage.sc_entities = {}
end)

local _sc_needs_rebuild = false

script.on_load(function()
  _sc_needs_rebuild = true
end)

-- Migration: rebuild sc_entities from existing placed entities
local function rebuild_entity_registry()
  if not storage.sc_entities then storage.sc_entities = {} end
  if not storage.entity_data then storage.entity_data = {} end
  if not storage.gui_data then storage.gui_data = {} end

  -- Clean up old hidden_combinators from previous architecture
  if storage.hidden_combinators then
    for _, combinators in pairs(storage.hidden_combinators) do
      if type(combinators) == "table" then
        for _, c in ipairs(combinators) do
          if c and c.valid then c.destroy() end
        end
      end
    end
    storage.hidden_combinators = nil
  end

  -- Re-scan all surfaces for switch-combinators
  for _, surface in pairs(game.surfaces) do
    for _, ent in pairs(surface.find_entities_filtered{name = "switch-combinator"}) do
      local un = ent.unit_number
      if not storage.sc_entities[un] then
        -- Find or create the output entity
        local output_entity = surface.find_entity("switch-combinator-output", {ent.position.x, ent.position.y + 1})
        if not output_entity then
          output_entity = surface.create_entity{
            name = "switch-combinator-output",
            position = {x = ent.position.x, y = ent.position.y + 1},
            force = ent.force,
            create_build_effect_smoke = false
          }
          -- Fallback: same position if y+1 blocked
          if not output_entity then
            output_entity = surface.create_entity{
              name = "switch-combinator-output",
              position = {x = ent.position.x, y = ent.position.y},
              force = ent.force,
              create_build_effect_smoke = false
            }
          end
          if output_entity then
            output_entity.destructible = false
            output_entity.operable = false
            output_entity.minable = false
          end
        end
        if output_entity and output_entity.valid then
          -- Ensure wiring
          local out_red = ent.get_wire_connector(defines.wire_connector_id.combinator_output_red, true)
          local cc_red = output_entity.get_wire_connector(defines.wire_connector_id.circuit_red, true)
          if out_red and cc_red then
            out_red.connect_to(cc_red, false, defines.wire_origin.script)
          end
          local out_green = ent.get_wire_connector(defines.wire_connector_id.combinator_output_green, true)
          local cc_green = output_entity.get_wire_connector(defines.wire_connector_id.circuit_green, true)
          if out_green and cc_green then
            out_green.connect_to(cc_green, false, defines.wire_origin.script)
          end

          storage.sc_entities[un] = { entity = ent, output_entity = output_entity }
        end
        -- Ensure entity data exists
        if not storage.entity_data[un] then
          state_manager.init_entity(un)
        end
      end
    end
  end
end

script.on_configuration_changed(function()
  rebuild_entity_registry()
end)

if DEBUG_TESTS then
  local test_framework = require("tests.test_framework")

  remote.add_interface("switch_combinator_tests", {
    run_tests = function(player_index, print_function)
      if test_runner and type(test_runner) == "table" and test_runner.run_all then
        test_framework._print_func = print_function
        test_runner.run_all()
        test_framework._print_func = nil
        return true
      else
        return false
      end
    end
  })
end

-- ============================================================================
-- Signal Reading Helpers
-- ============================================================================

local function read_input_signals(entity)
  if not entity or not entity.valid then return {} end
  local signals = {}
  local red_conn = entity.get_wire_connector(defines.wire_connector_id.combinator_input_red, true)
  if red_conn and red_conn.valid then
    local success, red_net = pcall(function() return red_conn.network end)
    if success and red_net and red_net.signals then
      for _, sig in pairs(red_net.signals) do
        local key = signal_utils.signal_key(sig.signal)
        if key then
          if not signals[key] then
            signals[key] = { signal = sig.signal, red = 0, green = 0 }
          end
          signals[key].red = sig.count
        end
      end
    end
  end
  local green_conn = entity.get_wire_connector(defines.wire_connector_id.combinator_input_green, true)
  if green_conn and green_conn.valid then
    local success, green_net = pcall(function() return green_conn.network end)
    if success and green_net and green_net.signals then
      for _, sig in pairs(green_net.signals) do
        local key = signal_utils.signal_key(sig.signal)
        if key then
          if not signals[key] then
            signals[key] = { signal = sig.signal, red = 0, green = 0 }
          end
          signals[key].green = sig.count
        end
      end
    end
  end
  return signals
end

-- ============================================================================
-- Evaluation: runs every few ticks, writes outputs to constant combinator
-- ============================================================================

local function evaluate_entity(un, entry)
  local entity = entry.entity
  local output_entity = entry.output_entity
  if not entity or not entity.valid then return end
  if not output_entity or not output_entity.valid then return end

  local entity_data = state_manager.get_entity_data(un)
  if not entity_data or not entity_data.groups then return end

  local input_signals = read_input_signals(entity)
  local mode = entity_data.mode or "first_match"

  local output_signals = {}

  for _, group in ipairs(entity_data.groups) do
    local group_met = evaluation.evaluate_conditions(group.conditions, input_signals)
    if group_met then
      for _, out in ipairs(group.outputs) do
        if out.signal and out.signal.name then
          local key = signal_utils.signal_key(out.signal)
          local count
          if out.use_input_count then
            count = evaluation.get_signal_value(input_signals, out.signal, out.red_wire ~= false, out.green_wire ~= false)
          else
            count = out.count or 1
          end
          if not output_signals[key] then
            output_signals[key] = { signal = out.signal, count = 0 }
          end
          output_signals[key].count = output_signals[key].count + count
        end
      end
      if mode == "first_match" then break end
    end
  end

  local cb = output_entity.get_or_create_control_behavior()
  if not cb then return end

  if cb.sections_count == 0 then cb.add_section() end
  local section = cb.get_section(1)
  if not section then return end

  for i = section.filters_count, 1, -1 do
    section.clear_slot(i)
  end

  -- Write new output signals
  local slot_idx = 1
  for _, entry_sig in pairs(output_signals) do
    if entry_sig.count ~= 0 then
      local slot_signal = {
        type = signal_utils.signal_type(entry_sig.signal),
        name = entry_sig.signal.name,
        quality = entry_sig.signal.quality or "normal"
      }
      section.set_slot(slot_idx, {
        value = slot_signal,
        min = entry_sig.count,
        max = entry_sig.count
      })
      slot_idx = slot_idx + 1
    end
  end
end

local function check_and_rebuild()
  if _sc_needs_rebuild then
    _sc_needs_rebuild = false
    rebuild_entity_registry()
  end
end

local function evaluate_all_entities()
  if not storage.sc_entities then return end
  for un, entry in pairs(storage.sc_entities) do
    if entry.entity and entry.entity.valid then
      evaluate_entity(un, entry)
    else
      -- Clean up invalid entries and destroy orphaned output entities
      if entry.output_entity and entry.output_entity.valid then
        entry.output_entity.destroy()
      end
      storage.sc_entities[un] = nil
      storage.entity_data[un] = nil
    end
  end
end

-- Evaluate every 6 ticks (~10 times per second)
script.on_nth_tick(6, function()
  check_and_rebuild()
  evaluate_all_entities()
end)

-- ============================================================================
-- Entity Events
-- ============================================================================

local function on_entity_built(event)
  local entity = event.created_entity or event.entity
  if not entity or not entity.valid then return end
  if entity.name ~= "switch-combinator" then return end

  state_manager.init_entity(entity.unit_number)

  -- Create hidden output constant combinator
  local output_pos = {x = entity.position.x, y = entity.position.y + 1}
  local output_entity = entity.surface.create_entity{
    name = "switch-combinator-output",
    position = output_pos,
    force = entity.force,
    create_build_effect_smoke = false
  }

  -- Fallback: try same position if y+1 is blocked (entity has no collision)
  if not output_entity then
    output_entity = entity.surface.create_entity{
      name = "switch-combinator-output",
      position = {x = entity.position.x, y = entity.position.y},
      force = entity.force,
      create_build_effect_smoke = false
    }
  end

  if output_entity and output_entity.valid then
    output_entity.destructible = false
    output_entity.operable = false
    output_entity.minable = false

    -- Wire the output combinator to the visible entity's output connectors
    -- so signals from the constant combinator appear on the switch-combinator's output wires
    local out_red = entity.get_wire_connector(defines.wire_connector_id.combinator_output_red, true)
    local cc_red = output_entity.get_wire_connector(defines.wire_connector_id.circuit_red, true)
    if out_red and cc_red then
      out_red.connect_to(cc_red, false, defines.wire_origin.script)
    end
    local out_green = entity.get_wire_connector(defines.wire_connector_id.combinator_output_green, true)
    local cc_green = output_entity.get_wire_connector(defines.wire_connector_id.circuit_green, true)
    if out_green and cc_green then
      out_green.connect_to(cc_green, false, defines.wire_origin.script)
    end
  end

  -- Register for fast lookup
  if not storage.sc_entities then storage.sc_entities = {} end
  storage.sc_entities[entity.unit_number] = {
    entity = entity,
    output_entity = output_entity
  }
end

local function on_entity_removed(event)
  local entity = event.entity
  if not entity or not entity.valid then return end
  if entity.name ~= "switch-combinator" then return end

  local un = entity.unit_number

  -- Destroy hidden output combinator
  if storage.sc_entities and storage.sc_entities[un] then
    local entry = storage.sc_entities[un]
    if entry.output_entity and entry.output_entity.valid then
      entry.output_entity.destroy()
    end
    storage.sc_entities[un] = nil
  end

  storage.entity_data[un] = nil
end

script.on_event(defines.events.on_built_entity, on_entity_built)
script.on_event(defines.events.on_robot_built_entity, on_entity_built)

script.on_event(defines.events.on_entity_cloned, function(event)
  local source = event.source
  local destination = event.destination

  if source.name == "switch-combinator" and destination.name == "switch-combinator" then
    -- Treat clone as a new build for output entity creation first,
    -- then overwrite the blank data with the copied config
    on_entity_built({created_entity = destination})

    -- Clone configuration without sharing nested condition/output tables.
    local src_data = storage.entity_data[source.unit_number]
    if src_data then
      storage.entity_data[destination.unit_number] = state_manager.clone_entity_data(src_data)
    end
  end
end)

script.on_event(defines.events.on_entity_died, on_entity_removed)
script.on_event(defines.events.on_player_mined_entity, on_entity_removed)
script.on_event(defines.events.on_robot_mined_entity, on_entity_removed)

-- ============================================================================
-- GUI Event Handlers
-- ============================================================================

local gui_main = require("scripts.gui.main")
gui_main.set_tests_enabled(DEBUG_TESTS)

script.on_event(defines.events.on_gui_opened, function(event)
  local entity = event.entity
  if not entity or not entity.valid or entity.name ~= "switch-combinator" then return end

  local player = game.players[event.player_index]
  if not player then return end

  gui_main.open(player, entity, storage)

  local our_frame = player.gui.screen[GUI_PREFIX .. "main_frame"]
  if our_frame then
    player.opened = our_frame
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local player = game.players[event.player_index]
  if not player or not player.valid then return end

  local element = event.element
  if element and element.valid and element.name == GUI_PREFIX .. "main_frame" then
    gui_main.close(player, storage)
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not element or not element.valid then return end

  local player = game.players[event.player_index]
  gui_main.on_click(player, element, storage)
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
  local element = event.element
  if not element or not element.valid then return end

  local player = game.players[event.player_index]
  gui_main.on_text_changed(player, element, storage)
end)

script.on_event(defines.events.on_gui_elem_changed, function(event)
  local element = event.element
  if not element or not element.valid then return end

  local player = game.players[event.player_index]
  gui_main.on_elem_changed(player, element, storage)
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
  local element = event.element
  if not element or not element.valid then return end

  local player = game.players[event.player_index]
  gui_main.on_selection_changed(player, element, storage)
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(event)
  local element = event.element
  if not element or not element.valid then return end

  local player = game.players[event.player_index]
  gui_main.on_checked_changed(player, element, storage)
end)
