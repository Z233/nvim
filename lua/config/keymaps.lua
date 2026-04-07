local map = vim.keymap.set

-- Spider word motions
map({ "n", "o", "x" }, "w", "<cmd>lua require('spider').motion('w')<CR>", { desc = "Spider-w" })
map({ "n", "o", "x" }, "e", "<cmd>lua require('spider').motion('e')<CR>", { desc = "Spider-e" })
map({ "n", "o", "x" }, "b", "<cmd>lua require('spider').motion('b')<CR>", { desc = "Spider-b" })
map({ "n", "o", "x" }, "ge", "<cmd>lua require('spider').motion('ge')<CR>", { desc = "Spider-ge" })

-- Line operations
map("n", "cL", "cg_", { desc = "Change till line end" })
map("n", "vL", "vg_", { desc = "Visual till line end" })
map("n", "dL", "dg_", { desc = "Delete till line end" })
map("n", "yL", "yg_", { desc = "Yank till line end" })
map("n", "cH", "cg0", { desc = "Change till line start" })
map("n", "vH", "vg0", { desc = "Visual till line start" })
map("n", "dH", "dg0", { desc = "Delete till line start" })
map("n", "yH", "yg0", { desc = "Yank till line start" })

-- Easy motion
local easy_motion = require("utils.easy-motion")
map({ "n", "x" }, "s", easy_motion.jump, { desc = "Jump to 2 characters" })

-- Stay in visual mode after indent
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Make U opposite of u (redo)
map("n", "U", "<C-r>", { desc = "Redo" })

-- Powerful escape: clear highlights
map({ "i", "n" }, "<Esc>", function()
  vim.cmd("noh")
  return "<Esc>"
end, { expr = true, desc = "Escape and clear hlsearch" })

-- Auto-mark before search
map("n", "/", "ms/", { desc = "Search forward (mark s)" })
map("n", "?", "ms?", { desc = "Search backward (mark s)" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })

-- Clipboard paste
local function parse_clipboard_to_plain_text()
  local clipboard_content = vim.fn.getreg("+")
  local processed_content = clipboard_content:match("^%s*(.-)%s*$")
  vim.fn.setreg("*", processed_content)
  vim.fn.setreg("+", processed_content)
end

vim.api.nvim_create_user_command("ParseClipboardToPlainText", parse_clipboard_to_plain_text, {})
map({ "n", "v" }, "<leader>p", "<Cmd>ParseClipboardToPlainText<CR>p", { noremap = true, silent = true })

-- Copy file path
local function copyFilePath()
  local file = vim.fn.expand("%:p")
  file = string.format("@%s", file)
  vim.fn.setreg("+", file)
  print("Copied: " .. file)
end

local function copyFileWithLine()
  local file = vim.fn.expand("%:p")
  local line_start = vim.fn.line("v")
  local line_end = vim.fn.line(".")

  local location
  if vim.fn.mode() == "v" or vim.fn.mode() == "V" then
    if line_start > line_end then
      line_start, line_end = line_end, line_start
    end
    if line_start == line_end then
      location = string.format("@%s#L%d", file, line_start)
    else
      location = string.format("@%s#L%d-%d", file, line_start, line_end)
    end
  else
    location = string.format("@%s#L%d", file, line_end)
  end

  vim.fn.setreg("+", location)
  print("Copied: " .. location)
end

map({ "n", "x" }, "<leader>yf", copyFilePath, { desc = "Copy file path to clipboard" })
map({ "n", "x" }, "<leader>yl", copyFileWithLine, { desc = "Copy file location with line to clipboard" })

-- Buffer navigation (non-VSCode only)
if not vim.g.vscode then
  map("n", "gt", "<cmd>bnext<cr>", { desc = "Next Buffer" })
  map("n", "gT", "<cmd>bprev<cr>", { desc = "Prev Buffer" })
  map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
  map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete Buffer" })
  map("n", "<leader>bo", "<cmd>%bd|e#|bd#<cr><c-o>", { desc = "Delete Other Buffers" })
end

-- VSCode keymaps
if vim.g.vscode then
  require("config.keymaps-vscode")
end
