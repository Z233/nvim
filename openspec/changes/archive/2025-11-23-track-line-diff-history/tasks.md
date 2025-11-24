# Implementation Tasks: Track Line Diff History

**Change ID:** `track-line-diff-history`

## Tasks

### 1. Create Line History Module
- [x] **File**: `lua/utils/gitlens-line-history.lua` (new)
- [x] **Changes**:
  - Create module structure with history state
  - Implement stack management (push, pop, clear)
  - Add context detection (file/line tracking)
- [x] **Validation**: Module loads without errors, exports expected functions

### 2. Implement goToPreviousRevision Function
- [x] **File**: `lua/utils/gitlens-line-history.lua`
- [x] **Changes**:
  - Get current file path and line number from VSCode
  - Detect context changes and clear stack if needed
  - Execute `gitlens.diffLineWithPrevious` via vscode.eval
  - Push current state to history stack
  - Increment current_index
- [x] **Validation**:
  - Pressing `[R` shows previous revision
  - Stack grows with each navigation
  - Context changes reset the stack

### 3. Implement goToNextRevision Function
- [x] **File**: `lua/utils/gitlens-line-history.lua`
- [x] **Changes**:
  - Check if at end of history (current_index == 0)
  - Decrement current_index
  - If at working version: close diff view
  - Otherwise: navigate to state at stack[current_index]
  - Handle edge cases (empty stack, invalid state)
- [x] **Validation**:
  - After `[R` → `[R` → `[R`, pressing `]R` three times returns to working version
  - At working version, `]R` does nothing
  - Navigation maintains correct position in stack

### 4. Add Debug Logging
- [x] **File**: `lua/utils/gitlens-line-history.lua`
- [x] **Changes**:
  - Add DEBUG flag (same pattern as vscode-git-diff-navigation.lua)
  - Log stack operations (push, pop, clear)
  - Log context changes
  - Log navigation events
- [x] **Validation**: When DEBUG=1, see detailed logs of history operations

### 5. Implement Context Change Detection
- [x] **File**: `lua/utils/gitlens-line-history.lua`
- [x] **Changes**:
  - Get active editor file path from VSCode
  - Get cursor line number from Neovim
  - Compare with last tracked state
  - Allow ±5 line tolerance for line number changes
  - Clear stack on significant context change
- [x] **Validation**:
  - Changing files clears history
  - Moving to different line clears history
  - Small line shifts (±5) don't clear history

### 6. Update Keymaps
- [x] **File**: `lua/config/keymaps.lua`
- [x] **Changes**:
  - Remove direct GitLens command mappings for `[R` and `]R`
  - Require `utils.gitlens-line-history` module
  - Map `[R` to `lineDiffHistory.goToPreviousRevision`
  - Map `]R` to `lineDiffHistory.goToNextRevision`
- [x] **Validation**:
  - Keymaps trigger the new functions
  - No errors when pressing `[R` or `]R`

### 7. Add Stack Size Limit
- [x] **File**: `lua/utils/gitlens-line-history.lua`
- [x] **Changes**:
  - Add MAX_HISTORY_SIZE constant (default: 50)
  - Implement FIFO eviction when stack exceeds limit
  - Update push operation to check size
- [x] **Validation**:
  - Stack doesn't grow beyond MAX_HISTORY_SIZE
  - Oldest entries are removed first
  - Navigation still works correctly with limited stack

### 8. Error Handling
- [x] **File**: `lua/utils/gitlens-line-history.lua`
- [x] **Changes**:
  - Wrap GitLens commands in pcall
  - Handle VSCode API failures gracefully
  - Validate stack states before navigation
  - Fall back to safe state on errors
- [x] **Validation**:
  - Module doesn't crash on GitLens command failures
  - Invalid states don't break navigation
  - Errors are logged (when DEBUG=1)

## Manual Testing Checklist

- [x] Basic navigation: `[R` → `]R` returns to previous state
- [x] Multiple backward: `[R` → `[R` creates history (note: GitLens limitation means same revision)
- [x] Multiple forward: After multiple `[R`, pressing `]R` returns step by step
- [x] At working version: `]R` does nothing
- [x] Context change (file): History clears when changing files
- [x] Context change (line): History clears when moving to different line
- [x] Line tolerance: Small line movements (±5) don't clear history
- [x] Stack limit: History doesn't exceed MAX_HISTORY_SIZE
- [x] Error recovery: Module handles GitLens command failures
- [x] Stack clearing: History clears when returning to working version

## Dependencies

- Requires `vscode-neovim` plugin
- Requires GitLens extension in VSCode
- Builds on patterns from `vscode-git-diff-navigation.lua`

## Success Criteria

- ✅ `[R` and `]R` provide intuitive back/forward navigation
- ✅ History is maintained per file/line context
- ✅ Navigation works correctly at all positions in history
- ✅ Stack management prevents memory leaks (cleared when returning to working version)
- ✅ Error handling prevents crashes
- ✅ Code follows existing module patterns
- ✅ SHA extraction from GitLens URI query parameters works correctly

## Known Limitations

- GitLens `diffLineWithPrevious` always shows the same revision relative to working tree
- Cannot navigate to arbitrary parent commits; only supports back/forward through navigation history
- Stack is cleared when returning to working version to prevent stale state
