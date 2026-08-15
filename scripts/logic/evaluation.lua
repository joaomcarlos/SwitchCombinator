-- Shared condition evaluation for the runtime and GUI preview.

local signal_utils = require("scripts.utils.signal_utils")

local evaluation = {}

function evaluation.get_signal_value(input_signals, signal, use_red, use_green)
  if not signal or not signal.name then return 0 end

  local key = signal_utils.signal_key(signal)
  if not key then return 0 end

  local entry = input_signals[key]
  if not entry then return 0 end

  local value = 0
  if use_red and type(entry.red) == "number" then value = value + entry.red end
  if use_green and type(entry.green) == "number" then value = value + entry.green end
  return value
end

function evaluation.compare_values(left_value, operator, right_value)
  return signal_utils.compare(left_value, operator, right_value)
end

function evaluation.evaluate_single_condition(condition, input_signals)
  if not condition.left_signal or not condition.left_signal.name then return false end

  local left_value = evaluation.get_signal_value(
    input_signals,
    condition.left_signal,
    condition.left_red ~= false,
    condition.left_green ~= false
  )

  local right_value
  if condition.compare_type == "signal" and condition.right_signal and condition.right_signal.name then
    right_value = evaluation.get_signal_value(
      input_signals,
      condition.right_signal,
      condition.right_red ~= false,
      condition.right_green ~= false
    )
  else
    right_value = condition.constant or 0
  end

  return evaluation.compare_values(left_value, condition.operator or ">", right_value)
end

function evaluation.evaluate_conditions(conditions, input_signals)
  if #conditions == 0 then return false end

  local current_and_result = evaluation.evaluate_single_condition(conditions[1], input_signals)
  for index = 2, #conditions do
    local condition = conditions[index]
    local condition_result = evaluation.evaluate_single_condition(condition, input_signals)
    if condition.logic == "or" then
      if current_and_result then return true end
      current_and_result = condition_result
    else
      current_and_result = current_and_result and condition_result
    end
  end

  return current_and_result
end

return evaluation
