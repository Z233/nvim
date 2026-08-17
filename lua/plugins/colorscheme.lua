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
        plugins = {
          blink = true,
          diffview = true,
          fzf = true,
          gitsigns = true,
          lazy = true,
          mason = true,
          neo_tree = true,
          noice = true,
          whichkey = true,
        },
        on_colors = function(colors)
          colors.bg3 = "#ffffff"
        end,
      })
      vim.cmd.colorscheme("token-temper")
    end,
  },
}
