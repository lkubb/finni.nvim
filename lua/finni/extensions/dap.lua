local M = {}

--- Back up all breakpoints.
---@return {breakpoints: any[]}? save_data #
function M.on_save()
  if not package.loaded["dap"] then
    return nil
  end
  local breakpoints = require("dap.breakpoints")
  local all_breakpoints = {}
  for bufnr, bps in pairs(breakpoints.get()) do
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    for _, bp in ipairs(bps) do
      bp.filename = bufname
      table.insert(all_breakpoints, bp)
    end
  end
  return {
    breakpoints = all_breakpoints,
  }
end

--- Restore backed up breakpoints.
---@param data {breakpoints: any[]} Save data from `on_save`
function M.on_post_load(data)
  local dap = require("dap")
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
      dap.set_breakpoint(bp.condition, bp.hit_condition, bp.log_message)
    end
  end

  vim.api.nvim_win_set_buf(0, cur_bufnr)
  vim.fn.winrestview(view)
end

return M
