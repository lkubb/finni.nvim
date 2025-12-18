---@diagnostic disable: unused, undefined-field
---@namespace finni.pickers
local common = require("finni.pickers.common")

local pick ---@module "mini.pick"
---@cast pick -?

---@class mini_pick
local M = {}

--- Lazy-init imports and register extension
local function init()
  pick = pick or require("mini.pick")
  pick.registry["finni_manual"] = pick.registry["finni_manual"] or M.manual_picker
  pick.registry["finni_auto"] = pick.registry["finni_auto"] or M.auto_picker
  pick.registry["finni_auto_all"] = pick.registry["finni_auto_all"] or M.auto_all_picker
  pick.registry["finni_project"] = pick.registry["finni_project"] or M.project_picker
end

---@class MiniFinni: Picker
local MiniFinni = common.new_picker()

function MiniFinni:get_selection(typ, accepted)
  local item = accepted or (pick.get_picker_matches() or {}).current
  if typ == "project" then
    return item.project
  elseif typ == "manual" then
    return item.session_name
  else
    return item
  end
end

function MiniFinni:close()
  pick.stop()
end

function MiniFinni:refresh(args)
  local finder
  if args[1] == "manual" then
    finder = self:manual_finder()
  elseif args[1] == "auto" then
    finder = self:auto_finder(args[2])()
  elseif args[1] == "auto_all" then
    finder = self:auto_all_finder()
  elseif args[1] == "project" then
    finder = self:project_finder()
  else
    error("Not implemented")
  end
  pick.set_picker_items(finder)
end

--- Create a list of all manual sessions.
---@return {text: string, session_name: string}[]
function MiniFinni:manual_finder()
  return vim
    .iter(self:list_manual())
    :map(function(v)
      return { text = v, session_name = v }
    end)
    :totable()
end

function MiniFinni:manual_picker()
  local opts = self:resolve_opts("manual", {
    source = {
      name = "Finni Manual Sessions",
      items = self:wrap("manual_finder"),
      choose = self:wrap("load_manual"),
    },
    mappings = {
      delete_session = {
        char = "<M-d>",
        func = self:wrap("delete_manual"),
      },
    },
  })
  pick.start(opts)
end

--- Create a list of all autosessions, spanning all projects.
---@return {text: string, project: string, session: string}[]
function MiniFinni:auto_all_finder()
  return vim
    .iter(self:list_auto_all())
    :map(function(s)
      local project_text = s.project
      if project_text:len() > 51 then
        project_text = "…" .. project_text:sub(-50)
      end
      return {
        project = s.project,
        session = s.session,
        text = ("%-51s\0 %s"):format(project_text, s.session),
      }
    end)
    :totable()
end

function MiniFinni:auto_all_picker()
  local opts = self:resolve_opts("auto_all", {
    source = {
      name = "Finni Autosessions [all projects]",
      items = self:wrap("auto_all_finder"),
      choose = self:wrap("load_auto_all"),
    },
    mappings = {
      delete_session = {
        char = "<M-d>",
        func = self:wrap("delete_auto_all"),
      },
    },
  })
  pick.start(opts)
end

--- Create a function that lists all autosessions in a specific project.
---@param project_name? string Project to list.
---@return fun(): {text: string, project: string, session: string}[]
function MiniFinni:auto_finder(project_name)
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
function MiniFinni:auto_picker(project_name)
  project_name = self:resolve_project(project_name)
  if not project_name then
    return
  end
  local opts = self:resolve_opts("auto", {
    source = {
      name = ("Finni Autosessions [%s]"):format(project_name),
      items = self:auto_finder(project_name),
      choose = self:wrap("load_auto"),
    },
    mappings = {
      delete_session = {
        char = "<M-d>",
        func = self:wrap("delete_auto"),
      },
      goto_projects = {
        char = "<C-^>",
        func = self:wrap("back_to_projects"),
      },
    },
  })
  pick.start(opts)
end

--- Create a list of all projects.
---@return {text: string, project: string}[]
function MiniFinni:project_finder()
  return vim
    .iter(self:list_projects())
    :map(function(v)
      return { project = v, text = v }
    end)
    :totable()
end

function MiniFinni:project_picker()
  local opts = self:resolve_opts("project", {
    source = {
      name = "Finni Autosession Projects",
      items = self:wrap("project_finder"),
      choose = self:wrap("select_project"),
    },
    mappings = {
      delete_project = {
        char = "<M-d>",
        func = self:wrap("delete_project"),
      },
    },
  })
  pick.start(opts)
end

---@type Partial<PickerConfig>
local config = {}

--- Override picker defaults and register extensions.
---@param opts? Partial<PickerConfig> Defaults for future calls.
---@param register? boolean #
--- Force registering extensions to be able to launch pickers via the `Pick` Ex command.
--- Note: Loads `mini.pick`.
function M.setup(opts, register)
  config = opts or {}
  ---@diagnostic disable-next-line: undefined-global, unnecessary-if
  if MiniPick or register then -- luacheck: ignore
    init()
  end
end

--- Load or delete existing manual sessions.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
function M.manual_picker(opts)
  ---@diagnostic disable-next-line: param-type-mismatch
  MiniFinni.new(config, opts):manual_picker()
end

--- Load or delete existing autosessions spanning all projects.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
function M.auto_all_picker(opts)
  ---@diagnostic disable-next-line: param-type-mismatch
  MiniFinni.new(config, opts):auto_all_picker()
end

--- Load or delete existing autosessions in specific project only.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
---@param project_name? string List autosessions from this project. Defaults to current one.
function M.auto_picker(opts, project_name)
  ---@diagnostic disable-next-line: param-type-mismatch
  MiniFinni.new(config, opts):auto_picker(project_name)
end

--- Inspect or delete existing projects. Select project to manage/load its autosessions.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
function M.project_picker(opts)
  ---@diagnostic disable-next-line: param-type-mismatch
  MiniFinni.new(config, opts):project_picker()
end

---@diagnostic disable-next-line: unnecessary-if, undefined-global
if MiniPick then -- luacheck: ignore
  -- If MiniPick is already loaded, register ourselves immediately.
  init()
else
  M = common.lazy_init(M, init)
end

return M
