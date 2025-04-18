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

map({ "n", "o", "x" }, "w", "<cmd>lua require('spider').motion('w')<CR>", { desc = "Spider-w" })
map({ "n", "o", "x" }, "e", "<cmd>lua require('spider').motion('e')<CR>", { desc = "Spider-e" })
map({ "n", "o", "x" }, "b", "<cmd>lua require('spider').motion('b')<CR>", { desc = "Spider-b" })
map({ "n", "o", "x" }, "ge", "<cmd>lua require('spider').motion('ge')<CR>", { desc = "Spider-ge" })

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

map({ "n", "v" }, "<leader>p", "<Cmd>ParseClipboardToPlainText<CR>p", { noremap = true, silent = true })

if vim.g.vscode then
  -- #region Code Actions

  map(
    "n",
    "<leader>ef",
    '<Cmd>call VSCodeNotify("eslint.executeAutofix")<CR>',
    { desc = "ESLint: Fix all auto-fixable Problems" }
  )
  map("v", "<leader>f", '<Cmd>call VSCodeNotify("editor.action.formatSelection")<CR>', { desc = "Format selection" })

  map("n", "gl", '<Cmd>call VSCodeNotify("editor.action.goToTypeDefinition")<CR>', { desc = "Go to Type Definition" })

  map("n", "<leader>cr", '<Cmd>call VSCodeNotify("editor.action.rename")<CR>')
  map("n", "<leader>cd", '<Cmd>call VSCodeNotify("comment-divider.insertSolidLine")<CR>')
  map("n", "<leader>cm", '<Cmd>call VSCodeNotify("comment-divider.makeMainHeader")<CR>')

  local function goToImplementationAside()
    local vscode = require("vscode-neovim")
    vscode.call("editor.action.goToImplementation")
    vscode.call("workbench.action.moveEditorToRightGroup")
  end

  map("n", "gi", '<Cmd>call VSCodeNotify("editor.action.goToImplementation")<CR>')
  map("n", "<C-w>gi", goToImplementationAside)

  local function goToTypeDefinitionAside()
    local vscode = require("vscode-neovim")
    vscode.call("editor.action.goToTypeDefinition")
    vscode.call("workbench.action.moveEditorToRightGroup")
  end

  map("n", "<C-w>gl", goToTypeDefinitionAside)

  -- map("n", "<C-w>gd", '<Cmd>call VSCodeNotify("references-view.findReferences")<CR>')

  -- #endregion

  -- Git

  map(
    "n",
    "<leader>gi",
    '<Cmd>call VSCodeNotify("merge-conflict.accept.incoming")<CR>',
    { desc = "Merge Conflict: Accept Incoming" }
  )

  map(
    "n",
    "<leader>gc",
    '<Cmd>call VSCodeNotify("merge-conflict.accept.current")<CR>',
    { desc = "Merge Conflict: Accept Current" }
  )

  map(
    "n",
    "<leader>gb",
    '<Cmd>call VSCodeNotify("merge-conflict.accept.both")<CR>',
    { desc = "Merge Conflict: Accept Both" }
  )

  map(
    "n",
    "<leader>gt",
    '<Cmd>call VSCodeNotify("git.revertSelectedRanges")<CR>',
    { desc = "Git: Revert Selected Ranges" }
  )

  --

  -- Error Navigation

  map("n", "[e", '<Cmd>call VSCodeNotify("go-to-next-error.prev.error")<CR>')
  map("n", "]e", '<Cmd>call VSCodeNotify("go-to-next-error.next.error")<CR>')

  -- #region vscode-multi-cursor

  map({ "n", "v" }, "gb", "mciw*<Cmd>nohl<CR>", { remap = true })

  -- #endregion

  map("n", "<A-c>", '<Cmd>call VSCodeNotify("workbench.files.action.showActiveFileInExplorer")<CR>')

  map("n", "gr", '<Cmd>call VSCodeNotify("editor.action.goToReferences")<CR>', { desc = "Go to references" })

  map(
    { "n", "v" },
    "<leader>cl",
    '<Cmd>call VSCodeNotify("turboConsoleLog.displayLogMessage")<CR>',
    { desc = "Turbo Console Log: Display Log Message" }
  )

  map(
    { "n", "v" },
    "]l",
    '<Cmd>call VSCodeNotify("editor.action.marker.nextInFiles")<CR>',
    { desc = "Go to Next Problem in Files (Error, Warning, Info)" }
  )
  map(
    { "n", "v" },
    "[l",
    '<Cmd>call VSCodeNotify("editor.action.marker.prevInFiles")<CR>',
    { desc = "Go to Previous Problem in Files (Error, Warning, Info)" }
  )
end
