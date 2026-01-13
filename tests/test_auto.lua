---@diagnostic disable: need-check-nil
---@using finni.tests
local util = require("finni.util")

---@type finni.tests.helpers
local helpers = dofile("tests/helpers.lua")
---@type finni.tests.fixtures
local fixtures = dofile("tests/fixtures.lua")
local ex = helpers.ex
local eq, ok, no, none, some = ex.eq, ex.ok, ex.no, ex.none, ex.some

local session_data, project_dir, project_name = fixtures.autosession("basic")
local T ---@type table
local child ---@type finni.tests.Child

T, child = helpers.new_test({
  setup_plugins = {
    gitsigns = {},
  },
  job_opts = {
    cwd = project_dir,
  },
}, {
  hooks = {
    pre_case = function()
      session_data, project_dir, project_name = fixtures.autosession("basic")
      child.restart()
    end,
  },
})
local auto = child.mod("auto")

local function switch_or_create(branch, cwd)
  if vim.system({ "git", "switch", branch }, { cwd = cwd or project_dir }):wait().code > 0 then
    util.git({ "switch", "-c", branch }, { cwd = cwd or project_dir })
  end
end

T["Autosession on load works"] = function()
  child.with({ autosession = true }, function(autochild)
    none(autochild.filter_log({ level = "error" }))
    autochild.screen_contains("Lorem ipsum")
    eq(#autochild.api.nvim_list_bufs(), 2)
  end)
end

T["Autosession monitoring git branch works"] = function()
  auto.start()
  child.screen_contains("Lorem ipsum")
  vim.uv.sleep(1000) -- need to wait for gitsigns to synchronize
  switch_or_create("newbranchsession")
  child.screen_misses("Lorem ipsum")
  eq(auto.info().autosession_config.name, "newbranchsession")
end

T["Autosession monitoring global working dir works"] = function()
  -- create other project - need .git file to avoid resolving to finni.nvim project
  util.path.write_file(util.path.join(vim.fn.fnamemodify(project_dir, ":h"), "auto_cd", ".git"), "")
  auto.start()
  child.screen_contains("Lorem ipsum")
  child.cmd("cd ../auto_cd")
  child.screen_misses("Lorem ipsum")
  local info = auto.info().autosession_config
  eq(info.name, "default")
  eq(info.project.name, project_name:gsub("/basic/", "/auto_cd/"))
end

T["explicit_ctx()"] = MiniTest.new_set()

T["explicit_ctx()"]["with project name"] = function()
  child.cmd("cd ..")
  local ctx = auto.explicit_ctx("default", project_name)
  ok(ctx) ---@cast ctx -?
  eq(ctx.name, "default")
  eq(ctx.project.name, project_name)
end

T["explicit_ctx()"]["in current project"] = function()
  local ctx = auto.explicit_ctx("default")
  ok(ctx) ---@cast ctx -?
  eq(ctx.name, "default")
  eq(ctx.project.name, project_name)
end

T["explicit_ctx()"]["detects expectation mismatch"] = function()
  switch_or_create("newbranch")
  local ctx = auto.explicit_ctx("default", project_name)
  no(ctx)
  some(child.filter_log({ level = "error", pattern = "resolved to session `newbranch` instead" }))
end

T["start()"] = function()
  eq(#child.api.nvim_list_bufs(), 1)
  auto.start()
  none(child.filter_log({ level = "error" }))
  child.screen_contains("Lorem ipsum")
  eq(#child.api.nvim_list_bufs(), 2)
  local info = auto.info().autosession_config
  eq(info.project.name, project_name)
  eq(info.name, "default")
end

T["reset()"] = function()
  eq(#child.api.nvim_list_bufs(), 1)
  auto.start()
  child.screen_contains("Lorem ipsum")
  eq(#child.api.nvim_list_bufs(), 2)
  auto.reset()
  eq(#child.api.nvim_list_bufs(), 1)
  no(util.path.exists(session_data))
  local info = auto.info().autosession_config
  eq(info.project.name, project_name)
  eq(info.name, "default")
end

T["info()"] = function()
  auto.start()
  child.screen_contains("Lorem ipsum")
  local info = auto.info()
  ok(info.is_autosession)
  some(info.autosession_config)
  eq(info.autosession_config.name, "default")
  eq(info.autosession_config.project.name, project_name)
  none(info.autosession_data)
  info = auto.info({ with_snapshot = true })
  ok(info.is_autosession)
  some(info.autosession_config)
  eq(info.autosession_config.name, "default")
  eq(info.autosession_config.project.name, project_name)
  some(info.autosession_data)
end

return T
