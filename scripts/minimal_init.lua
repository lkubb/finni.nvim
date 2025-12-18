-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.g.finni_root = vim.fn.getcwd()
vim.opt.rtp:append(vim.g.finni_root)
-- vim.cmd([[let &rtp.=','.getcwd()]])

vim.o.swapfile = false
vim.bo.swapfile = false

-- Set up 'mini.test' only when calling headless Neovim (like with `make test`)
if #vim.api.nvim_list_uis() == 0 then
  -- Add 'mini.nvim' to 'runtimepath' to be able to use 'mini.test'
  -- Assumed that 'mini.nvim' is stored in 'deps/mini.nvim'
  vim
    .iter({ "fzf-lua", "mini.nvim", "plenary.nvim", "snacks.nvim", "telescope.nvim", "oil.nvim" })
    :each(function(dep)
      vim.opt.rtp:append(vim.fs.joinpath(vim.g.finni_root, "deps", dep))
    end)

  -- Set up 'mini.test'
  require("mini.test").setup()
end

-- Allow to inject lua code that is run during nvim initialization.
-- Necessary to test autosession behavior and snapshot restoration in VimEnter.
if vim.uv.fs_stat(".test/nvim_init.lua") then
  local init_func = loadfile(".test/nvim_init.lua")
  if init_func then
    init_func()()
  end
end
