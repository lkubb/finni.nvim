---@diagnostic disable: unused, undefined-field
---@namespace finni.pickers
local common = require("finni.pickers.common")

local action_state ---@module "telescope.actions.state"
local actions ---@module "telescope.actions"
local entry_display ---@module "telescope.pickers.entry_display"
local finders ---@module "telescope.finders"
local pickers ---@module "telescope.pickers"
local sorters ---@module "telescope.sorters"
local tconf ---@type table

---@cast action_state -?
---@cast actions -?
---@cast entry_display -?
---@cast finders -?
---@cast pickers -?
---@cast sorters -?

--- Lazy-init imports
local function init()
  action_state = action_state or require("telescope.actions.state")
  actions = actions or require("telescope.actions")
  entry_display = entry_display or require("telescope.pickers.entry_display")
  finders = finders or require("telescope.finders")
  pickers = pickers or require("telescope.pickers")
  sorters = sorters or require("telescope.sorters")
  tconf = tconf or require("telescope.config").values
end

---@class TeleFinni: Picker
local TeleFinni = common.new_picker()

function TeleFinni:get_selection(typ, _bufnr)
  local sel = action_state.get_selected_entry()
  if typ == "manual" then
    return sel[1]
  else
    return sel.value
  end
end

---@param bufnr integer
function TeleFinni:close(bufnr)
  actions.close(bufnr)
end

function TeleFinni:refresh(args, bufnr)
  local finder
  if args[1] == "manual" then
    finder = self:manual_finder()
  elseif args[1] == "auto" then
    finder = self:auto_finder(args[2])
  elseif args[1] == "auto_all" then
    finder = self:auto_all_finder()
  elseif args[1] == "project" then
    finder = self:project_finder()
  end
  local picker = action_state.get_current_picker(bufnr)
  picker:refresh(finder)
end

--- Create a finder for all manual sessions.
---@return table
function TeleFinni:manual_finder()
  return finders.new_table({
    results = self:list_manual(),
  })
end

--- Create separate columns for projects and sessions
---@param entry? table
---@return string?
---@return table?
function TeleFinni:auto_all_display(entry)
  if not entry then
    return
  end

  local layout, columns
  columns = {
    { entry.value.project },
    { entry.value.session },
  }
  layout = {
    separator = " ",
    items = {
      { width = 50 },
      {},
    },
  }

  local displayer = entry_display.create(layout)
  return displayer(columns)
end

--- Create a finder for all autosessions, spanning all projects.
---@return table
function TeleFinni:auto_all_finder()
  return finders.new_table({
    results = self:list_auto_all(),
    entry_maker = function(entry)
      local fmt = entry.project .. "@" .. entry.session
      return {
        value = entry,
        display = self:wrap("auto_all_display"),
        ordinal = fmt,
      }
    end,
  })
end

--- Create a finder for all autosessions in a project.
---@param project_name? string Project name to list autosessions for.
---@return table
function TeleFinni:auto_finder(project_name)
  return finders.new_table({
    results = self:list_auto(project_name),
    entry_maker = function(entry)
      return {
        value = entry,
        display = entry.session,
        ordinal = entry.session,
      }
    end,
  })
end

--- Create a finder for all projects.
---@return table
function TeleFinni:project_finder()
  return finders.new_table({
    results = self:list_projects(),
  })
end

--- Load or delete existing manual sessions.
function TeleFinni:manual_picker()
  local opts = vim.tbl_deep_extend("force", self.raw.default, self.raw.manual)
  return pickers
    .new(opts, {
      prompt_title = "Finni Manual Sessions",
      finder = self:manual_finder(),
      sorter = tconf.generic_sorter(opts),
      attach_mappings = function(_bufnr, map)
        actions.select_default:replace(self:wrap("load_manual"))
        map("n", "<M-d>", self:wrap("delete_manual"))
        map("i", "<M-d>", self:wrap("delete_manual"))
        return true
      end,
    })
    :find()
end

--- Load or delete existing autosessions spanning all projects.
function TeleFinni:auto_all_picker()
  local opts = self:resolve_opts("auto_all")
  return pickers
    .new(opts, {
      prompt_title = "Finni Autosessions [all projects]",
      finder = self:auto_all_finder(),
      sorter = tconf.generic_sorter(opts),
      attach_mappings = function(_bufnr, map)
        actions.select_default:replace(self:wrap("load_auto_all"))
        map("n", "<M-d>", self:wrap("delete_auto_all"))
        map("i", "<M-d>", self:wrap("delete_auto_all"))
        return true
      end,
    })
    :find()
end

--- Load or delete existing autosessions in specific project only.
---@param project_name? string List autosessions from this project. Defaults to current one.
function TeleFinni:auto_picker(project_name)
  project_name = self:resolve_project(project_name)
  if not project_name then
    return
  end
  local opts = self:resolve_opts("auto")
  return pickers
    .new(opts, {
      prompt_title = ("Finni Autosessions [%s]"):format(project_name),
      finder = self:auto_finder(project_name),
      sorter = tconf.generic_sorter(opts),
      attach_mappings = function(_bufnr, map)
        actions.select_default:replace(self:wrap("load_auto"))
        map("n", "<M-d>", self:wrap("delete_auto"))
        map("i", "<M-d>", self:wrap("delete_auto"))
        map("n", "<C-^>", self:wrap("back_to_projects"))
        map("i", "<C-^>", self:wrap("back_to_projects"))
        return true
      end,
    })
    :find()
end

--- Inspect or delete existing projects. Select project to manage/load its autosessions.
function TeleFinni:project_picker()
  local opts = vim.tbl_deep_extend("force", self.raw.default, self.raw.project)
  return pickers
    .new(opts, {
      prompt_title = "Finni Autosession Projects",
      finder = self:project_finder(),
      sorter = tconf.generic_sorter(opts),
      attach_mappings = function(_bufnr, map)
        actions.select_default:replace(self:wrap("select_project"))
        map("n", "<M-d>", self:wrap("delete_project"))
        map("i", "<M-d>", self:wrap("delete_project"))
        return true
      end,
    })
    :find()
end

---@class telescope
local M = {}

---@type Partial<PickerConfig>
local config = {}

--- Override picker defaults
---@param opts? Partial<PickerConfig> Defaults for future calls.
function M.setup(opts)
  config = opts or {}
  -- Since Telescope has an extensions system, we don't need to register at all.
end

--- Load or delete existing manual sessions.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
function M.manual_picker(opts)
  ---@diagnostic disable-next-line: param-type-mismatch
  TeleFinni.new(config, opts):manual_picker()
end

--- Load or delete existing autosessions spanning all projects.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
function M.auto_all_picker(opts)
  ---@diagnostic disable-next-line: param-type-mismatch
  TeleFinni.new(config, opts):auto_all_picker()
end

--- Load or delete existing autosessions in specific project only.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
---@param project_name? string List autosessions from this project. Defaults to current one.
function M.auto_picker(opts, project_name)
  ---@diagnostic disable-next-line: param-type-mismatch
  TeleFinni.new(config, opts):auto_picker(project_name)
end

--- Inspect or delete existing projects. Select project to manage/load its autosessions.
---@param opts? Partial<PickerConfig> Override Finni-specific and picker-specific options.
function M.project_picker(opts)
  ---@diagnostic disable-next-line: param-type-mismatch
  TeleFinni.new(config, opts):project_picker()
end

return common.lazy_init(M, init)
