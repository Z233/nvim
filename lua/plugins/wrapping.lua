return {
  {
    "andrewferrier/wrapping.nvim",
    cond = not vim.g.vscode,
    config = function()
      require("wrapping").setup({
        softener = { markdown = true },
      })
    end,
  },
}
