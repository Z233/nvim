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
      
      -- Helper function for self-closing JSX elements
      local function selfclosing_region(ai_type)
        local ts = vim.treesitter
        local bufnr = vim.api.nvim_get_current_buf()

        -- parser for current buffer (tsx/jsx)
        local ok, parser = pcall(ts.get_parser, bufnr)
        if not ok or not parser then return nil end

        local tree = parser:parse()[1]
        if not tree then return nil end

        local root = tree:root()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local row, col = cursor[1] - 1, cursor[2]

        -- node under cursor
        local node = root:named_descendant_for_range(row, col, row, col)

        -- climb to nearest jsx_self_closing_element
        local function up_to_selfclosing(n)
          while n do
            local t = n:type()
            if t == "jsx_self_closing_element" then return n end
            n = n:parent()
          end
          return nil
        end

        local elem = up_to_selfclosing(node)
        if not elem then return nil end

        -- OUTER: full element range
        local sr, sc, er, ec = elem:range() -- 0-based, end col exclusive

        if ai_type == "a" then
          return {
            from = { line = sr + 1, col = sc + 1 },
            to   = { line = er + 1, col = ec     },
          }
        end

        -- INNER: attributes only (exclude the tag name and the closing "/>")
        -- gather attributes
        local attrs = {}
        for child in elem:iter_children() do
          local ct = child:type()
          if ct == "jsx_attribute" or ct == "jsx_spread_attribute" then
            table.insert(attrs, child)
          end
        end

        if #attrs > 0 then
          local ar, ac, zr, zc = attrs[1]:range()
          local br, bc, wr, wc = attrs[#attrs]:range()
          return {
            from = { line = ar + 1, col = ac + 1 },
            to   = { line = wr + 1, col = wc     },
          }
        else
          -- no attributes: make inner a zero-length selection right after the name
          local name = elem:field("name")[1]
          if not name then return nil end
          local nr, nc, er2, ec2 = name:range()
          return {
            from = { line = er2 + 1, col = ec2 + 1 },
            to   = { line = er2 + 1, col = ec2 + 1 },
          }
        end
      end
      
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
          B = false,
          s = function(ai_type) return selfclosing_region(ai_type) end,
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
