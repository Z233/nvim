# Implementation Tasks: Default GitLens View

**Change ID:** `default-gitlens-view`

## Tasks

### 1. Update Diff Editor Detection
- **File**: `lua/utils/vscode-git-diff-navigation.lua:269-278`
- **Function**: `isInGitDiffEditor()`
- **Change**: Support both `git://` and `gitlens://` schemes (GitLens uses `git://` in practice)
- **Validation**: ✅ Tested detection in diff view, confirms returns `true`

### 2. Update Open in Normal Editor Function
- **File**: `lua/utils/vscode-git-diff-navigation.lua:500-558`
- **Function**: `openCurrentFileInNormalEditor()`
- **Change**: Support both `git://` and `gitlens://` schemes
- **Validation**: ✅ Tested switching from diff view to normal editor, cursor position preserved

### 3. Replace git.openChange with gitlens.diffWithPrevious in goToNextFile()
- **File**: `lua/utils/vscode-git-diff-navigation.lua:280-286`
- **Function**: `goToNextFile()`
- **Changes**:
  - Line 284: Replaced `git.openChange` with `gitlens.diffWithPrevious`
  - Updated comments to reference diff view (not specifically GitLens)
- **Validation**: ✅ Navigate to next file in diff view works correctly

### 4. Replace git.openChange with gitlens.diffWithPrevious in goToPreviousFile()
- **File**: `lua/utils/vscode-git-diff-navigation.lua:377-385`
- **Function**: `goToPreviousFile()`
- **Changes**:
  - Line 381: Replaced `git.openChange` with `gitlens.diffWithPrevious`
  - Updated comments to reference diff view
- **Validation**: ✅ Navigate to previous file in diff view works correctly

### 5. Add Cursor Synchronization in Diff View
- **File**: `lua/utils/vscode-git-diff-navigation.lua:228-267, 477-498`
- **Functions**: `executeNavigationWithCursorSync()`, `goToNextChange()`, `goToPreviousChange()`
- **Changes**:
  - Created shared `executeNavigationWithCursorSync()` function (DRY principle)
  - Updated both functions to sync cursor position in diff view
  - Reduced code duplication by ~140 lines
- **Validation**: ✅ `]d` and `[d` navigation works with proper cursor sync in diff view

### 6. Update Keymap for <leader>gd
- **File**: `lua/config/keymaps.lua:95`
- **Change**: Replaced `git.openChange` with `gitlens.diffWithPrevious`
- **After**: `vmap("n", "<leader>gd", "gitlens.diffWithPrevious", { desc = "Git: Open Diff View (GitLens)" })`
- **Validation**: ✅ `<leader>gd` opens diff view with GitLens enhancements

### 7. Update Documentation and Comments
- **Files**: `lua/utils/vscode-git-diff-navigation.lua`
- **Changes**:
  - Updated header to reference GitLens
  - Updated all inline comments to reflect diff view (supports both schemes)
  - Noted that commands work with both git and GitLens diff views
- **Validation**: ✅ Code review completed

## Manual Testing Checklist

- [x] `<leader>gd` opens diff view with GitLens enhancements
- [x] `]gf` navigates to next file in diff view
- [x] `[gf` navigates to previous file in diff view
- [x] `]d` navigates to next change within file in diff view with cursor sync
- [x] `[d` navigates to previous change within file in diff view with cursor sync
- [x] `<leader>go` switches from diff view to normal editor
- [x] Cursor position is preserved when switching from diff to normal editor
- [x] All navigation wraps correctly at boundaries
- [x] Scheme detection supports both `git://` and `gitlens://`
- [x] No regressions in normal editor navigation
- [x] Code follows DRY principle with shared cursor sync function

## Dependencies

- GitLens extension must be installed and active in VSCode
- All tasks completed successfully

## Success Criteria

- ✅ All keybindings use GitLens commands (`gitlens.diffWithPrevious`)
- ✅ Navigation maintains diff view context when switching files
- ✅ No references to `git.openChange` remain in active code paths
- ✅ All manual tests passed
- ✅ Scheme detection works for both `git://` and `gitlens://`
- ✅ Cursor synchronization works in both diff and normal editor views
- ✅ Code refactored to follow DRY principle (~140 lines reduced)
