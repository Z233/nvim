local vscode = require("vscode-neovim")
local map = vim.keymap.set

pcall(vim.keymap.del, "n", "]d")
pcall(vim.keymap.del, "n", "[d")
pcall(vim.keymap.del, "n", "]D")
pcall(vim.keymap.del, "n", "[D")

local function vmap(mode, lhs, command, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, function()
    vscode.call(command)
  end, opts)
end

-- Code Actions
vmap("n", "<leader>ef", "eslint.executeAutofix", { desc = "ESLint: Fix all auto-fixable Problems" })
vmap("v", "<leader>f", "editor.action.formatSelection", { desc = "Format selection" })
vmap("n", "gl", "editor.action.goToTypeDefinition", { desc = "Go to Type Definition" })
vmap("n", "<leader>cr", "editor.action.rename")
vmap("n", "<leader>cd", "comment-divider.insertSolidLine")
vmap("n", "<leader>cm", "comment-divider.makeMainHeader")

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

-- Git
vmap("n", "<leader>gi", "merge-conflict.accept.incoming", { desc = "Merge Conflict: Accept Incoming" })
vmap("n", "<leader>gc", "merge-conflict.accept.current", { desc = "Merge Conflict: Accept Current" })
vmap("n", "<leader>gb", "merge-conflict.accept.both", { desc = "Merge Conflict: Accept Both" })
vmap({ "n", "v" }, "<leader>gt", "git.revertSelectedRanges", { desc = "Git: Revert Selected Ranges" })
vmap("v", "<leader>gs", "git.stageSelectedRanges", { desc = "Git: Stage Selected Ranges" })
vmap("v", "<leader>gu", "git.unstageSelectedRanges", { desc = "Git: Unstage Selected Ranges" })

-- GitLens Revision Navigation
vmap("n", "]r", "gitlens.diffWithNext", { desc = "GitLens: Diff with Next Revision" })
vmap("n", "[r", "gitlens.diffWithPrevious", { desc = "GitLens: Diff with Previous Revision" })

local lineDiffHistory = require("utils.gitlens-line-history")
map("n", "[R", lineDiffHistory.goToPreviousRevision, { desc = "GitLens: Diff Line with Previous Revision" })
map("n", "]R", lineDiffHistory.goToNextRevision, { desc = "GitLens: Go Back in History" })

-- Dirty Diff / Changes
local gitDiff = require("utils.vscode-git-diff-navigation")
map("n", "]d", gitDiff.goToNextChange, { desc = "Go to Next Change" })
map("n", "[d", gitDiff.goToPreviousChange, { desc = "Go to Previous Change" })
map("n", "]gf", gitDiff.goToNextFile, { desc = "Go to Next Changed File" })
map("n", "[gf", gitDiff.goToPreviousFile, { desc = "Go to Previous Changed File" })
map("n", "<leader>go", gitDiff.openCurrentFileInNormalEditor, { desc = "Git: Open in Normal Editor" })
vmap("n", "]D", "editor.action.dirtydiff.next", { desc = "Show Next Change (inline diff)" })
vmap("n", "[D", "editor.action.dirtydiff.previous", { desc = "Show Previous Change (inline diff)" })

-- Error Navigation
vmap("n", "[e", "go-to-next-error.prev.error")
vmap("n", "]e", "go-to-next-error.next.error")

-- Multi-cursor
map({ "n", "v" }, "gb", "mciw*<Cmd>nohl<CR>", { remap = true })

-- Misc
vmap("n", "<A-c>", "workbench.files.action.showActiveFileInExplorer")
vmap("n", "gr", "editor.action.goToReferences", { desc = "Go to references" })
vmap(
  { "n", "v" },
  "<leader>cl",
  "turboConsoleLog.displayLogMessage",
  { desc = "Turbo Console Log: Display Log Message" }
)
vmap(
  { "n", "v" },
  "]l",
  "editor.action.marker.nextInFiles",
  { desc = "Go to Next Problem in Files (Error, Warning, Info)" }
)
vmap(
  { "n", "v" },
  "[l",
  "editor.action.marker.prevInFiles",
  { desc = "Go to Previous Problem in Files (Error, Warning, Info)" }
)

-- Folding
vmap("n", "zM", "editor.foldAll", { desc = "Fold All" })
vmap("n", "zR", "editor.unfoldAll", { desc = "Unfold All" })
vmap("n", "zc", "editor.fold", { desc = "Fold" })
vmap("n", "zC", "editor.foldRecursively", { desc = "Fold Recursively" })
vmap("n", "zo", "editor.unfold", { desc = "Unfold" })
vmap("n", "zO", "editor.unfoldRecursively", { desc = "Unfold Recursively" })
vmap("n", "za", "editor.toggleFold", { desc = "Toggle Fold" })

-- Scrolling
local scroll = require("utils.vscode-scroll")
map("n", "<C-u>", scroll.scrollHalfPageUp, { desc = "Scroll half page up, cursor centered" })
map("n", "<C-d>", scroll.scrollHalfPageDown, { desc = "Scroll half page down, cursor centered" })

-- Copy commit SHA
local function copyLineCommitSha()
  local line = vim.fn.line(".")
  local file = vim.fn.expand("%:p")
  local output = vim.fn.system({ "git", "blame", "-L", line .. "," .. line, "--porcelain", file })
  local sha = output:match("^(%x+)")

  if sha and sha ~= "" and not sha:match("^0+$") then
    vim.fn.setreg("+", sha)
    vscode.call("editor.action.showHover")
    print("Copied: " .. sha)
  else
    print("No commit SHA found (line not committed yet)")
  end
end

map("n", "<leader>yc", copyLineCommitSha, { desc = "Copy line commit SHA to clipboard" })
