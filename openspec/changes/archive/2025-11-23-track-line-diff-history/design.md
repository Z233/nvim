# Design: Line Diff History Tracking

**Change ID:** `track-line-diff-history`

## Architecture Overview

This design implements a navigation history stack for GitLens line-level diffs, allowing users to move backward and forward through previously viewed revisions.

## Component Design

### 1. History Stack Structure

```lua
{
  stack = {},        -- Array of history states
  current_index = 0, -- Current position in stack (0 = working version)
  file_path = nil,   -- Current file path
  line_number = nil  -- Current line number
}
```

**History State Entry:**
```lua
{
  file = string,      -- File path
  line = number,      -- Line number (1-based)
  timestamp = number  -- When this state was created
}
```

### 2. Navigation Flow

#### Going Backward (`[R` - goToPreviousRevision)
1. Check if context changed (file/line different from last state)
   - If changed: Clear stack, set current_index = 0
2. Execute `gitlens.diffLineWithPrevious`
3. Push current state to stack
4. Increment current_index

#### Going Forward (`]R` - goToNextRevision)
1. Check if at the end of stack (current_index == 0)
   - If yes: Do nothing (already at working version)
2. Decrement current_index
3. If current_index == 0:
   - Close diff view (return to working version)
4. Else:
   - Navigate to state at stack[current_index]

### 3. State Management

#### When to Clear History
- File changes (detected via VSCode active editor)
- Line number changes significantly (more than ±5 lines)
- Manual clear command (optional)

#### Stack Size Limit
- Default: 50 entries
- Configurable via module constant
- FIFO eviction when limit reached

## Integration Points

### With Existing Code
- Uses existing `vscode-neovim` integration patterns
- Follows same debug logging approach as `vscode-git-diff-navigation.lua`
- Integrates with VSCode's active editor API

### With GitLens
- Wraps `gitlens.diffLineWithPrevious` command
- Monitors diff view state through VSCode tab API
- No modifications to GitLens itself

## Trade-offs

### Chosen Approach: In-Memory Stack
**Pros:**
- Simple implementation
- Fast access
- No persistence complexity

**Cons:**
- History lost on restart
- Memory usage grows with navigation

**Alternatives Considered:**
1. **Persistent storage** - Too complex for user value
2. **Global history** - Confusing across files/lines
3. **Time-based navigation** - Doesn't match user mental model

### Context Detection Strategy
**Chosen:** File path + line number (with tolerance)

**Why:**
- Accurately detects when user changes context
- Tolerates minor line shifts (e.g., from edits above)
- Simple to implement

**Alternatives:**
- Content-based hashing - Too slow
- Exact line matching - Too brittle

## Error Handling

### GitLens Command Failures
- If `gitlens.diffLineWithPrevious` fails, don't modify stack
- Log error in debug mode
- Show user-friendly message

### Invalid Stack States
- Validate before navigation
- Fall back to working version if state is invalid
- Clear corrupted stack

## Performance Considerations

- **Stack operations:** O(1) for push/pop
- **Memory:** ~50 bytes per entry × 50 entries = ~2.5KB max
- **VSCode API calls:** Minimal - only on navigation

## Future Enhancements (Not in Scope)

- Persist history across sessions
- Show history in UI (like VS Code's timeline view)
- Support for file-level history (not just line-level)
- Integration with `]r`/`[r` for unified history
