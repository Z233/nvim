return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    cond = not vim.g.vscode,
    opts = {
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>y", group = "yank" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "gz", group = "surround" },
      },
    },
  },
}
