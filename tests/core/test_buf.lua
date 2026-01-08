---@diagnostic disable: need-check-nil
---@using finni.tests
local util = require("finni.util")

---@type finni.tests.helpers
local helpers = dofile("tests/helpers.lua")
local ex = helpers.ex
---@diagnostic disable-next-line: unused
local eq, ne, ok, no, match, none, some = ex.eq, ex.ne, ex.ok, ex.no, ex.match, ex.none, ex.some

local T, child = helpers.new_test({ setup = true })

local buf = child.mod("core.buf")

-- Need to patch restore_soon because it returns data that cannot be serialized
---@diagnostic disable-next-line: duplicate-set-field
rawset(buf, "restore_soon", function(...)
  child.lua_func(function(...)
    ---@diagnostic disable-next-line: param-type-mismatch
    require("finni.core.buf").restore_soon(...)
  end, ...)
end)

local function update_ctx(upd, bufnr)
  ---@diagnostic disable-next-line: redefined-local
  child.lua_func(function(upd, bufnr)
    vim.b[bufnr or 0].finni_ctx =
      vim.tbl_deep_extend("force", vim.b[bufnr or 0].finni_ctx or {}, upd)
  end, upd, bufnr)
end

T["get_marks"] = function()
  local get_marks = function(bufnr)
    ---@diagnostic disable-next-line: redefined-local
    return child.lua_func(function(bufnr)
      ---@diagnostic disable-next-line: redefined-local
      local buf = require("finni.core.buf")
      return buf.get_marks(buf.ctx(bufnr))
    end, bufnr)
  end

  -- Ensure basic functionality
  child.cmd("edit LICENSE")
  local expected = { ['"'] = { 1, 0 }, ["["] = { 1, 0 }, ["]"] = { child.fn.line("$"), 0 } }
  eq(get_marks(), expected)
  child.api.nvim_buf_set_mark(0, "m", 3, 5, {})
  expected["m"] = { 3, 5 }
  eq(get_marks(), expected)

  -- Ensure inactive buffers work
  local license_bufnr = child.api.nvim_get_current_buf()
  child.cmd("vsplit Makefile")
  ne(get_marks(), expected)
  eq(get_marks(license_bufnr), expected)
  child.cmd("q")

  -- Ensure hidden buffers work
  child.cmd("edit Makefile")
  eq(get_marks(license_bufnr), expected)
  child.cmd("bd | tabnew | edit Makefile")
  eq(get_marks(license_bufnr), expected)
  child.cmd("q")

  -- Ensure unrestored buffers are handled properly
  local unrestored_marks = { a = { 3, 2 }, m = expected.m }
  update_ctx({ initialized = false })
  eq(get_marks(), expected)
  some(child.filter_log({ level = "error", pattern = "missing snapshot data" }))
  update_ctx({ initialized = false, snapshot_data = { marks = unrestored_marks } })
  eq(get_marks(), unrestored_marks)
end

T["parse_changelist"] = function()
  local parse_changelist = function(bufnr)
    ---@diagnostic disable-next-line: redefined-local
    return child.lua_func(function(bufnr)
      ---@diagnostic disable-next-line: redefined-local
      local buf = require("finni.core.buf")
      return buf.parse_changelist(buf.ctx(bufnr))
    end, bufnr)
  end

  -- Ensure basic functionality
  child.cmd("edit LICENSE")
  child.type_keys({ "gg0", "4j3limm<Esc>", "j2lap<Esc>", "10jx", "2j" })
  local expected = {
    { 5, 3 },
    { 6, 7 },
    { 16, 7 },
  }
  local expected_pos = 0
  eq(parse_changelist(), { expected, expected_pos })
  child.type_keys("3g;")
  expected_pos = 2
  eq(parse_changelist(), { expected, expected_pos })

  -- Ensure inactive buffers work
  local license_bufnr = child.api.nvim_get_current_buf()
  child.cmd("vsplit Makefile")
  eq(parse_changelist(), { {}, 0 })
  eq(parse_changelist(license_bufnr), { expected, expected_pos })
  child.cmd("q")

  -- Ensure hidden buffers work
  -- My comment in the function suggests the following would fail, but
  -- it seems to work. Unsure what prompted it or how to provoke the situation.
  child.cmd("edit Makefile")
  eq(parse_changelist(license_bufnr), { expected, expected_pos })
  child.cmd("bd | tabnew | edit Makefile")
  eq(parse_changelist(license_bufnr), { expected, expected_pos })

  -- Ensure unrestored buffers are handled properly
  update_ctx({ initialized = false })
  eq(parse_changelist(), { {}, 0 })
  some(child.filter_log({ level = "error", pattern = "missing snapshot data" }))
  local unrestored_changelist = { { { 1, 3 }, { 3, 7 } }, 1 }
  update_ctx({ initialized = false, snapshot_data = { changelist = unrestored_changelist } })
  eq(parse_changelist(), unrestored_changelist)
end

T["added"] = MiniTest.new_set()

T["added"]["works with paths"] = function()
  eq(#child.filter_bufs("LICENSE"), 0)
  buf.added("LICENSE")
  eq(#child.filter_bufs("LICENSE"), 1)
end

T["added"]["works with paths + uuid"] = function()
  local bufnr = buf.added("LICENSE", "foo-bar-baz").bufnr
  none(child.filter_log({ level = "warn" }))
  local info = child.filter_bufs("LICENSE")[1]
  eq(info.bufnr, bufnr)
  eq(info.uuid, "foo-bar-baz")
end

T["added"]["refuses uuid mismatch (paths)"] = function()
  buf.added("LICENSE")
  ex.err(function()
    buf.added("LICENSE", "foo-bar-baz")
  end, "UUID collision")
  some(child.filter_log({ level = "error" }))
end

T["added"]["works with unnamed bufs"] = function()
  local bufs = child.filter_bufs()
  eq(#bufs, 1)
  local prev_bufnr = bufs[1].bufnr
  local new_bufnr = buf.added("").bufnr
  none(child.filter_log({ level = "warn" }))
  ne(new_bufnr, prev_bufnr)
  local new_bufinfo = child.filter_bufs()[2]
  eq(new_bufinfo.bufnr, new_bufnr)
  some(new_bufinfo.uuid)
end

T["added"]["works with unnamed bufs + uuid"] = function()
  local bufnr = buf.added("", "foo-bar-baz").bufnr
  none(child.filter_log({ level = "warn" }))
  local info = child.filter_bufs()[2]
  eq(info.bufnr, bufnr)
  eq(info.uuid, "foo-bar-baz")
end

T["added"]["adds new buf on uuid mismatch (unnamed)"] = function()
  local bufnr_1 = buf.added("", "foo-bar-baz").bufnr
  local bufnr_2 = buf.added("", "foo-bar-quux").bufnr
  none(child.filter_log({ level = "warn" }))
  local info = child.filter_bufs()
  eq(info[2].bufnr, bufnr_1)
  eq(info[3].bufnr, bufnr_2)
  eq(info[2].uuid, "foo-bar-baz")
  eq(info[3].uuid, "foo-bar-quux")
end

T["save_modified"] = MiniTest.new_set()

---@param state_dir string
---@param bufs? integer[]
local function save_modified(state_dir, bufs)
  ---@diagnostic disable-next-line: redefined-local
  return child.lua_func(function(state_dir, bufs)
    ---@diagnostic disable-next-line: redefined-local
    local buf = require("finni.core.buf")
    local buf_ctx = vim.iter(bufs or vim.api.nvim_list_bufs()):map(buf.ctx):totable()
    return buf.save_modified(state_dir, buf_ctx)
  end, state_dir, bufs)
end

---@param state_dir string
---@param keep table<string, true?>
local function clean_modified(state_dir, keep)
  ---@diagnostic disable-next-line: redefined-local
  return child.lua_func(function(state_dir, keep)
    ---@diagnostic disable-next-line: redefined-local
    local buf = require("finni.core.buf")
    local buf_ctx = vim.iter(keep):map(buf.ctx_by_uuid):fold(function(agg, ctx)
      agg = agg or {}
      agg[ctx.uuid] = ctx
    end)
    return buf.clean_modified(state_dir, buf_ctx)
  end, state_dir, keep)
end

local function run_saves_modified_buffers(content_ptrn)
  local tmpdir = child.fn.tempname()
  local res = save_modified(tmpdir)
  none(child.filter_log({ level = "warn" }))
  local uuid = child.b.finni_ctx.uuid
  local save_file = vim.fs.joinpath(tmpdir, "modified_buffers", uuid .. ".buffer")
  local undo_file = vim.fs.joinpath(tmpdir, "modified_buffers", uuid .. ".undo")
  eq(res, { [uuid] = true })
  ok((util.path.exists(save_file)), (util.path.exists(undo_file)))
  match(util.path.read_file(save_file), content_ptrn)
  -- ensure we don't rewrite unchanged buffer contents
  child.lua_func(function()
    local old_get_text = vim.api.nvim_buf_get_text
    vim.api.nvim_buf_get_text = function(...)
      vim.g.buf_get_text_called = true
      vim.api.nvim_buf_get_text = old_get_text
      return old_get_text(...)
    end
  end)
  none(child.filter_log({ level = "debug", pattern = "skipping save" }))
  res = save_modified(tmpdir)
  eq(res, { [uuid] = true })
  eq(child.g.buf_get_text_called, vim.NIL)
  some(child.filter_log({ level = "debug", pattern = "skipping save" }))
  -- but ensure we rewrite them if either file is missing
  util.path.delete_file(save_file)
  res = save_modified(tmpdir)
  eq(res, { [uuid] = true })
  ok((util.path.exists(save_file)), (util.path.exists(undo_file)))
  util.path.delete_file(undo_file)
  res = save_modified(tmpdir)
  eq(res, { [uuid] = true })
  ok((util.path.exists(save_file)), (util.path.exists(undo_file)))
  -- but skip wundo when cmdline is active
  util.path.delete_file(save_file)
  util.path.delete_file(undo_file)
  child.type_keys("q:")
  res = save_modified(tmpdir)
  eq(res, { [uuid] = true })
  none(child.filter_log({ level = "error" }))
  ok(util.path.exists(save_file))
  no(util.path.exists(undo_file))
end

T["save_modified"]["saves modified named buffers"] = function()
  child.cmd("edit LICENSE")
  child.type_keys({ "gg", "0", "4j", "3l", "i", "mm", "<Esc>", "x" })
  run_saves_modified_buffers("Permmission")
end

T["save_modified"]["saves modified unnamed buffers"] = function()
  child.type_keys({ "i", "asdf<Esc>", "o", "ghij<Esc>", "a", "a<Esc>", "u", "hk" })
  run_saves_modified_buffers("asdf\nghij")
end

local function run_skips_pending_buffers()
  update_ctx({ pending_modifications = true })
  local tmpdir = child.fn.tempname()
  local res = save_modified(tmpdir)
  local uuid = child.b.finni_ctx.uuid
  eq(res, { [uuid] = true })
  local save_file = vim.fs.joinpath(tmpdir, "modified_buffers", uuid .. ".buffer")
  local undo_file = vim.fs.joinpath(tmpdir, "modified_buffers", uuid .. ".undo")
  no((util.path.exists(save_file)), (util.path.exists(undo_file)))
end

T["save_modified"]["skips named buffers pending restoration"] = function()
  child.cmd("edit LICENSE")
  run_skips_pending_buffers()
end

T["save_modified"]["skips unnamed buffers pending restoration"] = function()
  child.type_keys({ "i", "asdf<Esc>", "o", "ghij<Esc>", "a", "a<Esc>", "u", "hk" })
  run_skips_pending_buffers()
end

T["save_modified"]["skips unrestored buffers"] = function()
  child.cmd("edit LICENSE")
  update_ctx({ unrestored_modifications = true })
  local tmpdir = child.fn.tempname()
  local res = save_modified(tmpdir)
  local uuid = child.b.finni_ctx.uuid
  eq(res, { [uuid] = true })
  local save_file = vim.fs.joinpath(tmpdir, "modified_buffers", uuid .. ".buffer")
  local undo_file = vim.fs.joinpath(tmpdir, "modified_buffers", uuid .. ".undo")
  no((util.path.exists(save_file)), (util.path.exists(undo_file)))
end

T["clean_modified"] = function()
  child.cmd("edit LICENSE")
  child.type_keys({ "gg", "0", "4j", "3l", "i", "mm", "<Esc>", "x" })
  local tmpdir = child.fn.tempname()
  local res = save_modified(tmpdir)
  local uuid = child.b.finni_ctx.uuid
  eq(res, { [uuid] = true })
  ---@cast res -?
  res["some-other-uuid-shouldnotcauseaproblem"] = true
  local save_file = vim.fs.joinpath(tmpdir, "modified_buffers", uuid .. ".buffer")
  local undo_file = vim.fs.joinpath(tmpdir, "modified_buffers", uuid .. ".undo")
  ok((util.path.exists(save_file)), (util.path.exists(undo_file)))
  buf.clean_modified(tmpdir, res)
  ok((util.path.exists(save_file)), (util.path.exists(undo_file)))
  buf.clean_modified(tmpdir, {})
  no((util.path.exists(save_file)), (util.path.exists(undo_file)))
  save_modified(tmpdir)
  util.path.delete_file(undo_file)
  buf.clean_modified(tmpdir, {})
  no((util.path.exists(save_file)), (util.path.exists(undo_file)))
  save_modified(tmpdir)
  util.path.delete_file(save_file)
  -- We only glob for .buffer files, so an orphaned undo file will persist. Should not be an issue.
  buf.clean_modified(tmpdir, {})
  ok((util.path.exists(undo_file)))
end

T["restore"] = MiniTest.new_set()
---@return finni.core.Snapshot
local function get_snapshot_data()
  local cwd = vim.fn.getcwd(-1, -1)
  ---@type finni.core.Snapshot
  local snapshot = {
    buffers = {
      {
        name = vim.fs.joinpath(cwd, "LICENSE"),
        loaded = true,
        options = {},
        last_pos = { 1, 0 },
        uuid = "foo-bar-baz",
        in_win = true,
      },
    },
    buflist = {},
    global = {
      cwd = cwd,
      command_history = false,
      debug_history = false,
      expr_history = false,
      height = 14,
      input_history = false,
      options = {},
      search_history = false,
      width = 49,
    },
    tab_scoped = false,
    tabs = {
      {
        options = {},
        wins = {
          "leaf",
          {
            bufname = vim.fs.joinpath(cwd, "LICENSE"),
            bufuuid = "foo-bar-baz",
            current = true,
            cursor = { 1, 0 },
            view = {
              col = 0,
              coladd = 0,
              curswant = 0,
              leftcol = 0,
              lnum = 1,
              skipcol = 0,
              topfill = 0,
              topline = 1,
            },
            width = 49,
            height = 14,
            options = {},
            old_winid = 1,
          },
        },
        current = true,
      },
    },
  }
  return snapshot
end

T["restore"]["restores options"] = function()
  local ss = get_snapshot_data()
  local b = ss.buffers[1] ---@cast b -?
  b.options.shiftwidth = 42
  local bufnr = buf.restore(b, ss)
  eq(child.api.nvim_get_option_value("shiftwidth", { buf = bufnr }), 42)
end

T["restore"]["restores buftype=help"] = function()
  local ss = get_snapshot_data()
  local b = ss.buffers[1] ---@cast b -?
  b.bt = "help"
  local bufnr = buf.restore(b, ss)
  eq(child.api.nvim_get_option_value("buftype", { buf = bufnr }), "help")
end

T["restore"]["works with unloaded bufs"] = function()
  local ss = get_snapshot_data()
  local b = ss.buffers[1] ---@cast b -?
  b.loaded = false
  local bufnr = buf.restore(b, ss)
  eq(child.api.nvim_buf_is_loaded(bufnr), false)
end

T["restore"]["warns about and skips already initialized buffers"] = function()
  local ss = get_snapshot_data()
  local b = ss.buffers[1] ---@cast b -?
  b.options.shiftwidth = 42
  local bufnr = buf.restore(b, ss)
  none(child.filter_log({ level = "warn", "already initialized" }))
  b.options.shiftwidth = 41
  local new_bufnr = buf.restore(b, ss)
  eq(new_bufnr, bufnr)
  some(child.filter_log({ level = "warn", pattern = "more than once" }))
  eq(child.api.nvim_get_option_value("shiftwidth", { buf = bufnr }), 42)
end

T["restore"]["schedules restoration on bufenter"] = function()
  local ss = get_snapshot_data()
  local b = ss.buffers[1] ---@cast b -?
  local bufnr = buf.restore(b, ss)
  local autocmds = child.api.nvim_get_autocmds({
    buffer = bufnr,
    event = "BufEnter",
    group = "FinniBufferRestore",
  })
  eq(#autocmds, 1)
  local autocmd = autocmds[1]
  ok(autocmd.once, child.api.nvim_buf_get_var(bufnr, "finni_ctx").need_edit)
  child.api.nvim_win_set_buf(0, bufnr)
  no(child.api.nvim_buf_get_var(bufnr, "finni_ctx").need_edit)
  ok(child.api.nvim_buf_get_var(bufnr, "finni_ctx").initialized)
end

-- If we reload the buffer before the VeryLazy has finished, some plugins
-- might be broken.
T["restore"]["does not trigger :edit before lazy.nvim VeryLazy event is done"] = function()
  local ss = get_snapshot_data()
  local b = ss.buffers[1] ---@cast b -?
  child.g._finni_verylazy_done = false
  local bufnr = buf.restore(b, ss)
  child.api.nvim_win_set_buf(0, bufnr)
  ok(child.api.nvim_buf_get_var(bufnr, "finni_ctx").need_edit)
  no(child.api.nvim_buf_get_var(bufnr, "finni_ctx").initialized)
  child.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
  no(child.api.nvim_buf_get_var(bufnr, "finni_ctx").need_edit)
  ok(child.api.nvim_buf_get_var(bufnr, "finni_ctx").initialized)
end

T["restore_soon"] = MiniTest.new_set()

T["restore_soon"]["works"] = function()
  local ss = get_snapshot_data()
  local b = ss.buffers[1] ---@cast b -?
  buf.restore_soon(b, ss, nil, { timeout = 1 })
  vim.uv.sleep(10)
  local bufs = child.filter_bufs(vim.pesc(b.name))
  some(bufs)
end

T["restore_soon"]["triggers on CursorHold"] = function()
  child.go.eventignore = "CursorHold,CursorHoldI"
  local ss = get_snapshot_data()
  local b = ss.buffers[1] ---@cast b -?
  buf.restore_soon(b, ss, nil, { timeout = 9999 })
  vim.uv.sleep(50)
  local bufs = child.filter_bufs(vim.pesc(b.name))
  none(bufs)
  child.go.eventignore = ""
  child.api.nvim_exec_autocmds("CursorHold", {})
  bufs = child.filter_bufs(vim.pesc(b.name))
  some(bufs)
end

T["restore_soon"]["respects timeout"] = function()
  child.go.eventignore = "CursorHold,CursorHoldI"
  local ss = get_snapshot_data()
  local b = ss.buffers[1] ---@cast b -?
  buf.restore_soon(b, ss, nil, { timeout = 100 })
  vim.uv.sleep(10)
  local bufs = child.filter_bufs(vim.pesc(b.name))
  none(bufs)
  vim.uv.sleep(100)
  bufs = child.filter_bufs(vim.pesc(b.name))
  some(bufs)
end

T["restore_soon"]["buf.added forces early restoration"] = function()
  child.go.eventignore = "CursorHold,CursorHoldI"
  local ss = get_snapshot_data()
  local b = ss.buffers[1] ---@cast b -?
  b.options.shiftwidth = 42
  buf.restore_soon(b, ss, nil, { timeout = 9999 })
  none(child.filter_bufs(vim.pesc(b.name)))
  buf.added(b.name, b.uuid)
  local bufs = child.filter_bufs(vim.pesc(b.name))
  some(bufs)
  local bufnr = bufs[1].bufnr
  eq(child.api.nvim_get_option_value("shiftwidth", { buf = bufnr }), 42)
end

T["restore_soon"]["calls callback"] = function()
  local ss = get_snapshot_data()
  local b = ss.buffers[1] ---@cast b -?
  buf.restore_soon(b, ss, nil, {
    timeout = 1,
    callback = function()
      vim.g.restore_soon_callback = true
    end,
  })
  vim.uv.sleep(10)
  some(child.filter_bufs(vim.pesc(b.name)))
  ok(child.g.restore_soon_callback)
end

T["restore_soon"]["does not allow overwriting once scheduled"] = function()
  child.go.eventignore = "CursorHold,CursorHoldI"
  local ss = get_snapshot_data()
  local b = ss.buffers[1] ---@cast b -?
  b.options.shiftwidth = 42
  buf.restore_soon(b, ss, nil, { timeout = 9999 })
  none(child.filter_log({ level = "error", pattern = "twice" }))
  b.options.shiftwidth = 41
  buf.restore_soon(b, ss, nil, { timeout = 9999 })
  some(child.filter_log({ level = "error", pattern = "twice" }))
  child.go.eventignore = ""
  child.api.nvim_exec_autocmds("CursorHold", {})
  local bufs = child.filter_bufs(vim.pesc(b.name))
  some(bufs)
  local bufnr = bufs[1].bufnr
  eq(child.api.nvim_get_option_value("shiftwidth", { buf = bufnr }), 42)
end

return T
