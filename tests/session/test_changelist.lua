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

T["changelist"] = function()
  child.cmd("edit LICENSE")
  child.type_keys({ "gg0", "4j3limm<Esc>", "j2lap<Esc>", "10jx", "2j" })
  reload({ changelist = true })
  none(child.filter_log({ level = "warn" }))
  local expected = {
    { col = 3, coladd = 0, lnum = 5 },
    { col = 7, coladd = 0, lnum = 6 },
    { col = 7, coladd = 0, lnum = 16 },
  }
  local changes = child.fn.getchangelist()
  local changelist, pos = changes[1], changes[2]
  eq(changelist, expected)
  eq(pos, 3)
  eq(child.api.nvim_win_get_cursor(0), { 18, 7 })
  child.type_keys("g;")
  eq(child.api.nvim_win_get_cursor(0), { 16, 7 })
  reload({ changelist = true })
  eq(child.api.nvim_win_get_cursor(0), { 16, 7 })
  changes = child.fn.getchangelist()
  changelist, pos = changes[1], changes[2]
  eq(changelist, expected)
  eq(pos, 3) -- Note: Even if the cursor is on the change item, it's still treated as away from it.
  child.type_keys("g;g;")
  eq(child.api.nvim_win_get_cursor(0), { 6, 7 })
  reload({ changelist = true })
  eq(child.api.nvim_win_get_cursor(0), { 6, 7 })
  changes = child.fn.getchangelist()
  changelist, pos = changes[1], changes[2]
  eq(changelist, expected)
  eq(pos, 1)
  child.type_keys("g;")
  eq(child.api.nvim_win_get_cursor(0), { 5, 3 })
  reload({ changelist = true })
  eq(child.api.nvim_win_get_cursor(0), { 5, 3 })
  changes = child.fn.getchangelist()
  changelist, pos = changes[1], changes[2]
  eq(changelist, expected)
  eq(pos, 0)
end

return T
