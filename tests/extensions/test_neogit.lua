---@diagnostic disable: need-check-nil, undefined-field
---@type finni.tests.helpers
local helpers = dofile("tests/helpers.lua")
local ex = helpers.ex
---@diagnostic disable-next-line: unused
local eq, ok, none, no, ne = ex.eq, ex.ok, ex.none, ex.no, ex.ne

local sess ---@module "finni.session"

local function reset()
  sess.detach()
  sess.delete("neogit", { silence_errors = true })
end

local T, child = helpers.new_test(
  { config = { extensions = { neogit = {} } }, setup_plugins = { neogit = {} } },
  {
    post_case = reset,
  }
)
sess = child.mod("session")

T["status view"] = function()
  reset()
  MiniTest.finally(reset) -- post_case is not run on error ?!
  -- Setup Neogit window, ensure we're in a constant position and save session
  child.cmd("Neogit")
  child.screen_contains("Recent Commits")
  eq(#child.api.nvim_list_tabpages(), 2)
  child.type_keys({ "gg", "0" })
  eq(child.api.nvim_win_get_cursor(0), { 1, 0 })
  child.type_keys("2j")
  eq(child.api.nvim_win_get_cursor(0), { 3, 0 })

  local function run_assertions()
    child.screen_contains("Recent Commits")
    eq(#child.api.nvim_list_tabpages(), 2)
    eq(child.bo.ft, "NeogitStatus")
    eq(child.api.nvim_win_get_cursor(0), { 3, 0 })
  end

  -- Check that extension works when Neogit window is the active one
  sess.save("neogit")
  child.restart()
  ne(child.bo.ft, "NeogitStatus")
  eq(#child.api.nvim_list_tabpages(), 1)
  sess.load("neogit")
  run_assertions()

  -- Check that extension works when Neogit window is not the active one
  child.cmd("tabprev")
  sess.save("neogit")
  child.restart()
  sess.load("neogit")
  eq(#child.api.nvim_list_tabpages(), 2)
  ne(child.bo.ft, "NeogitStatus")
  child.cmd("tabnext")
  run_assertions()
end

T["commit view"] = function()
  reset()
  MiniTest.finally(reset)

  -- Setup Neogit window, ensure we're in a constant position and save session
  -- Note: This test requires a fully cloned `finni.nvim` repo, not a shallow one.
  child.lua_func(function()
    require("neogit.buffers.commit_view")
      .new("9a356e6bf5c8cbbb71dd1f3140bb46fc7a3ee012")
      :open("tab")
  end)
  child.screen_contains("Dedicate this plugin to Finni")
  eq(#child.api.nvim_list_tabpages(), 2)
  child.type_keys({ "gg", "0" })
  eq(child.api.nvim_win_get_cursor(0), { 1, 0 })
  child.type_keys("2j")
  eq(child.api.nvim_win_get_cursor(0), { 3, 0 })

  local function run_assertions()
    child.screen_contains("Dedicate this plugin to Finni")
    eq(#child.api.nvim_list_tabpages(), 2)
    eq(child.bo.ft, "NeogitCommitView")
    eq(child.api.nvim_win_get_cursor(0), { 3, 0 })
  end

  -- Check that extension works when Neogit commit view is the active one
  sess.save("neogit")
  child.restart()
  ne(child.bo.ft, "NeogitCommitView")
  eq(#child.api.nvim_list_tabpages(), 1)
  sess.load("neogit")
  run_assertions()

  -- Check that extension works when Neogit commit view is not the active one
  child.cmd("tabprev")
  sess.save("neogit")
  child.restart()
  sess.load("neogit")
  eq(#child.api.nvim_list_tabpages(), 2)
  ne(child.bo.ft, "NeogitCommitView")
  child.cmd("tabnext")
  run_assertions()
end

return T
