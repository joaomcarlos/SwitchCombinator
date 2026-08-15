-- Signal utility functions for Switch Combinator

local signal_utils = {}

-- Get a unique key string for a signal
function signal_utils.signal_type(signal)
  if not signal or not signal.name then return nil end
  return signal.type or "item"
end

function signal_utils.signal_key(signal)
  local signal_type = signal_utils.signal_type(signal)
  if not signal_type then return nil end

  local key = signal_type .. "/" .. signal.name
  if signal.quality and signal.quality ~= "normal" then
    key = key .. "@" .. signal.quality
  end
  return key
end

-- Check if two signals are equal
function signal_utils.signals_equal(signal1, signal2)
  if not signal1 or not signal2 then return false end
  local key1 = signal_utils.signal_key(signal1)
  local key2 = signal_utils.signal_key(signal2)
  return key1 ~= nil and key1 == key2
end

-- Compare two values using an operator
function signal_utils.compare(left, operator, right)
  if operator == ">" then
    return left > right
  elseif operator == "<" then
    return left < right
  elseif operator == ">=" then
    return left >= right
  elseif operator == "<=" then
    return left <= right
  elseif operator == "==" or operator == "=" then
    return left == right
  elseif operator == "!=" or operator == "≠" then
    return left ~= right
  elseif operator == "≥" then
    return left >= right
  elseif operator == "≤" then
    return left <= right
  else
    return false
  end
end

-- Merge multiple output signal dictionaries
function signal_utils.merge_outputs(...)
  local result = {}
  
  for i = 1, select("#", ...) do
    local outputs = select(i, ...)
    if outputs then
      for key, entry in pairs(outputs) do
        if entry and entry.signal and entry.count and type(entry.count) == "number" and entry.count ~= 0 then
          if result[key] then
            -- Sum counts for duplicate signals
            result[key].count = result[key].count + entry.count
          else
            -- Add new signal
            result[key] = {
              signal = entry.signal,
              count = entry.count
            }
          end
        end
      end
    end
  end
  
  return result
end

-- Convert signal dictionary to array format
function signal_utils.dict_to_array(signals_dict)
  local result = {}
  
  if signals_dict then
    for key, entry in pairs(signals_dict) do
      if entry and entry.signal and entry.count and type(entry.count) == "number" and entry.count ~= 0 then
        table.insert(result, {
          signal = entry.signal,
          count = entry.count
        })
      end
    end
  end
  
  return result
end

return signal_utils
