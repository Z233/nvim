-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here


local autocmd = vim.api.nvim_create_autocmd

autocmd("BufEnter", {
  callback = function()
    vim.opt.formatoptions:remove { "c", "r", "o" }
  end,
  group = general,
  desc = "Disable New Line Comment",
})


autocmd("TextYankPost", {
  callback = function()
    require("vim.highlight").on_yank { higroup = "YankHighlight", timeout = 200 }
  end,
  group = general,
  desc = "Highlight when yanking",
})