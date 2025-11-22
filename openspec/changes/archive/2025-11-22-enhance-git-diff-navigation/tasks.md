## 1. Refactor navigation utility functions
- [x] 1.1 Extract file-switching logic into `goToNextFile()` function
- [x] 1.2 Extract file-switching logic into `goToPreviousFile()` function
- [x] 1.3 Modify `goToNextChange()` to remove file-switching and add wrapping behavior
- [x] 1.4 Modify `goToPreviousChange()` to remove file-switching and add wrapping behavior
- [x] 1.5 Ensure both normal editor and diff editor code paths are updated
- [x] 1.6 Preserve existing caching mechanisms (2-second TTL)
- [x] 1.7 Fix cursor sync issue: Use `vscode.eval()` with explicit cursor position return and `vim.api.nvim_win_set_cursor()` to sync VSCode cursor changes back to Neovim
- [x] 1.8 Update file sorting to match VSCode file explorer tree order (deeper paths first within same parent directory)
- [x] 1.9 Fix `]gf`/`[gf` to maintain view context (diff view stays in diff, normal editor stays normal)
- [x] 1.10 Add `openCurrentFileInNormalEditor()` function to switch from diff/git view to normal editor

## 2. Add new keybindings
- [x] 2.1 Add `]gf` keybinding mapped to `goToNextFile()` in `lua/config/keymaps.lua`
- [x] 2.2 Add `[gf` keybinding mapped to `goToPreviousFile()` in `lua/config/keymaps.lua`
- [x] 2.3 Update keybinding descriptions to clarify behavior
- [x] 2.4 Add `<leader>gd` keybinding to open current file in diff view
- [x] 2.5 Add `<leader>go` keybinding to open current file in normal editor from diff/git view

## 3. Testing
- [x] 3.1 Test `]d`/`[d` navigation stays within files in normal editor
- [x] 3.2 Test `]d`/`[d` navigation stays within files in diff editor
- [x] 3.3 Test `]d`/`[d` wrapping behavior at file boundaries
- [x] 3.4 Test `]gf`/`[gf` file switching in normal editor (stays in normal editor)
- [x] 3.5 Test `]gf`/`[gf` file switching in diff editor (stays in diff view)
- [x] 3.6 Test wrapping behavior when at first/last changed file
- [x] 3.7 Test behavior with no git changes
- [x] 3.8 Verify caching still works efficiently
- [x] 3.9 Verify file ordering matches VSCode file explorer tree order
- [x] 3.10 Test `<leader>go` from standard diff view (with modified/original)
- [x] 3.11 Test `<leader>go` from git file view (single file with git scheme)
- [x] 3.12 Test `<leader>gd` and `<leader>go` form a complete toggle cycle

## 4. Documentation
- [x] 4.1 Update any inline comments explaining the keybinding behavior
- [x] 4.2 Verify DEBUG logging messages reflect the new behavior

## 5. Bug Fixes & Improvements
- [x] 5.1 Fixed cursor sync issue where VSCode cursor changes weren't propagating back to Neovim
- [x] 5.2 Solution: Capture cursor position from VSCode after command execution and explicitly set in Neovim using `vim.api.nvim_win_set_cursor()`
- [x] 5.3 Improved file sorting algorithm to match VSCode file explorer tree order: directories are compared level-by-level, and within the same parent directory, deeper paths appear first
- [x] 5.4 Fixed `]gf`/`[gf` to maintain view context: diff view stays in diff, normal editor stays in normal editor
- [x] 5.5 Added support for two types of diff/git views: standard diff view (modified/original) and single file git view (uri with git scheme)
