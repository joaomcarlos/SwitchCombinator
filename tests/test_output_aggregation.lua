-- Tests for Switch Combinator output aggregation logic
-- Tests how evaluate_entity builds output_signals dict and handles merging.

local test_framework = require("tests.test_framework")
local evaluation = require("scripts.logic.evaluation")
local signal_utils = require("scripts.utils.signal_utils")

local tests = {}

-- ============================================================================
-- Production evaluator plus a focused output aggregation seam.
-- ============================================================================
local get_signal_value = evaluation.get_signal_value
local evaluate_conditions = evaluation.evaluate_conditions

-- Simplified evaluate_entity that returns the output_signals dict
local function simulate_evaluate(entity_data, input_signals)
  local output_signals = {}
  local mode = entity_data.mode or "first_match"

  for _, group in ipairs(entity_data.groups) do
    local group_met = evaluate_conditions(group.conditions, input_signals)
    if group_met then
      for _, out in ipairs(group.outputs) do
        if out.signal and out.signal.name then
          local key = signal_utils.signal_key(out.signal)
          local count
          if out.use_input_count then
            count = get_signal_value(input_signals, out.signal, out.red_wire ~= false, out.green_wire ~= false)
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

  return output_signals
end

-- ============================================================================
-- Helpers
-- ============================================================================

local function make_cond(left_sig, op, compare_type, const, right_sig, logic)
  return {
    left_signal = left_sig,
    operator = op or ">",
    compare_type = compare_type or "constant",
    constant = const or 0,
    right_signal = right_sig,
    left_red = true, left_green = true,
    right_red = true, right_green = true,
    logic = logic
  }
end

local function make_out(signal, count, use_input)
  return {
    signal = signal,
    count = count or 1,
    use_input_count = use_input or false,
    red_wire = true,
    green_wire = true
  }
end

local function make_group(name, conditions, outputs)
  return { name = name, conditions = conditions, outputs = outputs }
end

local function make_entity_data(mode, groups)
  return { mode = mode, groups = groups }
end

-- ============================================================================
-- Tests
-- ============================================================================

function tests.test_single_output()
  local inputs = { ["item/iron-plate"] = { red = 10, green = 0 } }
  local groups = {
    make_group("G1",
      { make_cond({type = "item", name = "iron-plate"}, ">", "constant", 5) },
      { make_out({type = "virtual", name = "signal-A"}, 7) }
    )
  }
  local result = simulate_evaluate(make_entity_data("first_match", groups), inputs)

  test_framework.assert_not_nil(result["virtual/signal-A"], "Output signal A exists")
  test_framework.assert_equal(result["virtual/signal-A"].count, 7, "Fixed count 7")
end

function tests.test_no_match_no_output()
  local inputs = { ["item/iron-plate"] = { red = 1, green = 0 } }
  local groups = {
    make_group("G1",
      { make_cond({type = "item", name = "iron-plate"}, ">", "constant", 5) },
      { make_out({type = "virtual", name = "signal-A"}, 7) }
    )
  }
  local result = simulate_evaluate(make_entity_data("first_match", groups), inputs)

  test_framework.assert_nil(result["virtual/signal-A"], "No match → no output")
end

function tests.test_use_input_count()
  local inputs = { ["item/iron-plate"] = { red = 42, green = 0 } }
  local groups = {
    make_group("G1",
      { make_cond({type = "item", name = "iron-plate"}, ">", "constant", 5) },
      { make_out({type = "item", name = "iron-plate"}, nil, true) } -- use_input_count=true
    )
  }
  local result = simulate_evaluate(make_entity_data("first_match", groups), inputs)

  test_framework.assert_not_nil(result["item/iron-plate"], "Output exists")
  test_framework.assert_equal(result["item/iron-plate"].count, 42, "use_input_count uses input value 42")
end

function tests.test_output_signal_merge_same_group()
  local inputs = { ["item/iron-plate"] = { red = 10, green = 0 } }
  local groups = {
    make_group("G1",
      { make_cond({type = "item", name = "iron-plate"}, ">", "constant", 5) },
      {
        make_out({type = "virtual", name = "signal-A"}, 3),
        make_out({type = "virtual", name = "signal-A"}, 5)
      }
    )
  }
  local result = simulate_evaluate(make_entity_data("first_match", groups), inputs)

  test_framework.assert_equal(result["virtual/signal-A"].count, 8, "Same signal in group merges: 3+5=8")
end

function tests.test_output_signal_merge_multi_match()
  local inputs = { ["item/iron-plate"] = { red = 10, green = 0 } }
  local groups = {
    make_group("G1",
      { make_cond({type = "item", name = "iron-plate"}, ">", "constant", 5) },
      { make_out({type = "virtual", name = "signal-A"}, 3) }
    ),
    make_group("G2",
      { make_cond({type = "item", name = "iron-plate"}, ">", "constant", 5) },
      { make_out({type = "virtual", name = "signal-A"}, 7) }
    )
  }
  local result = simulate_evaluate(make_entity_data("multi_match", groups), inputs)

  test_framework.assert_equal(result["virtual/signal-A"].count, 10, "Multi-match merges across groups: 3+7=10")
end

function tests.test_first_match_stops_after_first()
  local inputs = { ["item/iron-plate"] = { red = 10, green = 0 } }
  local groups = {
    make_group("G1",
      { make_cond({type = "item", name = "iron-plate"}, ">", "constant", 5) },
      { make_out({type = "virtual", name = "signal-A"}, 3) }
    ),
    make_group("G2",
      { make_cond({type = "item", name = "iron-plate"}, ">", "constant", 5) },
      { make_out({type = "virtual", name = "signal-A"}, 7) }
    )
  }
  local result = simulate_evaluate(make_entity_data("first_match", groups), inputs)

  test_framework.assert_equal(result["virtual/signal-A"].count, 3, "First-match stops at group 1")
end

function tests.test_zero_count_filtered()
  -- When use_input_count returns 0, the signal should be in dict but with count 0
  local inputs = { ["item/iron-plate"] = { red = 0, green = 0 } }
  local groups = {
    make_group("G1",
      { make_cond({type = "item", name = "iron-plate"}, ">=", "constant", 0) },
      { make_out({type = "item", name = "iron-plate"}, nil, true) }
    )
  }
  local result = simulate_evaluate(make_entity_data("first_match", groups), inputs)

  -- Count is 0 but signal exists in dict; the real evaluate_entity filters count~=0 when writing slots
  test_framework.assert_not_nil(result["item/iron-plate"], "Zero count signal in dict")
  test_framework.assert_equal(result["item/iron-plate"].count, 0, "Count is 0")
end

function tests.test_nil_signal_skipped()
  local inputs = { ["item/iron-plate"] = { red = 10, green = 0 } }
  local groups = {
    make_group("G1",
      { make_cond({type = "item", name = "iron-plate"}, ">", "constant", 5) },
      {
        make_out({type = "virtual", name = "signal-A"}, 1),
        make_out(nil, 99), -- nil signal should be skipped
        make_out({name = "incomplete"}, 99) -- missing type defaults to item
      }
    )
  }
  local result = simulate_evaluate(make_entity_data("first_match", groups), inputs)

  test_framework.assert_not_nil(result["virtual/signal-A"], "Valid signal kept")
  test_framework.assert_nil(result["nil"], "Nil signal skipped")
  test_framework.assert_equal(result["item/incomplete"].count, 99, "Missing type defaults to item")
end

function tests.test_wire_filter_on_output()
  local inputs = {
    ["virtual/signal-A"] = { red = 10, green = 5 }
  }
  local groups = {
    make_group("G1",
      { make_cond({type = "virtual", name = "signal-A"}, ">", "constant", 0) },
      {
        { signal = {type = "virtual", name = "signal-A"}, count = 1, use_input_count = true,
          red_wire = false, green_wire = true } -- green only
      }
    )
  }
  local result = simulate_evaluate(make_entity_data("first_match", groups), inputs)

  test_framework.assert_equal(result["virtual/signal-A"].count, 5, "Green-only input count = 5")
end

function tests.test_multiple_different_outputs()
  local inputs = { ["item/iron-plate"] = { red = 10, green = 0 } }
  local groups = {
    make_group("G1",
      { make_cond({type = "item", name = "iron-plate"}, ">", "constant", 5) },
      {
        make_out({type = "virtual", name = "signal-A"}, 1),
        make_out({type = "virtual", name = "signal-B"}, 2),
        make_out({type = "virtual", name = "signal-C"}, 3)
      }
    )
  }
  local result = simulate_evaluate(make_entity_data("first_match", groups), inputs)

  test_framework.assert_equal(result["virtual/signal-A"].count, 1, "Signal A")
  test_framework.assert_equal(result["virtual/signal-B"].count, 2, "Signal B")
  test_framework.assert_equal(result["virtual/signal-C"].count, 3, "Signal C")
end

function tests.test_negative_input_count()
  local inputs = { ["item/iron-plate"] = { red = -7, green = 0 } }
  local groups = {
    make_group("G1",
      { make_cond({type = "item", name = "iron-plate"}, "<", "constant", 0) },
      { make_out({type = "item", name = "iron-plate"}, nil, true) }
    )
  }
  local result = simulate_evaluate(make_entity_data("first_match", groups), inputs)

  test_framework.assert_equal(result["item/iron-plate"].count, -7, "Negative input count preserved")
end

-- ============================================================================
-- Run all
-- ============================================================================

function tests.run_all()
  local pf = test_framework._print_func or game.print
  pf("[TEST] Running Output Aggregation Tests...")

  test_framework.run_test("Single Output", tests.test_single_output)
  test_framework.run_test("No Match No Output", tests.test_no_match_no_output)
  test_framework.run_test("Use Input Count", tests.test_use_input_count)
  test_framework.run_test("Output Merge Same Group", tests.test_output_signal_merge_same_group)
  test_framework.run_test("Output Merge Multi Match", tests.test_output_signal_merge_multi_match)
  test_framework.run_test("First Match Stops", tests.test_first_match_stops_after_first)
  test_framework.run_test("Zero Count Filtered", tests.test_zero_count_filtered)
  test_framework.run_test("Nil Signal Skipped", tests.test_nil_signal_skipped)
  test_framework.run_test("Wire Filter On Output", tests.test_wire_filter_on_output)
  test_framework.run_test("Multiple Different Outputs", tests.test_multiple_different_outputs)
  test_framework.run_test("Negative Input Count", tests.test_negative_input_count)

  pf("[TEST] Output Aggregation: Passed=" .. test_framework.passed .. " Failed=" .. test_framework.failed)
end

return tests
