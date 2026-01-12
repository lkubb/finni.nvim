---@diagnostic disable: need-check-nil
---@using finni.tests

---@type finni.tests.helpers
local helpers = dofile("tests/helpers.lua")
local ex = helpers.ex
---@diagnostic disable-next-line: unused
local eq, ne, ok, no, match, none, some = ex.eq, ex.ne, ex.ok, ex.no, ex.match, ex.none, ex.some

local T, child = helpers.new_test({ setup = true })

local ext = child.mod("core.ext")

T["hooks"] = MiniTest.new_set({
  parametrize = { { "pre_load" }, { "post_load" }, { "pre_save" }, { "post_save" } },
})

T["hooks"]["add_hook/remove_hook"] = function(evt)
  child.lua_func(function(evt) ---@diagnostic disable-line: redefined-local
    _G.finni_testing_hook = function(...) ---@diagnostic disable-line: global-in-non-module
      vim.g.hook_params = { ... }
    end
    require("finni.core.ext").add_hook(evt, finni_testing_hook)
  end, evt)
  ext.dispatch(evt, "testsession", { foo = "bar" }) ---@diagnostic disable-line: param-type-mismatch
  local params = child.g.hook_params
  eq(params, { "testsession", { foo = "bar" } })
  child.g.hook_params = nil

  child.lua_func(function(evt) ---@diagnostic disable-line: redefined-local
    require("finni.core.ext").remove_hook(evt, finni_testing_hook)
  end, evt)
  ext.dispatch(evt, "testsession", { foo = "bar" }) ---@diagnostic disable-line: param-type-mismatch
  eq(child.g.hook_params, vim.NIL)
end

local function init_ext(code, resession)
  local tmp = vim.fn.tempname()
  local tgt =
    vim.fs.joinpath(tmp, "lua", resession and "resession" or "finni", "extensions", "testext.lua")
  require("finni.util.path").write_file(tgt, code)
  vim.opt.rtp:append(tmp)
end

T["get() finni extension"] = function()
  local res = child.with({
    init = {
      init_ext,
      [[
return {foobar = true}
      ]],
    },
  }, function(chld)
    return chld.lua_func(function()
      return require("finni.core.ext").get("testext")
    end)
  end)
  eq(res, { foobar = true })
end

T["get() resession extension"] = MiniTest.new_set({ parametrize = { { false }, { true } } })
T["get() resession extension"]["fallback"] = function(require_fallback)
  local config
  if not require_fallback then
    config = {
      extensions = {
        testext = {
          resession_compat = true,
        },
      },
    }
  end
  local res, log = child.with({
    config = config,
    init = {
      init_ext,
      [[
return {foobar = true}
      ]],
      true,
    },
  }, function(chld)
    local res = chld.lua_func(function() ---@diagnostic disable-line: redefined-local
      return require("finni.core.ext").get("testext")
    end)
    local log = ---@diagnostic disable-line: redefined-local
      chld.filter_log({ level = "warn", pattern = "Missing extension.*to true to avoid overhead" })
    ---@diagnostic disable-next-line: redundant-return-value
    return res, log
  end)
  eq(res, { foobar = true })
  local log_test = require_fallback and some or none
  log_test(log)
end

T["get() nonexistent extension"] = function()
  eq(ext.get("nonexistent_ext"), nil)
  child.filter_log({ level = "warn", pattern = "Missing extension.*namespace is wrong" })
end

T["get() calls ext.config() once with user config"] =
  MiniTest.new_set({ parametrize = { { false }, { true } } })
T["get() calls ext.config() once with user config"][""] = function(resession)
  local cnt = child.with({
    config = {
      extensions = {
        testext = {
          no_error = true,
        },
      },
    },
    init = {
      init_ext,
      [[
return {config = function(extconf) if extconf and extconf.no_error then vim.g.ext_config_cnt = (vim.g.ext_config_cnt or 0) + 1 end end}
      ]],
      resession,
    },
  }, function(chld)
    return chld.lua_func(function()
      local ext = require("finni.core.ext") ---@diagnostic disable-line: redefined-local
      ext.get("testext")
      ext.get("testext")
      ext.get("testext")
      return vim.g.ext_config_cnt
    end)
  end)
  eq(cnt, 1)
end

T["get() does not crash when loading ext errors"] = function()
  local res, log = child.with({
    init = {
      init_ext,
      "error('hi there')",
    },
  }, function(chld)
    local res = chld.lua_func(function() ---@diagnostic disable-line: redefined-local
      return require("finni.core.ext").get("testext")
    end)
    local log = chld.filter_log({ ---@diagnostic disable-line: redefined-local
      level = "warn",
      pattern = '.*Missing extension "testext" in namespace "finni".*',
    })
    ---@diagnostic disable-next-line: redundant-return-value
    return res, log
  end)
  eq(res, nil)
  some(log)
end

T["get() does not crash when ext.config() errors"] = function()
  local res, log = child.with({
    init = {
      init_ext,
      [[
return {config = function() error('hi there') end}
      ]],
    },
  }, function(chld)
    local res = chld.lua_func(function() ---@diagnostic disable-line: redefined-local
      return require("finni.core.ext").get("testext")
    end)
    local log = chld.filter_log({ ---@diagnostic disable-line: redefined-local
      level = "error",
      pattern = "Error configuring Finni extension.*testext.*hi there",
    })
    ---@diagnostic disable-next-line: redundant-return-value
    return res, log
  end)
  eq(res, nil)
  some(log)
end

T["call"] = MiniTest.new_set({
  parametrize = {
    { "on_pre_load", { { bar = "baz" }, { "buf-name" } } },
    { "on_post_load", { { bar = "baz" }, { "buf-name" } } },
    { "on_post_bufinit", { true } },
    { "on_buf_load", { 12 } },
  },
})

T["call"]["works"] = function(stage, args)
  local res = child.with({
    config = {
      extensions = {
        testext = {},
      },
    },
    init = {
      init_ext,
      string.format(
        [[
return {%s = function(...) vim.g.hook_args = {...} end}
      ]],
        stage
      ),
    },
  }, function(chld)
    return chld.lua_func(function(stage, args) ---@diagnostic disable-line: redefined-local
      require("finni.core.ext").call(stage, { testext = { testdata = true } }, unpack(args))
      return vim.g.hook_args
    end, stage, args)
  end)
  eq(res, vim.list_extend({ { testdata = true } }, args))
end

return T
