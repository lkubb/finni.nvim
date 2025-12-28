---@diagnostic disable: need-check-nil, undefined-field
---@type finni.tests.helpers
local helpers = dofile("tests/helpers.lua")
local ex = helpers.ex
---@diagnostic disable-next-line: unused
local eq, ok, no, none, some, contains, match, no_match =
  ex.eq, ex.ok, ex.no, ex.none, ex.some, ex.contains, ex.match, ex.no_match

local sess ---@module "finni.session"

local function reset()
  sess.detach()
  sess.delete("test_session", { silence_errors = true })
end

local T, child = helpers.new_test(nil, {
  post_case = reset,
})
sess = child.mod("session")

---@param opts? finni.session.SaveOpts
---@param load_opts? finni.session.LoadOpts
---@param tab? boolean
local function reload(opts, load_opts, tab)
  (tab and sess.save_tab or sess.save)("test_session", opts)
  child.restart()
  sess.load("test_session", load_opts)
  child.wait(function()
    return not child.mod("core.snapshot").is_loading()
  end)
end

T["save modified"] = MiniTest.new_set()

local function setup_license_mod()
  child.cmd("edit LICENSE")
  child.type_keys({ "gg", "0", "4j", "3l", "i", "mm", "<Esc>", "x" })
  child.screen_contains("Permmission")
  child.type_keys("u")
  child.screen_contains("Permmmission")
  eq(child.api.nvim_win_get_cursor(0), { 5, 4 })
end

local function setup_unnamed_mod()
  child.type_keys({ "i", "asdf<Esc>", "o", "ghij<Esc>", "a", "a<Esc>", "u", "hk" })
  eq(child.api.nvim_win_get_cursor(0), { 1, 2 })
end

local function assert_license_mod(cursor)
  cursor = cursor or { 5, 4 }
  eq(child.api.nvim_win_get_cursor(0), cursor)
  child.screen_contains("Permmmission")
  child.type_keys("u")
  child.screen_contains("Permission")
  child.type_keys({ "<C-r>", "<C-r>" })
  child.screen_contains("Permmission")
end

local function assert_unnamed_mod(cursor)
  cursor = cursor or { 1, 2 }
  eq(child.api.nvim_win_get_cursor(0), cursor)
  child.screen_contains({ "asdf", "ghij" })
  child.screen_misses("ghija")
  child.type_keys("u")
  child.screen_misses("ghij")
  child.type_keys("<C-r><C-r>")
  child.screen_contains("ghija")
end

T["save modified"]["active window"] = function()
  setup_license_mod()
  reload({ modified = true })
  assert_license_mod()
end

T["save modified"]["changes persist over restarts without restoration"] = function()
  setup_license_mod()
  child.cmd("edit Makefile")
  reload({ modified = true })
  reload({ modified = true })
  reload({ modified = true })
  child.cmd("edit LICENSE")
  assert_license_mod()
end

T["save modified"]["changes in unnamed buffer persist over restarts without restoration"] = function()
  setup_unnamed_mod()
  child.cmd("edit Makefile")
  reload({ modified = true })
  reload({ modified = true })
  reload({ modified = true })
  child.cmd("bnext")
  assert_unnamed_mod()
end

T["save modified"]["discarded changes are cleaned up"] = function()
  setup_license_mod()
  reload({ modified = true })
  local state_dir = child.lua_func(function()
    return require("finni.util").path.get_session_state_dir("test_session", "session")
  end)
  local buf_change_path =
    vim.fs.joinpath(state_dir, "modified_buffers", child.b.finni_ctx.uuid .. ".buffer")
  local util = require("finni.util")
  ok(util.path.exists(buf_change_path))
  child.cmd("edit!")
  sess.save("test_session")
  child.wait(function()
    return not util.path.exists(buf_change_path)
  end, 2000, "Buffer changes were not cleaned up")
end

T["save modified"]["discarded unnamed buffer changes are cleaned up"] = function()
  -- TODO: Should they be preserved until closed? The history is discarded as well!
  setup_unnamed_mod()
  reload({ modified = true })
  local state_dir = child.lua_func(function()
    return require("finni.util").path.get_session_state_dir("test_session", "session")
  end)
  local buf_change_path =
    vim.fs.joinpath(state_dir, "modified_buffers", child.b.finni_ctx.uuid .. ".buffer")
  local util = require("finni.util")
  ok(util.path.exists(buf_change_path))
  child.type_keys("999u")
  sess.save("test_session")
  child.wait(function()
    return not util.path.exists(buf_change_path)
  end, 2000, "Buffer changes were not cleaned up")
end

T["save modified"]["changes are reflected in buffer text before restoration"] = function()
  setup_license_mod()
  child.cmd("edit Makefile")
  reload({ modified = true })
  match(child.get_buftext({ pattern = "LICENSE$" }), "Permmmission")
end

T["save modified"]["changes are reflected in unnamed buffer text before restoration"] = function()
  setup_unnamed_mod()
  sess.save("test_session", { modified = true })
  local uuid = child.b.finni_ctx.uuid
  child.cmd("edit Makefile")
  reload({ modified = true })
  match(child.get_buftext({ uuid = uuid }), "asdf\nghij")
end

T["save modified"]["unnamed in active window"] = function()
  setup_unnamed_mod()
  reload({ modified = true })
  assert_unnamed_mod()
end

T["save modified"]["inactive window in current tab"] = function()
  child.cmd("edit .stylua.toml")
  child.cmd("vsplit LICENSE")
  setup_license_mod()
  child.type_keys({ "<C-w>", "p" })
  child.type_keys({ "gg", "0", "jl" })
  eq(child.api.nvim_win_get_cursor(0), { 2, 1 })
  reload({ modified = true })
  eq(child.api.nvim_win_get_cursor(0), { 2, 1 })
  child.type_keys({ "<C-w>", "p" })
  assert_license_mod()
end

T["save modified"]["unnamed in inactive window in current tab"] = function()
  setup_unnamed_mod()
  child.cmd("vsplit LICENSE")
  setup_license_mod()
  reload({ modified = true })
  assert_license_mod()
  child.type_keys({ "<C-w>", "p" })
  assert_unnamed_mod()
end

T["save modified"]["hidden buffer"] = function()
  setup_license_mod()
  child.cmd("edit .stylua.toml")
  child.type_keys({ "gg", "0", "jl" })
  eq(child.api.nvim_win_get_cursor(0), { 2, 1 })
  reload({ modified = true })
  eq(child.api.nvim_win_get_cursor(0), { 2, 1 })
  child.type_keys({ "<C-^>" })
  assert_license_mod()
end

T["save modified"]["unnamed hidden buffer"] = function()
  setup_unnamed_mod()
  child.cmd("edit .stylua.toml")
  child.type_keys({ "gg", "0", "jl" })
  eq(child.api.nvim_win_get_cursor(0), { 2, 1 })
  reload({ modified = true })
  eq(child.api.nvim_win_get_cursor(0), { 2, 1 })
  child.cmd("bnext")
  assert_unnamed_mod()
end

T["save modified"]["buffer in multiple windows"] = function()
  setup_license_mod()
  child.cmd("vsplit")
  child.type_keys("gg02jl")
  eq(child.api.nvim_win_get_cursor(0), { 3, 1 })
  reload({ modified = true })
  eq(child.api.nvim_win_get_cursor(0), { 3, 1 })
  child.screen_contains("Permmmission")
  child.screen_misses("Permission")
  child.type_keys("u")
  child.screen_contains("Permission")
  child.screen_misses("Permmmission")
  child.type_keys("<C-r><C-r>")
  child.screen_contains("Permmission")
  child.type_keys("<C-w>p")
  eq(child.api.nvim_win_get_cursor(0), { 5, 4 })
end

T["save modified"]["unnamed buffer in multiple windows"] = function()
  setup_unnamed_mod()
  child.cmd("vsplit")
  child.type_keys("gg0j3l")
  eq(child.api.nvim_win_get_cursor(0), { 2, 3 })
  reload({ modified = true })
  eq(child.api.nvim_win_get_cursor(0), { 2, 3 })
  assert_unnamed_mod({ 2, 3 })
  child.type_keys("<C-w>p")
  eq(child.api.nvim_win_get_cursor(0), { 1, 2 })
end

T["save modified"]["buffer in multiple tabs"] = function()
  setup_license_mod()
  child.cmd("tabnew")
  child.cmd("edit LICENSE")
  child.type_keys("gg02jl")
  eq(child.api.nvim_win_get_cursor(0), { 3, 1 })
  reload({ modified = true })
  assert_license_mod({ 3, 1 })
  child.cmd("tabprev")
  eq(child.api.nvim_win_get_cursor(0), { 5, 4 })
  child.screen_contains("Permmission")
  child.screen_misses("Permmmission")
end

T["save modified"]["unnamed buffer in multiple tabs"] = function()
  setup_unnamed_mod()
  child.cmd("tabnew")
  child.cmd("buf 1")
  child.type_keys("gg0jl")
  eq(child.api.nvim_win_get_cursor(0), { 2, 1 })
  reload({ modified = true })
  assert_unnamed_mod({ 2, 1 })
  child.cmd("tabprev")
  eq(child.api.nvim_win_get_cursor(0), { 1, 2 })
  child.screen_contains("ghija")
end

return T
