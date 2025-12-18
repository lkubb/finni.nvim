---@diagnostic disable: unused
---@namespace finni.pickers

---@alias PickerTypes "manual"|"auto"|"auto_all"|"project"

---@class PickerRawOverrides: table<PickerTypes, table>
---@field default table Override any (picker plugin-specific) options passed to all picker types.
---@field manual table Override any (picker plugin-specific) options passed to the manual session picker.
---@field auto table Override any (picker plugin-specific) options passed to the autosession picker.
---@field auto_all table Override any (picker plugin-specific) options passed to the global autosession picker.
---@field project table Override any (picker plugin-specific) options passed to the project autosession picker.

---@class PickerConfig
---@field dir? string Override the default manual session directory (`session.dir`)
---@field raw PickerRawOverrides #
--- Override any options that are passed to a picker.
--- Valid values depend on the specific picker plugin.

local M = {}

--- Wrap all functions exposed in a table in a lazy-init check.
---@generic T
---@param mod T
---@param init_func fun()
---@return T
function M.lazy_init(mod, init_func)
  -- Make sure all the API functions trigger the lazy load
  for k, v in pairs(mod) do
    if type(v) == "function" and k ~= "setup" then
      mod[k] = function(...)
        if not mod._initialized then
          init_func()
          mod._initialized = true
        end
        return v(...)
      end
    end
  end
  return mod
end

---@class Picker: PickerConfig
local Picker = {}

--- Turn a method call into a function call.
---@param method string Method of picker to wrap
---@return fun (...: any): any Method turned into function
function Picker:wrap(method)
  return function(...)
    ---@diagnostic disable-next-line: param-type-mismatch, undefined-field
    return self[method](self, ...)
  end
end

--- List names of all manual sessions inconfigured `dir`
---@return string[]
function Picker:list_manual()
  return require("finni.session").list({ dir = self.dir })
end

--- List all autosessions in all projects
---@return {project: string, session: string}[]
function Picker:list_auto_all()
  local res = require("finni.auto").list_projects({ with_sessions = true })
  local entries = {}
  for project, sessions in pairs(res) do
    for _, session in ipairs(sessions) do
      entries[#entries + 1] = { project = project, session = session }
    end
  end
  return entries
end

--- List all autosessions in specific projects
---@param project_name? string Project to list. Defaults to active one
---@return {project: string, session: string}[]
function Picker:list_auto(project_name)
  return vim
    .iter(require("finni.auto").list({ project_name = project_name }))
    :map(function(v)
      return { session = v, project = project_name }
    end)
    :totable()
end

--- List names of all known projects in configured autosession `dir`
---@return string[]
function Picker:list_projects()
  return require("finni.auto").list_projects()
end

--- Load the selected manual session.
function Picker:load_manual(...)
  local sess = self:get_selection("manual", ...)
  self:close(...)
  require("finni.session").load(sess, { dir = self.dir })
end

--- Delete the selected manual session.
function Picker:delete_manual(...)
  local sess = self:get_selection("manual", ...)
  require("finni.session").delete(sess, { dir = self.dir })
  self:refresh({ "manual" }, ...)
end

--- Load the autosession selected from overview of single project.
function Picker:load_auto(...)
  local sess = self:get_selection("auto", ...)
  self:close(...)
  if not sess then
    return
  end
  require("finni.auto").switch(sess.session, sess.project)
end

--- Load the autosession selected from overview of all projects.
function Picker:load_auto_all(...)
  local sess = self:get_selection("auto_all", ...)
  self:close(...)
  if not sess then
    return
  end
  require("finni.auto").switch(sess.session, sess.project)
end

--- Delete the autosession selected from overview of single project.
function Picker:delete_auto(...)
  local sess = self:get_selection("auto", ...)
  if not sess then
    return
  end
  require("finni.auto").delete(sess.session, sess.project)
  self:refresh({ "auto", sess.project }, ...)
end

--- Delete the autosession selected from overview of all projects.
function Picker:delete_auto_all(...)
  local sess = self:get_selection("auto_all", ...)
  if not sess then
    return
  end
  require("finni.auto").delete(sess.session, sess.project)
  self:refresh({ "auto_all" }, ...)
end

--- Open an autosession picker for the selected project.
function Picker:select_project(...)
  local project = self:get_selection("project", ...)
  return self:auto_picker(project)
end

--- Delete the selected project.
function Picker:delete_project(...)
  local proj = self:get_selection("project", ...)
  require("finni.auto").reset_project({ name = proj })
  self:refresh({ "project" }, ...)
end

--- Receive selecttion. Abstract method.
---@overload fun(typ: "project"|"manual", ...): string?
---@overload fun(typ: "auto"|"auto_all", ...): {session: string, project: string}?
---@param typ PickerTypes Active picker type
---@param ... any
---@return (string|{session: string, project: string})?
function Picker:get_selection(typ, ...)
  error("Not implemented")
end

--- Close picker. Abstract method.
---@param ... any
function Picker:close(...)
  error("Not implemented")
end

--- Refresh picker. Abstract method.
---@param ... any
function Picker:refresh(...)
  error("Not implemented")
end

--- Close current picker and go to project overview. Abstract method.
---@param ... any
function Picker:back_to_projects(...)
  self:close(...)
  return self:project_picker()
end

--- Implement default logic for project names.
---@return string?
function Picker:resolve_project(project_name)
  project_name = project_name or require("finni.auto").current_project()
  if not project_name then
    vim.notify("Finni: Could not find active project", vim.log.levels.WARN)
    return
  end
  return project_name
end

--- Merge picker plugin specific opts
---@param typ PickerTypes
---@param ... table Variadic tables to merge on top of defaults
function Picker:resolve_opts(typ, ...)
  return vim.tbl_deep_extend("force", self.raw.default, self.raw[typ], ...)
end

---@param defaults Partial<PickerConfig>
---@param opts? Partial<PickerConfig>
---@return self
function Picker.new(defaults, opts)
  error("Not implemented")
end

--- Load or delete existing manual sessions. Abstract method.
function Picker:manual_picker()
  error("Not implemented")
end

--- Load or delete existing autosessions in specific project only. Abstract method.
---@param project_name? string List autosessions from this project. Defaults to current one.
function Picker:auto_picker(project_name)
  error("Not implemented")
end

--- Load or delete existing autosessions spanning all projects. Abstract method.
function Picker:auto_all_picker()
  error("Not implemented")
end

--- Load or delete existing manual sessions. Abstract method.
function Picker:project_picker()
  error("Not implemented")
end

---@type PickerConfig
local picker_config_base = {
  dir = nil,
  raw = {
    default = {},
    manual = {},
    auto_all = {},
    auto = {},
    project = {},
  },
}

---@return Picker
function M.new_picker()
  local pkr = setmetatable({}, { __index = Picker })
  pkr.new = function(defaults, opts)
    ---@diagnostic disable-next-line: param-type-mismatch
    local pconf = vim.tbl_deep_extend("force", picker_config_base, defaults, opts or {})
    return setmetatable(pconf --[[@as table]], pkr)
  end
  pkr.__index = pkr
  return pkr
end

return M
