-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    if opts.remap and not vim.g.vscode then
      opts.remap = nil
    end
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

if vim.g.vscode then
    -- VSCode extension
    -- vim.cmd('source ' .. vim.fn.stdpath('config') .. '\\vim\\vscode-neovim.vim')
else
    -- ordinary Neovim
end

map("n", "cL", "vg_c", { desc = "Change till line end" })
map("n", "<leader>gd", "<Cmd>call VSCodeNotify('editor.action.revealDefinitionAside')<CR>", { desc = "Go to definition aside" })
