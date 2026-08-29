return {
  {
    "lewis6991/gitsigns.nvim",
    cond = not vim.g.vscode,
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },
  {
    "esmuellert/codediff.nvim",
    cond = not vim.g.vscode,
    version = "*",
    cmd = "CodeDiff",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      { "<leader>gd", "<cmd>CodeDiff<cr>", desc = "Open CodeDiff" },
      { "<leader>gh", "<cmd>CodeDiff history %<cr>", desc = "File history" },
      {
        "<leader>gq",
        function()
          require("codediff.ui.lifecycle").close()
        end,
        desc = "Close CodeDiff",
      },
    },
    opts = {
      explorer = {
        position = "left",
        width = 36,
        view_mode = "tree",
        flatten_dirs = true,
        initial_focus = "explorer",
      },
      diff = {
        layout = "side-by-side",
        compact = true,
        compute_moves = false,
      },
    },
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
