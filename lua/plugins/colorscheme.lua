return {
  {
    "sharpchen/Eva-Theme.nvim",
    lazy = false,
    priority = 1000,
    cond = not vim.g.vscode,
    config = function()
      vim.cmd.colorscheme("Eva-Light")
    end,
  },
}
