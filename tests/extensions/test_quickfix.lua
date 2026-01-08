---@diagnostic disable: need-check-nil, undefined-field
---@type finni.tests.helpers
local helpers = dofile("tests/helpers.lua")
local ex = helpers.ex
---@diagnostic disable-next-line: unused
local eq, ok, none, no, ne = ex.eq, ex.ok, ex.none, ex.no, ex.ne

local sess ---@module "finni.session"

local function reset()
  sess.detach()
  sess.delete("quickfix", { silence_errors = true })
end

local T, child = helpers.new_test(nil, {
  post_case = reset,
})
sess = child.mod("session")

local qfl = {
  {
    idx = 1,
    title = "first",
    items = {
      { filename = "lua/finni/auto.lua", nr = 1, lnum = 1, text = "one" },
    },
  },
  {
    idx = 2,
    title = "second",
    items = {
      { filename = "lua/finni/auto.lua", nr = 1, lnum = 2, text = "one" },
      { filename = "lua/finni/session.lua", nr = 2, lnum = 2, text = "two" },
    },
  },
  {
    idx = 2,
    title = "third",
    items = {
      { filename = "lua/finni/auto.lua", nr = 1, lnum = 3, text = "one" },
      { filename = "lua/finni/session.lua", nr = 2, lnum = 2, text = "two" },
      { filename = "lua/finni/config.lua", nr = 3, lnum = 4, text = "three" },
    },
  },
  {
    idx = 3,
    title = "fourth",
    items = {
      { filename = "lua/finni/auto.lua", nr = 1, lnum = 4, text = "one" },
      { filename = "lua/finni/session.lua", nr = 2, lnum = 2, text = "two" },
      { filename = "lua/finni/config.lua", nr = 3, lnum = 3, text = "three" },
      { filename = "lua/finni/log.lua", nr = 4, lnum = 5, text = "four" },
    },
  },
}

T["quickfix lists are restored"] = function()
  reset()
  MiniTest.finally(reset) -- post_case is not run on error ?!
  vim.iter(qfl):each(function(qflist)
    child.fn.setqflist({}, " ", qflist)
  end)
  child.cmd("3 chistory")
  eq(child.fn.getqflist({ all = true }).idx, 2)
  sess.save("quickfix")
  child.restart()
  none(child.fn.getqflist())
  sess.load("quickfix")
  local third = child.fn.getqflist({ all = true })
  eq(third.nr, 3)
  eq(third.title, "third")
  eq(third.idx, 2)
  eq(#third.items, 3)
  child.cmd("1 chistory")
  local first = child.fn.getqflist({ all = true })
  eq(first.nr, 1)
  eq(first.title, "first")
  eq(first.idx, 1)
  eq(#first.items, 1)
  child.cmd("2 chistory")
  local second = child.fn.getqflist({ all = true })
  eq(second.nr, 2)
  eq(second.title, "second")
  eq(second.idx, 2)
  eq(#second.items, 2)
  child.cmd("4 chistory")
  local fourth = child.fn.getqflist({ all = true })
  eq(fourth.nr, 4)
  eq(fourth.title, "fourth")
  eq(fourth.idx, 3)
  eq(#fourth.items, 4)
end

T["quickfix window is restored in current tab"] = function()
  reset()
  MiniTest.finally(reset)
  vim.iter(qfl):each(function(qflist)
    child.fn.setqflist({}, " ", qflist)
  end)
  child.cmd("copen")
  eq(child.bo.bt, "quickfix")
  eq(child.bo.ft, "qf")
  child.screen_contains("one", "two", "three", "four", "auto.lua", "session.lua")
  sess.save("quickfix")
  child.restart()
  sess.load("quickfix")
  eq(child.bo.bt, "quickfix")
  eq(child.bo.ft, "qf")
  child.screen_contains("one", "two", "three", "four", "auto.lua", "session.lua")
end

T["quickfix window is restored in other tab"] = function()
  reset()
  MiniTest.finally(reset)
  vim.iter(qfl):each(function(qflist)
    child.fn.setqflist({}, " ", qflist)
  end)
  child.cmd("copen")
  child.cmd("tabnew")
  child.cmd("edit LICENSE")
  sess.save("quickfix")
  child.restart()
  sess.load("quickfix")
  child.cmd("tabprev")
  child.screen_contains("one", "two", "three", "four", "auto.lua", "session.lua")
end

return T
