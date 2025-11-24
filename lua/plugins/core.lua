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
    'nvim-mini/mini.ai',
    opts = function()
      local ai = require("mini.ai")
      
      -- Helpers for tag regions (self-closing + paired) using Tree-sitter
      local function _get_parser()
        local ts = vim.treesitter
        local ok, parser = pcall(ts.get_parser, vim.api.nvim_get_current_buf())
        if not ok then return nil end
        local t = parser:parse()[1]
        if not t then return nil end
        return t:root()
      end

      local function _cursor_pos()
        local r, c = unpack(vim.api.nvim_win_get_cursor(0))
        return r - 1, c -- 0-based for TS
      end

      local function _region(sr, sc, er, ec)
        -- mini.ai expects 1-based lines; end col is exclusive
        return { from = { line = sr + 1, col = sc + 1 }, to = { line = er + 1, col = ec } }
      end

      local _SELF_TYPES = {
        jsx_self_closing_element = true,
        self_closing_tag = true,         -- html
        xml_empty_element = true,        -- some xml grammars
      }

      local _PAIRED_TYPES = {
        jsx_element = true,
        element = true,                  -- html/xml
      }

      local _ATTR_TYPES = {
        jsx_attribute = true,
        jsx_spread_attribute = true,
        attribute = true,                -- html/xml
      }

      local function _ascend_to_tag(node)
        while node do
          local t = node:type()
          if _SELF_TYPES[t] or _PAIRED_TYPES[t] then return node end
          -- If we're on an opening/start tag node, jump to its parent element
          if t == "jsx_opening_element" and node:parent() and node:parent():type() == "jsx_element" then
            return node:parent()
          end
          if t == "start_tag" and node:parent() and node:parent():type() == "element" then
            return node:parent()
          end
          node = node:parent()
        end
        return nil
      end

      local function _first_last_attr(elem)
        local first_attr, last_attr
        for child in elem:iter_children() do
          if _ATTR_TYPES[child:type()] then
            if not first_attr then first_attr = child end
            last_attr = child
          end
        end
        return first_attr, last_attr
      end

      -- Generic tag (paired or self-closing): 'a' = whole element;
      -- 'i' = children for paired, attributes for self-closing
      local function any_tag_region(ai_type)
        local root = _get_parser()
        if not root then return nil end
        local cr, cc = _cursor_pos()
        local node = root:named_descendant_for_range(cr, cc, cr, cc)
        local elem = _ascend_to_tag(node)
        if not elem then return nil end

        local t = elem:type()
        local sr, sc, er, ec = elem:range()

        if ai_type == "a" then
          return _region(sr, sc, er, ec)
        end

        -- inner:
        if _SELF_TYPES[t] then
          -- for self-closing, mirror 's' behavior (attributes-only)
          local fa, la = _first_last_attr(elem)
          if fa and la then
            local ar, ac, _, _ = fa:range()
            local br, bc, wr, wc = la:range()
            return _region(ar, ac, wr, wc)
          else
            local ir, ic = er, math.max(sc, ec - 2)
            return _region(ir, ic, ir, ic)
          end
        end

        if _PAIRED_TYPES[t] then
          -- paired: find opening and closing tags manually
          local opening_tag, closing_tag
          for child in elem:iter_children() do
            local ct = child:type()
            if ct == "jsx_opening_element" or ct == "start_tag" then
              opening_tag = child
            elseif ct == "jsx_closing_element" or ct == "end_tag" then
              closing_tag = child
            end
          end
          
          if opening_tag and closing_tag then
            local or1, oc1, or2, oc2 = opening_tag:range()
            local cr1, cc1, _, _ = closing_tag:range()
            return _region(or2, oc2, cr1, cc1)
          else
            -- Fallback: no reliable tags found
            return nil
          end
        end

        return nil
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
          t = function(ai_type)  -- any tag, paired or self-closing
            return any_tag_region(ai_type)
          end,
          b = false,
          B = false,
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
    "nvim-mini/mini.surround",
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
  },
  {
    "Goose97/timber.nvim",
    vscode = true,
    version = "*",
    event = "VeryLazy",
    config = function()
      local ts_fn_utils = require("utils.treesitter-function-name")
      local js_default_log_template = [[console.debug('[%function_name] %log_target', %log_target);]]

      require("timber").setup({
        template_placeholders = {
          function_name = ts_fn_utils.find_function_name,
        },
        log_templates = {
          default = {
            javascript = js_default_log_template,
            typescript = js_default_log_template,
            astro = js_default_log_template,
            vue = js_default_log_template,
            jsx = js_default_log_template,
            tsx = js_default_log_template,
          }
        }
      })
    end
  }
}
