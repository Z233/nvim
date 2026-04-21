return {
  {
    "sharpchen/Eva-Theme.nvim",
    lazy = false,
    priority = 1000,
    build = ":EvaCompile",
    cond = not vim.g.vscode,
    config = function()
      vim.cmd.colorscheme("Eva-Light")
    end,
  },
}
