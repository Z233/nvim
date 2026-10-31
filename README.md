# Neovim configuration

Custom terminal and VSCode configuration managed with lazy.nvim, without LazyVim.

## Requirements

- Neovim 0.13 (currently tested with `0.13.0-dev-1964+ge0516a46e8`).
- Tree-sitter CLI 0.26.1 or later (`brew install tree-sitter-cli`), a C compiler, `curl`, and `tar`.
- nvim-treesitter uses the `main` branch. Parsers install automatically; run `:TSUpdate` after plugin updates.

On this Mac, the shell selects `~/.local/opt/neovim-nightly/bin/nvim` before Homebrew's stable binary.
The shell settings are managed separately with chezmoi.

## Verification

Run `bash tests/neovim-013.test.sh` to check startup, TypeScript LSP, highlighting, indentation, completion, and keymaps.
The test prints its artifact directory, including `result.json` and `startup.log`.
Run the other `tests/*.test.sh` scripts for clipboard, CodeDiff, and directory startup checks.
