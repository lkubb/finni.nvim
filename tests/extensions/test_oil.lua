---@diagnostic disable: need-check-nil, undefined-field
---@type finni.tests.helpers
local helpers = dofile("tests/helpers.lua")
local ex = helpers.ex
---@diagnostic disable-next-line: unused
local eq, ok, none, no = ex.eq, ex.ok, ex.none, ex.no

local sess ---@module "finni.session"

local function reset()
  sess.detach()
  sess.delete("neogit", { silence_errors = true })
end

local T, child = helpers.new_test(
  { config = { extensions = { oil = {} } }, setup_plugins = { oil = {} } },
  {
    post_case = reset,
  }
)
sess = child.mod("session")

T["oil window"] = function()
  reset()
  MiniTest.finally(reset) -- post_case is not run on error ?!
  child.cmd("Oil")
  child.screen_contains("LICENSE")
  eq(child.api.nvim_win_get_cursor(0), { 1, 5 })
  child.type_keys({ "2j", "3l" })
  eq(child.api.nvim_win_get_cursor(0), { 3, 8 })
  sess.save("oil")
  child.restart()
  child.screen_misses("LICENSE")
  sess.load("oil")
  child.screen_contains("LICENSE")
  eq(child.w.oil_did_enter, true)
  eq(child.api.nvim_win_get_cursor(0), { 3, 8 })
end

return T
