-- Unit tests for Switch Combinator signal utilities
local test_framework = require("tests.test_framework")
local signal_utils = require("scripts.utils.signal_utils")

local tests = {}

function tests.test_signal_key()
  -- Test valid signal
  local signal = {type = "virtual", name = "signal-checkmark"}
  local key = signal_utils.signal_key(signal)
  test_framework.assert_equal(key, "virtual/signal-checkmark", "Signal key generation")
  
  -- Test nil signal
  local key2 = signal_utils.signal_key(nil)
  test_framework.assert_equal(key2, nil, "Nil signal returns nil")
  
  -- Test signal with missing type
  local signal3 = {name = "signal-checkmark"}
  local key3 = signal_utils.signal_key(signal3)
  test_framework.assert_equal(key3, "item/signal-checkmark", "Signal without type defaults to item")
  
  -- Test signal with missing name
  local signal4 = {type = "virtual"}
  local key4 = signal_utils.signal_key(signal4)
  test_framework.assert_equal(key4, nil, "Signal without name returns nil")
end

function tests.test_signals_equal()
  -- Test equal signals
  local signal1 = {type = "virtual", name = "signal-checkmark"}
  local signal2 = {type = "virtual", name = "signal-checkmark"}
  test_framework.assert_true(signal_utils.signals_equal(signal1, signal2), "Equal signals should be equal")
  
  -- Test different types
  local signal3 = {type = "item", name = "signal-checkmark"}
  test_framework.assert_true(not signal_utils.signals_equal(signal1, signal3), "Different types should not be equal")
  
  -- Test different names
  local signal4 = {type = "virtual", name = "signal-x"}
  test_framework.assert_true(not signal_utils.signals_equal(signal1, signal4), "Different names should not be equal")
  
  -- Test nil signals
  test_framework.assert_true(not signal_utils.signals_equal(nil, signal1), "Nil signal should not equal valid signal")
  test_framework.assert_true(not signal_utils.signals_equal(signal1, nil), "Valid signal should not equal nil signal")

  local rare = {type = "item", name = "iron-plate", quality = "rare"}
  local legendary = {type = "item", name = "iron-plate", quality = "legendary"}
  test_framework.assert_true(signal_utils.signals_equal(rare, rare), "Same quality signals should be equal")
  test_framework.assert_true(not signal_utils.signals_equal(rare, legendary), "Different quality signals should not be equal")
end

function tests.test_signal_quality_key()
  test_framework.assert_equal(
    signal_utils.signal_key({type = "item", name = "iron-plate"}),
    "item/iron-plate",
    "Normal quality keeps the base signal key"
  )
  test_framework.assert_equal(
    signal_utils.signal_key({type = "item", name = "iron-plate", quality = "rare"}),
    "item/iron-plate@rare",
    "Non-normal quality is part of the signal key"
  )
end

function tests.test_compare()
  -- Test greater than
  test_framework.assert_true(signal_utils.compare(5, ">", 3), "5 > 3 should be true")
  test_framework.assert_true(not signal_utils.compare(3, ">", 5), "3 > 5 should be false")
  
  -- Test less than
  test_framework.assert_true(signal_utils.compare(3, "<", 5), "3 < 5 should be true")
  test_framework.assert_true(not signal_utils.compare(5, "<", 3), "5 < 3 should be false")
  
  -- Test equal
  test_framework.assert_true(signal_utils.compare(5, "=", 5), "5 = 5 should be true")
  test_framework.assert_true(not signal_utils.compare(5, "=", 3), "5 = 3 should be false")
  
  -- Test greater or equal
  test_framework.assert_true(signal_utils.compare(5, "≥", 3), "5 ≥ 3 should be true")
  test_framework.assert_true(signal_utils.compare(5, "≥", 5), "5 ≥ 5 should be true")
  test_framework.assert_true(not signal_utils.compare(3, "≥", 5), "3 ≥ 5 should be false")
  
  -- Test less or equal
  test_framework.assert_true(signal_utils.compare(3, "≤", 5), "3 ≤ 5 should be true")
  test_framework.assert_true(signal_utils.compare(5, "≤", 5), "5 ≤ 5 should be true")
  test_framework.assert_true(not signal_utils.compare(5, "≤", 3), "5 ≤ 3 should be false")
  
  -- Test not equal
  test_framework.assert_true(signal_utils.compare(5, "≠", 3), "5 ≠ 3 should be true")
  test_framework.assert_true(not signal_utils.compare(5, "≠", 5), "5 ≠ 5 should be false")
end

function tests.test_merge_outputs()
  -- Test merging two dictionaries
  local base = {
    ["virtual/signal-A"] = {signal = {type = "virtual", name = "signal-A"}, count = 5},
    ["virtual/signal-B"] = {signal = {type = "virtual", name = "signal-B"}, count = 3}
  }
  
  local addition = {
    ["virtual/signal-A"] = {signal = {type = "virtual", name = "signal-A"}, count = 2},
    ["virtual/signal-C"] = {signal = {type = "virtual", name = "signal-C"}, count = 7}
  }
  
  local result = signal_utils.merge_outputs(base, addition)
  
  test_framework.assert_equal(result["virtual/signal-A"].count, 7, "Signal A should be summed")
  test_framework.assert_equal(result["virtual/signal-B"].count, 3, "Signal B should be unchanged")
  test_framework.assert_equal(result["virtual/signal-C"].count, 7, "Signal C should be added")
end

function tests.test_dict_to_array()
  -- Test conversion
  local signals_dict = {
    ["virtual/signal-A"] = {signal = {type = "virtual", name = "signal-A"}, count = 5},
    ["virtual/signal-B"] = {signal = {type = "virtual", name = "signal-B"}, count = 0},
    ["virtual/signal-C"] = {signal = {type = "virtual", name = "signal-C"}, count = 3}
  }
  
  local result = signal_utils.dict_to_array(signals_dict)
  
  -- Should only include non-zero signals
  test_framework.assert_equal(#result, 2, "Should only include non-zero signals")
  
  -- Check that signals are present
  local found_A = false
  local found_C = false
  for _, entry in ipairs(result) do
    if entry.signal.name == "signal-A" then found_A = true end
    if entry.signal.name == "signal-C" then found_C = true end
  end
  
  test_framework.assert_true(found_A, "Signal A should be in array")
  test_framework.assert_true(found_C, "Signal C should be in array")
end

-- Run all tests
function tests.run_all()
  local pf = test_framework._print_func or game.print
  pf("[TEST] Running Signal Utils Tests...")
  
  test_framework.run_test("Signal Key", tests.test_signal_key)
  test_framework.run_test("Signals Equal", tests.test_signals_equal)
  test_framework.run_test("Signal Quality Key", tests.test_signal_quality_key)
  test_framework.run_test("Compare", tests.test_compare)
  test_framework.run_test("Merge Outputs", tests.test_merge_outputs)
  test_framework.run_test("Dict to Array", tests.test_dict_to_array)
  
  test_framework.summary()
end

return tests
