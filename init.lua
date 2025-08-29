vim.g.user_emmet_leader_key = "<C-C>"

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

local function parse_clipboard_to_plain_text()
  local clipboard_content = vim.fn.getreg("+")
  local processed_content = clipboard_content:match("^%s*(.-)%s*$")
  vim.fn.setreg("*", processed_content)
  vim.fn.setreg("+", processed_content)
end

vim.api.nvim_create_user_command("ParseClipboardToPlainText", parse_clipboard_to_plain_text, {})

