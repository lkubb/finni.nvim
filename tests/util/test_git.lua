---@diagnostic disable: access-invisible, duplicate-set-field, need-check-nil, return-type-mismatch

---@type finni.tests.helpers
local helpers = dofile("tests/helpers.lua")
local ex = helpers.ex
---@diagnostic disable-next-line: unused
local ok, eq, ne = ex.ok, ex.eq, ex.ne

local T, child = helpers.new_test()
local util = require("finni.util")

local gitutil = child.mod("util.git")
local TESTDIR = ".test/tmp/util_git"

local function cleanup()
  util.path.rmdir(TESTDIR, { recursive = true })
  util.path.mkdir(TESTDIR)
end

local function git(cmd, cwd)
  if type(cmd) == "string" then
    cmd = vim.split(cmd, " ")
  end
  return util.git(cmd, { cwd = cwd or TESTDIR })
end

local function commit(opts, cwd)
  opts = opts or {}
  if opts.add ~= false then
    git("add .", cwd)
  end
  git({
    "-c",
    "commit.gpgsign=false",
    "-c",
    "user.email=finni@te.st",
    "-c",
    "user.name=finni-test",
    "commit",
    "--no-verify",
    "-m",
    opts.msg or "testcommit",
  }, cwd)
end

T["list_branches"] = function()
  cleanup()
  git("init -b main")
  util.path.write_file(vim.fs.joinpath(TESTDIR, "foo"), "hello world")
  commit()
  git("switch -c foo")
  git("switch -c bar")
  git("switch -c baz")
  local res = gitutil.list_branches({ cwd = TESTDIR }) or {}
  table.sort(res)
  eq(res, { "bar", "baz", "foo", "main" })
end

T["current_branch"] = function()
  cleanup()
  git("init -b main")
  util.path.write_file(vim.fs.joinpath(TESTDIR, "foo"), "hello world")
  commit()
  eq(gitutil.current_branch({ cwd = TESTDIR }), "main")
  git("switch -c foo")
  eq(gitutil.current_branch({ cwd = TESTDIR }), "foo")
end

T["default_branch from name guess"] = function()
  cleanup()
  git("init -b main")
  util.path.write_file(vim.fs.joinpath(TESTDIR, "foo"), "hello world")
  commit()
  git("switch -c foo")
  eq(gitutil.default_branch({ cwd = TESTDIR }), "main")
end

T["find_git_dir regular"] = function()
  cleanup()
  git("init -b main")
  util.path.write_file(vim.fs.joinpath(TESTDIR, "foo"), "hello world")
  commit()
  ok(gitutil.find_git_dir(TESTDIR):find(vim.pesc(TESTDIR) .. "$"))
end

T["find_git_dir regular subpath"] = function()
  cleanup()
  git("init -b main")
  local path = vim.fs.joinpath(TESTDIR, "subdir")
  util.path.write_file(vim.fs.joinpath(path, "foo"), "hello world")
  commit()
  ok(gitutil.find_git_dir(path):find(vim.pesc(TESTDIR) .. "$"))
end

T["find_git_dir bare + worktree"] = function()
  cleanup()
  git("init -b main --bare .bare")
  util.path.write_file(vim.fs.joinpath(TESTDIR, ".git"), "gitdir: ./.bare")
  git("worktree add main")
  local wt = vim.fs.joinpath(TESTDIR, "main")
  local path = vim.fs.joinpath(wt, "subdir")
  util.path.write_file(vim.fs.joinpath(path, "foo"), "hello world")
  commit(nil, wt)
  ex.match(gitutil.find_git_dir(path), vim.pesc(TESTDIR) .. "$")
end

T["git_info regular"] = function()
  cleanup()
  git("init -b main")
  util.path.write_file(vim.fs.joinpath(TESTDIR, "foo"), "hello world")
  commit()
  git("switch -c foo")
  local res = gitutil.git_info({ cwd = TESTDIR })
  eq(res.branch, "foo")
  eq(res.default_branch, "main")
  ex.match(res.commongitdir, vim.pesc(vim.fs.joinpath(TESTDIR, ".git")) .. "$")
  ex.match(res.gitdir, vim.pesc(vim.fs.joinpath(TESTDIR, ".git")) .. "$")
  ex.match(res.toplevel, vim.pesc(TESTDIR) .. "$")
end

T["git_info bare + worktree"] = function()
  cleanup()
  git("init -b main --bare .bare")
  util.path.write_file(vim.fs.joinpath(TESTDIR, ".git"), "gitdir: ./.bare")
  git("worktree add main")
  local wt = vim.fs.joinpath(TESTDIR, "main")
  util.path.write_file(vim.fs.joinpath(wt, "foo"), "hello world")
  commit(nil, wt)
  git("worktree add foo")
  wt = vim.fs.joinpath(TESTDIR, "foo")
  util.path.write_file(vim.fs.joinpath(wt, "foo"), "hello world")
  local res = gitutil.git_info({ cwd = wt })
  eq(res.branch, "foo")
  eq(res.default_branch, "main")
  ex.match(res.commongitdir, vim.pesc(vim.fs.joinpath(TESTDIR, ".bare")) .. "$")
  ex.match(res.gitdir, vim.pesc(vim.fs.joinpath(TESTDIR, ".bare", "worktrees", "foo")) .. "$")
  ex.match(res.toplevel, vim.pesc(wt) .. "$")
end

return T
