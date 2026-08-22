return {
  {
    "ibhagwan/fzf-lua",
    cond = not vim.g.vscode,
    cmd = "FzfLua",
    -- Load before the first LSP jump so ui_select hooks gI/gd/gy multi-result
    -- picks (nvim default opens a quickfix window that Esc cannot close).
    event = { "LspAttach" },
    keys = {
      { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find Files" },
      { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Help Tags" },
      { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent Files" },
      { "<leader>fd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Document Diagnostics" },
      { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Document Symbols" },
      { "<leader>/", "<cmd>FzfLua grep_curbuf<cr>", desc = "Grep Current Buffer" },
    },
    opts = {
      -- Route vim.ui.select (LSP multi-location jumps, code actions) through fzf
      ui_select = true,
      defaults = {
        git_icons = false,
        file_icons = false,
      },
    },
  },
}
