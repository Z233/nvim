return {
  {
    "nvim-mini/mini.ai",
    event = "BufRead",
    opts = function()
      local ai = require("mini.ai")

      local function _get_parser()
        local ok, parser = pcall(vim.treesitter.get_parser, vim.api.nvim_get_current_buf())
        if not ok then
          return nil
        end
        local t = parser:parse()[1]
        if not t then
          return nil
        end
        return t:root()
      end

      local function _cursor_pos()
        local r, c = unpack(vim.api.nvim_win_get_cursor(0))
        return r - 1, c
      end

      local function _region(sr, sc, er, ec)
        return { from = { line = sr + 1, col = sc + 1 }, to = { line = er + 1, col = ec } }
      end

      local _SELF_TYPES = {
        jsx_self_closing_element = true,
        self_closing_tag = true,
        xml_empty_element = true,
      }

      local _PAIRED_TYPES = {
        jsx_element = true,
        element = true,
      }

      local _ATTR_TYPES = {
        jsx_attribute = true,
        jsx_spread_attribute = true,
        attribute = true,
      }

      local function _ascend_to_tag(node)
        while node do
          local t = node:type()
          if _SELF_TYPES[t] or _PAIRED_TYPES[t] then
            return node
          end
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
            if not first_attr then
              first_attr = child
            end
            last_attr = child
          end
        end
        return first_attr, last_attr
      end

      local function any_tag_region(ai_type)
        local root = _get_parser()
        if not root then
          return nil
        end
        local cr, cc = _cursor_pos()
        local node = root:named_descendant_for_range(cr, cc, cr, cc)
        local elem = _ascend_to_tag(node)
        if not elem then
          return nil
        end

        local t = elem:type()
        local sr, sc, er, ec = elem:range()

        if ai_type == "a" then
          return _region(sr, sc, er, ec)
        end

        if _SELF_TYPES[t] then
          local fa, la = _first_last_attr(elem)
          if fa and la then
            local ar, ac, _, _ = fa:range()
            local _, _, wr, wc = la:range()
            return _region(ar, ac, wr, wc)
          else
            local ir, ic = er, math.max(sc, ec - 2)
            return _region(ir, ic, ir, ic)
          end
        end

        if _PAIRED_TYPES[t] then
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
            local _, _, or2, oc2 = opening_tag:range()
            local cr1, cc1, _, _ = closing_tag:range()
            return _region(or2, oc2, cr1, cc1)
          else
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
          t = function(ai_type)
            return any_tag_region(ai_type)
          end,
          b = false,
          B = false,
        },
      }
    end,
  },
  {
    "nvim-mini/mini.surround",
    event = "BufRead",
    config = function()
      require("mini.surround").setup({
        n_lines = 200,
        custom_surroundings = {
          t = {
            input = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
          },
        },
        mappings = {
          add = "gza",
          delete = "gzd",
          find = "gzf",
          find_left = "gzF",
          highlight = "gzh",
          replace = "gzr",
          update_n_lines = "gzn",
          suffix_last = "l",
          suffix_next = "n",
        },
      })
    end,
  },
  {
    "chrisgrieser/nvim-spider",
    lazy = true,
  },
  {
    "m4xshen/hardtime.nvim",
    lazy = false,
    cond = not vim.g.vscode,
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      resetting_keys = {
        ["y"] = false,
        ["Y"] = false,
      },
    },
  },
}
