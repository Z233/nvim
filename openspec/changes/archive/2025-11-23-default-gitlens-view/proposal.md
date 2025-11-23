# Proposal: Default GitLens View

**Change ID:** `default-gitlens-view`
**Status:** Draft
**Created:** 2025-11-23

## Overview

Fully integrate GitLens as the primary git diff system, replacing VSCode's native git diff functionality. This includes:
- Using `gitlens://` scheme detection for diff editor context
- Replacing `git.openChange` with `gitlens.diffWithPrevious` for opening diff views
- Using GitLens-aware change navigation commands
- Ensuring all navigation keybindings work seamlessly with GitLens's enhanced diff interface

## Why

GitLens provides a superior diff experience with features like:
- Richer context and metadata
- Better visualization of changes
- Integrated blame and history

Debug logs revealed that `gitlens.diffWithPrevious` command actually opens diffs using the `git://` URI scheme (not `gitlens://`), but this is still preferable to native VSCode git commands because:
- GitLens enhances the diff view with additional features
- The `workbench.action.compareEditor.*` commands work seamlessly with GitLens-opened diffs
- Users get the GitLens experience they're familiar with

By defaulting to GitLens as the primary git diff view, users get consistent navigation behavior with the enhanced diff interface they're already using.

## What Changes

### Code Changes (`lua/utils/vscode-git-diff-navigation.lua`)
1. Update `isInGitDiffEditor()` to detect both `git` and `gitlens` schemes (since `gitlens.diffWithPrevious` uses `git://`)
2. Update `openCurrentFileInNormalEditor()` to handle diff views opened by GitLens commands
3. Replace all `git.openChange` commands with `gitlens.diffWithPrevious` in:
   - `goToNextFile()` - when switching files in diff view
   - `goToPreviousFile()` - when switching files in diff view
4. Update `goToNextChange()` and `goToPreviousChange()` to sync cursor position in diff view (same as normal editor)
5. Update comments to reflect GitLens integration

### Keymap Changes (`lua/config/keymaps.lua`)
6. Update `<leader>gd` binding from `git.openChange` to `gitlens.diffWithPrevious`

## Impact

- **No Breaking Changes:** Since `gitlens.diffWithPrevious` uses `git://` scheme, both GitLens and native git diffs are supported
- **Benefit:** GitLens users get enhanced diff features with seamless navigation
- **Cursor Sync:** Fixed cursor synchronization issue in diff views for `]d`/`[d` navigation

## Alternatives Considered

1. **Support both schemes** - Adds complexity with minimal benefit since GitLens is the de facto standard
2. **Add configuration option** - Unnecessary complexity for a clear default preference
3. **Auto-detect available schemes** - Over-engineered for a straightforward preference switch

## Related Changes

This change focuses solely on scheme detection. The navigation logic, file switching, and cursor positioning remain unchanged.
