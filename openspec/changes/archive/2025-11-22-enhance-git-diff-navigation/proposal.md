# Change: Enhance Git Diff Navigation

## Why
The current `]d`/`[d` keybindings conflate two distinct behaviors: navigating changes within a file and switching between changed files. This coupling reduces predictability and makes it harder to quickly review changes in a single file without accidentally jumping to another file. Additionally, there was no easy way to toggle between diff view and normal editor.

## What Changes
- **MODIFIED**: `]d`/`[d` will only navigate changes within the current file (wrapping to first/last change at boundaries)
- **ADDED**: New `]gf`/`[gf` keybindings for switching between changed files while maintaining view context
- **ADDED**: New `<leader>gd` keybinding to open current file in diff view
- **ADDED**: New `<leader>go` keybinding to switch from diff/git view to normal editor
- The new file-switching keybindings will support both normal editor and diff editor contexts and maintain the current view mode
- Both keybindings preserve their existing cache optimization (2-second TTL for changed files list)
- **FIXED**: Cursor synchronization issue where VSCode cursor movements weren't propagating back to Neovim
- **FIXED**: File-switching in diff view now maintains diff view instead of switching to normal editor
- **IMPROVED**: File ordering now matches VSCode file explorer tree order for intuitive navigation

## Impact
- Affected specs: `vscode-git-navigation` (new capability)
- Affected code:
  - `lua/config/keymaps.lua` - Add new keybindings for `]gf`/`[gf`, `<leader>gd`, and `<leader>go`
  - `lua/utils/vscode-git-diff-navigation.lua` - Refactor to separate file-switching logic into dedicated functions, fix cursor sync by explicitly capturing VSCode cursor position and setting it in Neovim, improve file sorting algorithm, and add view context preservation
- Breaking change: Users accustomed to file-switching behavior of `]d`/`[d` will need to use `]gf`/`[gf` instead

## Technical Notes

### Cursor Synchronization Issue
The implementation revealed a cursor synchronization issue between VSCode and Neovim. When calling VSCode commands via `vscode.eval()`, cursor position changes in VSCode don't automatically propagate back to Neovim. The solution is to:
1. Execute the VSCode navigation command with `await`
2. Capture the resulting cursor position from VSCode's editor object
3. Explicitly set Neovim's cursor using `vim.api.nvim_win_set_cursor()` with the 1-based converted coordinates

### File Sorting Algorithm
Changed files are now sorted to match VSCode's file explorer tree order for more intuitive navigation:
- Directories are compared level-by-level alphabetically
- Within the same parent directory, deeper paths appear first (files in subdirectories before parent directory files)
- Files at the same depth are sorted alphabetically by filename

This ensures that `]gf`/`[gf` navigation follows the same visual order as the file tree, making it easier to understand which file comes next.

### View Context Preservation
File-switching keybindings (`]gf`/`[gf`) now maintain the current view context:
- When in diff view: uses `git.openChange` to open the next/previous file in diff view
- When in normal editor: uses `openTextDocument` + `showTextDocument` to open in normal editor
- This is detected via `isInGitDiffEditor()` check

### Diff/Git View to Normal Editor Toggle
Added `openCurrentFileInNormalEditor()` function that supports two types of diff/git views:
1. **Standard diff view**: Has `input.modified` and `input.original` properties (opened via `git.openChange`)
2. **Single file git view**: Has `input.uri` with `scheme === 'git'` (viewing a file from git directly)

The function:
- Detects which type of view is active
- Extracts the file path appropriately
- Closes the diff/git editor
- Opens the file in normal editor
- Preserves cursor position

This pairs with `<leader>gd` to create a complete toggle cycle: `<leader>gd` → diff view, `<leader>go` → normal editor.
