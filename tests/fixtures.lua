local util = require("finni.util")

local uv = vim.uv

local function copy_recursive(src, dst)
  local stat = assert(uv.fs_stat(src), "Source does not exist: " .. src)

  if stat.type == "link" then
    local target = assert(uv.fs_readlink(src))
    assert(uv.fs_symlink(target, dst))
    return
  end

  if stat.type ~= "directory" then
    ---@diagnostic disable-next-line: unnecessary-assert
    assert(uv.fs_copyfile(src, dst, { excl = true }))
    return
  end

  util.path.mkdir(dst)

  local req = assert(uv.fs_scandir(src))
  while true do
    local name = uv.fs_scandir_next(req)
    if not name then
      break
    end
    local src_child = util.path.join(src, name)
    local dst_child = util.path.join(dst, name)
    copy_recursive(src_child, dst_child)
  end
end

---@class finni.tests.fixtures
local M = {}

local PROJECTS_SRC = "tests/files/projects/"
local SESSIONS_SRC = "tests/files/sessions/"
local PROJECTS = ".test/projects"

--- Copy a fixture project to a temp path
---@param name string Name of the fixture project
---@return string project_path Project workdir
function M.project(name)
  local src = util.path.join(PROJECTS_SRC, name)
  local dst = util.path.join(PROJECTS, name)
  util.path.rmdir(dst, { recursive = true })
  copy_recursive(src, dst)
  vim.system({ "git", "init" }, { cwd = dst })
  uv.sleep(10) -- ensures that this project is recognized correctly (sometimes there's a race condition)
  return vim.fn.fnamemodify(dst, ":p")
end

---@param s string
---@param chars string
---@return string
local function rstrip(s, chars)
  return s:match("^(.-)[" .. chars .. "]*$") or s
end

--- Copy a fixture project to a temp path and create a manual session for it
---@param name string Name of the fixture project
---@return string session_path Session data file path
---@return string project_path Project workdir
function M.session(name)
  local project_dir = M.project(name)
  local src = util.path.join(SESSIONS_SRC, name .. ".json")
  local data = vim.json.decode(
    (assert(util.path.read_file(src)):gsub("%$%{PROJECT%}", rstrip(project_dir, "/")))
  )
  local dst = ".test/env/data/nvim/session/" .. name .. ".json"
  util.path.write_json_file(dst, data)
  return vim.fn.fnamemodify(dst, ":p"), project_dir
end

--- Copy a fixture project to a temp path and create an autosession for it
---@param name string Name of the fixture project
---@return string session_path Session data file path
---@return string project_path Project workdir
---@return string project_name Finni project name
function M.autosession(name)
  local project_dir = M.project(name)
  local project_name = util.auto.workspace_project_map(project_dir)
  local src = util.path.join(SESSIONS_SRC, name .. ".json")
  local data = vim.json.decode(
    (assert(util.path.read_file(src)):gsub("%$%{PROJECT%}", rstrip(project_dir, "/")))
  )
  local dst = ".test/env/data/nvim/finni/" .. util.path.escape(project_name) .. "/default.json"
  util.path.write_json_file(dst, data)
  return vim.fn.fnamemodify(dst, ":p"), project_dir, project_name
end

return M
