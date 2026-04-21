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
    init = function()
      -- Open neo-tree automatically when nvim is started with a directory argument
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("neotree_start_directory", { clear = true }),
        desc = "Open neo-tree on directory",
        once = true,
        callback = function()
          if package.loaded["neo-tree"] then
            return
          end
          local arg = vim.fn.argv(0)
          if arg == "" then
            return
          end
          local stat = vim.uv.fs_stat(arg)
          if stat and stat.type == "directory" then
            vim.schedule(function()
              vim.cmd("Neotree show dir=" .. vim.fn.fnameescape(arg))
            end)
          end
        end,
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        hijack_netrw_behavior = "open_default",
      },
      window = {
        width = 30,
        mappings = {
          ["<C-h>"] = false,
          ["<C-j>"] = false,
          ["<C-k>"] = false,
          ["<C-l>"] = false,
        },
      },
    },
  },
}
