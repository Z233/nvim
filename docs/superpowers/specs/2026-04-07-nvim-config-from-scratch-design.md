# Neovim Config From Scratch

Replace LazyVim framework with a hand-crafted configuration using lazy.nvim as plugin manager.

## Goals

- Full transparency: every option, keymap, and autocmd is explicitly defined
- Lightweight: no framework overhead, aggressive lazy-loading
- Complete IDE: LSP, completion, fuzzy finder, file tree, statusline, bufferline
- Dual environment: shared config for terminal Neovim and VSCode Neovim extension

## Directory Structure

```
~/.config/nvim/
  init.lua                     -- entry: options -> lazy -> keymaps -> autocmds
  lua/
    config/
      options.lua              -- vim.opt / vim.g
      lazy.lua                 -- lazy.nvim bootstrap + plugin spec entry
      keymaps.lua              -- shared keymaps + conditional require of vscode keymaps
      keymaps-vscode.lua       -- VSCode-only keymaps
      autocmds.lua             -- autocommands
    plugins/
      colorscheme.lua          -- Eva-Theme
      treesitter.lua           -- nvim-treesitter + textobjects
      lsp.lua                  -- nvim-lspconfig + mason + mason-lspconfig
      completion.lua           -- blink.cmp
      fuzzy.lua                -- fzf-lua
      filetree.lua             -- neo-tree
      ui.lua                   -- lualine + bufferline
      editor.lua               -- mini.ai, mini.surround, nvim-spider, hardtime
      vscode.lua               -- vscode-multi-cursor (cond = vim.g.vscode)
      extras.lua               -- timber, jieba.vim
    utils/                     -- existing utilities (preserved as-is)
      easy-motion.lua
      vscode-scroll.lua
      vscode-git-diff-navigation.lua
      gitlens-line-history.lua
      treesitter-function-name.lua
```

## init.lua Load Order

1. `config/options.lua` -- no dependencies
2. `config/lazy.lua` -- bootstrap lazy.nvim, load all plugin specs from `plugins/`
3. `config/keymaps.lua` -- after plugins are registered
4. `config/autocmds.lua` -- autocommands

## Plugin Inventory

### Core (loaded at startup)

| Plugin | Purpose | Loading |
|--------|---------|---------|
| lazy.nvim | Plugin manager | bootstrap |
| Eva-Theme.nvim | Colorscheme | `lazy=false, priority=1000` |
| nvim-treesitter | Syntax highlighting, textobjects | `event=BufRead` |

### LSP (loaded on file open)

| Plugin | Purpose | Loading |
|--------|---------|---------|
| nvim-lspconfig | LSP configuration | `event=BufRead` |
| mason.nvim | LSP server installer | follows lspconfig |
| mason-lspconfig.nvim | Bridge mason + lspconfig | follows mason |

LSP servers: `ts_ls`, `volar`, `lua_ls`, `jsonls`, `yamlls`.

### Completion (loaded on insert)

| Plugin | Purpose | Loading |
|--------|---------|---------|
| blink.cmp | Completion engine (Rust-based) | `event=InsertEnter` |

### Editor Enhancement (lazy loaded)

| Plugin | Purpose | Loading |
|--------|---------|---------|
| mini.ai | Extended text objects | `event=BufRead` |
| mini.surround | Surround operations | `event=BufRead` |
| nvim-spider | Smart word motion | `lazy=true` (keymap trigger) |
| hardtime.nvim | Enforce good habits | `lazy=false` |
| jieba.vim | Chinese word segmentation | `event=BufRead` |

### Search and Navigation

| Plugin | Purpose | Loading |
|--------|---------|---------|
| fzf-lua | Fuzzy file/text search | `cmd` / keymap trigger |
| neo-tree.nvim | File tree | `cmd` / keymap trigger |

### UI

| Plugin | Purpose | Loading |
|--------|---------|---------|
| lualine.nvim | Statusline | `event=VeryLazy` |
| bufferline.nvim | Buffer tabs | `event=VeryLazy` |

### Extras

| Plugin | Purpose | Loading |
|--------|---------|---------|
| timber.nvim | Debug log generation | `event=VeryLazy` |
| vscode-multi-cursor.nvim | VSCode multi-cursor | `cond=vim.g.vscode` |

## Options (config/options.lua)

Preserved from current config:
- `guifont = "Dank Mono:h15"`
- `clipboard = "unnamedplus"`
- `language en_US.UTF-8`

Non-VSCode additions:
- `relativenumber = true`, `number = true`
- `scrolloff = 8`, `sidescrolloff = 8`
- `undofile = true`
- `wrap = false`
- `smoothscroll = true`

New defaults (replacing LazyVim implicit settings):
- `termguicolors = true`
- `expandtab = true`, `shiftwidth = 2`, `tabstop = 2`
- `ignorecase = true`, `smartcase = true`
- `signcolumn = "yes"`
- `splitbelow = true`, `splitright = true`
- `updatetime = 250`
- `timeoutlen = 300`
- `cursorline = true`
- `mouse = "a"`

## Keymaps Strategy

### Shared keymaps (config/keymaps.lua)

Migrated from current config:
- Spider word motions (w, e, b, ge)
- cL/vL/dL/yL and cH/vH/dH/yH line operations
- easy-motion jump (s)
- Visual indent stay (<, >)
- U for redo
- Esc clear highlights
- Search with auto-mark (/, ?)
- Window navigation (Ctrl+hjkl)
- ParseClipboardToPlainText paste (<leader>p)
- Copy file path / file location (<leader>yf, <leader>yl)

### LSP keymaps (plugins/lsp.lua on_attach)

- `gd` goto definition
- `gD` goto declaration
- `gI` goto implementation
- `gy` goto type definition
- `gr` references (via fzf-lua)
- `K` hover
- `gK` / `<C-k>` signature help
- `<leader>ca` code action
- `<leader>cr` rename
- `<leader>cf` format
- Diagnostic navigation: `]d`, `[d`, `]e`, `[e`

### Buffer navigation (config/keymaps.lua, non-VSCode)

- `gt` / `gT` next/prev buffer
- `<leader>bb` switch to other buffer
- `<leader>bd` delete buffer
- `<leader>bo` delete other buffers

### VSCode keymaps (config/keymaps-vscode.lua)

All existing VSCode keymaps preserved as-is, loaded conditionally when `vim.g.vscode` is true.

## Autocmds (config/autocmds.lua)

Preserved:
- Yank history ring (TextYankPost)

New:
- Highlight on yank (vim.hl.on_yank)
- Close special buffers with `q` (help, man, quickfix, etc.)
- Restore cursor position on file open
- Auto-create parent directories on save

## VSCode Isolation

- Terminal-only plugins use `cond = not vim.g.vscode` (neo-tree, lualine, bufferline, LSP, mason, fzf-lua, blink.cmp)
- VSCode-only plugins use `cond = vim.g.vscode` (vscode-multi-cursor)
- Shared plugins load in both environments: mini.ai, mini.surround, nvim-spider, hardtime, timber, jieba.vim
- VSCode keymaps live in `config/keymaps-vscode.lua`, conditionally required

## Migration Notes

- All `utils/` files preserved unchanged
- `lazy-lock.json` will be regenerated
- `lazyvim.json` can be deleted (LazyVim extras config)
- `CLAUDE.md` and `AGENTS.md` preserved
- Old `plugins/core.lua` replaced entirely by new plugin files
