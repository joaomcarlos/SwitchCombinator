-- Unit tests for Switch Combinator core evaluation logic
-- Tests compare_values, evaluate_single_condition, and evaluate_conditions
-- These are pure Lua functions copied from control.lua for isolated testing.

local test_framework = require("tests.test_framework")
local evaluation = require("scripts.logic.evaluation")

local tests = {}

-- ============================================================================
-- Shared production evaluator (no Factorio API calls)
-- ============================================================================
local compare_values = evaluation.compare_values
local evaluate_single_condition = evaluation.evaluate_single_condition
local evaluate_conditions = evaluation.evaluate_conditions

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

-- ============================================================================
-- Tests: compare_values
-- ============================================================================

function tests.test_compare_values_all_operators()
  -- Boundary value tests for every operator
  test_framework.assert_true(compare_values(5, ">", 3),  "5 > 3")
  test_framework.assert_false(compare_values(3, ">", 5), "3 > 5")
  test_framework.assert_false(compare_values(5, ">", 5), "5 > 5")

  test_framework.assert_true(compare_values(3, "<", 5),  "3 < 5")
  test_framework.assert_false(compare_values(5, "<", 3), "5 < 3")
  test_framework.assert_false(compare_values(5, "<", 5), "5 < 5")

  test_framework.assert_true(compare_values(5, "=", 5),  "5 = 5")
  test_framework.assert_false(compare_values(5, "=", 3), "5 = 3")

  test_framework.assert_true(compare_values(5, ">=", 5),  "5 >= 5")
  test_framework.assert_true(compare_values(5, ">=", 3), "5 >= 3")
  test_framework.assert_false(compare_values(3, ">=", 5), "3 >= 5")

  test_framework.assert_true(compare_values(5, "<=", 5),  "5 <= 5")
  test_framework.assert_true(compare_values(3, "<=", 5),  "3 <= 5")
  test_framework.assert_false(compare_values(5, "<=", 3), "5 <= 3")

  test_framework.assert_true(compare_values(5, "!=", 3),  "5 != 3")
  test_framework.assert_false(compare_values(5, "!=", 5), "5 != 5")

  -- Unknown operator defaults to false
  test_framework.assert_false(compare_values(5, "???", 3), "Unknown operator returns false")
end

function tests.test_compare_values_negative_zero()
  test_framework.assert_true(compare_values(-5, "<", 0),  "-5 < 0")
  test_framework.assert_true(compare_values(0, "=", 0),    "0 = 0")
  test_framework.assert_true(compare_values(-10, ">=", -10), "-10 >= -10")
  test_framework.assert_false(compare_values(0, ">", 0),   "0 > 0 is false")
end

-- ============================================================================
-- Tests: evaluate_single_condition
-- ============================================================================

function tests.test_evaluate_single_condition_constant()
  local inputs = { ["item/iron-plate"] = { red = 100, green = 0 } }

  local cond = make_cond({type = "item", name = "iron-plate"}, ">", "constant", 50, nil, nil)
  test_framework.assert_true(evaluate_single_condition(cond, inputs), "iron-plate(100) > 50")

  cond.constant = 100
  test_framework.assert_false(evaluate_single_condition(cond, inputs), "iron-plate(100) > 100")

  cond.operator = ">="
  test_framework.assert_true(evaluate_single_condition(cond, inputs), "iron-plate(100) >= 100")

  cond.operator = "="
  test_framework.assert_true(evaluate_single_condition(cond, inputs), "iron-plate(100) = 100")

  cond.constant = 200
  cond.operator = "="
  test_framework.assert_false(evaluate_single_condition(cond, inputs), "iron-plate(100) = 200")
end

function tests.test_evaluate_single_condition_signal_compare()
  local inputs = {
    ["item/iron-plate"] = { red = 100, green = 0 },
    ["virtual/signal-A"] = { red = 50, green = 0 }
  }

  local cond = make_cond({type = "item", name = "iron-plate"}, ">", "signal", 0, {type = "virtual", name = "signal-A"}, nil)
  test_framework.assert_true(evaluate_single_condition(cond, inputs), "iron-plate(100) > signal-A(50)")

  inputs["virtual/signal-A"] = { red = 200, green = 0 }
  test_framework.assert_false(evaluate_single_condition(cond, inputs), "iron-plate(100) > signal-A(200)")
end

function tests.test_evaluate_single_condition_nil_left_signal()
  local cond = make_cond(nil, ">", "constant", 0, nil, nil)
  test_framework.assert_false(evaluate_single_condition(cond, {}), "Nil left signal → false")
end

function tests.test_evaluate_single_condition_missing_input()
  local cond = make_cond({type = "item", name = "iron-plate"}, ">", "constant", 0, nil, nil)
  test_framework.assert_false(evaluate_single_condition(cond, {}), "Missing input signal → false (0 > 0)")
end

function tests.test_evaluate_signal_type_and_quality_identity()
  local inputs = {
    ["item/iron-plate"] = {red = 3, green = 0},
    ["item/iron-plate@rare"] = {red = 7, green = 0}
  }

  local rare_condition = make_cond(
    {type = nil, name = "iron-plate", quality = "rare"},
    ">",
    "constant",
    5,
    nil,
    nil
  )
  test_framework.assert_true(
    evaluate_single_condition(rare_condition, inputs),
    "Missing item type and non-normal quality resolve to the distinct input"
  )

  rare_condition.left_signal.quality = "legendary"
  test_framework.assert_false(
    evaluate_single_condition(rare_condition, inputs),
    "Different quality does not reuse the rare input"
  )
end

function tests.test_evaluate_single_condition_wire_filters()
  local inputs = {
    ["item/iron-plate"] = { red = 100, green = 5 }
  }

  -- Red only
  local cond = make_cond({type = "item", name = "iron-plate"}, ">", "constant", 50, nil, nil)
  cond.left_red = true
  cond.left_green = false
  test_framework.assert_true(evaluate_single_condition(cond, inputs), "Red-only 100 > 50")

  -- Green only
  cond.left_red = false
  cond.left_green = true
  test_framework.assert_false(evaluate_single_condition(cond, inputs), "Green-only 5 > 50")

  -- Both
  cond.left_red = true
  cond.left_green = true
  test_framework.assert_true(evaluate_single_condition(cond, inputs), "Both 105 > 50")
end

-- ============================================================================
-- Tests: evaluate_conditions (AND/OR logic)
-- ============================================================================

function tests.test_evaluate_conditions_empty()
  test_framework.assert_false(evaluate_conditions({}, {}), "Empty conditions → false")
end

function tests.test_evaluate_conditions_single()
  local inputs = { ["item/iron-plate"] = { red = 10, green = 0 } }
  local conds = { make_cond({type = "item", name = "iron-plate"}, ">", "constant", 5, nil, nil) }
  test_framework.assert_true(evaluate_conditions(conds, inputs), "Single true condition")

  conds[1].constant = 20
  test_framework.assert_false(evaluate_conditions(conds, inputs), "Single false condition")
end

function tests.test_evaluate_conditions_and()
  local inputs = {
    ["item/iron-plate"] = { red = 10, green = 0 },
    ["item/copper-plate"] = { red = 8, green = 0 }
  }
  local conds = {
    make_cond({type = "item", name = "iron-plate"}, ">", "constant", 5, nil, nil),
    make_cond({type = "item", name = "copper-plate"}, ">", "constant", 5, nil, "and")
  }
  test_framework.assert_true(evaluate_conditions(conds, inputs), "Both true AND → true")

  conds[2].constant = 20
  test_framework.assert_false(evaluate_conditions(conds, inputs), "Second false AND → false")
end

function tests.test_evaluate_conditions_or()
  local inputs = {
    ["item/iron-plate"] = { red = 10, green = 0 },
    ["item/copper-plate"] = { red = 2, green = 0 }
  }
  local conds = {
    make_cond({type = "item", name = "iron-plate"}, ">", "constant", 5, nil, nil),
    make_cond({type = "item", name = "copper-plate"}, ">", "constant", 5, nil, "or")
  }
  test_framework.assert_true(evaluate_conditions(conds, inputs), "First true, second false OR → true")

  conds[1].constant = 20
  test_framework.assert_false(evaluate_conditions(conds, inputs), "Both false OR → false")
end

function tests.test_evaluate_conditions_mixed_and_or()
  local inputs = {
    ["item/iron-plate"] = { red = 10, green = 0 },
    ["item/copper-plate"] = { red = 2, green = 0 },
    ["virtual/signal-A"] = { red = 100, green = 0 }
  }
  -- (iron > 5 AND copper > 5) OR signal-A > 50
  local conds = {
    make_cond({type = "item", name = "iron-plate"}, ">", "constant", 5, nil, nil),
    make_cond({type = "item", name = "copper-plate"}, ">", "constant", 5, nil, "and"),
    make_cond({type = "virtual", name = "signal-A"}, ">", "constant", 50, nil, "or")
  }
  -- iron=10>5 true, copper=2>5 false → AND-group false
  -- signal-A=100>50 true → OR makes whole thing true
  test_framework.assert_true(evaluate_conditions(conds, inputs), "(T AND F) OR T → true")

  -- Now make signal-A false too
  conds[3].constant = 200
  test_framework.assert_false(evaluate_conditions(conds, inputs), "(T AND F) OR F → false")
end

function tests.test_evaluate_conditions_complex_groups()
  -- (A AND B) OR (C AND D) OR E
  local inputs = {
    ["virtual/signal-A"] = { red = 1, green = 0 },
    ["virtual/signal-B"] = { red = 1, green = 0 },
    ["virtual/signal-C"] = { red = 0, green = 0 },
    ["virtual/signal-D"] = { red = 1, green = 0 },
    ["virtual/signal-E"] = { red = 0, green = 0 }
  }
  local conds = {
    make_cond({type = "virtual", name = "signal-A"}, "=", "constant", 1, nil, nil),
    make_cond({type = "virtual", name = "signal-B"}, "=", "constant", 1, nil, "and"),
    make_cond({type = "virtual", name = "signal-C"}, "=", "constant", 1, nil, "or"),
    make_cond({type = "virtual", name = "signal-D"}, "=", "constant", 1, nil, "and"),
    make_cond({type = "virtual", name = "signal-E"}, "=", "constant", 1, nil, "or")
  }
  -- (1 AND 1)=T OR (0 AND 1)=F OR 0 → true because first group is true
  test_framework.assert_true(evaluate_conditions(conds, inputs), "(1 AND 1) OR (0 AND 1) OR 0 → true")

  -- Now make A false: (0 AND 1)=F OR (0 AND 1)=F OR 0 → false
  inputs["virtual/signal-A"] = { red = 0, green = 0 }
  test_framework.assert_false(evaluate_conditions(conds, inputs), "(0 AND 1) OR (0 AND 1) OR 0 → false")
end

function tests.test_compare_floats()
  test_framework.assert_true(compare_values(1.5, ">", 1.0), "1.5 > 1.0")
  test_framework.assert_true(compare_values(0.5 + 0.5, "=", 1.0), "Exact float equality")
  test_framework.assert_false(compare_values(1.0, "<", 1.0), "1.0 < 1.0 false")
end

function tests.test_all_false_or_chain()
  local inputs = {}
  local conds = {
    make_cond({type = "item", name = "a"}, ">", "constant", 0, nil, nil),
    make_cond({type = "item", name = "b"}, ">", "constant", 0, nil, "or"),
    make_cond({type = "item", name = "c"}, ">", "constant", 0, nil, "or")
  }
  test_framework.assert_false(evaluate_conditions(conds, inputs), "All false OR chain → false")
end

function tests.test_all_true_and_chain()
  local inputs = {
    ["item/a"] = { red = 5, green = 0 },
    ["item/b"] = { red = 5, green = 0 },
    ["item/c"] = { red = 5, green = 0 }
  }
  local conds = {
    make_cond({type = "item", name = "a"}, ">", "constant", 0, nil, nil),
    make_cond({type = "item", name = "b"}, ">", "constant", 0, nil, "and"),
    make_cond({type = "item", name = "c"}, ">", "constant", 0, nil, "and")
  }
  test_framework.assert_true(evaluate_conditions(conds, inputs), "All true AND chain → true")
end

function tests.test_signal_vs_same_signal()
  local inputs = {
    ["virtual/signal-A"] = { red = 10, green = 0 }
  }
  local conds = {
    make_cond({type = "virtual", name = "signal-A"}, "=", "signal", 0, {type = "virtual", name = "signal-A"}, nil)
  }
  test_framework.assert_true(evaluate_conditions(conds, inputs), "signal-A = signal-A (10 = 10)")
end

-- ============================================================================
-- Run all
-- ============================================================================

function tests.run_all()
  local pf = test_framework._print_func or game.print
  pf("[TEST] Running Evaluation Logic Tests...")

  test_framework.run_test("Compare Values All Operators", tests.test_compare_values_all_operators)
  test_framework.run_test("Compare Values Negative/Zero", tests.test_compare_values_negative_zero)
  test_framework.run_test("Evaluate Single Condition (Constant)", tests.test_evaluate_single_condition_constant)
  test_framework.run_test("Evaluate Single Condition (Signal Compare)", tests.test_evaluate_single_condition_signal_compare)
  test_framework.run_test("Evaluate Single Condition (Nil Left Signal)", tests.test_evaluate_single_condition_nil_left_signal)
  test_framework.run_test("Evaluate Single Condition (Missing Input)", tests.test_evaluate_single_condition_missing_input)
  test_framework.run_test("Evaluate Signal Type And Quality Identity", tests.test_evaluate_signal_type_and_quality_identity)
  test_framework.run_test("Evaluate Single Condition (Wire Filters)", tests.test_evaluate_single_condition_wire_filters)
  test_framework.run_test("Evaluate Conditions (Empty)", tests.test_evaluate_conditions_empty)
  test_framework.run_test("Evaluate Conditions (Single)", tests.test_evaluate_conditions_single)
  test_framework.run_test("Evaluate Conditions (AND)", tests.test_evaluate_conditions_and)
  test_framework.run_test("Evaluate Conditions (OR)", tests.test_evaluate_conditions_or)
  test_framework.run_test("Evaluate Conditions (Mixed AND/OR)", tests.test_evaluate_conditions_mixed_and_or)
  test_framework.run_test("Evaluate Conditions (Complex Groups)", tests.test_evaluate_conditions_complex_groups)
  test_framework.run_test("Compare Floats", tests.test_compare_floats)
  test_framework.run_test("All False OR Chain", tests.test_all_false_or_chain)
  test_framework.run_test("All True AND Chain", tests.test_all_true_and_chain)
  test_framework.run_test("Signal vs Same Signal", tests.test_signal_vs_same_signal)

  pf("[TEST] Evaluation: Passed=" .. test_framework.passed .. " Failed=" .. test_framework.failed)
end

return tests
