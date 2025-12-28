---@using finni.tests
local util = require("finni.util")

---@type finni.tests.helpers
local helpers = dofile("tests/helpers.lua")
---@type finni.tests.fixtures
local fixtures = dofile("tests/fixtures.lua")
local ex = helpers.ex
local eq, ok, none = ex.eq, ex.ok, ex.none

local T, child = helpers.new_test(nil, { n_retry = 2 })

local pickers = {
  fzf_lua = child.mod("pickers.fzf_lua"),
  mini_pick = child.mod("pickers.mini_pick", true), -- mini.pick blocks until it returns
  snacks = child.mod("pickers.snacks"),
  telescope = child.mod("pickers.telescope"),
}

getmetatable(T).opts.parametrize = vim
  .iter(vim.tbl_keys(pickers))
  :map(function(v)
    return { v }
  end)
  :totable()

T["Manual picker works"] = function(picker)
  picker = pickers[picker]
  local sess_data = fixtures.session("basic", true)
  picker.manual_picker()
  child.screen_contains("Finni Manual Sessions", "basic")
  -- Other than with fzf_lua (external process), this fails with "E31: No such mapping" for some reason,
  -- but the session is still loaded.
  pcall(child.type_keys, "<CR>")
  none(child.filter_log({ level = "error" }))
  child.screen_misses("Finni Manual Sessions")
  child.screen_contains("Lorem ipsum")
  local bufs = child.api.nvim_list_bufs()
  eq(#bufs, 2)
  child.restart()
  picker.manual_picker()
  child.screen_contains("Finni Manual Sessions")
  ok((util.path.exists(sess_data)))
  child.type_keys("<M-d>")
  child.wait(function()
    return not util.path.exists(sess_data)
  end, nil, "Session was not deleted")
end

T["Manual picker respects call overrides"] = function(picker)
  picker = pickers[picker]
  local sess_data = fixtures.session("basic", true)
  local old_sess_dir = vim.fn.fnamemodify(sess_data, ":h")
  local new_sess_dir = util.path.join(vim.fn.fnamemodify(old_sess_dir, ":h"), "foobar")
  MiniTest.finally(function()
    util.path.rmdir(new_sess_dir, { recursive = true })
  end)
  util.path.mv(old_sess_dir, new_sess_dir)
  sess_data = util.path.join(new_sess_dir, vim.fn.fnamemodify(sess_data, ":t"))
  picker.manual_picker({ dir = "foobar" })
  child.screen_contains("Finni Manual Sessions", "basic")
  ok((util.path.exists(sess_data)))
  child.type_keys("<M-d>")
  child.wait(function()
    return not util.path.exists(sess_data)
  end, nil, "Session was not deleted")
end

T["Manual picker respects default overrides"] = function(picker)
  picker = pickers[picker]
  local sess_data = fixtures.session("basic", true)
  local old_sess_dir = vim.fn.fnamemodify(sess_data, ":h")
  local new_sess_dir = util.path.join(vim.fn.fnamemodify(old_sess_dir, ":h"), "foobar")
  MiniTest.finally(function()
    util.path.rmdir(new_sess_dir, { recursive = true })
  end)
  util.path.mv(old_sess_dir, new_sess_dir)
  sess_data = util.path.join(new_sess_dir, vim.fn.fnamemodify(sess_data, ":t"))
  picker.setup({ dir = "foobar" })
  picker.manual_picker()
  child.screen_contains("Finni Manual Sessions", "basic")
  ok((util.path.exists(sess_data)))
  child.type_keys("<M-d>")
  child.wait(function()
    return not util.path.exists(sess_data)
  end, nil, "Session was not deleted")
end

T["All autosessions picker works"] = function(picker)
  picker = pickers[picker]
  local sess_data = fixtures.autosession("basic")
  picker.auto_all_picker()
  child.screen_contains("Finni Autosessions", ".test/projects")
  pcall(child.type_keys, "<CR>")
  none(child.filter_log({ level = "error" }))
  child.screen_misses("Finni Autosessions")
  child.screen_contains("Lorem ipsum")
  local bufs = child.api.nvim_list_bufs()
  eq(#bufs, 2)
  child.restart()
  picker.auto_all_picker()
  child.screen_contains("Finni Autosessions")
  ok((util.path.exists(sess_data)))
  child.type_keys("<M-d>")
  child.wait(function()
    return not util.path.exists(sess_data)
  end, nil, "Session was not deleted")
end

T["Autosession in project picker works"] = function(picker)
  picker = pickers[picker]
  local sess_data, project_dir, project_name = fixtures.autosession("basic")
  child.cmd("cd " .. vim.fn.fnameescape(project_dir))
  picker.auto_picker()
  none(child.filter_log({ level = "error" }))
  child.screen_contains(
    { vim.pesc("Autosessions [" .. project_name:sub(1, 4)), "basic/]" },
    "default"
  )
  pcall(child.type_keys, "<CR>")
  none(child.filter_log({ level = "error" }))
  child.screen_misses({ vim.pesc("Autosessions [" .. project_name:sub(1, 4)), "basic/]" })
  child.screen_contains("Lorem ipsum")
  local bufs = child.api.nvim_list_bufs()
  eq(#bufs, 2)
  child.restart()
  child.cmd("cd " .. vim.fn.fnameescape(project_dir))
  picker.auto_picker()
  none(child.filter_log({ level = "error" }))
  child.screen_contains({ vim.pesc("Autosessions [" .. project_name:sub(1, 4)), "basic/]" })
  ok((util.path.exists(sess_data)))
  child.type_keys("<M-d>")
  child.wait(function()
    return not util.path.exists(sess_data)
  end, nil, "Session was not deleted")
  child.type_keys("<C-^>")
  child.screen_contains(
    "Finni Autosession Projects",
    { vim.pesc(project_name:sub(1, 20)), vim.pesc(project_name:sub(-20)) }
  )
end

T["Project picker works"] = function(picker)
  picker = pickers[picker]
  local sess_data, _, project_name = fixtures.autosession("basic")
  picker.project_picker()
  none(child.filter_log({ level = "error" }))
  child.screen_contains(
    "Finni Autosession Projects",
    { vim.pesc(project_name:sub(1, 20)), vim.pesc(project_name:sub(-20)) }
  )
  pcall(child.type_keys, "<CR>")
  none(child.filter_log({ level = "error" }))
  child.screen_contains(
    { vim.pesc("Autosessions [" .. project_name:sub(1, 4)), "basic/]" },
    "default"
  )
  child.type_keys(5, "<C-^>")
  child.screen_contains("Finni Autosession Projects")
  ok((util.path.exists(sess_data)))
  child.type_keys(5, "<M-d>")
  child.wait(function()
    return not util.path.exists(sess_data)
      and not util.path.exists(vim.fn.fnamemodify(sess_data, ":h"))
  end, nil, "Project was not deleted")
end

T["Pickers are registered"] = function(picker)
  fixtures.autosession("basic")
  local cmd
  local needs_setup = true
  if picker == "snacks" then
    return -- Snacks does not provide an Ex command
  elseif picker == "mini_pick" then
    cmd = "Pick finni_auto_all"
  elseif picker == "fzf_lua" then
    cmd = "FzfLua finni_auto_all"
  elseif picker == "telescope" then
    if vim.fn.has("nvim-0.10.4") == 0 then
      MiniTest.skip("Telescope requires nvim 0.10.4+")
    end
    cmd = "Telescope finni auto_all"
    needs_setup = false
  end
  if needs_setup then
    pickers[picker].setup({}, true)
  end
  if picker == "mini_pick" then
    child.lua("require('mini.pick').setup()")
    child.lua_notify(("vim.cmd('%s')"):format(cmd))
  else
    child.cmd(cmd)
  end
  child.screen_contains("Finni Autosessions", vim.pesc(".test/projects"))
end

return T
