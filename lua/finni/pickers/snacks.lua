---@diagnostic disable: unused, undefined-field
---@namespace finni.pickers
local common = require("finni.pickers.common")

local picker ---@module "snacks.picker"
---@cast picker -?

--- Lazy-init imports
local function init()
  picker = picker or require("snacks").picker
end

---@class SnacksFinni: Picker
local SnacksFinni = common.new_picker()

function SnacksFinni:get_selection(typ, _instance, item)
  if typ == "project" then
    return item.project
  elseif typ == "manual" then
    return item.session_name
  end
  return item
end

function SnacksFinni:close(instance)
  instance:close()
end

function SnacksFinni:refresh(_, instance)
  instance:find({ refresh = true })
end

--- Create a list of all manual sessions.
---@return {text: string, session_name: string}[]
function SnacksFinni:manual_finder()
  return vim
    .iter(self:list_manual())
    :map(function(v)
      return { text = v, session_name = v }
    end)
    :totable()
end

function SnacksFinni:manual_picker()
  local opts = self:resolve_opts("manual", {
    title = "Finni Manual Sessions",
    finder = self:wrap("manual_finder"),
    confirm = self:wrap("load_manual"),
    format = "text",
    layout = {
      preset = "select",
    },
    actions = {
      delete_session = self:wrap("delete_manual"),
    },
    win = {
      input = {
        keys = {
          ["<M-d>"] = { "delete_session", mode = { "n", "i" }, desc = "Delete manual session" },
        },
      },
    },
  })
  picker.pick(opts)
end

--- Create a list of all autosessions, spanning all projects.
---@return {text: string, project: string, session: string}[]
function SnacksFinni:auto_all_finder()
  return vim
    .iter(self:list_auto_all())
    :map(function(s)
      return {
        project = s.project,
        session = s.session,
        text = ("%s@%s"):format(s.project, s.session),
      }
    end)
    :totable()
end

function SnacksFinni:auto_all_picker()
  local opts = self:resolve_opts("auto_all", {
    title = "Finni Autosessions [all projects]",
    finder = self:wrap("auto_all_finder"),
    confirm = self:wrap("load_auto_all"),
    format = function(item)
      local project = item.project
      if project:len() > 51 then
        project = "…" .. project:sub(-50)
      end
      return {
        { ("%-51s"):format(project), "SnacksPickerLabel" },
        { " | " },
        { item.session, "String" },
      }
    end,
    layout = {
      preset = "select",
    },
    actions = {
      delete_session = self:wrap("delete_auto_all"),
    },
    win = {
      input = {
        keys = {
          ["<M-d>"] = { "delete_session", mode = { "n", "i" }, desc = "Delete autosession" },
        },
      },
    },
  })
  picker.pick(opts)
end

--- Create a function that lists all autosessions in a specific project.
---@param project_name? string Project to list.
---@return fun(): {text: string, project: string, session: string}[]
function SnacksFinni:auto_finder(project_name)
  return function()
    return vim
      .iter(self:list_auto(project_name))
      :map(function(v)
        return { session = v.session, project = v.project, text = v.session }
      end)
      :totable()
  end
end

---@param project_name? string List autosessions from this project. Defaults to current one.
function SnacksFinni:auto_picker(project_name)
  project_name = self:resolve_project(project_name)
  if not project_name then
    return
  end
  local opts = self:resolve_opts("auto", {
    title = ("Finni Autosessions [%s]"):format(project_name),
    finder = self:auto_finder(project_name),
    confirm = self:wrap("load_auto"),
    format = "text",
    layout = {
      preset = "select",
    },
    actions = {
      delete_session = self:wrap("delete_auto"),
      project_overview = self:wrap("back_to_projects"),
    },
    win = {
      input = {
        keys = {
          ["<M-d>"] = { "delete_session", mode = { "n", "i" }, desc = "Delete autosession" },
          ["<C-^>"] = { "project_overview", mode = { "n", "i" }, desc = "Back to projects" },
        },
      },
    },
  })
  picker.pick(opts)
end

--- Create a list of all projects.
---@return {text: string, project: string}[]
function SnacksFinni:project_finder()
  return vim
    .iter(self:list_projects())
    :map(function(v)
      return { project = v, text = v }
    end)
    :totable()
end

function SnacksFinni:project_picker()
  local opts = self:resolve_opts("project", {
    title = "Finni Autosession Projects",
    finder = self:wrap("project_finder"),
    confirm = self:wrap("select_project"),
    format = "text",
    layout = {
      preset = "select",
    },
    actions = {
      delete_project = self:wrap("delete_project"),
    },
    win = {
      input = {
        keys = {
          ["<M-d>"] = { "delete_project", mode = { "n", "i" }, desc = "Delete project" },
        },
      },
    },
  })
  picker.pick(opts)
end

---@class snacks
local M = {}

---@type Partial<PickerConfig>
local config = {}

--- Override picker defaults
---@param opts? Partial<PickerConfig> Defaults for future calls.
function M.setup(opts)
  config = opts or {}
end

--- Load or delete existing manual sessions.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
function M.manual_picker(opts)
  ---@diagnostic disable-next-line: param-type-mismatch
  SnacksFinni.new(config, opts):manual_picker()
end

--- Load or delete existing autosessions spanning all projects.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
function M.auto_all_picker(opts)
  ---@diagnostic disable-next-line: param-type-mismatch
  SnacksFinni.new(config, opts):auto_all_picker()
end

--- Load or delete existing autosessions in specific project only.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
---@param project_name? string List autosessions from this project. Defaults to current one.
function M.auto_picker(opts, project_name)
  ---@diagnostic disable-next-line: param-type-mismatch
  SnacksFinni.new(config, opts):auto_picker(project_name)
end

--- Inspect or delete existing projects. Select project to manage/load its autosessions.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
function M.project_picker(opts)
  ---@diagnostic disable-next-line: param-type-mismatch
  SnacksFinni.new(config, opts):project_picker()
end

return common.lazy_init(M, init)
