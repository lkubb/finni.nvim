---@diagnostic disable: unused
---@namespace finni.pickers
local common = require("finni.pickers.common")

local fzf ---@type fzf-lua

---@class fzf_lua
local M = {}

--- Lazy-init imports and register extension
local function init()
  fzf = fzf or require("fzf-lua")
  fzf.register_extension("finni_manual", M.manual_picker)
  fzf.register_extension("finni_auto", M.auto_picker)
  fzf.register_extension("finni_auto_all", M.auto_all_picker)
  fzf.register_extension("finni_project", M.project_picker)
end

---@class FZFFinni: Picker
local FZFFinni = common.new_picker()

function FZFFinni:get_selection(typ, item)
  if typ == "auto_all" then
    local splt = vim.split(assert(item[1]), " | ", { plain = true })
    return { project = assert(splt[1]), session = assert(splt[2]) }
  elseif typ == "auto" then
    local splt = vim.split(assert(item[1]), "[\\|:", { plain = true })
    return { project = assert(splt[1]), session = assert(splt[2]) }
  else
    return item[1]
  end
end

--- Noop, fzf-lua closes automatically
function FZFFinni:close() end

function FZFFinni:refresh(args)
  -- Cannot resume, just start a new picker
  -- TODO: Maybe we can restore the query though?
  if args[1] == "manual" then
    return self:manual_picker()
  elseif args[1] == "auto" then
    return self:auto_picker(args[2])
  elseif args[1] == "auto_all" then
    return self:auto_all_picker()
  elseif args[1] == "project" then
    return self:project_picker()
  end
end

function FZFFinni:manual_picker()
  local opts = self:resolve_opts("manual", {
    prompt = "Finni Manual Sessions❯ ",
    actions = {
      default = self:wrap("load_manual"),
      ["alt-d"] = self:wrap("delete_manual"),
    },
  })
  fzf.fzf_exec(function(fzf_cb)
    vim.iter(self:list_manual()):each(fzf_cb)
    fzf_cb()
  end, opts)
end

--- Load or delete existing autosessions spanning all projects.
function FZFFinni:auto_all_picker()
  local opts = self:resolve_opts("auto_all", {
    prompt = "Finni Autosessions [all projects]❯ ",
    actions = {
      default = self:wrap("load_auto_all"),
      ["alt-d"] = self:wrap("delete_auto_all"),
    },
  })
  fzf.fzf_exec(function(fzf_cb)
    vim.iter(self:list_auto_all()):each(function(s)
      fzf_cb(s.project .. " | " .. s.session)
    end)
    fzf_cb()
  end, opts)
end

--- Load or delete existing autosessions in specific project only.
---@param project_name? string List autosessions from this project. Defaults to current one.
function FZFFinni:auto_picker(project_name)
  project_name = self:resolve_project(project_name)
  if not project_name then
    return
  end
  local opts = self:resolve_opts("auto", {
    prompt = ("Finni Autosessions [%s]❯ "):format(project_name),
    actions = {
      default = self:wrap("load_auto"),
      ["alt-d"] = self:wrap("delete_auto"),
      ["ctrl-6"] = self:wrap("back_to_projects"),
    },
    fzf_opts = {
      ["--delimiter"] = "[\\):]",
      ["--with-nth"] = "2..",
    },
  })
  fzf.fzf_exec(function(fzf_cb)
    vim
      .iter(self:list_auto(project_name))
      :map(function(v)
        return v.project .. "[\\|:" .. v.session
      end)
      :each(fzf_cb)
    fzf_cb()
  end, opts)
end

--- Inspect or delete existing projects. Select project to manage/load its autosessions.
function FZFFinni:project_picker()
  local opts = self:resolve_opts("auto", {
    prompt = "Finni Autosession Projects❯ ",
    actions = {
      default = self:wrap("select_project"),
      ["alt-d"] = self:wrap("delete_project"),
    },
  })
  fzf.fzf_exec(function(fzf_cb)
    vim.iter(self:list_projects()):each(fzf_cb)
    fzf_cb()
  end, opts)
end

---@type Partial<PickerConfig>
local config = {}

--- Override picker defaults and register extensions.
---@param opts? Partial<PickerConfig> Defaults for future calls.
---@param register? boolean #
--- Force registering extensions to be able to launch pickers via the `FzfLua` Ex command.
--- Note: Loads `fzf-lua`.
function M.setup(opts, register)
  config = opts or {}
  if package.loaded["fzf-lua"] or register then
    init()
  end
end

--- Load or delete existing manual sessions.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
function M.manual_picker(opts)
  ---@diagnostic disable-next-line: param-type-mismatch
  FZFFinni.new(config, opts):manual_picker()
end

--- Load or delete existing autosessions spanning all projects.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
function M.auto_all_picker(opts)
  ---@diagnostic disable-next-line: param-type-mismatch
  FZFFinni.new(config, opts):auto_all_picker()
end

--- Load or delete existing autosessions in specific project only.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
---@param project_name? string List autosessions from this project. Defaults to current one.
function M.auto_picker(opts, project_name)
  ---@diagnostic disable-next-line: param-type-mismatch
  FZFFinni.new(config, opts):auto_picker(project_name)
end

--- Inspect or delete existing projects. Select project to manage/load its autosessions.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
function M.project_picker(opts)
  ---@diagnostic disable-next-line: param-type-mismatch
  FZFFinni.new(config, opts):project_picker()
end

if package.loaded["fzf-lua"] then
  -- If fzf-lua is already loaded, register ourselves immediately.
  init()
else
  M = common.lazy_init(M, init)
end

return M
