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
        on_highlights = function(highlights)
          highlights.Normal.bg = "NONE"
          highlights.NormalNC.bg = "NONE"
        end,
      })
      vim.cmd.colorscheme("token-temper")
    end,
  },
}
