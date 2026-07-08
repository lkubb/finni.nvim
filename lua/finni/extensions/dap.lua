local M = {}

---@namespace finni.extensions.dap
---@class Breakpoint: dap.bp
---@field filename string Full filename of the file the breakpoint applies to

--- Back up all breakpoints.
---@return {breakpoints: Breakpoint[]}? save_data #
function M.on_save()
  if not package.loaded["dap"] then
    return nil
  end
  local breakpoints = require("dap.breakpoints") ---@diagnostic disable-line: unresolved-require
  local all_breakpoints = {} ---@type Breakpoint[]
  for bufnr, bps in
    pairs(breakpoints.get()--[[@as table<integer,dap.bp[]>]]) -- function signature is wrong
  do
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    for _, bp in ipairs(bps) do
      ---@cast bp Breakpoint
      bp.filename = bufname
      table.insert(all_breakpoints, bp)
    end
  end
  return {
    breakpoints = all_breakpoints,
  }
end

--- Restore backed up breakpoints.
---@param data {breakpoints: Breakpoint[]} Save data from `on_save`
function M.on_post_load(data)
  local set_bp = require("dap").set_breakpoint ---@diagnostic disable-line: unresolved-require, undefined-field
  local cur_bufnr = vim.api.nvim_get_current_buf()
  local view = vim.fn.winsaveview()

  for _, bp in ipairs(data.breakpoints or {}) do
    local bufnr = vim.fn.bufadd(bp.filename)
    if not vim.api.nvim_buf_is_loaded(bufnr) then
      vim.fn.bufload(bufnr)
    end
    vim.api.nvim_win_set_buf(0, bufnr)
    local set_cursor = pcall(vim.api.nvim_win_set_cursor, 0, { bp.line, 0 })
    if set_cursor then
      set_bp(bp.condition, bp.hitCondition, bp.logMessage)
    end
  end

  vim.api.nvim_win_set_buf(0, cur_bufnr)
  vim.fn.winrestview(view)
end

return M
