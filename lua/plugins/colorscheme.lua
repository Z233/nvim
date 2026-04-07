return {
  {
    "sharpchen/Eva-Theme.nvim",
    lazy = false,
    priority = 1000,
    build = ":EvaCompile",
    config = function()
      vim.cmd.colorscheme("Eva-Light")
    end,
  },
}
