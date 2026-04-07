return {
  {
    "vscode-neovim/vscode-multi-cursor.nvim",
    event = "VeryLazy",
    cond = not not vim.g.vscode,
    config = function()
      require("vscode-multi-cursor").setup({
        default_mappings = true,
        no_selection = false,
      })
    end,
  },
}
