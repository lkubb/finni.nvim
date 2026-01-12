---@diagnostic disable: need-check-nil
---@using finni.tests
local util = require("finni.util")
---@type finni.tests.helpers
local helpers = dofile("tests/helpers.lua")
---@diagnostic disable-next-line: unused
local eq, ne, ok, no, match, none, some =
  helpers.ex.eq,
  helpers.ex.ne,
  helpers.ex.ok,
  helpers.ex.no,
  helpers.ex.match,
  helpers.ex.none,
  helpers.ex.some

local T, child = helpers.new_test({ setup = true })

local session = child.mod("core.session")

---@param name? string
---@param opts? finni.core.Session.InitOptsWithMeta
---@param tab? integer
---@return string
---@return string
---@return string
local function new_sess(name, opts, tab)
  ---@diagnostic disable-next-line: redefined-local
  return child.lua_func(function(name, opts, tab)
    name = name or "testsession"
    local tmp = vim.fn.tempname()
    local session_file, state_dir, context_dir =
      vim.fs.joinpath(tmp, name .. ".json"),
      vim.fs.joinpath(tmp, "state"),
      vim.fs.joinpath(tmp, "context")
    ---@diagnostic disable-next-line: assign-type-mismatch
    local sess = require("finni.core.session").create_new(
      name,
      session_file,
      state_dir,
      context_dir,
      opts or {},
      tab
    )
    sess:attach()
    return session_file, state_dir, context_dir
  end, name, opts, tab)
end

----------------
-- Public API --
----------------

T["get_current_data"] = MiniTest.new_set({ parametrize = { { false }, { true } } })

T["get_current_data"]["works"] = function(tab_scoped)
  new_sess("testsession", {
    autosave_interval = 42,
    meta = { foo = "bar" },
  }, tab_scoped and 1 or nil)
  local res = session.get_current_data()
  some(res)
  eq(res.name, "testsession")
  eq(res.autosave_interval, 42)
  eq(res.tab_scoped, tab_scoped)
  eq(res.tabid, tab_scoped and 1 or nil)
  eq(res.meta, { foo = "bar" })
end

--- Session objects are not serializable, wrapper to query the result's name
---@param func keyof finni.core.session
local function get_sess(func, ...)
  return child.lua_func(function(func, ...) ---@diagnostic disable-line: redefined-local
    ---@diagnostic disable-next-line: undefined-field
    local res = require("finni.core.session")[func](...)
    if vim.list_contains({ "get_all", "get_tabs" }, func) then
      return vim
        .iter(pairs(res or {}))
        :map(function(_, sess)
          return sess.name
        end)
        :totable()
    end
    return res and res.name
  end, func, ...)
end

T["get_current/get_active"] = MiniTest.new_set({ parametrize = { { false }, { true } } })
T["get_current/get_active"]["works"] = function(tab_scoped)
  new_sess("foobar", {}, tab_scoped and 1 or nil)
  eq(session.get_current(), "foobar")
  eq(get_sess("get_active"), "foobar")
end

T["get_current/get_global/get_tabid/get_named/get_tabs/get_all works with multiple sessions"] = function()
  eq(get_sess("get_global"), nil)

  new_sess("global")
  child.cmd("tabnew")
  new_sess("tab", {}, 2)
  eq(session.get_current(), "tab")
  eq(get_sess("get_global"), "global")
  eq(get_sess("get_tabid", 2), "tab")
  eq(get_sess("get_named", "global"), "global")
  eq(get_sess("get_named", "tab"), "tab")

  child.cmd("tabprev")
  eq(session.get_current(), "global")
  eq(get_sess("get_global"), "global")
  eq(get_sess("get_tabid", 2), "tab")
  eq(get_sess("get_named", "global"), "global")
  eq(get_sess("get_named", "tab"), "tab")

  eq(get_sess("get_tabid", 3), nil)
  eq(get_sess("get_named", "nonexistent"), nil)

  eq(get_sess("get_tabs"), { "tab" })
  eq(get_sess("get_all"), { "global", "tab" })
end

T["detach"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      new_sess("global")
      child.cmd("tabnew")
      new_sess("tab", {}, 2)
      child.cmd("tabnew")
      new_sess("tab_other", {}, 3)
      child.cmd("tabfirst")
    end,
  },
})

T["detach"]["defaults to all"] = function()
  session.detach()
  eq(get_sess("get_all"), {})
end

T["detach"]["__global"] = function()
  session.detach("__global")
  eq(get_sess("get_global"), nil)
  eq(get_sess("get_tabid", 2), "tab")
  eq(get_sess("get_tabid", 3), "tab_other")
end

T["detach"]["__active with global"] = function()
  session.detach("__active")
  eq(get_sess("get_global"), nil)
  eq(get_sess("get_tabid", 2), "tab")
  eq(get_sess("get_tabid", 3), "tab_other")
end

T["detach"]["__active with tab"] = function()
  child.cmd("tabnext")
  session.detach("__active")
  eq(get_sess("get_global"), "global")
  eq(get_sess("get_tabid", 2), nil)
  eq(get_sess("get_tabid", 3), "tab_other")
end

T["detach"]["__active_tab with active global"] = function()
  session.detach("__active_tab")
  eq(get_sess("get_global"), "global")
  eq(get_sess("get_tabid", 2), "tab")
  eq(get_sess("get_tabid", 3), "tab_other")
end

T["detach"]["__active_tab with active tab"] = function()
  child.cmd("tabnext")
  session.detach("__active_tab")
  eq(get_sess("get_global"), "global")
  eq(get_sess("get_tabid", 2), nil)
  eq(get_sess("get_tabid", 3), "tab_other")
end

T["detach"]["__all_tabs"] = function()
  session.detach("__all_tabs")
  eq(get_sess("get_global"), "global")
  eq(get_sess("get_tabid", 2), nil)
  eq(get_sess("get_tabid", 3), nil)
end

T["detach"]["named global"] = function()
  session.detach("global")
  eq(get_sess("get_global"), nil)
  eq(get_sess("get_tabid", 2), "tab")
  eq(get_sess("get_tabid", 3), "tab_other")
end

T["detach"]["named tab"] = function()
  session.detach("tab")
  eq(get_sess("get_global"), "global")
  eq(get_sess("get_tabid", 2), nil)
  eq(get_sess("get_tabid", 3), "tab_other")
end

T["detach"]["specific tabid"] = function()
  session.detach(2)
  eq(get_sess("get_global"), "global")
  eq(get_sess("get_tabid", 2), nil)
  eq(get_sess("get_tabid", 3), "tab_other")
  session.detach(3)
  eq(get_sess("get_tabid", 3), nil)
end

T["detach"]["list of named/tabid/special"] = function()
  session.detach({ "__active", 2, "tab_other" })
  eq(get_sess("get_all"), {})
end

T["save_all"] = function()
  local global_sess = new_sess("global", { autosave_enabled = false })
  child.cmd("tabnew")
  local tab_sess = new_sess("tab", { autosave_enabled = false }, 2)
  no(util.path.exists(global_sess), util.path.exists(tab_sess))
  session.save_all()
  ok(util.path.exists(global_sess), util.path.exists(tab_sess))
end

T["autosave"] = MiniTest.new_set({ parametrize = { { false }, { true } } })

T["autosave"]["works"] = function(autosave_enabled)
  local global_sess = new_sess("global", { autosave_enabled = autosave_enabled })
  child.cmd("tabnew")
  local tab_sess = new_sess("tab", { autosave_enabled = autosave_enabled }, 2)
  no(util.path.exists(global_sess), util.path.exists(tab_sess))
  session.autosave()
  local check = autosave_enabled and ok or no
  check(util.path.exists(global_sess), util.path.exists(tab_sess))
end

--------------------
-- Session object --
--------------------

T["Session:opts"] = function()
  new_sess("testsession", { autosave_interval = 42, command_history = true })
  local res = child.lua_func(function()
    return require("finni.core.session").get_active():opts()
  end)
  some(res)
  eq(res.autosave_enabled, false)
  eq(res.autosave_interval, 42)
  eq(res.command_history, true)
  ok(res.session_file, res.state_dir, res.context_dir)
  -- The following should not be in :opts(), only in :info()
  no(res.name) ---@diagnostic disable-line: undefined-field
  eq(res.tabid, nil) ---@diagnostic disable-line: undefined-field
  eq(res.tab_scoped, nil) ---@diagnostic disable-line: undefined-field
end

T["Session:info"] = function()
  new_sess("testsession", { autosave_interval = 42, command_history = true }, 1)
  local res = child.lua_func(function()
    return require("finni.core.session").get_active():info()
  end)
  some(res)
  eq(res.autosave_enabled, false)
  eq(res.autosave_interval, 42)
  eq(res.command_history, true)
  ok(res.name, res.tab_scoped, res.session_file, res.state_dir, res.context_dir)
  eq(res.tabid, 1)
end

T["Session:update"] = function()
  local answer_func = function()
    return 42
  end
  local answer_hook = function(varname)
    return function()
      vim.g[varname] = 42
    end
  end
  new_sess("testsession", {
    autosave_interval = 1337,
    autosave_enabled = true,
    autosave_notify = false,
    on_attach = answer_hook("on_attach"),
    on_detach = answer_hook("on_detach"),
    buf_filter = answer_func,
    tab_buf_filter = answer_func,
    jumps = true,
    changelist = true,
    global_marks = true,
    local_marks = true,
    command_history = true,
    search_history = true,
    input_history = true,
    expr_history = true,
    debug_history = true,
    options = { "filetype" },
    modified = true,
    meta = { foo = "bar" },
  })
  local opts = child.lua_func(function()
    local chaos_func = function()
      return 43
    end
    local chaos_hook = function(varname)
      return function()
        vim.g[varname] = 43
      end
    end
    local sess = require("finni.core.session").get_active()
    sess:update({
      autosave_interval = 1338,
      autosave_enabled = false,
      autosave_notify = false,
      on_attach = chaos_hook("on_attach_new"),
      on_detach = chaos_hook("on_detach_new"),
      buf_filter = chaos_func,
      tab_buf_filter = chaos_func,
      jumps = false,
      changelist = false,
      global_marks = false,
      local_marks = false,
      command_history = false,
      search_history = false,
      input_history = false,
      expr_history = false,
      debug_history = false,
      options = { "cmdheight" },
      modified = false,
      meta = { foo = "baz" },
    })
    local rend = sess:opts()
    sess:detach("foo", {})
    return rend
  end)
  eq(opts.autosave_interval, 1338)
  eq(opts.autosave_enabled, false)
  eq(opts.autosave_notify, false)
  eq(opts.buf_filter(), 43)
  eq(opts.tab_buf_filter(), 43)
  eq(opts.jumps, false)
  eq(opts.changelist, false)
  eq(opts.global_marks, false)
  eq(opts.local_marks, false)
  eq(opts.command_history, false)
  eq(opts.search_history, false)
  eq(opts.input_history, false)
  eq(opts.expr_history, false)
  eq(opts.debug_history, false)
  eq(opts.options, { "cmdheight" })
  eq(opts.modified, false)
  eq(opts.meta, { foo = "baz" })
  eq(child.g.on_attach, 42)
  eq(child.g.on_detach, vim.NIL)
  eq(child.g.on_attach_new, vim.NIL)
  eq(child.g.on_detach_new, 43)
end

T["Session:delete"] = function()
  local session_file = new_sess()
  session.save_all()
  ok(util.path.exists(session_file))
  child.lua_func(function()
    require("finni.core.session").get_active():delete()
  end)
  no(util.path.exists(session_file))
end

T["Session:add_hook"] = function()
  new_sess()
  child.lua_func(function()
    require("finni.core.session")
      .get_active()
      :detach("foo", {})
      :add_hook("attach", function()
        vim.g.attach_called = 1
      end)
      :add_hook("detach", function()
        vim.g.detach_called = 1
      end)
      :attach()
      :detach("foo", {})
  end)
  eq(child.g.attach_called, 1)
  eq(child.g.detach_called, 1)
end

T["Session:is_attached"] = function()
  new_sess()
  local res = child.lua_func(function()
    local sess = assert(require("finni.core.session").get_active())
    sess:save()
    sess:detach("foo", {})
    local testsess = require("finni.core.session").from_snapshot(
      "testsession",
      sess.session_file,
      sess.state_dir,
      sess.context_dir,
      sess:opts()
    )
    local res = { testsess:is_attached() } ---@diagnostic disable-line: redefined-local
    testsess = testsess:restore()
    res[#res + 1] = testsess:is_attached()
    testsess = testsess:attach()
    res[#res + 1] = testsess:is_attached()
    testsess = testsess:detach("foo", {})
    res[#res + 1] = testsess:is_attached()
    testsess = testsess:attach()
    res[#res + 1] = testsess:is_attached()
    return res
  end)
  eq(res, { false, false, true, false, true })
end

return T
