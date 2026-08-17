return {
  {
    "ThorstenRhau/token",
    lazy = false,
    priority = 1000,
    cond = not vim.g.vscode,
    config = function()
      vim.o.background = "light"
      require("token").setup()
      vim.cmd.colorscheme("token-temper")
    end,
  },
}
