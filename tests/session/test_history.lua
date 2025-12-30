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

local function histadd(typ, entry)
  if typ == "cmd" then
    pcall(child.type_keys, (":%s<CR>"):format(entry))
    match(child.cmd_capture("history cmd"), vim.pesc(entry))
  elseif typ == "search" then
    pcall(child.type_keys, ("/%s<CR>"):format(entry))
    match(child.cmd_capture("history search"), vim.pesc(entry))
  elseif typ == "input" then
    child.lua_notify("vim.fn.input('hi')")
    child.type_keys(10, ("%s<CR>"):format(entry))
    match(child.cmd_capture("history input"), vim.pesc(entry))
  elseif typ == "expr" then
    child.type_keys(('"=%s<CR>pu'):format(entry))
    match(child.cmd_capture("history expr"), vim.pesc(entry))
  elseif typ == "debug" then
    child.type_keys(100, { ":debug pwd<CR>", ("%s<CR>"):format(entry), "<CR>" })
    match(child.cmd_capture("history debug"), vim.pesc(entry))
  else
    error("Unknown history type: " .. vim.inspect(typ))
  end
end

local function init_hists(except)
  local _ = except ~= "cmd" and histadd("cmd", "pwd")
  _ = except ~= "search" and histadd("search", "barbaz")
  _ = except ~= "input" and histadd("input", "foobar")
  _ = except ~= "expr" and histadd("expr", "$FINNI_TESTING")
  _ = except ~= "debug" and histadd("debug", "cont")
end

T["histories"] = MiniTest.new_set({
  hooks = {
    pre_case = init_hists,
  },
  parametrize = { { "cmd" }, { "search" }, { "input" }, { "expr" }, { "debug" } },
})

T["histories"]["are handled separately"] = function(typ)
  if typ ~= "cmd" and vim.fn.has("nvim-0.11") ~= 1 then
    MiniTest.skip("Proper history handling requires nvim 0.11+")
  end

  local patterns = {
    cmd = "%s+1%s+pwd",
    search = "1%s+barbaz",
    input = "1%s+foobar",
    expr = "1%s+%$FINNI_TESTING",
    debug = "1%s+cont",
  }
  local opts = {}
  if typ == "cmd" then
    opts.command_history = true
  else
    opts[typ .. "_history"] = true
  end

  -- ensure only selected history is preserved
  reload(opts)
  for notyp, ptrn in pairs(patterns) do
    if notyp ~= typ then
      no_match(child.cmd_capture("history " .. notyp), ptrn)
    end
  end
  match(child.cmd_capture("history " .. typ), patterns[typ])

  -- ensure selected history is cleared, but others are left alone
  local extra_items = {
    cmd = "echo 'foo'",
    search = "quux",
    input = "there",
    expr = "$SHELL",
    debug = "q",
  }
  child.restart() -- clear all histories
  init_hists(typ) -- initialize all except our target one
  histadd(typ, extra_items[typ]) -- add an unexpected target history item that should be removed
  sess.load("test_session")
  match(child.cmd_capture("history " .. typ), patterns[typ]) -- ensure expected item is present
  no_match(child.cmd_capture("history " .. typ), extra_items[typ]) -- ensure previous item was cleared
  for other_typ, ptrn in pairs(patterns) do
    if other_typ ~= typ then
      match(child.cmd_capture("history " .. other_typ), ptrn) -- ensure all other histories are untouched
    end
  end
end

return T
