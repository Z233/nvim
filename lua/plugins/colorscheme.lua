return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    cond = not vim.g.vscode,
    opts = {
      style = "day",
      terminal_colors = true,
      on_colors = function(colors)
        local white = "#ffffff"

        colors.bg = white
        colors.bg_sidebar = white
        colors.bg_float = white
        colors.bg_popup = white
        colors.bg_statusline = white
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight-day")
    end,
  },
}
