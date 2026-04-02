-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.guifont = "Dank Mono:h15"
vim.opt.clipboard = "unnamedplus"

vim.cmd("language en_US.UTF-8")

if not vim.g.vscode then
  vim.opt.relativenumber = true
  vim.opt.scrolloff = 8
  vim.opt.sidescrolloff = 8
  vim.opt.undofile = true
  vim.opt.wrap = false
  vim.opt.smoothscroll = true
end
