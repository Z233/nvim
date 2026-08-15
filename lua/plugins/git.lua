return {
  {
    "lewis6991/gitsigns.nvim",
    cond = not vim.g.vscode,
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },
  {
    "dlyongemallo/diffview-plus.nvim",
    cond = not vim.g.vscode,
    version = "*",
    cmd = {
      "DiffviewOpen",
      "DiffviewToggle",
      "DiffviewFileHistory",
      "DiffviewDiffFiles",
      "DiffviewLog",
      "DiffviewClose",
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
    },
    opts = {},
  },
  {
    "kdheepak/lazygit.nvim",
    cond = not vim.g.vscode,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
      { "<leader>gf", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (current file)" },
      { "<leader>gl", "<cmd>LazyGitFilter<cr>", desc = "LazyGit log" },
    },
    init = function()
      vim.g.lazygit_floating_window_scaling_factor = 0.95
      vim.g.lazygit_floating_window_winblend = 0
      vim.g.lazygit_use_neovim_remote = 0
    end,
  },
}
