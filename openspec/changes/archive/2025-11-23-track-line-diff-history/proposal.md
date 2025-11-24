# Proposal: Track Line Diff History

**Change ID:** `track-line-diff-history`
**Status:** Draft
**Created:** 2025-11-23

## Overview

Implement a history tracking mechanism for GitLens line-level diff navigation (`[R`/`]R`) that allows users to navigate backward through previously viewed revisions and forward through the navigation history, similar to a browser's back/forward buttons.

## Why

Currently, the `[R` keybinding uses `gitlens.diffLineWithPrevious` to view a line's history, and `]R` uses `gitlens.diffLineWithWorking` to jump back to the working version. This creates a poor user experience:

**Problem:**
```
Working version → [R → Revision 1 → [R → Revision 2 → [R → Revision 3 → ]R → Working version
```
After viewing multiple historical revisions with `[R`, pressing `]R` skips all intermediate revisions and jumps directly to the working version, losing the navigation context.

**Desired behavior:**
```
Working version → [R → Revision 1 → [R → Revision 2 → [R → Revision 3 → ]R → Revision 2 → ]R → Revision 1 → ]R → Working version
```
Users should be able to step backward through history (`[R`) and forward through their navigation path (`]R`), maintaining a complete navigation stack.

## What Changes

### New Module: `lua/utils/gitlens-line-history.lua`
Create a new module to manage line diff history navigation:
1. Maintain a history stack of viewed revisions for the current line
2. Track current position in the history stack
3. Provide `goToPreviousRevision()` - wraps `gitlens.diffLineWithPrevious` and pushes to stack
4. Provide `goToNextRevision()` - pops from stack and navigates to previous state
5. Clear history when line/file changes

### Update Keymaps: `lua/config/keymaps.lua`
Replace direct GitLens commands with history-aware functions:
- `[R` → call `lineDiffHistory.goToPreviousRevision()`
- `]R` → call `lineDiffHistory.goToNextRevision()`

## Impact

- **No Breaking Changes:** Existing `[R` behavior remains the same (view previous revision)
- **Enhanced UX:** `]R` now provides intuitive "go back one step" instead of "jump to working version"
- **State Management:** Adds minimal state tracking (history stack per line)
- **Performance:** Negligible - only tracks navigation history in memory

## Alternatives Considered

1. **Remove `]R` mapping** - Simple but asymmetric and less useful
2. **Use `gitlens.diffLineWithWorking` for `]R`** - Current behavior, but unintuitive after multiple `[R` presses
3. **Use different commands** - No suitable GitLens commands exist for "next revision"

## Design Considerations

### History Stack Management
- **Per-file, per-line tracking:** Each line maintains its own history stack
- **Clear conditions:** Clear history when changing files or lines
- **Stack size limit:** Optionally limit stack depth (e.g., 50 items) to prevent memory issues

### Edge Cases
- When at the end of history (working version), `]R` should do nothing or show a message
- When at the beginning of history, `[R` should continue calling GitLens to fetch older revisions
- File/line changes should reset the history stack
