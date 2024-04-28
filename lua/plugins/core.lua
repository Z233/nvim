return {
  {
    "LazyVim/LazyVim",
    opts = {
      defaults = {
        keymaps = false,
      },
    },
  },
  {
    'echasnovski/mini.ai',
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }, {}),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
          t = false,
          b = false,
          B = false
        },
      }
    end
  },
  {
    'vscode-neovim/vscode-multi-cursor.nvim',
    event = 'VeryLazy',
    cond = not not vim.g.vscode,
    vscode = true,
    config = function(_, _)
      require('vscode-multi-cursor').setup { -- Config is optional
        -- Whether to set default mappings
        default_mappings = true,
        -- If set to true, only multiple cursors will be created without multiple selections
        no_selection = false
      }
    end,
  },
  {
    "chrisgrieser/nvim-spider",
    lazy = true,
    vscode = true
  },
  {
    "echasnovski/mini.surround",
    vscode = true,
    event = "BufRead",
    keys = function(_, keys)
      local mappings = {
        { "sa", desc = "Add surrounding",       mode = { "n", "v" } },
        { "sd", desc = "Delete surrounding" },
        { "sf", desc = "Find right surrounding" },
        { "sF", desc = "Find left surrounding" },
        { "sh", desc = "Highlight surrounding" },
        { "sr", desc = "Replace surrounding" },
      }
      return vim.list_extend(mappings, keys)
    end,
    config = function(_, _)
      require("mini.surround").setup({
        n_lines = 200,
        custom_surroundings = {
          t = {
            input = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
          },
        },
      })
    end,
  },
  {
    "mattn/emmet-vim",
    vscode = true
  },
  {
    "tpope/vim-abolish",
    vscode = true
  }
}
