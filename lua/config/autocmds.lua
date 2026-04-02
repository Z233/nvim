-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local autocmd = vim.api.nvim_create_autocmd

-- Yank history: rotate yanks into numbered registers (simple yank ring)
autocmd("TextYankPost", {
  callback = function()
    local op = vim.v.event.operator
    if op == "y" or op == "d" or op == "c" then
      for i = 9, 2, -1 do
        vim.fn.setreg(tostring(i), vim.fn.getreg(tostring(i - 1)))
      end
      vim.fn.setreg("1", vim.fn.getreg('"'))
    end
  end,
})
