return {
  {
    "chrisgrieser/nvim-origami",
    cond = not vim.g.vscode,
    event = "VeryLazy",
    opts = {},
    init = function()
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
    end,
  },
}
