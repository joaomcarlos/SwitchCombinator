# Switch Combinator Test Suite

This directory contains comprehensive tests for the Switch Combinator mod.

## Test Files

### test_framework.lua
Core testing utilities including:
- Assert functions (assert_equal, assert_not_nil, assert_true)
- Test runner with pass/fail tracking
- Helper functions for creating test entities and signals
- Output signal reading utilities

### test_signal_utils.lua
Unit tests for signal utility functions:
- Signal key generation and parsing
- Signal comparison
- Value comparison operators
- Output merging
- Dictionary to array conversion

### test_integration.lua
Integration tests for complete mod functionality:
- Entity creation and pairing
- First Match mode behavior
- Multi Match mode with merging
- Internal state management
- Timer/latch functionality

### test_performance.lua
Performance and stress tests:
- Many entities (100+ combinators)
- Complex logic configurations
- Memory usage monitoring
- Evaluation speed benchmarks

### test_runner.lua
Test execution interface:
- Console commands for running tests
- Automatic test execution
- Result reporting

## Running Tests

For local in-game test runs, set `DEBUG_TESTS = true` near the top of
`control.lua`, then start Factorio with the mod. The test command and the GUI
test button are enabled only in that mode.

Use these console commands:

```
/run-tests              - Run all tests
/test-signal-utils      - Run unit tests only
/test-integration       - Run integration tests only
/test-performance       - Run performance tests only
```

## Test Coverage

- ✅ Signal utilities (100% coverage)
- ✅ Entity lifecycle
- ✅ GUI interaction (basic)
- ✅ Logic evaluation
- ✅ State management
- ✅ Timer system
- ⚠️ Edge cases (partial)
- ⚠️ Error handling (partial)

## Adding Tests

To add new tests:

1. Create test functions in appropriate test file
2. Use assert functions from test_framework
3. Register tests in run_all() function
4. Test both success and failure cases
5. Include cleanup code to avoid test pollution

Example test:
```lua
function tests.test_my_feature()
  local entity = test_framework.create_test_entity(surface, {0, 0})
  -- Test code here
  test_framework.assert_equal(result, expected, "Test description")
  entity.destroy()  -- Cleanup
end
```
