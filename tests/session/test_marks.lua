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

T["local_marks"] = function()
  child.cmd("edit LICENSE")
  child.api.nvim_buf_set_mark(0, "m", 1, 2, {})
  child.api.nvim_buf_set_mark(0, "x", 4, 3, {})
  child.cmd("edit Makefile")
  child.api.nvim_buf_set_mark(0, "m", 3, 1, {})
  child.api.nvim_buf_set_mark(0, "x", 5, 3, {})

  -- Ensure local marks are persisted
  reload({ local_marks = true })
  child.cmd("edit LICENSE")
  none(child.filter_log({ level = "warn" }))
  eq(child.api.nvim_buf_get_mark(0, "m"), { 1, 2 })
  eq(child.api.nvim_buf_get_mark(0, "x"), { 4, 3 })
  child.cmd("edit Makefile")
  none(child.filter_log({ level = "warn" }))
  eq(child.api.nvim_buf_get_mark(0, "m"), { 3, 1 })
  eq(child.api.nvim_buf_get_mark(0, "x"), { 5, 3 })

  -- Ensure local marks are cleared/overridden
  child.restart()
  child.cmd("edit LICENSE")
  child.api.nvim_buf_set_mark(0, "m", 2, 2, {})
  child.api.nvim_buf_set_mark(0, "y", 3, 2, {})
  sess.load("test_session")
  child.cmd("edit LICENSE")
  none(child.filter_log({ level = "warn" }))
  eq(child.api.nvim_buf_get_mark(0, "m"), { 1, 2 })
  eq(child.api.nvim_buf_get_mark(0, "y"), { 0, 0 })
end

T["global_marks"] = function()
  child.cmd("edit LICENSE")
  child.api.nvim_buf_set_mark(0, "M", 1, 2, {})
  child.api.nvim_buf_set_mark(0, "X", 4, 3, {})

  -- Ensure global marks are persisted
  reload({ global_marks = true })
  none(child.filter_log({ level = "warn" }))
  local mark = child.api.nvim_get_mark("M", {})
  eq(vim.fn.fnamemodify(mark[4], ":t"), "LICENSE")
  eq({ mark[1], mark[2] }, { 1, 2 })
  mark = child.api.nvim_get_mark("X", {})
  eq(vim.fn.fnamemodify(mark[4], ":t"), "LICENSE")
  eq({ mark[1], mark[2] }, { 4, 3 })

  -- Ensure global marks are cleared/overridden
  child.restart()
  child.cmd("edit LICENSE")
  child.api.nvim_buf_set_mark(0, "M", 2, 2, {})
  child.api.nvim_buf_set_mark(0, "Y", 3, 2, {})
  vim.uv.sleep(1000) -- need to wait after setting the above marks, otherwise M is reset for some reason
  sess.load("test_session")
  none(child.filter_log({ level = "warn" }))
  mark = child.api.nvim_get_mark("M", {})
  eq({ mark[1], mark[2] }, { 1, 2 })
  eq(vim.fn.fnamemodify(mark[4], ":t"), "LICENSE")
  eq(child.api.nvim_get_mark("Y", {}), { 0, 0, 0, "" })
end

return T
