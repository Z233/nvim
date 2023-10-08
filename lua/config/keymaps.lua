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
else
    -- ordinary Neovim
end

map("n", "cL", "cg_", { desc = "Change till line end" })
map("n", "vL", "vg_", { desc = "Visual till line end" })
map("n", "dL", "dg_", { desc = "Delete till line end" })
map("n", "yL", "yg_", { desc = "Yank till line end" })
map("n", "cH", "cg0", { desc = "Change till line start" })
map("n", "vH", "vg0", { desc = "Visual till line start" })
map("n", "dH", "dg0", { desc = "Delete till line start" })
map("n", "yH", "yg0", { desc = "Yank till line start" })

-- map("o", "L", "g_", { desc: "Move to end of line" });

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })

map("n", "<leader>ef", '<Cmd>call VSCodeNotify("eslint.executeAutofix")<CR>', { desc = "ESLint: Fix all auto-fixable Problems" })
map("n", "gl", '<Cmd>call VSCodeNotify("editor.action.goToTypeDefinition")<CR>', { desc = "Go to Type Definition" })
map("v", "<leader>cf", '<Cmd>call VSCodeNotify("editor.action.formatSelection")<CR>', { desc = "Format selection" } )

map("n", "<A-c>", '<Cmd>call VSCodeNotify("workbench.files.action.showActiveFileInExplorer")<CR>')

map("n", "gr", '<Cmd>call VSCodeNotify("editor.action.goToReferences")<CR>', { desc = "Go to references" })

map({'n', 'v'}, "<leader>cl", '<Cmd>call VSCodeNotify("turboConsoleLog.displayLogMessage")<CR>', { desc = "Turbo Console Log: Display Log Message" } )

map("n", "<leader>cr", '<Cmd>call VSCodeNotify("editor.action.rename")<CR>')