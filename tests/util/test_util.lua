---@diagnostic disable: access-invisible, duplicate-set-field, need-check-nil, return-type-mismatch

---@type finni.tests.helpers
local helpers = dofile("tests/helpers.lua")
local ex = helpers.ex
---@diagnostic disable-next-line: unused
local eq, ne = ex.eq, ex.ne

local T, child = helpers.new_test({ setup = true }, { parametrize = { { false }, { true } } })
local util = child.mod("util")

---@param foo integer
---@param cause_err boolean
---@return integer
---@return string
local flaky_func = function(foo, cause_err)
  if foo ~= 42 then
    vim.g.wrong_answer = true
  end
  if cause_err then
    error("foo")
  else
    return 1337, "hi"
  end
end

---@param err string
---@return integer
---@return string
local err_func = function(err)
  vim.g.error_string = err
  vim.g.caught = true
  return 1337, "hi"
end

---@param should_err boolean
T["try_finally"] = function(should_err)
  child.g.caught = false
  local res, res_1, res_2 = pcall(util.try_finally, flaky_func, function()
    vim.g.caught = true
  end, 42, should_err)
  eq(child.g.wrong_answer, vim.NIL)
  eq(res, not should_err)
  eq(child.g.caught, true)
  if should_err then
    ex.match(res_1, ": foo")
    ex.match(res_1, "util/test_util%.lua:")
  else
    eq(res_1, 1337)
    eq(res_2, "hi")
  end
end

---@param should_err boolean
T["try_catch"] = function(should_err)
  child.g.caught = false
  local res, msg = util.try_catch(flaky_func, err_func, 42, should_err)
  eq(child.g.wrong_answer, vim.NIL)
  eq(res, 1337)
  eq(msg, "hi")
  eq(child.g.caught, should_err)
  ex[should_err and "match" or "no_match"](tostring(child.g.error_string), ": foo")
  ex[should_err and "match" or "no_match"](tostring(child.g.error_string), "util/test_util%.lua:")
end

---@param should_err boolean
T["try_catch_else"] = function(should_err)
  child.g.caught = false
  local res, msg = util.try_catch_else(flaky_func, err_func, function(one, two)
    return one + 1, two
  end, 42, should_err)
  eq(res, should_err and 1337 or 1338)
  eq(msg, "hi")
  eq(child.g.caught, should_err)
  if should_err then
    ex.match(child.g.error_string, ": foo")
    ex.match(child.g.error_string, "util/test_util%.lua:")
  end
end

---@param should_err boolean
T["try_any"] = function(should_err)
  child.g.caught = false
  local res, msg = util.try_any({
    flaky_func,
    function(foo, _cause_err)
      if foo ~= 42 then
        vim.g.wrong_answer = true
      end
      vim.g.caught = true
      return 1338, "hi"
    end,
  }, 42, should_err)
  eq(res, should_err and 1338 or 1337)
  eq(msg, "hi")
  eq(child.g.caught, should_err)
end

T["log"] = MiniTest.new_set({ parametrize = { { "info" }, { "error" } } })

---@param should_err boolean
---@param level finni.log.ConfigLevel
T["log"]["try_log"] = function(should_err, level)
  local res, msg = util.try_log(
    flaky_func,
    { "Fudged stuff (%s %s): %s", "hi", "there", level = level ~= "error" and level or nil } --[[@as finni.util.TryLog]],
    42,
    should_err
  )
  eq(child.g.wrong_answer, vim.NIL)
  eq(res, not should_err and 1337 or nil)
  eq(msg, not should_err and "hi" or nil)
  local log = child.filter_log({ level = level, pattern = "foo" })
  if should_err then
    ex.some(log)
    eq(log[1].level, level:upper())
    ex.match(log[1].message, "Fudged stuff %(hi there%)")
    ex.match(log[1].message, "util/test_util%.lua:")
  else
    eq(log, {})
  end
end

---@param should_err boolean
---@param level finni.log.ConfigLevel
T["log"]["try_log_else"] = function(should_err, level)
  ---@param one integer
  ---@param two string
  ---@return integer
  ---@return string
  local els = function(one, two)
    return one + 1, two
  end
  local res, msg = util.try_log_else(
    flaky_func,
    { "Fudged stuff (%s %s): %s", "hi", "there", level = level ~= "error" and level or nil } --[[@as finni.util.TryLog]],
    els,
    42,
    should_err
  )
  eq(child.g.wrong_answer, vim.NIL)
  eq(res, not should_err and 1338 or nil)
  eq(msg, not should_err and "hi" or nil)
  local log = child.filter_log({ level = level, pattern = "foo" })
  if should_err then
    ex.some(log)
    eq(log[1].level, level:upper())
    ex.match(log[1].message, "Fudged stuff %(hi there%)")
    ex.match(log[1].message, "util/test_util%.lua:")
  else
    eq(log, {})
  end
end

return T
