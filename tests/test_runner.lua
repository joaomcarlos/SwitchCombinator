-- Test runner for Switch Combinator mod
-- Run tests with /run-tests command or automatically on init

local test_framework = require("tests.test_framework")
local test_signal_utils = require("tests.test_signal_utils")
local test_evaluation = require("tests.test_evaluation")
local test_entity_lifecycle = require("tests.test_entity_lifecycle")
local test_edge_cases = require("tests.test_edge_cases")
local test_output_aggregation = require("tests.test_output_aggregation")
local test_state_deep = require("tests.test_state_deep")
local test_stress = require("tests.test_stress")
local test_signal_reading = require("tests.test_signal_reading")
local test_integration = require("tests.test_integration")
local test_ui = require("tests.test_ui")

-- Run all tests function
local function run_all_tests()
  local pf = test_framework._print_func or game.print

  pf("[TEST] Starting Switch Combinator Test Suite...")
  pf("[TEST] ======================================")

  test_framework.reset()
  test_signal_utils.run_all()

  test_framework.reset()
  test_evaluation.run_all()

  test_framework.reset()
  test_entity_lifecycle.run_all()

  test_framework.reset()
  test_edge_cases.run_all()

  test_framework.reset()
  test_output_aggregation.run_all()

  test_framework.reset()
  test_state_deep.run_all()

  test_framework.reset()
  test_stress.run_all()

  test_framework.reset()
  test_signal_reading.run_all()

  test_framework.reset()
  test_integration.run_all()

  test_framework.reset()
  test_ui.run_all()

  pf("[TEST] ======================================")
  pf("[TEST] Final Results:")
  pf("[TEST] Total Passed: " .. test_framework.passed)
  pf("[TEST] Total Failed: " .. test_framework.failed)
  pf(test_framework.failed == 0 and "[TEST] ✓ All tests passed!" or "[TEST] ✗ Some tests failed.")
end

-- Register command if commands system is available
if commands then
  commands.add_command("run-tests", "Run all Switch Combinator tests", run_all_tests)
else
  -- No fallback - tests must be run manually via GUI or remote interface
end

-- Export the test runner
return {
  run_all = run_all_tests
}
