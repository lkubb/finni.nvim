---@class finni.tests.helpers
local M = {}

---@module "mini.test"
_G.MiniTest = _G.MiniTest

---@namespace finni.tests
---@using finni.core

local ldump = require("tests._ldump")
local path = require("finni.util.path")

-- NOTE: ldump.preserve_modules should not be set, it inversely queries package.loaded. Some
--       loaded modules don't return anything and thus contain `true` as the value, meaning
--       any `true` in the serialized data would be converted to e.g. require("vim._options").
ldump.preserve_modules = false

local init_file = ".test/nvim_init.lua"

--- Proxy for running module functions on child.
---@class ModuleProxy<Module>: Module
---@field _mod `Module` Name of the module to proxy
---@field _child Child Child instance to run against
---@field _async boolean Don't wait for the call to finish. Return values are dropped!
local Proxy = {}

function Proxy:__index(k)
  return function(...)
    if rawget(self, "_async") then
      self._child.lua_func_async(function(mod, name, ...)
        require(mod)[name](...)
      end, self._mod, k, ...)
      return
    end
    local ret = self._child.lua_func(function(mod, name, ...)
      return require(mod)[name](...)
    end, self._mod, k, ...)
    return ret ~= vim.NIL and ret or nil
  end
end

function Proxy:__newindex(k, v)
  -- Dumping a function with upvals takes more time (~50%), so skip it if possible.
  local hasupvals = debug.getinfo(v, "u").nups > 0
  self._child.lua_func(function(mod, attr, val, upvals)
    ---@diagnostic disable-next-line: need-check-nil
    require(mod)[attr] = upvals and loadstring(val)() or loadstring(val)
  end, self._mod, k, hasupvals and ldump(v) or string.dump(v), hasupvals)
end

--- Snapshot with helper methods
---@class Snapshot: finni.core.Snapshot
local Snapshot = {}
Snapshot.__index = Snapshot

--- Get a saved tab by its index.
---@param number? integer Tab number to get. Defaults to 1.
---@return Snapshot.TabData tab Snapshot data for tab
function Snapshot:tab(number)
  number = number or 1
  local tab = assert(self.tabs[number], ("Missing tab number %s"):format(number))
  return tab
end

--- Get a saved window by its index in the flattened table of layout leaves.
---@param winnr? integer Win number to get. Defaults to 1.
---@param tabnr? integer Restrict to windows in this tab. If unspecified, references all windows.
---@return layout.WinInfo win Snapshot data for window
function Snapshot:win(winnr, tabnr)
  winnr = winnr or 1
  local win = assert(
    self:wins(tabnr and { tabnr } or nil)[winnr],
    ("Missing win number %s%s"):format(winnr, tabnr and (" in tab %s"):format(tabnr) or "")
  )
  return win
end

--- Find a saved buffer by name and/or UUID.
---@param match {name?: string, uuid?: string}|string Match spec. String for bufname or table with name/uuid keys.
---@return Snapshot.BufData bufdata Snapshot buffer data
function Snapshot:buf(match)
  match = type(match) == "table" and match or { name = match }
  for _, buf in ipairs(self.buffers) do
    if not match.name or buf.name:match(match.name) then
      if not match.uuid or buf.uuid == match.uuid then
        return buf
      end
    end
  end
  error(("Did not find a buffer that matches %s"):format(vim.inspect(match)))
end

--- Get the index of a buffer in the snapshot's buflist. Fails if not found.
---@param name string Name of the buffer
---@return integer
function Snapshot:bufno(name)
  for i, buf in ipairs(self.buflist) do
    if buf == name then
      return i
    end
  end
  error(("Did not find %s in buflist"):format(name))
end

--- Get a flattened list of all windows, optionally restricted to specific tabs.
---@param tabs? integer|integer[] Restrict windows to this tab/these tabs.
---@return layout.WinInfo[] win_list Flattened list of windows in snapshot
function Snapshot:wins(tabs)
  if not tabs then
    tabs = {}
    for i = 1, #self.tabs do
      tabs[i] = i
    end
  elseif type(tabs) == "number" then
    tabs = { tabs }
  end
  local wins = {}
  local function visitor(node)
    if node[1] == "leaf" then
      wins[#wins + 1] = node[2]
    else
      for _, sub in ipairs(node[2]) do
        visitor(sub)
      end
    end
  end
  for _, tab in ipairs(tabs) do
    ---@diagnostic disable-next-line: need-check-nil
    visitor(self.tabs[tab].wins)
  end
  return wins
end

--- Return a function that checks all varargs for booleanish equality with `bool`.
---@param bool boolean Check args for equality with either true or false.
---@return fun(...): boolean
local function check_booleanish(bool)
  return function(...)
    local cnt = select("#", ...)
    for i = 1, cnt do
      if not not select(i, ...) ~= bool then
        return false
      end
    end
    return true
  end
end

--- Return a function that prints failure information for `check_booleanish`.
---@param bool boolean Check args for equality with either true or false.
---@return fun(...): boolean
local function booleanish_context(bool)
  local str = bool and "Expected truish, but following args were falsy: %s" or "Not Falsy: %s"
  return function(...)
    local cnt = select("#", ...)
    local fails = {}
    for i = 1, cnt do
      if not not select(i, ...) ~= bool then
        fails[i] = vim.inspect(select(i, ...))
      end
    end
    return str:format(vim.inspect(fails))
  end
end

--- MiniTest expectations, both inbuilt and custom ones.
M.ex = {
  eq = MiniTest.expect.equality,
  ne = MiniTest.expect.no_equality,
  err = MiniTest.expect.error,
  ok = MiniTest.new_expectation("truish", check_booleanish(true), booleanish_context(true)),
  no = MiniTest.new_expectation("falsy", check_booleanish(false), booleanish_context(false)),
  contains = MiniTest.new_expectation("list contains", function(list, ...)
    for val in vim.iter({ ... }) do
      if not vim.list_contains(list, val) then
        return false
      end
    end
    return true
  end, function(list, ...)
    local fails = {}
    for val in vim.iter({ ... }) do
      if not vim.list_contains(list, val) then
        fails[#fails + 1] = val
      end
    end
    return ("Missing items: %s\nAll items: %s"):format(
      table.concat(fails, ", "),
      table.concat(list, ", ")
    )
  end),
  none = MiniTest.new_expectation("falsy or empty list/string", function(item)
    return not item or item == "" or (type(item) == "table" and vim.tbl_isempty(item))
  end, function(item)
    return ("Not empty: %s"):format(vim.inspect(item))
  end),
  some = MiniTest.new_expectation("not falsy or empty list/string", function(item)
    return item and item ~= "" and (type(item) ~= "table" or not vim.tbl_isempty(item))
  end, function(item)
    return ("Empty: %s"):format(vim.inspect(item))
  end),
  match = MiniTest.new_expectation("string matching", function(str, pattern)
    return str:find(pattern) ~= nil
  end, function(str, pattern)
    return ("Pattern: %s\nObserved string: %s"):format(vim.inspect(pattern), str)
  end),
  no_match = MiniTest.new_expectation("no string matching", function(str, pattern)
    return str:find(pattern) == nil
  end, function(str, pattern)
    return ("Pattern: %s\nObserved string: %s"):format(vim.inspect(pattern), str)
  end),
}

--- Setup a new unit test to be run in the current neovim (not a child instance).
--- Automatically restores all fields after each test to simplify patching.
--- Creates an empty `<func_name>()` set for each public function.
---@param mod table Module under test. All attributes are restored after each test.
---@return table test_set A MiniTest test set.
function M.unit(mod)
  local baks = {}
  local T = MiniTest.new_set({
    hooks = {
      post_case = function()
        for name, bak in pairs(baks) do
          mod[name] = bak
        end
      end,
    },
  })
  for name, attr in pairs(mod) do
    baks[name] = attr
    if type(attr) == "function" then
      T[name .. "()"] = MiniTest.new_set()
    end
  end

  return T
end

local default_config = {
  log = {
    handler = function(rend)
      local l = vim.g.LOG or {}
      l[#l + 1] = rend
      vim.g.LOG = l
    end,
    level = "trace",
  },
}

---@class Child.InitOpts
---@field nvim_executable? string Nvim executable path
---@field connection_timeout? integer Timeout in milliseconds. Defaults to 5000.
---@field setup? boolean #
---   Call `finni.config.setup()` during initialization.
---   Defaults to false.
---@field init? [fun(...), any...] #
---   Tuple of function and variable number of arguments to pass to this function during Neovim initialization.
---   `setup` is called after this function, if enabled.
---@field config? finni.UserConfig #
---   Set the configuration used by this child instance.
---@field autosession? boolean Enable autosessions
---@field job_opts? Child.InitOpts.job_opts #
---   Pass options to `vim.fn.jobstart` for child neovim instance

---@class Child.InitOpts.job_opts
---@field clear_env? boolean
---@field cwd? string
---@field detach? boolean
---@field env? table<string, string>
---@field height? number
---@field on_exit? fun()
---@field on_stdout? fun()
---@field on_stderr? fun()
---@field overlapped? boolean
---@field pty? boolean
---@field rpc? boolean
---@field stderr_buffered? boolean
---@field stdout_buffered? boolean
---@field stdin? string
---@field term? boolean
---@field width? integer

--- Setup a new integration test with child neovim instance.
---@param init_opts? Child.InitOpts #
---   setup: Whether to call `finni.config.setup()` during initialization. Defaults to false.
---   config: Finni config to set
---   init: Tuple of function and variable number of arguments to call during initialization.
---         The function should not have upvalues (use args to pass relevant parameters instead).
---         Essentially allows arbitrary logic in `minimal_init`.
---   job_opts: Pass options to `vim.fn.jobstart` for child neovim instance
---@return Child child Child neovim process instance.
local function new_child(init_opts)
  init_opts = init_opts or {}
  init_opts.config = vim.tbl_deep_extend("force", default_config, init_opts.config or {}) --[[@as finni.UserConfig]]

  local start_args ---@type string[]
  local start_opts = init_opts ---@type Child.InitOpts

  ---@class Child: MiniTest.child
  ---@field init? string Serialized function that's run during Neovim initialization
  ---@field _init_stat? uv.fs_stat.result Stat result of init.lua after being written by this child.
  local child = MiniTest.new_child_neovim()

  --- Access `finni` modules on the child.
  ---@generic Module
  ---@param mod finni.`Module` Module name, relative to `finni.`
  ---@return Module module Proxy for running module functions on child
  child.mod = function(mod, async)
    -- NOTE: This works in EmmyLua because each module has a type named after its import path.
    --       ModuleProxy<Module> class works for type checking, but breaks goto definition and proper hovers.
    return setmetatable(
      { _child = child, _mod = "finni." .. mod, _async = async and true or false },
      Proxy
    )
  end

  -- Need to wrap the inbuilt `start` function to ensure our init function is synced
  -- before starting the child neovim.
  local wrapped_start = child.start
  child.start = function(args, opts)
    args = args or {} ---@type string[]
    opts = opts or {} ---@type Child.InitOpts
    opts.config = vim.tbl_deep_extend("force", default_config, opts.config or {})

    start_args, start_opts = args, opts

    local function build_init()
      local init_func = opts.init and opts.init[1]
      local init_func_args = opts.init and { unpack(opts.init, 2) }
      local autosession = opts.autosession
      local config = opts.config
      local do_setup = opts.setup

      local init = function()
        vim.g.finni_autosession = autosession
        -- Could pass it in the .setup() call as well, but this is how users should do it.
        vim.g.finni_config = config
        if init_func then
          -- This function has several upvalues defined in this function. They are serialized with it.
          init_func(unpack(init_func_args))
        end
        if do_setup then
          require("finni.config").setup()
        end
      end
      child.init = ldump(init)
      child._init_hash = vim.fn.sha256(child.init)
    end

    build_init()
    ---@cast child.init string
    ---@cast child._init_hash string

    if path.sha256(init_file) ~= child._init_hash then
      path.write_file(init_file, child.init)
      assert(path.exists(init_file), "Failed to create init file!")
    end

    local orig_jobstart = vim.fn.jobstart
    vim.fn.jobstart = function(cmd, job_opts)
      ---@type table?
      local pass_opts = vim.tbl_deep_extend(
        "force",
        { env = { FINNI_TESTING = "true" } },
        opts.job_opts or {},
        job_opts or {}
      )
      ---@diagnostic disable-next-line: param-type-mismatch
      if vim.tbl_isempty(pass_opts) then
        return orig_jobstart(cmd)
      end
      return orig_jobstart(cmd, pass_opts)
    end
    local init_path = path.join(assert(vim.uv.cwd()), "scripts", "minimal_init.lua")
    wrapped_start(vim.list_extend(args, { "-u", init_path }), opts)
    vim.fn.jobstart = orig_jobstart
  end

  local wrapped_restart = child.restart
  child.restart = function(args, opts)
    args = args or start_args
    opts = vim.tbl_deep_extend("force", start_opts or {}, opts or {})
    return wrapped_restart(args, opts)
  end

  --- Helper to create a Finni snapshot from the child's current state with helper methods.
  ---@param target_tabpage? TabID
  ---@param opts? snapshot.CreateOpts
  ---@param snapshot_ctx? snapshot.Context
  ---@return Snapshot
  child.get_snapshot = function(target_tabpage, opts, snapshot_ctx)
    child.wait(function()
      return not child.mod("core.snapshot").is_loading()
    end, 2000, "Timeout waiting for snapshot restoration to finish")
    local ss = child.mod("core.snapshot").create(target_tabpage, opts, snapshot_ctx)
    assert(ss, ("Failed to create snapshot, got: %s"):format(vim.inspect(ss)))
    ---@diagnostic disable: unnecessary-assert
    assert(ss.buflist, "Missing buflist")
    assert(ss.buffers, "Missing buffers")
    assert(ss.tabs, "Missing tabs")
    assert(ss.global, "Missing global data")
    assert(ss.tab_scoped ~= nil, "Missing tab_scoped")
    ---@diagnostic enable: unnecessary-assert
    return setmetatable(ss, Snapshot)
  end

  --- Force-clear event loop.
  --- See: https://github.com/nvim-mini/mini.nvim/issues/93#issuecomment-1202103850
  child.poke_eventloop = function()
    child.api.nvim_eval("1")
  end

  --- Wait a variable time for a predicate to return true.
  ---@param predicate fun(): boolean Predicate function. When it returns `true`, execution continues.
  ---@param timeout? integer Maximum total wait time in ms. Defaults to 2000.
  ---@param errmsg? string Error message to show. If undefined, returns boolean status instead.
  ---@return boolean not_timed_out Indicates whether the predicate turned true or not.
  child.wait = function(predicate, timeout, errmsg)
    local cnt = 0
    local sleep_time = math.floor((timeout or 2000) / 40)
    local timed_out = true
    while cnt < 40 do
      if predicate() then
        timed_out = false
        break
      end
      cnt = cnt + 1
      vim.uv.sleep(sleep_time)
      child.poke_eventloop()
    end
    if timed_out and errmsg then
      error(errmsg)
    end
    return not timed_out
  end

  --- Filter child log messages by level and/or pattern.
  ---@param spec? {level?: finni.log.ConfigLevel, pattern?: string}
  ---@return string[] log_msgs Filtered log messages
  child.filter_log = function(spec)
    local log = child.g.LOG
    if not log or log == vim.NIL then
      return {}
    end
    spec = spec or {}
    log = vim.iter(log)
    if spec.level then
      local match_level = spec.level:upper()
      log = log:filter(function(it)
        return it.level == match_level
      end)
    end
    if spec.pattern then
      log = log:filter(function(it)
        return it.message:match(spec.pattern)
      end)
    end
    return log:totable()
  end

  --- Get a new child instance, based on this one
  --- Optionally run a single function in this context only.
  ---@generic Args, Rets
  ---@overload fun(ovrr_opts: Child.InitOpts): Child, table
  ---@overload fun(ovrr_opts: Child.InitOpts, inner: (fun(child: Child, ...: Args...): Rets...), ...: Args...): Rets...
  ---@param ovrr_opts Child.InitOpts
  ---@param inner? fun(child: Child, ...: Args...): Rets... Inner function to run in overridden child
  ---@param ... Args... If `inner` is passed, variadic arguments to it
  ---@return Child|Rets... child_or_rets If no `inner` is passed, the new child. Otherwise variadic returns of `inner`.
  ---@return table? test_set If no `inner` is passed, MiniTest test set to use with the new child
  child.with = function(ovrr_opts, inner, ...)
    local new_init_opts = vim.tbl_deep_extend("force", init_opts, ovrr_opts) ---@type Child.InitOpts
    local newborn = new_child(new_init_opts)
    if inner then
      newborn.restart()
      local rets = vim.F.pack_len(inner(newborn, ...))
      newborn.stop()
      return vim.F.unpack_len(rets)
    end
    return newborn,
      MiniTest.new_set({
        hooks = {
          pre_case = newborn.restart,
          post_once = newborn.stop,
        },
      })
  end

  local wrapped_stop = child.stop
  child.stop = function(...)
    if child._init_stat then
      path.delete_file(init_file)
    end
    return wrapped_stop(...)
  end

  --- Run a lua function without waiting for it to return (lua_notify for lua_func).
  ---@generic Args
  ---@param f fun(...: Args...)
  ---@param ... Args...
  child.lua_func_async = function(f, ...)
    return child.lua_notify(
      "local f = ...; return assert(loadstring(f))(select(2, ...))",
      { string.dump(f), ... }
    )
  end

  --- Get the text on the child's screen as a string.
  ---@return string
  child.get_screentext = function()
    local screenshot = child.get_screenshot()
    return table.concat(
      vim
        .iter(screenshot.text)
        :map(function(cols)
          return table.concat(cols, "")
        end)
        :totable(),
      "\n"
    )
  end

  --- Build a function that checks for the presence/absence
  --- of patterns on the child's screen. Each vararg is AND'ed,
  --- if a single argument is a list of patterns, these are OR'd:
  ---   (foo, {bar, baz}) => foo and (bar or baz)
  ---@param should_match boolean
  ---@return fun(...: string|string[]): boolean
  local function check_screen(should_match)
    ---@param ... string|string[]
    ---@return boolean
    return function(...)
      local all_ptrns = { ... }
      local _ok = pcall(child.wait, function()
        local text = child.get_screentext()
        return vim.iter(all_ptrns):all(function(any_ptrns)
          return vim.iter(type(any_ptrns) ~= "table" and { any_ptrns } or any_ptrns):any(function(p)
            return (text:find(p) and true or false) == should_match
          end)
        end)
      end, nil, "Text not found")
      return _ok
    end
  end

  ---@param ... string|string[]
  ---@return string
  local function check_screen_msg(...)
    local all_ptrns = { ... }
    return ("Patterns:\n    %s\n\nScreen:\n%s"):format(
      table.concat(
        vim
          .iter(all_ptrns)
          :map(function(any_ptrns)
            return "Any of: "
              .. table.concat(
                vim
                  .iter(type(any_ptrns) ~= "table" and { any_ptrns } or any_ptrns)
                  :map(function(p)
                    return ("`%s`"):format(p)
                  end)
                  :totable(),
                ", "
              )
          end)
          :totable(),
        "\n  + "
      ),
      child.get_screentext()
    )
  end

  child.screen_contains =
    MiniTest.new_expectation("screen contains", check_screen(true), check_screen_msg)
  child.screen_misses =
    MiniTest.new_expectation("screen misses", check_screen(false), check_screen_msg)

  return child
end

--- Options for MiniTest.new_set.
---@class Helpers.set_opts
---@field hooks? Helpers.set_opts.hooks
---@field parametrize? [any ...][]
---@field data? table
---@field n_retry? integer

---@class Helpers.set_opts.hooks
---@field pre_once? fun()
---@field pre_case? fun()
---@field post_case? fun()
---@field post_once? fun()

--- Setup a new integration test with child neovim instance.
---@param init_opts? Child.InitOpts #
---   setup: Whether to call `finni.config.setup()` after start/init func. Defaults to true.
---   config: Finni config to set
---   init: Tuple of function and variable number of arguments to call during initialization.
---@param set_opts? Helpers.set_opts Override default options passed to `MiniTest.new_set`
---@return table test_set A MiniTest test set.
---@return Child child Child neovim process instance.
function M.new_test(init_opts, set_opts)
  local child = new_child(init_opts)

  local T = MiniTest.new_set(vim.tbl_deep_extend("force", {
    hooks = {
      pre_case = child.restart,
      post_once = child.stop,
    },
  }, set_opts or {}))
  return T, child
end

return M
