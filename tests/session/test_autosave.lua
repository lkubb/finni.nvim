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

T["autosave_enabled saves when detaching"] = function()
  child.cmd("edit LICENSE")
  sess.save("test_session", { attach = true, autosave_enabled = true })
  child.cmd("edit Makefile")
  sess.detach()
  child.restart()
  sess.load("test_session")
  match(child.api.nvim_buf_get_name(0), "Makefile$")
end

T["autosave_enabled saves when force-quitting"] = function()
  child.cmd("edit LICENSE")
  sess.save("test_session", { attach = true, autosave_enabled = true, modified = true })
  child.cmd("edit Makefile")
  child.type_keys("ihello world<Esc>")
  pcall(child.cmd, "qa!")
  child.restart()
  sess.load("test_session")
  match(child.api.nvim_buf_get_name(0), "Makefile$")
  match(child.get_buftext(), "hello world")
end

-- Test for :qa with modifications, not yet implemented in finni

-- T["autosave_enabled allows to leave with modifications without bang"] = function()
--   child.cmd("edit LICENSE")
--   sess.save("test_session", { attach = true, autosave_enabled = true, modified = true })
--   child.cmd("edit Makefile")
--   child.type_keys("ihello world<Esc>")
--   local _, msg = pcall(child.cmd, "qa")
--   match(msg or "", "Invalid channel") -- ensure child has quit
--   child.restart()
--   sess.load("test_session")
--   match(child.api.nvim_buf_get_name(0), "Makefile$")
--   match(child.get_buftext(), "hello world")
-- end

return T
