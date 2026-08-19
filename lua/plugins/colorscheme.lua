return {
  {
    "sharpchen/Eva-Theme.nvim",
    lazy = false,
    priority = 1000,
    cond = not vim.g.vscode,
    config = function()
      require("Eva-Theme").setup({
        override_highlight = function(variant, palette)
          return {
            Normal = { bg = "NONE" },
            NormalNC = { bg = "NONE" },
            SignColumn = { bg = "NONE" },
            EndOfBuffer = { bg = "NONE" },
            WinBar = { bg = "NONE" },
            WinBarNC = { bg = "NONE" },
          }
        end,
      })
      vim.cmd.colorscheme("Eva-Light")
    end,
  },
}
