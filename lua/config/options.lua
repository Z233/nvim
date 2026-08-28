-- ~/.config/nvim/lua/config/options.lua

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.user_emmet_leader_key = "<C-C>"

-- Disable netrw (neo-tree replaces it)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Encoding
vim.cmd("language en_US.UTF-8")

-- Appearance
vim.opt.termguicolors = true
vim.opt.guifont = "Dank Mono:h15"
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Scrolling
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.smoothscroll = true

-- Editing
if vim.fn.has("mac") == 1 and not vim.g.vscode then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC 52 copy with pbpaste",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = { "pbpaste" },
      ["*"] = { "pbpaste" },
    },
    cache_enabled = 0,
  }
end
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
vim.opt.wrap = false
vim.opt.mouse = "a"

-- Performance
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- VSCode: suppress all messages to prevent output panel auto-opening
if vim.g.vscode then
  vim.notify = function() end
end

-- VSCode: suppress all messages to prevent output panel auto-opening
if vim.g.vscode then
  vim.notify = function() end
end
