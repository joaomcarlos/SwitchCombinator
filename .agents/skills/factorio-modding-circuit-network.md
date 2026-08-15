---
title: Factorio Modding — Circuit Network & Combinators
description: Circuit network skill for Factorio 2.0. Wire connectors, combinators, signals, control behavior, and inserter control. Verified working patterns.
---

# Factorio Modding — Circuit Network & Combinators

Use this skill when working with circuit networks: reading signals, writing to combinators, controlling inserters, or building custom combinator mods.

Use the official [Factorio Data repository](https://github.com/wube/factorio-data) as the versioned source of truth for circuit-related prototype definitions, signal prototypes, and vanilla names. Match the branch, tag, or release to the target game version; use the official API docs for wire connectors, network objects, control behaviors, and event contracts.

---

## Wire Connectors (Factorio 2.0)

In Factorio 2.0, wire connections use `defines.wire_connector_id`:

```lua
local red_conn = entity.get_wire_connector(defines.wire_connector_id.combinator_input_red, true)
local green_conn = entity.get_wire_connector(defines.wire_connector_id.combinator_input_green, true)
```

Common `defines.wire_connector_id` values:
- `combinator_input_red`, `combinator_input_green`
- `combinator_output_red`, `combinator_output_green`
- `circuit_red`, `circuit_green` (for generic circuit connections)

### Connecting Wires Between Entities
```lua
local out_red = source_entity.get_wire_connector(defines.wire_connector_id.combinator_output_red, true)
local in_red = target_entity.get_wire_connector(defines.wire_connector_id.circuit_red, true)
if out_red and in_red then
  out_red.connect_to(in_red, false, defines.wire_origin.script)
end
```

### Reading Circuit Network Signals
```lua
local function read_input_signals(entity)
  if not entity or not entity.valid then return {} end
  local signals = {}

  local red_conn = entity.get_wire_connector(defines.wire_connector_id.combinator_input_red, false)
  if red_conn then
    local ok, red_net = pcall(function() return red_conn.network end)
    if ok and red_net and red_net.signals then
      for _, sig in pairs(red_net.signals) do
        local key = sig.signal.type .. "/" .. sig.signal.name
        if not signals[key] then signals[key] = { signal = sig.signal, red = 0, green = 0 } end
        signals[key].red = sig.count
      end
    end
  end

  local green_conn = entity.get_wire_connector(defines.wire_connector_id.combinator_input_green, false)
  if green_conn then
    local ok, green_net = pcall(function() return green_conn.network end)
    if ok and green_net and green_net.signals then
      for _, sig in pairs(green_net.signals) do
        local key = sig.signal.type .. "/" .. sig.signal.name
        if not signals[key] then signals[key] = { signal = sig.signal, red = 0, green = 0 } end
        signals[key].green = sig.count
      end
    end
  end

  return signals
end
```

---

## Constant Combinator (Factorio 2.0)

In Factorio 2.0, constant combinators use `sections` instead of the old `parameters`:

```lua
local cb = combinator.get_or_create_control_behavior()
if not cb then return end

if cb.sections_count == 0 then cb.add_section() end
local section = cb.get_section(1)
if not section then return end

-- Clear existing slots
for i = section.filters_count, 1, -1 do
  section.clear_slot(i)
end

-- Write new signals
section.set_slot(1, { value = {type = "item", name = "iron-plate"}, min = 100 })
section.set_slot(2, { value = {type = "virtual", name = "signal-A"}, min = 1 })
```

---

## Inserter Control Behavior

```lua
local behavior = entity.get_or_create_control_behavior()
if behavior then
  behavior.circuit_mode_of_operation = defines.control_behavior.inserter.circuit_mode_of_operation.enable_disable
  behavior.circuit_condition = {
    comparator = ">",
    first_signal = {type = "item", name = "iron-plate"},
    constant = 100,
  }
end
```

---

## Signal Data Format

A signal table looks like:
```lua
{type = "item", name = "iron-plate"}
{type = "fluid", name = "water"}
{type = "virtual", name = "signal-A"}
```

Virtual signals include: `signal-each`, `signal-anything`, `signal-everything`, and `signal-A` through `signal-Z`.

---

## Combinator Mod Patterns

### Hidden Output Entity Pattern
For custom combinators that need to output signals via script:
1. Create a visible decider-combinator entity (has input/output wire connectors)
2. Create a hidden constant-combinator at the same position
3. Wire the hidden combinator's output to the visible entity's output connectors via script
4. Read input signals from the visible entity, evaluate logic, write to hidden combinator

See `switch-combinator` mod in the workspace for a complete implementation.

### Entity Wiring Helper
```lua
local function wire_outputs(visible_entity, hidden_combinator)
  local out_red = visible_entity.get_wire_connector(defines.wire_connector_id.combinator_output_red, true)
  local cc_red = hidden_combinator.get_wire_connector(defines.wire_connector_id.circuit_red, true)
  if out_red and cc_red then
    out_red.connect_to(cc_red, false, defines.wire_origin.script)
  end
  local out_green = visible_entity.get_wire_connector(defines.wire_connector_id.combinator_output_green, true)
  local cc_green = hidden_combinator.get_wire_connector(defines.wire_connector_id.circuit_green, true)
  if out_green and cc_green then
    out_green.connect_to(cc_green, false, defines.wire_origin.script)
  end
end
```
