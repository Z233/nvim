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
  local vscode = require("vscode-neovim")
  
  pcall(vim.keymap.del, "n", "]d")
  pcall(vim.keymap.del, "n", "[d")
  pcall(vim.keymap.del, "n", "]D")
  pcall(vim.keymap.del, "n", "[D")
  
  -- VSCode specific keymap helper function
  local function vmap(mode, lhs, command, opts)
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, function()
      vscode.call(command)
    end, opts)
  end

  -- #region Code Actions

  vmap("n", "<leader>ef", "eslint.executeAutofix", { desc = "ESLint: Fix all auto-fixable Problems" })
  vmap("v", "<leader>f", "editor.action.formatSelection", { desc = "Format selection" })
  vmap("n", "gl", "editor.action.goToTypeDefinition", { desc = "Go to Type Definition" })
  vmap("n", "<leader>cr", "editor.action.rename")
  vmap("n", "<leader>cd", "comment-divider.insertSolidLine")
  vmap("n", "<leader>cm", "comment-divider.makeMainHeader")

  -- Complex VSCode functions that need direct vscode.call
  local function goToImplementationAside()
    vscode.call("editor.action.goToImplementation")
    vscode.call("workbench.action.moveEditorToRightGroup")
  end

  local function goToTypeDefinitionAside()
    vscode.call("editor.action.goToTypeDefinition")
    vscode.call("workbench.action.moveEditorToRightGroup")
  end

  vmap("n", "gi", "editor.action.goToImplementation")
  map("n", "<C-w>gi", goToImplementationAside)
  map("n", "<C-w>gl", goToTypeDefinitionAside)

  -- map("n", "<C-w>gd", '<Cmd>call VSCodeNotify("references-view.findReferences")<CR>')

  -- #endregion

  -- Git

  vmap("n", "<leader>gi", "merge-conflict.accept.incoming", { desc = "Merge Conflict: Accept Incoming" })
  vmap("n", "<leader>gc", "merge-conflict.accept.current", { desc = "Merge Conflict: Accept Current" })
  vmap("n", "<leader>gb", "merge-conflict.accept.both", { desc = "Merge Conflict: Accept Both" })
  vmap({ "n", "v" }, "<leader>gt", "git.revertSelectedRanges", { desc = "Git: Revert Selected Ranges" })

  -- Dirty Diff / Changes
  vmap("n", "]d", "workbench.action.editor.nextChange", { desc = "Go to Next Change" })
  vmap("n", "[d", "workbench.action.editor.previousChange", { desc = "Go to Previous Change" })
  vmap("n", "]D", "editor.action.dirtydiff.next", { desc = "Show Next Change (inline diff)" })
  vmap("n", "[D", "editor.action.dirtydiff.previous", { desc = "Show Previous Change (inline diff)" })

  -- Error Navigation

  vmap("n", "[e", "go-to-next-error.prev.error")
  vmap("n", "]e", "go-to-next-error.next.error")

  -- #region vscode-multi-cursor

  map({ "n", "v" }, "gb", "mciw*<Cmd>nohl<CR>", { remap = true })

  -- #endregion

  vmap("n", "<A-c>", "workbench.files.action.showActiveFileInExplorer")
  vmap("n", "gr", "editor.action.goToReferences", { desc = "Go to references" })
  vmap({ "n", "v" }, "<leader>cl", "turboConsoleLog.displayLogMessage", { desc = "Turbo Console Log: Display Log Message" })
  vmap({ "n", "v" }, "]l", "editor.action.marker.nextInFiles", { desc = "Go to Next Problem in Files (Error, Warning, Info)" })
  vmap({ "n", "v" }, "[l", "editor.action.marker.prevInFiles", { desc = "Go to Previous Problem in Files (Error, Warning, Info)" })

  -- Folding
  vmap("n", "zM", "editor.foldAll", { desc = "Fold All" })
  vmap("n", "zR", "editor.unfoldAll", { desc = "Unfold All" })
  vmap("n", "zc", "editor.fold", { desc = "Fold" })
  vmap("n", "zC", "editor.foldRecursively", { desc = "Fold Recursively" })
  vmap("n", "zo", "editor.unfold", { desc = "Unfold" })
  vmap("n", "zO", "editor.unfoldRecursively", { desc = "Unfold Recursively" })
  vmap("n", "za", "editor.toggleFold", { desc = "Toggle Fold" })

  -- Copy file path and line number to clipboard
  local function copyFileLocation()
    vscode.eval([[
      const editor = vscode.window.activeTextEditor;
      if (editor) {
        const relativePath = vscode.workspace.asRelativePath(editor.document.uri);
        const lineNumber = editor.selection.active.line + 1; // Convert to 1-indexed
        const location = `${relativePath}:${lineNumber}`;
        await vscode.env.clipboard.writeText(location);
        return location;
      }
      return null;
    ]])
  end

  map("n", "<leader>yf", copyFileLocation, { desc = "Copy file location to clipboard" })
end
