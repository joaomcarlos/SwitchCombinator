-- Tests for Switch Combinator signal reading logic
-- Tests get_signal_value and input signal aggregation without real wiring.

local test_framework = require("tests.test_framework")

local tests = {}

-- ============================================================================
-- Pure copies from control.lua (no Factorio API calls)
-- ============================================================================

local function get_signal_value(input_signals, signal, use_red, use_green)
  if not signal or not signal.name or not signal.type then return 0 end
  local key = signal.type .. "/" .. signal.name
  local entry = input_signals[key]
  if not entry then return 0 end
  local val = 0
  if use_red and type(entry.red) == "number" then val = val + entry.red end
  if use_green and type(entry.green) == "number" then val = val + entry.green end
  return val
end

-- ============================================================================
-- Tests
-- ============================================================================

function tests.test_get_signal_value_basic()
  local inputs = {
    ["item/iron-plate"] = { red = 100, green = 50 }
  }

  local signal = {type = "item", name = "iron-plate"}
  test_framework.assert_equal(get_signal_value(inputs, signal, true, true), 150, "Both wires: 100+50=150")
  test_framework.assert_equal(get_signal_value(inputs, signal, true, false), 100, "Red only: 100")
  test_framework.assert_equal(get_signal_value(inputs, signal, false, true), 50, "Green only: 50")
  test_framework.assert_equal(get_signal_value(inputs, signal, false, false), 0, "Neither: 0")
end

function tests.test_get_signal_value_missing_signal()
  local inputs = {
    ["item/iron-plate"] = { red = 100, green = 50 }
  }

  local signal = {type = "item", name = "copper-plate"}
  test_framework.assert_equal(get_signal_value(inputs, signal, true, true), 0, "Missing signal → 0")
end

function tests.test_get_signal_value_nil_signal()
  local inputs = { ["item/iron-plate"] = { red = 100, green = 50 } }

  test_framework.assert_equal(get_signal_value(inputs, nil, true, true), 0, "Nil signal → 0")
  test_framework.assert_equal(get_signal_value(inputs, {}, true, true), 0, "Empty signal → 0")
  test_framework.assert_equal(get_signal_value(inputs, {name = "x"}, true, true), 0, "Missing type → 0")
  test_framework.assert_equal(get_signal_value(inputs, {type = "item"}, true, true), 0, "Missing name → 0")
end

function tests.test_get_signal_value_zero_inputs()
  local inputs = {
    ["item/iron-plate"] = { red = 0, green = 0 }
  }

  local signal = {type = "item", name = "iron-plate"}
  test_framework.assert_equal(get_signal_value(inputs, signal, true, true), 0, "Zero values → 0")
end

function tests.test_get_signal_value_negative()
  local inputs = {
    ["virtual/signal-A"] = { red = -10, green = -5 }
  }

  local signal = {type = "virtual", name = "signal-A"}
  test_framework.assert_equal(get_signal_value(inputs, signal, true, true), -15, "Negative sum: -10 + -5 = -15")
  test_framework.assert_equal(get_signal_value(inputs, signal, true, false), -10, "Red only negative")
end

function tests.test_get_signal_value_large_numbers()
  local inputs = {
    ["item/iron-plate"] = { red = 1000000, green = 2000000 }
  }

  local signal = {type = "item", name = "iron-plate"}
  test_framework.assert_equal(get_signal_value(inputs, signal, true, true), 3000000, "Large number sum")
end

function tests.test_get_signal_value_virtual_signal()
  local inputs = {
    ["virtual/signal-checkmark"] = { red = 1, green = 0 }
  }

  local signal = {type = "virtual", name = "signal-checkmark"}
  test_framework.assert_equal(get_signal_value(inputs, signal, true, true), 1, "Virtual signal read")
end

function tests.test_get_signal_value_fluid_signal()
  local inputs = {
    ["fluid/water"] = { red = 500, green = 0 }
  }

  local signal = {type = "fluid", name = "water"}
  test_framework.assert_equal(get_signal_value(inputs, signal, true, true), 500, "Fluid signal read")
end

function tests.test_get_signal_value_empty_networks()
  local inputs = {}

  local signal = {type = "item", name = "iron-plate"}
  test_framework.assert_equal(get_signal_value(inputs, signal, true, true), 0, "Empty inputs → 0")
end

function tests.test_signal_key_formatting()
  local signal = {type = "item", name = "iron-plate"}
  local key = signal.type .. "/" .. signal.name
  test_framework.assert_equal(key, "item/iron-plate", "Key format")
end

-- ============================================================================
-- Run all
-- ============================================================================

function tests.run_all()
  local pf = test_framework._print_func or game.print
  pf("[TEST] Running Signal Reading Tests...")

  test_framework.run_test("Get Signal Value Basic", tests.test_get_signal_value_basic)
  test_framework.run_test("Get Signal Value Missing", tests.test_get_signal_value_missing_signal)
  test_framework.run_test("Get Signal Value Nil", tests.test_get_signal_value_nil_signal)
  test_framework.run_test("Get Signal Value Zero", tests.test_get_signal_value_zero_inputs)
  test_framework.run_test("Get Signal Value Negative", tests.test_get_signal_value_negative)
  test_framework.run_test("Get Signal Value Large", tests.test_get_signal_value_large_numbers)
  test_framework.run_test("Get Signal Value Virtual", tests.test_get_signal_value_virtual_signal)
  test_framework.run_test("Get Signal Value Fluid", tests.test_get_signal_value_fluid_signal)
  test_framework.run_test("Get Signal Value Empty Networks", tests.test_get_signal_value_empty_networks)
  test_framework.run_test("Signal Key Formatting", tests.test_signal_key_formatting)

  pf("[TEST] Signal Reading: Passed=" .. test_framework.passed .. " Failed=" .. test_framework.failed)
end

return tests
