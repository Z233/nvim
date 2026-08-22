local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Yank history: rotate yanks into numbered registers
autocmd("TextYankPost", {
  group = augroup("yank_history", { clear = true }),
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

-- Highlight on yank
autocmd("TextYankPost", {
  group = augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Close special buffers with q
autocmd("FileType", {
  group = augroup("close_with_q", { clear = true }),
  pattern = { "help", "man", "qf", "checkhealth", "notify", "lspinfo", "startuptime" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- LSP multi-location jumps (gd/gD/gI/gy on nvim >= 0.11) open a persistent
-- quickfix pane titled "LSP locations". Selecting an entry with <CR> keeps
-- the builtin jump (.cc/.ll) and then closes the pane automatically.
autocmd("BufWinEnter", {
  group = augroup("lsp_locations_qf", { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "quickfix" then
      return
    end
    local function select_entry()
      local is_loc = vim.fn.win_gettype(0) == "locationlist"
      local title = is_loc
          and vim.fn.getloclist(0, { title = true }).title
          or vim.w.quickfix_title
      local close_pane = title == "LSP locations"
      vim.cmd(is_loc and ".ll" or ".cc") -- builtin jump to entry under cursor
      if close_pane and vim.fn.winnr("$") > 1 then
        vim.cmd(is_loc and "lcl" or "ccl")
      end
    end
    vim.keymap.set("n", "<CR>", select_entry, { buffer = ev.buf, desc = "Select location" })
  end,
})

-- Restore cursor position on file open
autocmd("BufReadPost", {
  group = augroup("restore_cursor", { clear = true }),
  callback = function(event)
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(event.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Auto-create parent directories on save
autocmd("BufWritePre", {
  group = augroup("auto_create_dir", { clear = true }),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
