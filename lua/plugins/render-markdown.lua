return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "mdx" },
    cond = not vim.g.vscode,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      file_types = { "markdown", "mdx" },
    },
  },
}
