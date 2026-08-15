-- State Manager for Switch Combinator
-- Matches decider combinator data model:
--   Conditions: left_signal OP right_signal_or_constant, R/G on both sides, OR/AND logic
--   Outputs: signal, count OR input_count, R/G wire filter

local state_manager = {}

local function deep_copy(value)
  if type(value) ~= "table" then return value end

  local copy = {}
  for key, nested_value in pairs(value) do
    copy[deep_copy(key)] = deep_copy(nested_value)
  end
  return copy
end

function state_manager.clone_entity_data(data)
  return deep_copy(data)
end

-- ============================================================================
-- Entity Data Management
-- ============================================================================

function state_manager.get_entity_data(unit_number)
  if not storage.entity_data then storage.entity_data = {} end
  return storage.entity_data[unit_number]
end

function state_manager.set_entity_data(unit_number, data)
  if not storage.entity_data then storage.entity_data = {} end
  storage.entity_data[unit_number] = data
end

function state_manager.init_entity(unit_number)
  state_manager.set_entity_data(unit_number, {
    mode = "first_match",
    description = "",
    groups = {
      { 
        name = "Match 1", 
        conditions = {
          {
            left_signal = nil,
            left_red = true,
            left_green = true,
            operator = ">",
            compare_type = "constant",
            constant = 0,
            right_signal = nil,
            right_red = true,
            right_green = true,
            logic = nil
          }
        }, 
        outputs = {
          {
            signal = nil,
            count = 1,
            use_input_count = false,
            red_wire = true,
            green_wire = true
          }
        }
      }
    }
  })
end

-- ============================================================================
-- Mode
-- ============================================================================

function state_manager.get_mode(unit_number)
  local data = state_manager.get_entity_data(unit_number)
  return data and data.mode or "first_match"
end

function state_manager.set_mode(unit_number, mode)
  local data = state_manager.get_entity_data(unit_number)
  if data then data.mode = mode end
end

-- ============================================================================
-- Groups  (each group has: name, conditions[], outputs[])
-- ============================================================================

function state_manager.get_groups(unit_number)
  local data = state_manager.get_entity_data(unit_number)
  return data and data.groups or {}
end

function state_manager.get_group(unit_number, group_index)
  local groups = state_manager.get_groups(unit_number)
  return groups[group_index]
end

function state_manager.add_group(unit_number)
  local data = state_manager.get_entity_data(unit_number)
  if not data then return nil end
  if not data.groups then data.groups = {} end
  local idx = #data.groups + 1
  data.groups[idx] = {
    name = "Match " .. idx,
    conditions = {
      {
        left_signal = nil,
        left_red = true,
        left_green = true,
        operator = ">",
        compare_type = "constant",
        constant = 0,
        right_signal = nil,
        right_red = true,
        right_green = true,
        logic = nil
      }
    },
    outputs = {
      {
        signal = nil,
        count = 1,
        use_input_count = false,
        red_wire = true,
        green_wire = true
      }
    }
  }
  return idx
end

function state_manager.remove_group(unit_number, group_index)
  local data = state_manager.get_entity_data(unit_number)
  if not data or not data.groups then return end
  table.remove(data.groups, group_index)
end

function state_manager.rename_group(unit_number, group_index, new_name)
  local g = state_manager.get_group(unit_number, group_index)
  if g then g.name = new_name end
end

-- ============================================================================
-- Conditions
-- Each condition: {
--   left_signal, left_red, left_green,
--   operator,
--   compare_type ("constant" or "signal"),
--   constant (number),
--   right_signal, right_red, right_green,
--   logic ("or" or "and") -- relation to NEXT condition
-- }
-- ============================================================================

function state_manager.add_condition(unit_number, group_index)
  local g = state_manager.get_group(unit_number, group_index)
  if not g then return end
  -- Default logic for new condition: if there are existing conditions, default to "or"
  local logic = #g.conditions > 0 and "or" or nil
  table.insert(g.conditions, {
    left_signal = nil,
    left_red = true,
    left_green = true,
    operator = ">",
    compare_type = "constant",
    constant = 0,
    right_signal = nil,
    right_red = true,
    right_green = true,
    logic = logic  -- relation to PREVIOUS condition ("or"/"and"), nil for first
  })
  return #g.conditions
end

function state_manager.remove_condition(unit_number, group_index, cond_index)
  local g = state_manager.get_group(unit_number, group_index)
  if not g then return end
  table.remove(g.conditions, cond_index)
  -- Fix logic of new first condition
  if #g.conditions > 0 and g.conditions[1] then
    g.conditions[1].logic = nil
  end
end

function state_manager.set_condition_left_signal(unit_number, group_index, cond_index, signal)
  local g = state_manager.get_group(unit_number, group_index)
  if g and g.conditions[cond_index] then g.conditions[cond_index].left_signal = signal end
end

function state_manager.set_condition_right_signal(unit_number, group_index, cond_index, signal)
  local g = state_manager.get_group(unit_number, group_index)
  if g and g.conditions[cond_index] then g.conditions[cond_index].right_signal = signal end
end

function state_manager.set_condition_operator(unit_number, group_index, cond_index, op)
  local g = state_manager.get_group(unit_number, group_index)
  if g and g.conditions[cond_index] then g.conditions[cond_index].operator = op end
end

function state_manager.set_condition_constant(unit_number, group_index, cond_index, val)
  local g = state_manager.get_group(unit_number, group_index)
  if g and g.conditions[cond_index] then g.conditions[cond_index].constant = val end
end

function state_manager.set_condition_compare_type(unit_number, group_index, cond_index, ctype)
  local g = state_manager.get_group(unit_number, group_index)
  if g and g.conditions[cond_index] then g.conditions[cond_index].compare_type = ctype end
end

function state_manager.set_condition_wire(unit_number, group_index, cond_index, side, wire_color, enabled)
  local g = state_manager.get_group(unit_number, group_index)
  if not g or not g.conditions[cond_index] then return end
  local c = g.conditions[cond_index]
  if side == "left" then
    if wire_color == "red" then c.left_red = enabled
    elseif wire_color == "green" then c.left_green = enabled end
  elseif side == "right" then
    if wire_color == "red" then c.right_red = enabled
    elseif wire_color == "green" then c.right_green = enabled end
  end
end

function state_manager.set_condition_logic(unit_number, group_index, cond_index, logic)
  local g = state_manager.get_group(unit_number, group_index)
  if g and g.conditions[cond_index] then g.conditions[cond_index].logic = logic end
end

-- ============================================================================
-- Outputs
-- Each output: { signal, count, use_input_count, red_wire, green_wire }
-- ============================================================================

function state_manager.add_output(unit_number, group_index)
  local g = state_manager.get_group(unit_number, group_index)
  if not g then return end
  table.insert(g.outputs, {
    signal = nil,
    count = 1,
    use_input_count = false,
    red_wire = true,
    green_wire = true
  })
  return #g.outputs
end

function state_manager.remove_output(unit_number, group_index, out_index)
  local g = state_manager.get_group(unit_number, group_index)
  if not g then return end
  table.remove(g.outputs, out_index)
end

function state_manager.set_output_signal(unit_number, group_index, out_index, signal)
  local g = state_manager.get_group(unit_number, group_index)
  if g and g.outputs[out_index] then g.outputs[out_index].signal = signal end
end

function state_manager.set_output_count(unit_number, group_index, out_index, count)
  local g = state_manager.get_group(unit_number, group_index)
  if g and g.outputs[out_index] then g.outputs[out_index].count = count end
end

function state_manager.set_output_use_input_count(unit_number, group_index, out_index, use)
  local g = state_manager.get_group(unit_number, group_index)
  if g and g.outputs[out_index] then g.outputs[out_index].use_input_count = use end
end

function state_manager.set_output_wire(unit_number, group_index, out_index, wire_color, enabled)
  local g = state_manager.get_group(unit_number, group_index)
  if g and g.outputs[out_index] then
    if wire_color == "red" then
      g.outputs[out_index].red_wire = enabled
    elseif wire_color == "green" then
      g.outputs[out_index].green_wire = enabled
    end
  end
end

function state_manager.get_description(unit_number)
  local data = state_manager.get_entity_data(unit_number)
  return data and data.description or ""
end

function state_manager.set_description(unit_number, desc)
  local data = state_manager.get_entity_data(unit_number)
  if data then data.description = desc end
end

return state_manager
