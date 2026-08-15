-- Native Factorio-style GUI for Switch Combinator.

local GUI_PREFIX = "sc_"
local state_manager = require("scripts.logic.state_manager")
local signal_utils = require("scripts.utils.signal_utils")
local evaluation = require("scripts.logic.evaluation")

local gui_main = {}
local tests_enabled = false

local OPERATORS = {">", "<", "=", ">=", "<=", "!="}
local WORKING_CAPTION = "[img=utility/status_working] Working"
local IDLE_CAPTION = "[img=utility/status_not_working] Idle"

-- ============================================================================
-- Shared helpers
-- ============================================================================

local function ps(player_index)
  if not storage.gui_data then storage.gui_data = {} end
  if not storage.gui_data[player_index] then storage.gui_data[player_index] = {} end
  return storage.gui_data[player_index]
end

local function find_element(root, name)
  if not root or not root.valid then return nil end
  if root.name == name then return root end
  if not root.children then return nil end

  for _, child in pairs(root.children) do
    local found = find_element(child, name)
    if found then return found end
  end

  return nil
end

local function get_entity(unit_number)
  if not unit_number then return nil end

  if storage.sc_entities and storage.sc_entities[unit_number] then
    local entity = storage.sc_entities[unit_number].entity
    if entity and entity.valid then return entity end
  end

  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{name = "switch-combinator"}) do
      if entity.unit_number == unit_number then return entity end
    end
  end

  return nil
end

local function get_network(entity, wire_connector_id, legacy_wire_type, legacy_connector_id)
  if not entity or not entity.valid then return nil end

  local connector = entity.get_wire_connector(wire_connector_id, true)
  if connector then
    local ok, network = pcall(function() return connector.network end)
    if ok and network then return network end
  end

  if entity.get_circuit_network and legacy_wire_type and legacy_connector_id then
    local ok, network = pcall(function()
      return entity.get_circuit_network(legacy_wire_type, legacy_connector_id)
    end)
    if ok and network then return network end
  end

  return nil
end

local function get_network_ids(entity)
  local red_network = get_network(
    entity,
    defines.wire_connector_id.combinator_input_red,
    defines.wire_type.red,
    (defines.circuit_connector_id and defines.circuit_connector_id.combinator_input) or nil
  )
  local green_network = get_network(
    entity,
    defines.wire_connector_id.combinator_input_green,
    defines.wire_type.green,
    (defines.circuit_connector_id and defines.circuit_connector_id.combinator_input) or nil
  )

  local function network_id(network)
    if not network then return nil end
    local ok, value = pcall(function() return network.network_id end)
    return ok and value or nil
  end

  return network_id(red_network), network_id(green_network), red_network ~= nil, green_network ~= nil
end

local function network_caption(entity)
  local red_id, green_id, red_connected, green_connected = get_network_ids(entity)
  if not red_connected and not green_connected then
    return "Not connected to a circuit network"
  end

  local parts = {}
  if red_connected then
    table.insert(parts, "[color=red]" .. tostring(red_id or "?") .. "[/color]")
  end
  if green_connected then
    table.insert(parts, "[color=green]" .. tostring(green_id or "?") .. "[/color]")
  end

  return "Connected to network: " .. table.concat(parts, "  ")
end

local function read_input_signals(entity)
  if not entity or not entity.valid then return {} end
  local signals = {}

  local function read_wire(wire_connector_id, wire_type, legacy_connector_id, field)
    local network = get_network(entity, wire_connector_id, wire_type, legacy_connector_id)
    if not network or not network.signals then return end

    for _, entry in pairs(network.signals) do
      local key = signal_utils.signal_key(entry.signal)
      if key then
        if not signals[key] then
          signals[key] = {signal = entry.signal, red = 0, green = 0}
        end
        signals[key][field] = entry.count
      end
    end
  end

  local input_connector = (defines.circuit_connector_id and defines.circuit_connector_id.combinator_input) or nil
  read_wire(
    defines.wire_connector_id.combinator_input_red,
    defines.wire_type.red,
    input_connector,
    "red"
  )
  read_wire(
    defines.wire_connector_id.combinator_input_green,
    defines.wire_type.green,
    input_connector,
    "green"
  )

  return signals
end

local function sorted_signal_entries(signals)
  local entries = {}
  for key, entry in pairs(signals) do
    table.insert(entries, {
      key = key,
      signal = entry.signal,
      count = entry.red + entry.green
    })
  end
  table.sort(entries, function(a, b) return a.key < b.key end)
  return entries
end

local function add_signal_selector(parent, params)
  local button = parent.add{
    type = "choose-elem-button",
    name = params.name,
    elem_type = "signal",
    signal = params.signal
  }
  button.style.width = params.width or 48

  if params.value and (params.show_zero or params.value ~= 0) then
    button.number = params.value
  end

  return button
end

local function build_rg_block(parent, prefix, red_state, green_state)
  local block = parent.add{type = "flow", direction = "vertical"}
  block.style.vertical_spacing = 0
  block.style.width = 38

  local red_row = block.add{type = "flow", direction = "horizontal"}
  red_row.style.vertical_align = "center"
  red_row.style.horizontal_spacing = 1
  red_row.add{
    type = "checkbox",
    name = prefix .. "_red",
    state = red_state,
    tooltip = "Red wire"
  }
  red_row.add{type = "label", caption = "R"}.style.font_color = {1, 0.2, 0.2}

  local green_row = block.add{type = "flow", direction = "horizontal"}
  green_row.style.vertical_align = "center"
  green_row.style.horizontal_spacing = 1
  green_row.add{
    type = "checkbox",
    name = prefix .. "_green",
    state = green_state,
    tooltip = "Green wire"
  }
  green_row.add{type = "label", caption = "G"}.style.font_color = {0.2, 1, 0.2}

  return block
end

local function get_output_entity(entity, unit_number)
  if not entity or not entity.valid then return nil end

  local output_entity
  if storage.sc_entities and storage.sc_entities[unit_number] then
    output_entity = storage.sc_entities[unit_number].output_entity
  end
  if output_entity and output_entity.valid then return output_entity end

  output_entity = entity.surface.find_entity(
    "switch-combinator-output",
    {entity.position.x, entity.position.y + 1}
  )
  if output_entity and output_entity.valid then return output_entity end
  return nil
end

local function read_output_signals(entity, unit_number)
  local output_entity = get_output_entity(entity, unit_number)
  if not output_entity then return {} end

  local behavior = output_entity.get_or_create_control_behavior()
  if not behavior or behavior.sections_count == 0 then return {} end

  local section = behavior.get_section(1)
  if not section then return {} end

  local signals = {}
  for index = 1, section.filters_count do
    local filter = section.get_slot(index)
    if filter and filter.value and filter.value.name then
      table.insert(signals, {
        signal = filter.value,
        count = filter.min or 0
      })
    end
  end
  return signals
end

local function add_signal_shelf(parent, title, entries, empty_caption)
  local flow = parent.add{type = "flow", direction = "vertical"}
  flow.style.width = 420
  flow.add{type = "label", caption = title, style = "bold_label"}

  local frame = flow.add{
    type = "frame",
    name = GUI_PREFIX .. title:gsub("%s", "_"):lower() .. "_frame",
    style = "deep_frame_in_shallow_frame",
    direction = "horizontal"
  }
  frame.style.horizontally_stretchable = true
  frame.style.minimal_height = 40
  frame.style.padding = 4

  if #entries == 0 then
    frame.add{type = "label", caption = empty_caption, style = "caption_label"}
    return flow
  end

  for _, entry in ipairs(entries) do
    local signal_type = signal_utils.signal_type(entry.signal)
    local signal_name = entry.signal.name
    local button = frame.add{
      type = "sprite-button",
      sprite = signal_type .. "/" .. signal_name,
      number = entry.count,
      tooltip = signal_name .. ": " .. tostring(entry.count),
      style = "slot_button"
    }
    button.enabled = false
  end

  return flow
end

local function add_condition_row(parent, group_index, condition_index, condition, input_signals)
  local row = parent.add{type = "flow", direction = "horizontal"}
  row.style.vertical_align = "center"
  row.style.horizontal_spacing = 2

  build_rg_block(
    row,
    GUI_PREFIX .. "cond_lw_" .. group_index .. "_" .. condition_index,
    condition.left_red ~= false,
    condition.left_green ~= false
  )

  local left_value = evaluation.get_signal_value(
    input_signals,
    condition.left_signal,
    condition.left_red ~= false,
    condition.left_green ~= false
  )
  add_signal_selector(row, {
    name = GUI_PREFIX .. "cond_lsig_" .. group_index .. "_" .. condition_index,
    signal = condition.left_signal,
    value = left_value,
    width = 48
  })

  local operator_index = 1
  for index, operator in ipairs(OPERATORS) do
    if operator == condition.operator then operator_index = index end
  end
  local operator = row.add{
    type = "drop-down",
    name = GUI_PREFIX .. "cond_op_" .. group_index .. "_" .. condition_index,
    items = OPERATORS,
    selected_index = operator_index
  }
  operator.style.width = 54

  row.add{
    type = "sprite-button",
    name = GUI_PREFIX .. "cond_switch_" .. group_index .. "_" .. condition_index,
    sprite = "utility/rename_icon",
    style = "slot_button",
    tooltip = "Toggle constant/signal"
  }

  if condition.compare_type == "signal" then
    local right_value = evaluation.get_signal_value(
      input_signals,
      condition.right_signal,
      condition.right_red ~= false,
      condition.right_green ~= false
    )
    add_signal_selector(row, {
      name = GUI_PREFIX .. "cond_right_" .. group_index .. "_" .. condition_index,
      signal = condition.right_signal,
      value = right_value,
      width = 48
    })
  else
    local constant = row.add{
      type = "textfield",
      name = GUI_PREFIX .. "cond_const_" .. group_index .. "_" .. condition_index,
      text = tostring(condition.constant or 0),
      numeric = true,
      allow_negative = true
    }
    constant.style.width = 54
  end

  build_rg_block(
    row,
    GUI_PREFIX .. "cond_rw_" .. group_index .. "_" .. condition_index,
    condition.right_red ~= false,
    condition.right_green ~= false
  )

  row.add{
    type = "sprite-button",
    name = GUI_PREFIX .. "del_cond_" .. group_index .. "_" .. condition_index,
    sprite = "utility/close",
    style = "frame_action_button",
    tooltip = "Remove condition"
  }

  return row
end

local function add_group_header(parent, group_index, group, show_delete)
  local header = parent.add{type = "flow", direction = "horizontal"}
  header.style.vertical_align = "center"
  header.style.horizontal_spacing = 4
  header.style.bottom_margin = 2

  header.add{
    type = "label",
    caption = group.name or ("Match " .. group_index),
    style = "caption_label"
  }
  header.add{type = "empty-widget"}.style.horizontally_stretchable = true

  if show_delete then
    header.add{
      type = "sprite-button",
      name = GUI_PREFIX .. "del_group_" .. group_index,
      sprite = "utility/close",
      style = "frame_action_button",
      tooltip = "Remove group"
    }
  end
end

local function add_conditions(parent, groups, input_signals)
  for group_index, group in ipairs(groups) do
    if group_index > 1 then
      parent.add{type = "line"}.style.top_margin = 4
    end

    local group_frame = parent.add{
      type = "frame",
      style = "deep_frame_in_shallow_frame",
      direction = "vertical"
    }
    group_frame.style.horizontally_stretchable = true
    group_frame.style.padding = 4

    add_group_header(group_frame, group_index, group, #groups > 1)

    for condition_index, condition in ipairs(group.conditions) do
      if condition_index > 1 then
        local logic = condition.logic or "and"
        local logic_button = group_frame.add{
          type = "button",
          name = GUI_PREFIX .. "cond_logic_" .. group_index .. "_" .. condition_index,
          caption = string.upper(logic),
          tooltip = "Click to toggle OR/AND"
        }
        logic_button.style.width = 58
        logic_button.style.height = 26
        logic_button.style.top_margin = 2
        logic_button.style.bottom_margin = 2
      end
      add_condition_row(group_frame, group_index, condition_index, condition, input_signals)
    end

    local add_condition = group_frame.add{
      type = "button",
      name = GUI_PREFIX .. "add_cond_" .. group_index,
      caption = "+ Add condition"
    }
    add_condition.style.horizontally_stretchable = true
    add_condition.style.top_margin = 4
  end

  parent.add{type = "line"}.style.top_margin = 4
  local add_group = parent.add{
    type = "button",
    name = GUI_PREFIX .. "add_group",
    caption = "+ Add group"
  }
  add_group.style.horizontally_stretchable = true
end

local function add_output_row(parent, group_index, output_index, output, input_signals, all_conditions_met)
  local row = parent.add{type = "flow", direction = "horizontal"}
  row.style.vertical_align = "center"
  row.style.horizontal_spacing = 3

  local output_button = row.add{
    type = "choose-elem-button",
    name = GUI_PREFIX .. "out_sig_" .. group_index .. "_" .. output_index,
    elem_type = "signal",
    signal = output.signal
  }
  output_button.style.width = 48

  local input_value = evaluation.get_signal_value(
    input_signals,
    output.signal,
    output.red_wire ~= false,
    output.green_wire ~= false
  )
  if output.signal and input_value ~= 0 then output_button.number = input_value end

  local count_settings = row.add{type = "flow", direction = "vertical"}
  count_settings.style.vertical_spacing = 0

  local fixed_row = count_settings.add{type = "flow", direction = "horizontal"}
  fixed_row.style.vertical_align = "center"
  local fixed_checkbox = fixed_row.add{
    type = "checkbox",
    name = GUI_PREFIX .. "out_radio_count_" .. group_index .. "_" .. output_index,
    caption = "Count",
    state = output.use_input_count ~= true,
    tooltip = "Use fixed count"
  }
  fixed_checkbox.style.width = 66
  local count_field = fixed_row.add{
    type = "textfield",
    name = GUI_PREFIX .. "out_count_" .. group_index .. "_" .. output_index,
    text = tostring(output.count or 1),
    numeric = true,
    allow_negative = true
  }
  count_field.style.width = 48
  count_field.enabled = output.use_input_count ~= true

  local input_row = count_settings.add{type = "flow", direction = "horizontal"}
  input_row.style.vertical_align = "center"
  local input_checkbox = input_row.add{
    type = "checkbox",
    name = GUI_PREFIX .. "out_radio_input_" .. group_index .. "_" .. output_index,
    caption = "Input count",
    state = output.use_input_count == true,
    tooltip = "Use input signal count"
  }
  input_checkbox.style.width = 92
  local input_label = input_row.add{type = "label", caption = tostring(input_value)}
  if all_conditions_met then input_label.style.font_color = {0.2, 1, 0.2} end

  row.add{
    type = "label",
    caption = all_conditions_met and WORKING_CAPTION or IDLE_CAPTION,
    tooltip = all_conditions_met and "Conditions matched" or "Conditions not matched"
  }

  build_rg_block(
    row,
    GUI_PREFIX .. "out_" .. group_index .. "_" .. output_index,
    output.red_wire ~= false,
    output.green_wire ~= false
  )

  row.add{
    type = "sprite-button",
    name = GUI_PREFIX .. "del_out_" .. group_index .. "_" .. output_index,
    sprite = "utility/close",
    style = "frame_action_button",
    tooltip = "Remove output"
  }
end

local function add_outputs(parent, groups, input_signals)
  for group_index, group in ipairs(groups) do
    if group_index > 1 then parent.add{type = "line"}.style.top_margin = 4 end

    local group_frame = parent.add{
      type = "frame",
      style = "deep_frame_in_shallow_frame",
      direction = "vertical"
    }
    group_frame.style.horizontally_stretchable = true
    group_frame.style.padding = 4

    local header = group_frame.add{type = "flow", direction = "horizontal"}
    header.style.bottom_margin = 2
    header.add{
      type = "label",
      caption = group.name or ("Match " .. group_index),
      style = "caption_label"
    }
    header.add{type = "empty-widget"}.style.horizontally_stretchable = true

    local all_conditions_met = evaluation.evaluate_conditions(group.conditions, input_signals)
    for output_index, output in ipairs(group.outputs) do
      add_output_row(
        group_frame,
        group_index,
        output_index,
        output,
        input_signals,
        all_conditions_met
      )
    end

    local add_output = group_frame.add{
      type = "button",
      name = GUI_PREFIX .. "add_out_" .. group_index,
      caption = "+ Add output"
    }
    add_output.style.horizontally_stretchable = true
    add_output.style.top_margin = 4
  end
end

-- ============================================================================
-- Open and layout
-- ============================================================================

function gui_main.open(player, entity, _storage)
  gui_main.close(player, _storage)

  local pstate = ps(player.index)
  pstate.unit_number = entity.unit_number

  if not state_manager.get_entity_data(entity.unit_number) then
    state_manager.init_entity(entity.unit_number)
  end

  local frame = player.gui.screen.add{
    type = "frame",
    name = GUI_PREFIX .. "main_frame",
    direction = "vertical"
  }
  frame.style.width = 884

  local titlebar = frame.add{type = "flow", direction = "horizontal"}
  titlebar.style.horizontal_spacing = 8
  titlebar.drag_target = frame
  local icon = titlebar.add{
    type = "sprite-button",
    sprite = "item/switch-combinator",
    style = "slot_button"
  }
  icon.enabled = false
  titlebar.add{type = "label", caption = "Switch Combinator", style = "frame_title"}
  local drag = titlebar.add{type = "empty-widget", style = "draggable_space_header"}
  drag.style.horizontally_stretchable = true
  drag.style.height = 24
  drag.drag_target = frame
  titlebar.add{
    type = "sprite-button",
    name = GUI_PREFIX .. "close",
    sprite = "utility/close",
    style = "frame_action_button",
    mouse_button_filter = {"left"}
  }

  local scroll = frame.add{
    type = "scroll-pane",
    name = GUI_PREFIX .. "scroll",
    vertical_scroll_policy = "auto",
    horizontal_scroll_policy = "never"
  }
  scroll.style.width = 884
  scroll.style.maximal_height = 760

  local inner = scroll.add{
    type = "frame",
    name = GUI_PREFIX .. "inner",
    style = "inside_shallow_frame_with_padding",
    direction = "vertical"
  }
  inner.style.horizontally_stretchable = true

  gui_main.build_content(inner, player, entity)

  local bottom = frame.add{
    type = "flow",
    name = GUI_PREFIX .. "bottom_bar",
    direction = "horizontal"
  }
  bottom.style.top_margin = 4
  if tests_enabled then
    bottom.add{type = "button", name = GUI_PREFIX .. "run_tests", caption = "Run Tests"}
  end

  frame.force_auto_center()
end

function gui_main.set_tests_enabled(enabled)
  tests_enabled = enabled == true
end

function gui_main.build_content(inner, player, entity)
  local pstate = ps(player.index)
  local unit_number = pstate.unit_number
  if not unit_number then error("build_content: no unit_number") end

  local groups = state_manager.get_groups(unit_number)
  local sc_entity = entity or get_entity(unit_number)
  local input_signals = read_input_signals(sc_entity)
  local output_signals = read_output_signals(sc_entity, unit_number)

  local content = inner.add{
    type = "flow",
    name = GUI_PREFIX .. "content",
    direction = "vertical"
  }

  local network = content.add{type = "flow", direction = "horizontal"}
  network.style.bottom_margin = 2
  network.add{type = "label", caption = network_caption(sc_entity)}

  local status = content.add{type = "flow", direction = "horizontal"}
  status.style.vertical_align = "center"
  status.style.bottom_margin = 4
  status.add{type = "label", caption = WORKING_CAPTION}

  local preview = content.add{
    type = "entity-preview",
    name = GUI_PREFIX .. "entity_preview"
  }
  preview.style.horizontally_stretchable = true
  preview.style.height = 118
  if sc_entity and sc_entity.valid then preview.entity = sc_entity end

  local headings = content.add{type = "table", column_count = 2}
  headings.style.horizontal_spacing = 12
  headings.style.horizontally_stretchable = true

  local conditions_heading = headings.add{type = "flow", direction = "horizontal"}
  conditions_heading.style.vertical_align = "center"
  conditions_heading.add{type = "label", caption = "Conditions", style = "bold_label"}
  conditions_heading.add{type = "empty-widget"}.style.horizontally_stretchable = true
  conditions_heading.add{type = "label", caption = "Mode:"}
  local mode = state_manager.get_mode(unit_number)
  conditions_heading.add{
    type = "checkbox",
    name = GUI_PREFIX .. "mode_first",
    caption = "First match",
    state = mode == "first_match"
  }
  conditions_heading.add{
    type = "checkbox",
    name = GUI_PREFIX .. "mode_multi",
    caption = "Multi match",
    state = mode == "multi_match"
  }

  headings.add{type = "label", caption = "Outputs", style = "bold_label"}

  local columns = content.add{type = "table", column_count = 2}
  columns.style.horizontal_spacing = 12
  columns.style.horizontally_stretchable = true

  local conditions_column = columns.add{type = "flow", direction = "vertical"}
  conditions_column.style.width = 420
  add_conditions(conditions_column, groups, input_signals)

  local outputs_column = columns.add{type = "flow", direction = "vertical"}
  outputs_column.style.width = 420
  add_outputs(outputs_column, groups, input_signals)

  local shelves = content.add{type = "table", column_count = 2}
  shelves.style.horizontal_spacing = 12
  shelves.style.horizontally_stretchable = true
  add_signal_shelf(shelves, "Input signals", sorted_signal_entries(input_signals), "No input signals")

  local output_entries = {}
  for _, entry in ipairs(output_signals) do
    table.insert(output_entries, {signal = entry.signal, count = entry.count})
  end
  add_signal_shelf(shelves, "Output signals", output_entries, "No output signals")

  local description = state_manager.get_description(unit_number)
  if description and description ~= "" then
    content.add{type = "label", caption = description, style = "caption_label"}
  end
  content.add{
    type = "button",
    name = GUI_PREFIX .. "open_description",
    caption = (description and description ~= "") and "Edit description" or "Add description"
  }
end

function gui_main.rebuild_groups(player, _storage)
  local frame = player.gui.screen[GUI_PREFIX .. "main_frame"]
  if not frame then return end

  local scroll = frame[GUI_PREFIX .. "scroll"]
  local inner = scroll and scroll[GUI_PREFIX .. "inner"]
  if not inner then return end

  local old_content = inner[GUI_PREFIX .. "content"]
  if old_content then old_content.destroy() end
  gui_main.build_content(inner, player, nil)
end

-- ============================================================================
-- Close and description dialog
-- ============================================================================

function gui_main.close(player, _storage)
  local desc_dialog = player.gui.screen[GUI_PREFIX .. "desc_dialog"]
  if desc_dialog then desc_dialog.destroy() end
  local existing_results = player.gui.screen[GUI_PREFIX .. "test_results_frame"]
  if existing_results then existing_results.destroy() end
  local main = player.gui.screen[GUI_PREFIX .. "main_frame"]
  if main then main.destroy() end
  ps(player.index).unit_number = nil
end

function gui_main.open_description_dialog(player)
  local unit_number = ps(player.index).unit_number
  if not unit_number then return end

  local existing = player.gui.screen[GUI_PREFIX .. "desc_dialog"]
  if existing then existing.destroy() end

  local dialog = player.gui.screen.add{
    type = "frame",
    name = GUI_PREFIX .. "desc_dialog",
    direction = "vertical"
  }
  dialog.style.width = 400

  local titlebar = dialog.add{type = "flow", direction = "horizontal"}
  titlebar.drag_target = dialog
  titlebar.add{type = "label", caption = "Description", style = "frame_title"}
  local drag = titlebar.add{type = "empty-widget", style = "draggable_space_header"}
  drag.style.horizontally_stretchable = true
  drag.style.height = 24
  drag.drag_target = dialog
  titlebar.add{
    type = "sprite-button",
    name = GUI_PREFIX .. "close_desc",
    sprite = "utility/close",
    style = "frame_action_button",
    mouse_button_filter = {"left"}
  }

  local inner = dialog.add{
    type = "frame",
    style = "inside_shallow_frame_with_padding",
    direction = "vertical"
  }
  local text_box = inner.add{
    type = "text-box",
    name = GUI_PREFIX .. "desc_text",
    text = state_manager.get_description(unit_number) or ""
  }
  text_box.style.horizontally_stretchable = true
  text_box.style.height = 120

  local buttons = dialog.add{type = "flow", direction = "horizontal"}
  buttons.style.top_margin = 4
  buttons.add{type = "empty-widget"}.style.horizontally_stretchable = true
  buttons.add{
    type = "button",
    name = GUI_PREFIX .. "desc_accept",
    caption = "Accept",
    style = "confirm_button"
  }

  dialog.force_auto_center()
end

-- ============================================================================
-- GUI events
-- ============================================================================

function gui_main.on_click(player, element, _storage)
  local name = element.name
  if not name or not name:find("^" .. GUI_PREFIX) then return end

  local unit_number = ps(player.index).unit_number
  if name == GUI_PREFIX .. "close" then gui_main.close(player, _storage); return end
  if name == GUI_PREFIX .. "close_results" then
    local results = player.gui.screen[GUI_PREFIX .. "test_results_frame"]
    if results then results.destroy() end
    return
  end
  if name == GUI_PREFIX .. "close_desc" then
    local dialog = player.gui.screen[GUI_PREFIX .. "desc_dialog"]
    if dialog then dialog.destroy() end
    return
  end
  if name == GUI_PREFIX .. "run_tests" then gui_main.run_tests(player, _storage); return end
  if name == GUI_PREFIX .. "open_description" then gui_main.open_description_dialog(player); return end

  if name == GUI_PREFIX .. "desc_accept" then
    if unit_number then
      local dialog = player.gui.screen[GUI_PREFIX .. "desc_dialog"]
      local inner = dialog and dialog.children[2]
      local text_box = inner and inner[GUI_PREFIX .. "desc_text"]
      if text_box then state_manager.set_description(unit_number, text_box.text) end
      if dialog then dialog.destroy() end
      gui_main.rebuild_groups(player, _storage)
    end
    return
  end

  if not unit_number then return end

  if name == GUI_PREFIX .. "add_group" then
    state_manager.add_group(unit_number)
    gui_main.rebuild_groups(player, _storage)
    return
  end

  local group_index = name:match("^" .. GUI_PREFIX .. "del_group_(%d+)$")
  if group_index then
    state_manager.remove_group(unit_number, tonumber(group_index))
    gui_main.rebuild_groups(player, _storage)
    return
  end

  group_index = name:match("^" .. GUI_PREFIX .. "add_cond_(%d+)$")
  if group_index then
    state_manager.add_condition(unit_number, tonumber(group_index))
    gui_main.rebuild_groups(player, _storage)
    return
  end

  local condition_group, condition_index = name:match("^" .. GUI_PREFIX .. "del_cond_(%d+)_(%d+)$")
  if condition_group and condition_index then
    state_manager.remove_condition(unit_number, tonumber(condition_group), tonumber(condition_index))
    gui_main.rebuild_groups(player, _storage)
    return
  end

  condition_group, condition_index = name:match("^" .. GUI_PREFIX .. "cond_switch_(%d+)_(%d+)$")
  if condition_group and condition_index then
    local group = state_manager.get_group(unit_number, tonumber(condition_group))
    local condition = group and group.conditions[tonumber(condition_index)]
    if condition then
      if condition.compare_type == "signal" then
        state_manager.set_condition_compare_type(unit_number, tonumber(condition_group), tonumber(condition_index), "constant")
        state_manager.set_condition_right_signal(unit_number, tonumber(condition_group), tonumber(condition_index), nil)
        if condition.constant == nil then
          state_manager.set_condition_constant(unit_number, tonumber(condition_group), tonumber(condition_index), 0)
        end
      else
        state_manager.set_condition_compare_type(unit_number, tonumber(condition_group), tonumber(condition_index), "signal")
        state_manager.set_condition_constant(unit_number, tonumber(condition_group), tonumber(condition_index), 0)
      end
    end
    gui_main.rebuild_groups(player, _storage)
    return
  end

  condition_group, condition_index = name:match("^" .. GUI_PREFIX .. "cond_logic_(%d+)_(%d+)$")
  if condition_group and condition_index then
    local group = state_manager.get_group(unit_number, tonumber(condition_group))
    local condition = group and group.conditions[tonumber(condition_index)]
    if condition then
      state_manager.set_condition_logic(
        unit_number,
        tonumber(condition_group),
        tonumber(condition_index),
        condition.logic == "or" and "and" or "or"
      )
    end
    gui_main.rebuild_groups(player, _storage)
    return
  end

  group_index = name:match("^" .. GUI_PREFIX .. "add_out_(%d+)$")
  if group_index then
    state_manager.add_output(unit_number, tonumber(group_index))
    gui_main.rebuild_groups(player, _storage)
    return
  end

  local output_group, output_index = name:match("^" .. GUI_PREFIX .. "del_out_(%d+)_(%d+)$")
  if output_group and output_index then
    state_manager.remove_output(unit_number, tonumber(output_group), tonumber(output_index))
    gui_main.rebuild_groups(player, _storage)
  end
end

function gui_main.on_checked_changed(player, element, _storage)
  local name = element.name
  if not name or not name:find("^" .. GUI_PREFIX) then return end

  local unit_number = ps(player.index).unit_number
  if not unit_number then return end

  if name == GUI_PREFIX .. "mode_first" then
    if element.state then
      state_manager.set_mode(unit_number, "first_match")
      local multi = find_element(player.gui.screen, GUI_PREFIX .. "mode_multi")
      if multi then multi.state = false end
    else
      element.state = true
    end
    return
  end

  if name == GUI_PREFIX .. "mode_multi" then
    if element.state then
      state_manager.set_mode(unit_number, "multi_match")
      local first = find_element(player.gui.screen, GUI_PREFIX .. "mode_first")
      if first then first.state = false end
    else
      element.state = true
    end
    return
  end

  local group_index, condition_index = name:match("^" .. GUI_PREFIX .. "cond_lw_(%d+)_(%d+)_red$")
  if group_index and condition_index then
    state_manager.set_condition_wire(unit_number, tonumber(group_index), tonumber(condition_index), "left", "red", element.state)
    return
  end
  group_index, condition_index = name:match("^" .. GUI_PREFIX .. "cond_lw_(%d+)_(%d+)_green$")
  if group_index and condition_index then
    state_manager.set_condition_wire(unit_number, tonumber(group_index), tonumber(condition_index), "left", "green", element.state)
    return
  end
  group_index, condition_index = name:match("^" .. GUI_PREFIX .. "cond_rw_(%d+)_(%d+)_red$")
  if group_index and condition_index then
    state_manager.set_condition_wire(unit_number, tonumber(group_index), tonumber(condition_index), "right", "red", element.state)
    return
  end
  group_index, condition_index = name:match("^" .. GUI_PREFIX .. "cond_rw_(%d+)_(%d+)_green$")
  if group_index and condition_index then
    state_manager.set_condition_wire(unit_number, tonumber(group_index), tonumber(condition_index), "right", "green", element.state)
    return
  end

  group_index, condition_index = name:match("^" .. GUI_PREFIX .. "out_(%d+)_(%d+)_red$")
  if group_index and condition_index then
    state_manager.set_output_wire(unit_number, tonumber(group_index), tonumber(condition_index), "red", element.state)
    return
  end
  group_index, condition_index = name:match("^" .. GUI_PREFIX .. "out_(%d+)_(%d+)_green$")
  if group_index and condition_index then
    state_manager.set_output_wire(unit_number, tonumber(group_index), tonumber(condition_index), "green", element.state)
    return
  end

  group_index, condition_index = name:match("^" .. GUI_PREFIX .. "out_radio_input_(%d+)_(%d+)$")
  if group_index and condition_index then
    state_manager.set_output_use_input_count(unit_number, tonumber(group_index), tonumber(condition_index), true)
    gui_main.rebuild_groups(player, _storage)
    return
  end

  group_index, condition_index = name:match("^" .. GUI_PREFIX .. "out_radio_count_(%d+)_(%d+)$")
  if group_index and condition_index then
    state_manager.set_output_use_input_count(unit_number, tonumber(group_index), tonumber(condition_index), false)
    gui_main.rebuild_groups(player, _storage)
  end
end

function gui_main.on_text_changed(player, element, _storage)
  local name = element.name
  if not name or not name:find("^" .. GUI_PREFIX) then return end

  local unit_number = ps(player.index).unit_number
  if not unit_number then return end

  local group_index, condition_index = name:match("^" .. GUI_PREFIX .. "cond_const_(%d+)_(%d+)$")
  if group_index and condition_index then
    state_manager.set_condition_compare_type(unit_number, tonumber(group_index), tonumber(condition_index), "constant")
    state_manager.set_condition_constant(unit_number, tonumber(group_index), tonumber(condition_index), tonumber(element.text) or 0)
    return
  end

  group_index, condition_index = name:match("^" .. GUI_PREFIX .. "out_count_(%d+)_(%d+)$")
  if group_index and condition_index then
    state_manager.set_output_count(unit_number, tonumber(group_index), tonumber(condition_index), tonumber(element.text) or 1)
  end
end

function gui_main.on_elem_changed(player, element, _storage)
  local name = element.name
  if not name or not name:find("^" .. GUI_PREFIX) then return end

  local unit_number = ps(player.index).unit_number
  if not unit_number then return end

  local group_index, condition_index = name:match("^" .. GUI_PREFIX .. "cond_lsig_(%d+)_(%d+)$")
  if group_index and condition_index then
    state_manager.set_condition_left_signal(unit_number, tonumber(group_index), tonumber(condition_index), element.elem_value)
    return
  end

  group_index, condition_index = name:match("^" .. GUI_PREFIX .. "cond_right_(%d+)_(%d+)$")
  if group_index and condition_index then
    state_manager.set_condition_compare_type(unit_number, tonumber(group_index), tonumber(condition_index), "signal")
    state_manager.set_condition_right_signal(unit_number, tonumber(group_index), tonumber(condition_index), element.elem_value)
    state_manager.set_condition_constant(unit_number, tonumber(group_index), tonumber(condition_index), 0)
    return
  end

  group_index, condition_index = name:match("^" .. GUI_PREFIX .. "out_sig_(%d+)_(%d+)$")
  if group_index and condition_index then
    state_manager.set_output_signal(unit_number, tonumber(group_index), tonumber(condition_index), element.elem_value)
  end
end

function gui_main.on_selection_changed(player, element, _storage)
  local name = element.name
  if not name or not name:find("^" .. GUI_PREFIX) then return end

  local unit_number = ps(player.index).unit_number
  if not unit_number then return end

  local group_index, condition_index = name:match("^" .. GUI_PREFIX .. "cond_op_(%d+)_(%d+)$")
  if group_index and condition_index then
    state_manager.set_condition_operator(
      unit_number,
      tonumber(group_index),
      tonumber(condition_index),
      OPERATORS[element.selected_index] or ">"
    )
  end
end

-- ============================================================================
-- Test runner dialog
-- ============================================================================

function gui_main.run_tests(player, _storage)
  local existing = player.gui.screen[GUI_PREFIX .. "test_results_frame"]
  if existing then existing.destroy() end

  local results_frame = player.gui.screen.add{
    type = "frame",
    name = GUI_PREFIX .. "test_results_frame",
    direction = "vertical"
  }

  local titlebar = results_frame.add{type = "flow", direction = "horizontal"}
  titlebar.add{type = "label", caption = "Test Results", style = "frame_title"}
  titlebar.add{type = "empty-widget"}.style.horizontally_stretchable = true
  titlebar.add{
    type = "sprite-button",
    name = GUI_PREFIX .. "close_results",
    sprite = "utility/close",
    style = "frame_action_button",
    mouse_button_filter = {"left"}
  }

  local scroll = results_frame.add{
    type = "scroll-pane",
    vertical_scroll_policy = "always",
    horizontal_scroll_policy = "never"
  }
  scroll.style.height = 400
  scroll.style.width = 600

  local text_box = scroll.add{
    type = "text-box",
    name = GUI_PREFIX .. "test_results_text",
    text = ""
  }
  text_box.style.height = 380
  text_box.style.width = 580
  text_box.read_only = true

  local function test_print(message)
    if text_box and text_box.valid then
      text_box.text = text_box.text .. message .. "\n"
    end
    if player and player.valid then player.print(message) end
  end

  local success = remote.call("switch_combinator_tests", "run_tests", player.index, test_print)
  if not success then player.print("[ERROR] Test runner not available") end
  if text_box and text_box.valid then text_box.text = text_box.text .. "Tests completed!\n" end

  results_frame.force_auto_center()
end

return gui_main
