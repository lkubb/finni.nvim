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

T["buf_filter"] = function()
  child.cmd("edit LICENSE | edit .stylua.toml | edit .gitignore")
  reload({
    buf_filter = function(bufnr, _opts)
      return vim.bo[bufnr].ft ~= "toml"
    end,
  })
  local bufs = child.api.nvim_list_bufs()
  eq(#bufs, 2)
  local expected = { "LICENSE", ".gitignore" }
  for _, bufnr in ipairs(bufs) do
    contains(expected, vim.fn.fnamemodify(child.api.nvim_buf_get_name(bufnr), ":t"))
  end
end

T["tab_buf_filter"] = function()
  child.cmd("edit LICENSE | edit .stylua.toml | edit .gitignore")
  reload({
    buf_filter = function(bufnr, _opts)
      return vim.bo[bufnr].ft ~= "toml"
    end,
    tab_buf_filter = function(_tabpage, bufnr, _opts)
      return vim.bo[bufnr].ft ~= "text"
    end,
  }, { reset = true }, true)
  local bufs = child.api.nvim_list_bufs()
  eq(#bufs, 1)
  eq(vim.fn.fnamemodify(child.api.nvim_buf_get_name(bufs[1]), ":t"), ".gitignore")
end

T["on_attach is called"] = function()
  reload(nil, {
    attach = true,
    on_attach = function()
      vim.g.attach_called = true
    end,
  })
  ok(child.g.attach_called ~= vim.NIL)
end

T["on_detach is called"] = function()
  reload(nil, {
    attach = true,
    on_detach = function()
      vim.g.detach_called = true
    end,
  })
  ok(child.g.detach_called == vim.NIL)
  sess.detach()
  ok(child.g.detach_called ~= vim.NIL)
end

T["on_detach can modify opts"] = function()
  child.cmd("edit LICENSE")
  reload(nil, {
    attach = true,
    on_detach = function()
      return { save = false }
    end,
  })
  child.cmd("edit Makefile")
  sess.detach(nil, nil, { save = true })
  child.restart()
  sess.load("test_session")
  match(child.api.nvim_buf_get_name(0), "LICENSE$")
end

return T
