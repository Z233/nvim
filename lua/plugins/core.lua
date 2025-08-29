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
    config = function(_, _)
      require("mini.surround").setup({
        n_lines = 200,
        custom_surroundings = {
          t = {
            input = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
          },
        },
        mappings = {
          add = 'gza', -- Add surrounding in Normal and Visual modes
          delete = 'gzd', -- Delete surrounding
          find = 'gzf', -- Find surrounding (to the right)
          find_left = 'gzF', -- Find surrounding (to the left)
          highlight = 'gzh', -- Highlight surrounding
          replace = 'gzr', -- Replace surrounding
          update_n_lines = 'gzn', -- Update `n_lines`

          suffix_last = 'l', -- Suffix to search with "prev" method
          suffix_next = 'n', -- Suffix to search with "next" method
        }
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
  },
  {
    "m4xshen/hardtime.nvim",
    vscode = true,
    lazy = false,
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {},
  }
}
