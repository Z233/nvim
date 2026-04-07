# Neovim Config From Scratch - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace LazyVim framework with a hand-crafted Neovim configuration using lazy.nvim as plugin manager, preserving all existing keymaps and VSCode support.

**Architecture:** Incremental migration — back up old config, build new config file-by-file, verify each layer with tmux before proceeding. Each task adds one concern (options, then plugins, then keymaps, etc.) so failures are easy to isolate.

**Tech Stack:** Neovim 0.12, lazy.nvim, nvim-treesitter, nvim-lspconfig, mason, blink.cmp, fzf-lua, neo-tree, lualine, bufferline, mini.ai, mini.surround, nvim-spider, hardtime, timber, jieba.vim, Eva-Theme

**Verification:** Every task ends with a tmux verification step — launch nvim in a tmux pane and confirm the change works before committing.

---

### Task 1: Back Up Old Config and Clean Slate

**Files:**
- Move: `~/.config/nvim/lua/config/lazy.lua` -> backed up
- Move: `~/.config/nvim/lua/plugins/core.lua` -> backed up
- Move: `~/.config/nvim/init.lua` -> backed up
- Delete: `~/.config/nvim/lazyvim.json`

- [ ] **Step 1: Create a backup branch**

```bash
cd ~/.config/nvim
git checkout -b from-scratch
```

- [ ] **Step 2: Remove LazyVim-specific files and clear plugin cache**

```bash
cd ~/.config/nvim
rm -f lazyvim.json
rm -rf ~/.local/share/nvim/lazy/LazyVim
```

- [ ] **Step 3: Create the new plugin directory structure**

```bash
mkdir -p ~/.config/nvim/lua/plugins
```

The old `plugins/core.lua` will be replaced incrementally by new plugin files. We keep it until all plugins are migrated, then delete it.

- [ ] **Step 4: Commit the cleanup**

```bash
cd ~/.config/nvim
git add -A
git commit -m "chore: remove lazyvim.json and prepare for from-scratch config"
```

---

### Task 2: Write init.lua and config/options.lua

**Files:**
- Rewrite: `~/.config/nvim/init.lua`
- Rewrite: `~/.config/nvim/lua/config/options.lua`

- [ ] **Step 1: Write new init.lua**

```lua
-- ~/.config/nvim/init.lua

require("config.options")
require("config.lazy")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    require("config.keymaps")
    require("config.autocmds")
  end,
})
```

Note: keymaps and autocmds load on VeryLazy so that plugins are available when keymaps reference them (e.g., `require("spider")`).

- [ ] **Step 2: Write new config/options.lua**

```lua
-- ~/.config/nvim/lua/config/options.lua

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.user_emmet_leader_key = "<C-C>"

-- Encoding
vim.cmd("language en_US.UTF-8")

-- Appearance
vim.opt.termguicolors = true
vim.opt.guifont = "Dank Mono:h15"
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Scrolling
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.smoothscroll = true

-- Editing
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
vim.opt.wrap = false
vim.opt.mouse = "a"

-- Performance
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
```

- [ ] **Step 3: Verify in tmux — nvim opens without errors**

```bash
tmux send-keys -t 0 'nvim' Enter
```

Wait 2 seconds, then capture the screen. Expect: nvim opens (may show errors about missing lazy.lua requires — that is expected at this stage since we have not yet rewritten lazy.lua). The key check is that options.lua loads without error.

```bash
tmux send-keys -t 0 ':echo &shiftwidth' Enter
```

Expected output: `2`

```bash
tmux send-keys -t 0 ':qa!' Enter
```

- [ ] **Step 4: Commit**

```bash
cd ~/.config/nvim
git add init.lua lua/config/options.lua
git commit -m "feat: rewrite init.lua and options.lua without LazyVim"
```

---

### Task 3: Write config/lazy.lua (lazy.nvim Bootstrap Only)

**Files:**
- Rewrite: `~/.config/nvim/lua/config/lazy.lua`
- Create: `~/.config/nvim/lua/plugins/colorscheme.lua`

- [ ] **Step 1: Write new lazy.lua — bootstrap + import plugins directory**

```lua
-- ~/.config/nvim/lua/config/lazy.lua

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
```

- [ ] **Step 2: Write colorscheme.lua**

```lua
-- ~/.config/nvim/lua/plugins/colorscheme.lua

return {
  {
    "sharpchen/Eva-Theme.nvim",
    lazy = false,
    priority = 1000,
    build = ":EvaCompile",
    config = function()
      vim.cmd.colorscheme("Eva-Light")
    end,
  },
}
```

- [ ] **Step 3: Delete old plugins/core.lua**

```bash
rm ~/.config/nvim/lua/plugins/core.lua
```

- [ ] **Step 4: Verify in tmux — nvim opens with Eva-Light theme, no errors**

```bash
tmux send-keys -t 0 'nvim' Enter
```

Wait for lazy.nvim to install Eva-Theme (first run). Then:

```bash
tmux send-keys -t 0 ':colorscheme' Enter
```

Expected output: `Eva-Light`

```bash
tmux send-keys -t 0 ':checkhealth lazy' Enter
```

Expected: no errors.

```bash
tmux send-keys -t 0 ':qa!' Enter
```

- [ ] **Step 5: Commit**

```bash
cd ~/.config/nvim
git add lua/config/lazy.lua lua/plugins/colorscheme.lua
git add -u  # stages the deletion of core.lua
git commit -m "feat: rewrite lazy.lua bootstrap, add colorscheme, remove LazyVim"
```

---

### Task 4: Write plugins/treesitter.lua

**Files:**
- Create: `~/.config/nvim/lua/plugins/treesitter.lua`

- [ ] **Step 1: Write treesitter.lua**

```lua
-- ~/.config/nvim/lua/plugins/treesitter.lua

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "BufRead",
    cond = not vim.g.vscode,
    opts = {
      ensure_installed = {
        "bash",
        "css",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "tsx",
        "typescript",
        "vue",
        "yaml",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}
```

- [ ] **Step 2: Verify in tmux — open a Lua file and check syntax highlighting**

```bash
tmux send-keys -t 0 'nvim ~/.config/nvim/init.lua' Enter
```

Wait for treesitter parsers to install (first run). Then check:

```bash
tmux send-keys -t 0 ':TSInstallInfo' Enter
```

Expected: `lua` parser shows as installed.

```bash
tmux send-keys -t 0 ':qa!' Enter
```

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/plugins/treesitter.lua
git commit -m "feat: add treesitter with explicit parser list"
```

---

### Task 5: Write plugins/lsp.lua

**Files:**
- Create: `~/.config/nvim/lua/plugins/lsp.lua`

- [ ] **Step 1: Write lsp.lua with mason + lspconfig + on_attach keymaps**

```lua
-- ~/.config/nvim/lua/plugins/lsp.lua

return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    cond = not vim.g.vscode,
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    cond = not vim.g.vscode,
    dependencies = { "mason.nvim" },
    opts = {
      ensure_installed = {
        "ts_ls",
        "volar",
        "lua_ls",
        "jsonls",
        "yamlls",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = "BufRead",
    cond = not vim.g.vscode,
    dependencies = {
      "mason.nvim",
      "mason-lspconfig.nvim",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      -- Try to merge blink.cmp capabilities if available
      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      local on_attach = function(_, bufnr)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- Navigation
        map("n", "gd", vim.lsp.buf.definition, "Goto Definition")
        map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
        map("n", "gI", vim.lsp.buf.implementation, "Goto Implementation")
        map("n", "gy", vim.lsp.buf.type_definition, "Goto Type Definition")
        map("n", "gr", function()
          local fzf_ok, fzf = pcall(require, "fzf-lua")
          if fzf_ok then
            fzf.lsp_references()
          else
            vim.lsp.buf.references()
          end
        end, "References")
        map("n", "K", vim.lsp.buf.hover, "Hover")
        map("n", "gK", vim.lsp.buf.signature_help, "Signature Help")
        map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")

        -- Actions
        map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
        map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
        map("n", "<leader>cf", function()
          vim.lsp.buf.format({ async = true })
        end, "Format")

        -- Diagnostics
        map("n", "]d", function()
          vim.diagnostic.jump({ count = 1, float = true })
        end, "Next Diagnostic")
        map("n", "[d", function()
          vim.diagnostic.jump({ count = -1, float = true })
        end, "Prev Diagnostic")
        map("n", "]e", function()
          vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
        end, "Next Error")
        map("n", "[e", function()
          vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
        end, "Prev Error")
      end

      local servers = {
        ts_ls = {},
        volar = {},
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        },
        jsonls = {},
        yamlls = {},
      }

      for server, config in pairs(servers) do
        config.capabilities = capabilities
        config.on_attach = on_attach
        lspconfig[server].setup(config)
      end
    end,
  },
}
```

- [ ] **Step 2: Verify in tmux — open a Lua file and check LSP attaches**

```bash
tmux send-keys -t 0 'nvim ~/.config/nvim/init.lua' Enter
```

Wait for mason to install lua_ls (first run, may take a minute). Then:

```bash
tmux send-keys -t 0 ':LspInfo' Enter
```

Expected: `lua_ls` shows as attached to the current buffer.

```bash
tmux send-keys -t 0 ':qa!' Enter
```

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/plugins/lsp.lua
git commit -m "feat: add LSP config with mason and on_attach keymaps"
```

---

### Task 6: Write plugins/completion.lua

**Files:**
- Create: `~/.config/nvim/lua/plugins/completion.lua`

- [ ] **Step 1: Write completion.lua with blink.cmp**

```lua
-- ~/.config/nvim/lua/plugins/completion.lua

return {
  {
    "saghen/blink.cmp",
    version = "*",
    event = "InsertEnter",
    cond = not vim.g.vscode,
    opts = {
      keymap = {
        preset = "default",
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },
}
```

- [ ] **Step 2: Verify in tmux — open a Lua file, enter insert mode, type, see completions**

```bash
tmux send-keys -t 0 'nvim ~/.config/nvim/init.lua' Enter
```

Wait a moment for LSP to attach, then enter insert mode and type `vim.`:

```bash
tmux send-keys -t 0 'o' 'vim.'
```

Expected: a completion popup appears showing `vim.api`, `vim.fn`, etc.

Press Escape and quit:

```bash
tmux send-keys -t 0 Escape ':qa!' Enter
```

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/plugins/completion.lua
git commit -m "feat: add blink.cmp completion engine"
```

---

### Task 7: Write plugins/fuzzy.lua

**Files:**
- Create: `~/.config/nvim/lua/plugins/fuzzy.lua`

- [ ] **Step 1: Write fuzzy.lua with fzf-lua**

```lua
-- ~/.config/nvim/lua/plugins/fuzzy.lua

return {
  {
    "ibhagwan/fzf-lua",
    cond = not vim.g.vscode,
    cmd = "FzfLua",
    keys = {
      { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find Files" },
      { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Help Tags" },
      { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent Files" },
      { "<leader>fd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Document Diagnostics" },
      { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Document Symbols" },
      { "<leader>/", "<cmd>FzfLua grep_curbuf<cr>", desc = "Grep Current Buffer" },
    },
    opts = {
      defaults = {
        git_icons = false,
        file_icons = false,
      },
    },
  },
}
```

- [ ] **Step 2: Verify in tmux — leader-ff opens file finder**

```bash
tmux send-keys -t 0 'nvim' Enter
```

Wait for nvim to load, then:

```bash
tmux send-keys -t 0 ' ff'
```

Expected: fzf-lua file picker opens showing files in the current directory.

Press Escape to close, then quit:

```bash
tmux send-keys -t 0 Escape ':qa!' Enter
```

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/plugins/fuzzy.lua
git commit -m "feat: add fzf-lua fuzzy finder"
```

---

### Task 8: Write plugins/filetree.lua

**Files:**
- Create: `~/.config/nvim/lua/plugins/filetree.lua`

- [ ] **Step 1: Write filetree.lua with neo-tree**

```lua
-- ~/.config/nvim/lua/plugins/filetree.lua

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
```

- [ ] **Step 2: Verify in tmux — leader-e opens file tree**

```bash
tmux send-keys -t 0 'nvim ~/.config/nvim/init.lua' Enter
```

Wait for nvim to load, then:

```bash
tmux send-keys -t 0 ' e'
```

Expected: neo-tree sidebar opens on the left showing the file tree with `init.lua` highlighted.

```bash
tmux send-keys -t 0 ':qa!' Enter
```

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/plugins/filetree.lua
git commit -m "feat: add neo-tree file explorer"
```

---

### Task 9: Write plugins/ui.lua

**Files:**
- Create: `~/.config/nvim/lua/plugins/ui.lua`

- [ ] **Step 1: Write ui.lua with lualine and bufferline**

```lua
-- ~/.config/nvim/lua/plugins/ui.lua

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    cond = not vim.g.vscode,
    opts = {
      options = {
        globalstatus = true,
        theme = "auto",
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    cond = not vim.g.vscode,
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        offsets = {
          {
            filetype = "neo-tree",
            text = "File Explorer",
            highlight = "Directory",
            text_align = "left",
          },
        },
      },
    },
  },
}
```

- [ ] **Step 2: Verify in tmux — lualine and bufferline appear**

```bash
tmux send-keys -t 0 'nvim ~/.config/nvim/init.lua' Enter
```

Expected: bottom statusline shows mode, branch, filename. Open a second file to see bufferline:

```bash
tmux send-keys -t 0 ':e lua/config/options.lua' Enter
```

Expected: buffer tabs appear at the top showing both open files.

```bash
tmux send-keys -t 0 ':qa!' Enter
```

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/plugins/ui.lua
git commit -m "feat: add lualine statusline and bufferline"
```

---

### Task 10: Write plugins/editor.lua

**Files:**
- Create: `~/.config/nvim/lua/plugins/editor.lua`

- [ ] **Step 1: Write editor.lua — mini.ai, mini.surround, nvim-spider, hardtime**

```lua
-- ~/.config/nvim/lua/plugins/editor.lua

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
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {},
  },
}
```

- [ ] **Step 2: Verify in tmux — mini.surround and spider work**

```bash
tmux send-keys -t 0 'nvim ~/.config/nvim/init.lua' Enter
```

Test mini.surround — place cursor on a word and try `gzaiw"` (surround inner word with quotes):

```bash
tmux send-keys -t 0 'gzaiw"'
```

Expected: the word under cursor gets wrapped in double quotes.

Undo and quit:

```bash
tmux send-keys -t 0 'u' ':qa!' Enter
```

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/plugins/editor.lua
git commit -m "feat: add editor plugins (mini.ai, mini.surround, spider, hardtime)"
```

---

### Task 11: Write plugins/extras.lua and plugins/vscode.lua

**Files:**
- Create: `~/.config/nvim/lua/plugins/extras.lua`
- Create: `~/.config/nvim/lua/plugins/vscode.lua`

- [ ] **Step 1: Write extras.lua — timber and jieba.vim**

```lua
-- ~/.config/nvim/lua/plugins/extras.lua

return {
  {
    "Goose97/timber.nvim",
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
          },
        },
      })
    end,
  },
  {
    "kkew3/jieba.vim",
    branch = "rust",
    build = "JIEBA_VIM_INSTALL_NVIM=1 ./build.sh",
    event = "BufRead",
    init = function()
      vim.g.jieba_vim_lazy = 1
      vim.g.jieba_vim_keymap = 1
    end,
  },
}
```

- [ ] **Step 2: Write vscode.lua — VSCode-only plugins**

```lua
-- ~/.config/nvim/lua/plugins/vscode.lua

return {
  {
    "vscode-neovim/vscode-multi-cursor.nvim",
    event = "VeryLazy",
    cond = not not vim.g.vscode,
    config = function()
      require("vscode-multi-cursor").setup({
        default_mappings = true,
        no_selection = false,
      })
    end,
  },
}
```

- [ ] **Step 3: Verify in tmux — nvim opens with no errors**

```bash
tmux send-keys -t 0 'nvim' Enter
```

Check for errors:

```bash
tmux send-keys -t 0 ':messages' Enter
```

Expected: no error messages.

```bash
tmux send-keys -t 0 ':qa!' Enter
```

- [ ] **Step 4: Commit**

```bash
cd ~/.config/nvim
git add lua/plugins/extras.lua lua/plugins/vscode.lua
git commit -m "feat: add timber, jieba, and vscode-multi-cursor plugins"
```

---

### Task 12: Write config/keymaps.lua (Shared Keymaps)

**Files:**
- Rewrite: `~/.config/nvim/lua/config/keymaps.lua`

- [ ] **Step 1: Write shared keymaps**

```lua
-- ~/.config/nvim/lua/config/keymaps.lua

local map = vim.keymap.set

-- Spider word motions
map({ "n", "o", "x" }, "w", "<cmd>lua require('spider').motion('w')<CR>", { desc = "Spider-w" })
map({ "n", "o", "x" }, "e", "<cmd>lua require('spider').motion('e')<CR>", { desc = "Spider-e" })
map({ "n", "o", "x" }, "b", "<cmd>lua require('spider').motion('b')<CR>", { desc = "Spider-b" })
map({ "n", "o", "x" }, "ge", "<cmd>lua require('spider').motion('ge')<CR>", { desc = "Spider-ge" })

-- Line operations
map("n", "cL", "cg_", { desc = "Change till line end" })
map("n", "vL", "vg_", { desc = "Visual till line end" })
map("n", "dL", "dg_", { desc = "Delete till line end" })
map("n", "yL", "yg_", { desc = "Yank till line end" })
map("n", "cH", "cg0", { desc = "Change till line start" })
map("n", "vH", "vg0", { desc = "Visual till line start" })
map("n", "dH", "dg0", { desc = "Delete till line start" })
map("n", "yH", "yg0", { desc = "Yank till line start" })

-- Easy motion
local easy_motion = require("utils.easy-motion")
map({ "n", "x" }, "s", easy_motion.jump, { desc = "Jump to 2 characters" })

-- Stay in visual mode after indent
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Make U opposite of u (redo)
map("n", "U", "<C-r>", { desc = "Redo" })

-- Powerful escape: clear highlights
map({ "i", "n" }, "<Esc>", function()
  vim.cmd("noh")
  return "<Esc>"
end, { expr = true, desc = "Escape and clear hlsearch" })

-- Auto-mark before search
map("n", "/", "ms/", { desc = "Search forward (mark s)" })
map("n", "?", "ms?", { desc = "Search backward (mark s)" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })

-- Clipboard paste
local function parse_clipboard_to_plain_text()
  local clipboard_content = vim.fn.getreg("+")
  local processed_content = clipboard_content:match("^%s*(.-)%s*$")
  vim.fn.setreg("*", processed_content)
  vim.fn.setreg("+", processed_content)
end

vim.api.nvim_create_user_command("ParseClipboardToPlainText", parse_clipboard_to_plain_text, {})
map({ "n", "v" }, "<leader>p", "<Cmd>ParseClipboardToPlainText<CR>p", { noremap = true, silent = true })

-- Copy file path
local function copyFilePath()
  local file = vim.fn.expand("%:p")
  file = string.format("@%s", file)
  vim.fn.setreg("+", file)
  print("Copied: " .. file)
end

local function copyFileWithLine()
  local file = vim.fn.expand("%:p")
  local line_start = vim.fn.line("v")
  local line_end = vim.fn.line(".")

  local location
  if vim.fn.mode() == "v" or vim.fn.mode() == "V" then
    if line_start > line_end then
      line_start, line_end = line_end, line_start
    end
    if line_start == line_end then
      location = string.format("@%s#L%d", file, line_start)
    else
      location = string.format("@%s#L%d-%d", file, line_start, line_end)
    end
  else
    location = string.format("@%s#L%d", file, line_end)
  end

  vim.fn.setreg("+", location)
  print("Copied: " .. location)
end

map({ "n", "x" }, "<leader>yf", copyFilePath, { desc = "Copy file path to clipboard" })
map({ "n", "x" }, "<leader>yl", copyFileWithLine, { desc = "Copy file location with line to clipboard" })

-- Buffer navigation (non-VSCode only)
if not vim.g.vscode then
  map("n", "gt", "<cmd>bnext<cr>", { desc = "Next Buffer" })
  map("n", "gT", "<cmd>bprev<cr>", { desc = "Prev Buffer" })
  map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
  map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete Buffer" })
  map("n", "<leader>bo", "<cmd>%bd|e#|bd#<cr><c-o>", { desc = "Delete Other Buffers" })
end

-- VSCode keymaps
if vim.g.vscode then
  require("config.keymaps-vscode")
end
```

- [ ] **Step 2: Verify in tmux — test a few keymaps**

```bash
tmux send-keys -t 0 'nvim ~/.config/nvim/init.lua' Enter
```

Test Esc clears highlights — search for something, then press Esc:

```bash
tmux send-keys -t 0 '/require' Enter
```

Expected: "require" is highlighted.

```bash
tmux send-keys -t 0 Escape
```

Expected: highlights are cleared.

Test U for redo — make a change, undo, then redo:

```bash
tmux send-keys -t 0 'dd' 'u' 'U'
```

Expected: line deleted, undone, then redone.

```bash
tmux send-keys -t 0 'u' ':qa!' Enter
```

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/config/keymaps.lua
git commit -m "feat: rewrite shared keymaps without LazyVim dependencies"
```

---

### Task 13: Write config/keymaps-vscode.lua

**Files:**
- Create: `~/.config/nvim/lua/config/keymaps-vscode.lua`

- [ ] **Step 1: Write VSCode-specific keymaps (migrated from old keymaps.lua)**

```lua
-- ~/.config/nvim/lua/config/keymaps-vscode.lua

local vscode = require("vscode-neovim")
local map = vim.keymap.set

pcall(vim.keymap.del, "n", "]d")
pcall(vim.keymap.del, "n", "[d")
pcall(vim.keymap.del, "n", "]D")
pcall(vim.keymap.del, "n", "[D")

local function vmap(mode, lhs, command, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, function()
    vscode.call(command)
  end, opts)
end

-- Code Actions
vmap("n", "<leader>ef", "eslint.executeAutofix", { desc = "ESLint: Fix all auto-fixable Problems" })
vmap("v", "<leader>f", "editor.action.formatSelection", { desc = "Format selection" })
vmap("n", "gl", "editor.action.goToTypeDefinition", { desc = "Go to Type Definition" })
vmap("n", "<leader>cr", "editor.action.rename")
vmap("n", "<leader>cd", "comment-divider.insertSolidLine")
vmap("n", "<leader>cm", "comment-divider.makeMainHeader")

local function goToImplementationAside()
  vscode.call("editor.action.goToImplementation")
  vscode.call("workbench.action.moveEditorToRightGroup")
end

local function goToTypeDefinitionAside()
  vscode.call("editor.action.goToTypeDefinition")
  vscode.call("workbench.action.moveEditorToRightGroup")
end

vmap("n", "gi", "editor.action.goToImplementation")
map("n", "<C-w>gi", goToImplementationAside)
map("n", "<C-w>gl", goToTypeDefinitionAside)

-- Git
vmap("n", "<leader>gi", "merge-conflict.accept.incoming", { desc = "Merge Conflict: Accept Incoming" })
vmap("n", "<leader>gc", "merge-conflict.accept.current", { desc = "Merge Conflict: Accept Current" })
vmap("n", "<leader>gb", "merge-conflict.accept.both", { desc = "Merge Conflict: Accept Both" })
vmap({ "n", "v" }, "<leader>gt", "git.revertSelectedRanges", { desc = "Git: Revert Selected Ranges" })
vmap("v", "<leader>gs", "git.stageSelectedRanges", { desc = "Git: Stage Selected Ranges" })
vmap("v", "<leader>gu", "git.unstageSelectedRanges", { desc = "Git: Unstage Selected Ranges" })

-- GitLens Revision Navigation
vmap("n", "]r", "gitlens.diffWithNext", { desc = "GitLens: Diff with Next Revision" })
vmap("n", "[r", "gitlens.diffWithPrevious", { desc = "GitLens: Diff with Previous Revision" })

local lineDiffHistory = require("utils.gitlens-line-history")
map("n", "[R", lineDiffHistory.goToPreviousRevision, { desc = "GitLens: Diff Line with Previous Revision" })
map("n", "]R", lineDiffHistory.goToNextRevision, { desc = "GitLens: Go Back in History" })

-- Dirty Diff / Changes
local gitDiff = require("utils.vscode-git-diff-navigation")
map("n", "]d", gitDiff.goToNextChange, { desc = "Go to Next Change" })
map("n", "[d", gitDiff.goToPreviousChange, { desc = "Go to Previous Change" })
map("n", "]gf", gitDiff.goToNextFile, { desc = "Go to Next Changed File" })
map("n", "[gf", gitDiff.goToPreviousFile, { desc = "Go to Previous Changed File" })
map("n", "<leader>go", gitDiff.openCurrentFileInNormalEditor, { desc = "Git: Open in Normal Editor" })
vmap("n", "]D", "editor.action.dirtydiff.next", { desc = "Show Next Change (inline diff)" })
vmap("n", "[D", "editor.action.dirtydiff.previous", { desc = "Show Previous Change (inline diff)" })

-- Error Navigation
vmap("n", "[e", "go-to-next-error.prev.error")
vmap("n", "]e", "go-to-next-error.next.error")

-- Multi-cursor
map({ "n", "v" }, "gb", "mciw*<Cmd>nohl<CR>", { remap = true })

-- Misc
vmap("n", "<A-c>", "workbench.files.action.showActiveFileInExplorer")
vmap("n", "gr", "editor.action.goToReferences", { desc = "Go to references" })
vmap(
  { "n", "v" },
  "<leader>cl",
  "turboConsoleLog.displayLogMessage",
  { desc = "Turbo Console Log: Display Log Message" }
)
vmap(
  { "n", "v" },
  "]l",
  "editor.action.marker.nextInFiles",
  { desc = "Go to Next Problem in Files (Error, Warning, Info)" }
)
vmap(
  { "n", "v" },
  "[l",
  "editor.action.marker.prevInFiles",
  { desc = "Go to Previous Problem in Files (Error, Warning, Info)" }
)

-- Folding
vmap("n", "zM", "editor.foldAll", { desc = "Fold All" })
vmap("n", "zR", "editor.unfoldAll", { desc = "Unfold All" })
vmap("n", "zc", "editor.fold", { desc = "Fold" })
vmap("n", "zC", "editor.foldRecursively", { desc = "Fold Recursively" })
vmap("n", "zo", "editor.unfold", { desc = "Unfold" })
vmap("n", "zO", "editor.unfoldRecursively", { desc = "Unfold Recursively" })
vmap("n", "za", "editor.toggleFold", { desc = "Toggle Fold" })

-- Scrolling
local scroll = require("utils.vscode-scroll")
map("n", "<C-u>", scroll.scrollHalfPageUp, { desc = "Scroll half page up, cursor centered" })
map("n", "<C-d>", scroll.scrollHalfPageDown, { desc = "Scroll half page down, cursor centered" })

-- Copy commit SHA
local function copyLineCommitSha()
  local line = vim.fn.line(".")
  local file = vim.fn.expand("%:p")
  local output = vim.fn.system({ "git", "blame", "-L", line .. "," .. line, "--porcelain", file })
  local sha = output:match("^(%x+)")

  if sha and sha ~= "" and not sha:match("^0+$") then
    vim.fn.setreg("+", sha)
    vscode.call("editor.action.showHover")
    print("Copied: " .. sha)
  else
    print("No commit SHA found (line not committed yet)")
  end
end

map("n", "<leader>yc", copyLineCommitSha, { desc = "Copy line commit SHA to clipboard" })
```

- [ ] **Step 2: Verify in tmux — file loads without syntax errors**

Since we cannot test VSCode keymaps in terminal, verify the file parses correctly:

```bash
tmux send-keys -t 0 'nvim -c "lua dofile(vim.fn.stdpath(\"config\") .. \"/lua/config/keymaps-vscode.lua\")" -c "echo \"VSCode keymaps OK\"" -c "qa!" 2>&1' Enter
```

Expected: error about `vscode-neovim` module not found (expected — it only exists in VSCode). The key point is there are no Lua syntax errors.

Alternative simpler check:

```bash
tmux send-keys -t 0 'nvim' Enter
```

```bash
tmux send-keys -t 0 ':messages' Enter
```

Expected: no errors (since `vim.g.vscode` is nil in terminal, the VSCode keymaps file is never loaded).

```bash
tmux send-keys -t 0 ':qa!' Enter
```

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/config/keymaps-vscode.lua
git commit -m "feat: extract VSCode-specific keymaps to dedicated file"
```

---

### Task 14: Write config/autocmds.lua

**Files:**
- Rewrite: `~/.config/nvim/lua/config/autocmds.lua`

- [ ] **Step 1: Write autocmds.lua**

```lua
-- ~/.config/nvim/lua/config/autocmds.lua

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Yank history: rotate yanks into numbered registers
autocmd("TextYankPost", {
  group = augroup("yank_history", { clear = true }),
  callback = function()
    local op = vim.v.event.operator
    if op == "y" or op == "d" or op == "c" then
      for i = 9, 2, -1 do
        vim.fn.setreg(tostring(i), vim.fn.getreg(tostring(i - 1)))
      end
      vim.fn.setreg("1", vim.fn.getreg('"'))
    end
  end,
})

-- Highlight on yank
autocmd("TextYankPost", {
  group = augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Close special buffers with q
autocmd("FileType", {
  group = augroup("close_with_q", { clear = true }),
  pattern = { "help", "man", "qf", "checkhealth", "notify", "lspinfo", "startuptime" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Restore cursor position on file open
autocmd("BufReadPost", {
  group = augroup("restore_cursor", { clear = true }),
  callback = function(event)
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(event.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Auto-create parent directories on save
autocmd("BufWritePre", {
  group = augroup("auto_create_dir", { clear = true }),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
```

- [ ] **Step 2: Verify in tmux — yank highlight works**

```bash
tmux send-keys -t 0 'nvim ~/.config/nvim/init.lua' Enter
```

Yank a line and observe the highlight flash:

```bash
tmux send-keys -t 0 'yy'
```

Expected: the yanked line briefly flashes with a highlight.

Test close-with-q — open help and press q:

```bash
tmux send-keys -t 0 ':help' Enter
tmux send-keys -t 0 'q'
```

Expected: help window closes.

```bash
tmux send-keys -t 0 ':qa!' Enter
```

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim
git add lua/config/autocmds.lua
git commit -m "feat: rewrite autocmds with yank ring, highlight, close-with-q, cursor restore"
```

---

### Task 15: Final Verification and Cleanup

**Files:**
- Verify all files in place
- Delete any leftover LazyVim artifacts

- [ ] **Step 1: Verify complete file structure**

```bash
find ~/.config/nvim/lua -name "*.lua" -type f | sort
```

Expected output:
```
/Users/fronz/.config/nvim/lua/config/autocmds.lua
/Users/fronz/.config/nvim/lua/config/keymaps-vscode.lua
/Users/fronz/.config/nvim/lua/config/keymaps.lua
/Users/fronz/.config/nvim/lua/config/lazy.lua
/Users/fronz/.config/nvim/lua/config/options.lua
/Users/fronz/.config/nvim/lua/plugins/colorscheme.lua
/Users/fronz/.config/nvim/lua/plugins/completion.lua
/Users/fronz/.config/nvim/lua/plugins/editor.lua
/Users/fronz/.config/nvim/lua/plugins/extras.lua
/Users/fronz/.config/nvim/lua/plugins/filetree.lua
/Users/fronz/.config/nvim/lua/plugins/fuzzy.lua
/Users/fronz/.config/nvim/lua/plugins/lsp.lua
/Users/fronz/.config/nvim/lua/plugins/treesitter.lua
/Users/fronz/.config/nvim/lua/plugins/ui.lua
/Users/fronz/.config/nvim/lua/plugins/vscode.lua
/Users/fronz/.config/nvim/lua/utils/easy-motion.lua
/Users/fronz/.config/nvim/lua/utils/gitlens-line-history.lua
/Users/fronz/.config/nvim/lua/utils/treesitter-function-name.lua
/Users/fronz/.config/nvim/lua/utils/vscode-git-diff-navigation.lua
/Users/fronz/.config/nvim/lua/utils/vscode-scroll.lua
```

- [ ] **Step 2: Full integration test in tmux — cold start**

Clear the lazy.nvim lock file to force fresh install:

```bash
rm -f ~/.config/nvim/lazy-lock.json
```

Launch nvim in tmux:

```bash
tmux send-keys -t 0 'nvim' Enter
```

Wait for all plugins to install. Then run a full checklist:

```bash
tmux send-keys -t 0 ':checkhealth' Enter
```

Review the output for any critical errors. Press `q` to close.

- [ ] **Step 3: Test each plugin layer**

Open a Lua file:

```bash
tmux send-keys -t 0 ':e ~/.config/nvim/init.lua' Enter
```

Test sequence:
1. **Treesitter**: syntax should be highlighted in colors
2. **LSP**: `:LspInfo` should show `lua_ls` attached
3. **Completion**: press `o` then type `vim.` — completion popup should appear, press `Escape`
4. **Fuzzy finder**: press `<Space>ff` — file picker opens, press `Escape`
5. **File tree**: press `<Space>e` — neo-tree sidebar opens, press `<Space>e` to close
6. **UI**: lualine visible at bottom, bufferline at top after opening 2+ files
7. **Mini.surround**: on a word, type `gzaiw"` — word gets quoted, then `u` to undo
8. **Keymaps**: `U` should redo, `Escape` should clear search highlights

```bash
tmux send-keys -t 0 ':qa!' Enter
```

- [ ] **Step 4: Test opening a markdown file (the OOM scenario)**

```bash
tmux send-keys -t 0 'nvim ~/some-test-file.md' Enter
```

Expected: file opens without OOM crash, syntax highlighting works.

```bash
tmux send-keys -t 0 ':qa!' Enter
```

- [ ] **Step 5: Final commit**

```bash
cd ~/.config/nvim
git add -A
git commit -m "chore: finalize from-scratch nvim config, remove LazyVim artifacts"
```
