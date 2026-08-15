-- Test framework for Switch Combinator mod

local test_framework = {}

test_framework.tests = {}
test_framework.passed = 0
test_framework.failed = 0

-- Module-level print function (set before test runs, never stored in storage)
test_framework._print_func = nil

local function pf(msg)
  if test_framework._print_func then
    test_framework._print_func(msg)
  elseif game then
    game.print(msg)
  end
end

function test_framework.assert_equal(actual, expected, message)
  if actual == expected then return true end
  test_framework.failed = test_framework.failed + 1
  pf("[TEST FAIL] " .. (message or "Assertion failed") .. ": Expected " .. tostring(expected) .. ", got " .. tostring(actual))
  return false
end

function test_framework.assert_not_nil(value, message)
  if value ~= nil then return true end
  test_framework.failed = test_framework.failed + 1
  pf("[TEST FAIL] " .. (message or "Value should not be nil"))
  return false
end

function test_framework.assert_true(condition, message)
  if condition then return true end
  test_framework.failed = test_framework.failed + 1
  pf("[TEST FAIL] " .. (message or "Condition should be true"))
  return false
end

function test_framework.assert_false(condition, message)
  if not condition then return true end
  test_framework.failed = test_framework.failed + 1
  pf("[TEST FAIL] " .. (message or "Condition should be false"))
  return false
end

function test_framework.assert_nil(value, message)
  if value == nil then return true end
  test_framework.failed = test_framework.failed + 1
  pf("[TEST FAIL] " .. (message or "Value should be nil") .. ": got " .. tostring(value))
  return false
end

function test_framework.assert_not_equal(actual, unexpected, message)
  if actual ~= unexpected then return true end
  test_framework.failed = test_framework.failed + 1
  pf("[TEST FAIL] " .. (message or "Assertion failed") .. ": Expected not " .. tostring(unexpected) .. ", got " .. tostring(actual))
  return false
end

function test_framework.assert_gt(actual, expected, message)
  if actual > expected then return true end
  test_framework.failed = test_framework.failed + 1
  pf("[TEST FAIL] " .. (message or "Assertion failed") .. ": Expected " .. tostring(actual) .. " > " .. tostring(expected))
  return false
end

function test_framework.assert_lt(actual, expected, message)
  if actual < expected then return true end
  test_framework.failed = test_framework.failed + 1
  pf("[TEST FAIL] " .. (message or "Assertion failed") .. ": Expected " .. tostring(actual) .. " < " .. tostring(expected))
  return false
end

function test_framework.run_test(name, test_func)
  pf("[TEST] Running: " .. name)
  local success, result = pcall(test_func)
  if success then
    if result == nil or result == true then
      test_framework.passed = test_framework.passed + 1
      pf("[TEST PASS] " .. name)
    else
      test_framework.failed = test_framework.failed + 1
      pf("[TEST FAIL] " .. name .. ": " .. tostring(result))
    end
  else
    test_framework.failed = test_framework.failed + 1
    pf("[TEST ERROR] " .. name .. ": " .. tostring(result))
  end
end

function test_framework.reset()
  test_framework.tests = {}
  test_framework.passed = 0
  test_framework.failed = 0
end

function test_framework.summary()
  pf("[TEST SUMMARY] Passed: " .. test_framework.passed .. ", Failed: " .. test_framework.failed)
  pf(test_framework.failed == 0 and "[TEST] All tests passed!" or "[TEST] Some tests failed!")
end

return test_framework
