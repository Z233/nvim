-- ~/.config/nvim/init.lua

require("config.options")

-- Recover filetype when a real file buffer enters a window without it.
-- Built-in detection runs on BufRead; neo-tree occasionally misses it when
-- opening files from `nvim .`, which leaves the whole FileType chain
-- (LSP, ftplugin, treesitter) disabled. Assigning filetype here re-fires it.
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("recover_filetype", { clear = true }),
  callback = function(event)
    if vim.bo[event.buf].buftype ~= "" or vim.bo[event.buf].filetype ~= "" then
      return
    end
    if vim.api.nvim_buf_get_name(event.buf) == "" then
      return
    end
    local filetype = vim.filetype.match({ buf = event.buf })
    if filetype then
      vim.bo[event.buf].filetype = filetype
    end
  end,
})

-- Hide the empty bootstrap buffer left behind by remote editor clients.
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("hide_empty_bootstrap_buffer", { clear = true }),
  callback = function(event)
    if vim.api.nvim_buf_get_name(event.buf) == "" then
      return
    end

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if
        buf ~= event.buf
        and vim.api.nvim_buf_get_name(buf) == ""
        and vim.bo[buf].buftype == ""
        and not vim.bo[buf].modified
      then
        vim.bo[buf].buflisted = false
      end
    end
  end,
})

require("config.lazy")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    require("config.keymaps")
    require("config.autocmds")
  end,
})
