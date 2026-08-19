return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    cond = not vim.g.vscode,
    opts = {
      style = "day",
      terminal_colors = true,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight-day")
    end,
  },
}
