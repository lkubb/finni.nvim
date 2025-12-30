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

T["save jumplist"] = MiniTest.new_set()

--- Add jumplist entry at current pos and move to `tgt`
---@param tgt string
local function addjump(tgt)
  child.cmd("normal! m'")
  child.type_keys(tgt)
end

---@param winid? integer
---@return [string, integer][]
---@return integer
local function getjumps(winid)
  local jumplist = child.fn.getjumplist(winid or 0)
  local jmps, pos = jumplist[1], jumplist[2]
  return vim
    .iter(jmps)
    :map(function(v)
      return { vim.fn.fnamemodify(child.api.nvim_buf_get_name(v.bufnr), ":t"), v.lnum }
    end)
    :totable(),
    pos
end

local function setup_license_jmp()
  child.cmd("edit LICENSE")
  child.type_keys("gg03j")
  addjump("G")
  addjump("11k")
  addjump("gg")
  addjump("2j3l")
  return { { "LICENSE", 4 }, { "LICENSE", 21 }, { "LICENSE", 10 }, { "LICENSE", 1 } }
end

T["save jumplist"]["single file"] = function()
  local expected = setup_license_jmp()

  reload({ jumps = true })
  eq(child.api.nvim_win_get_cursor(0), { 3, 3 })
  local jumps, pos = getjumps()
  eq(jumps, expected)
  eq(pos, 4)

  child.type_keys("<C-o>")
  reload({ jumps = true })
  expected[#expected + 1] = { "LICENSE", 3 }
  jumps, pos = getjumps()
  eq(jumps, expected)
  eq(pos, 3)

  child.type_keys("<C-o><C-o><C-o>2j") -- go back, but also change current cursor position
  reload({ jumps = true })
  eq(child.api.nvim_win_get_cursor(0), { 6, 0 }) -- ensure the cursor position is still correct
  jumps, pos = getjumps()
  eq(jumps, expected)
  eq(pos, 0)
end

T["save jumplist"]["two files"] = function()
  local expected = setup_license_jmp()
  child.cmd("edit .gitignore")
  child.type_keys("gg02j3l")
  addjump("ggj")
  ---@type [string, integer][]
  expected =
    vim.list_extend(expected, { { "LICENSE", 3 }, { ".gitignore", 1 }, { ".gitignore", 3 } })

  reload({ jumps = true })
  eq(child.api.nvim_win_get_cursor(0), { 2, 3 })
  local jumps, pos = getjumps()
  eq(jumps, expected)
  eq(pos, 7)

  child.type_keys("<C-o>")
  expected[#expected + 1] = { ".gitignore", 2 }
  reload({ jumps = true })
  jumps, pos = getjumps()
  eq(jumps, expected)
  eq(pos, 6)

  for i = 5, 0, -1 do
    child.type_keys("<C-o>")
    reload({ jumps = true })
    jumps, pos = getjumps()
    eq(jumps, expected)
    eq(pos, i)
  end
end

T["save jumplist"]["multi file"] = function()
  local expected = setup_license_jmp()
  child.cmd("keepjumps edit .gitignore")
  child.type_keys("999k02j3l")
  addjump("ggj")
  child.cmd("edit Makefile")
  child.type_keys("3<C-o>") -- cause current jumplist entry to be non-final and to be in a different file than displayed
  child.cmd("keepjumps edit .stylua.toml") -- make the displayed buffer a different one than the one the current jumplist entry points to
  child.type_keys("999k03j") -- reset cursor position without causing another jumplist entry
  local balt = child.fn.expand("#")
  ---@type [string, integer][]
  expected = vim.list_extend(expected, {
    { ".gitignore", 3 },
    { ".gitignore", 2 },
    { "Makefile", 1 },
  })

  reload({ jumps = true })
  eq(child.api.nvim_win_get_cursor(0), { 4, 0 })
  eq(vim.fn.fnamemodify(child.fn.expand("%"), ":t"), ".stylua.toml")
  eq(vim.fn.fnamemodify(child.fn.expand("#"), ":t"), balt)
  local jumps, pos = getjumps()
  eq(jumps, expected)
  eq(pos, 3)

  -- Now do the same, but with the target buffer being the same as the one currently displayed
  child.cmd("keepjumps edit LICENSE")
  balt = child.fn.expand("#")
  reload({ jumps = true })
  eq(child.api.nvim_win_get_cursor(0), { 1, 0 })
  eq(vim.fn.fnamemodify(child.fn.expand("%"), ":t"), "LICENSE")
  eq(vim.fn.fnamemodify(child.fn.expand("#"), ":t"), balt)
  jumps, pos = getjumps()
  eq(jumps, expected)
  eq(pos, 3)

  -- Check that we can change the cursor pos in displayed buffer from target entry
  child.cmd("keepjumps edit LICENSE")
  child.type_keys("2jl")
  reload({ jumps = true })
  eq(child.api.nvim_win_get_cursor(0), { 3, 1 })
  eq(vim.fn.fnamemodify(child.fn.expand("%"), ":t"), "LICENSE")
  eq(vim.fn.fnamemodify(child.fn.expand("#"), ":t"), balt)
  jumps, pos = getjumps()
  eq(jumps, expected)
  eq(pos, 3)

  -- Now do the same, but with the currently displayed buffer being the target of the last jumplist entry
  child.cmd("keepjumps edit Makefile")
  balt = child.fn.expand("#")
  reload({ jumps = true })
  eq(child.api.nvim_win_get_cursor(0), { 1, 0 })
  eq(vim.fn.fnamemodify(child.fn.expand("%"), ":t"), "Makefile")
  eq(vim.fn.fnamemodify(child.fn.expand("#"), ":t"), balt)
  jumps, pos = getjumps()
  eq(jumps, expected)
  eq(pos, 3)

  -- Check that we can change the cursor pos in displayed buffer from last jumplist entry
  child.cmd("keepjumps edit Makefile")
  child.type_keys("5j2l")
  reload({ jumps = true })
  eq(child.api.nvim_win_get_cursor(0), { 6, 2 })
  eq(vim.fn.fnamemodify(child.fn.expand("%"), ":t"), "Makefile")
  eq(vim.fn.fnamemodify(child.fn.expand("#"), ":t"), balt)
  jumps, pos = getjumps()
  eq(jumps, expected)
  eq(pos, 3)
end

T["save jumplist"]["multi win"] = function()
  local expected_1 = setup_license_jmp()
  child.cmd("edit .gitignore")
  child.type_keys("gg02j3l")
  addjump("ggj")
  ---@type [string, integer][]
  expected_1 =
    vim.list_extend(expected_1, { { "LICENSE", 3 }, { ".gitignore", 1 }, { ".gitignore", 3 } })

  child.cmd("vsplit .stylua.toml | clearjumps")
  child.type_keys("gg0")
  addjump("5j")
  addjump("3k")
  child.cmd("edit LICENSE | keepjumps norm! gg03j")
  addjump("2j")
  addjump("j")

  local expected_2 = {
    { ".stylua.toml", 1 },
    { ".stylua.toml", 5 },
    { ".stylua.toml", 2 },
    { "LICENSE", 4 },
    { "LICENSE", 6 },
  }

  local function win(nr)
    return child.fn.win_getid(nr)
  end

  reload({ jumps = true })
  eq(child.api.nvim_win_get_cursor(win(2)), { 7, 0 })
  local jumps_2, pos_2 = getjumps(win(2))
  eq(jumps_2, expected_2)
  eq(pos_2, 5)

  eq(child.api.nvim_win_get_cursor(win(1)), { 2, 3 })

  -- Need to focus window once to restore jumplist reliably in time
  child.type_keys("<C-w>p<C-w>p")
  local jumps_1, pos_1 = getjumps(win(1))
  eq(jumps_1, expected_1)
  eq(pos_1, 7)

  child.type_keys("<C-o>")
  expected_2[#expected_2 + 1] = { "LICENSE", 7 }
  reload({ jumps = true })
  jumps_2, pos_2 = getjumps()
  eq(jumps_2, expected_2)
  eq(pos_2, 4)

  for i = 3, 0, -1 do
    child.type_keys("<C-o>")
    reload({ jumps = true })
    jumps_2, pos_2 = getjumps()
    eq(jumps_2, expected_2)
    eq(pos_2, i)
  end

  -- Verify window 1 is still correct, even if it hasn't been focused (and thus restored)
  -- for a couple of restarts.
  eq(child.api.nvim_win_get_cursor(win(1)), { 2, 3 })
  child.type_keys("<C-w>p<C-w>p")
  jumps_1, pos_1 = getjumps(win(1))
  eq(jumps_1, expected_1)
  eq(pos_1, 7)
end

return T
