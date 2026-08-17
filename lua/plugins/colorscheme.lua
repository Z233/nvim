return {
  {
    "ThorstenRhau/token",
    lazy = false,
    priority = 1000,
    cond = not vim.g.vscode,
    config = function()
      vim.o.background = "light"
      require("token").setup({
        terminal_colors = true,
        on_colors = function(colors)
          local white = "#ffffff"

          colors.bg0 = white
          colors.bg1 = white
          colors.bg2 = white
          colors.bg3 = white
          colors.bg4 = white
          colors.bg5 = white
        end,
      })
      vim.cmd.colorscheme("token-temper")
    end,
  },
}
