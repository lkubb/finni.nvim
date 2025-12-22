-- Add current directory to 'runtimepath' to be able to use 'lua' files
local this_file = debug.getinfo(1, "S").source:sub(2)
vim.g.finni_root = this_file:match("(.*)/scripts/minimal_init%.lua") or vim.fn.getcwd()
vim.opt.rtp:append(vim.g.finni_root)
-- vim.cmd([[let &rtp.=','.getcwd()]])

vim.o.swapfile = false
vim.bo.swapfile = false

-- Set up 'mini.test' only when calling headless Neovim (like with `make test`)
if #vim.api.nvim_list_uis() == 0 then
  -- Add 'mini.nvim' to 'runtimepath' to be able to use 'mini.test'
  -- Assumed that 'mini.nvim' is stored in 'deps/mini.nvim'
  vim
    .iter({
      "fzf-lua",
      "gitsigns.nvim",
      "mini.nvim",
      "plenary.nvim",
      "snacks.nvim",
      "telescope.nvim",
      "oil.nvim",
    })
    :each(function(dep)
      vim.opt.rtp:append(vim.fs.joinpath(vim.g.finni_root, "deps", dep))
    end)

  -- Set up 'mini.test'
  require("mini.test").setup()
end

local init_file = vim.fs.joinpath(vim.g.finni_root, ".test", "nvim_init.lua")
local function _logerr(msg)
  local fconf = require("finni.config")
  if not fconf.log then
    vim.g.finni_config = vim.g.finni_config
      or {
        log = {
          handler = function(rend)
            local l = vim.g.LOG or {}
            l[#l + 1] = rend
            vim.g.LOG = l
          end,
          level = "trace",
        },
      }
    fconf.setup()
  end
  require("finni.log").error(msg)
end

-- Allow to inject lua code that is run during nvim initialization.
-- Necessary to test autosession behavior and snapshot restoration in VimEnter.
if vim.uv.fs_stat(init_file) then
  local init_func_builder = loadfile(init_file)
  if init_func_builder then
    local ok, init_func = pcall(init_func_builder)
    if not ok then
      ---@cast init_func string
      _logerr(init_func)
      return
    end
    ---@cast init_func -string
    local _ok, err = pcall(init_func)
    if not _ok then
      ---@cast err string
      _logerr(err)
      return
    end
  end
end
