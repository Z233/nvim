return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cond = not vim.g.vscode,
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle File Tree" },
      { "<leader>E", "<cmd>Neotree reveal<cr>", desc = "Reveal in File Tree" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
      },
      window = {
        width = 30,
      },
    },
  },
}
