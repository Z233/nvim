# Specification: Line Diff History Navigation

**Capability:** `line-diff-history`
**Version:** 1.0.0
**Status:** Active

## Purpose

Provides bidirectional navigation through GitLens line-level diff history, allowing users to step backward through revisions and forward through their navigation path, similar to browser back/forward buttons.

## ADDED Requirements

### Requirement: Navigate Backward Through Line History
The system SHALL allow users to navigate backward through the revision history of a specific line, maintaining a navigation stack of viewed states.

#### Scenario: User views multiple previous revisions

**Given** a user is editing a file with a line that has revision history
**When** the user presses `[R` three times in succession
**Then** the system shall execute `gitlens.diffLineWithPrevious` three times
**And** push three states to the navigation history stack
**And** display each progressively older revision

**Acceptance Criteria:**
- Each `[R` press shows an older revision of the line
- Navigation stack grows with each backward navigation
- GitLens diff view is opened for each revision
- Current position in stack is tracked

---

### Requirement: Navigate Forward Through Navigation History
The system SHALL allow users to navigate forward through previously visited revision states, stepping back through their navigation path.

#### Scenario: User navigates forward after viewing history

**Given** a user has pressed `[R` three times to view old revisions
**And** the navigation stack contains three historical states
**When** the user presses `]R` three times
**Then** the system shall step forward through the stack
**And** return to each previously viewed state in reverse order
**And** finally return to the working version

**Acceptance Criteria:**
- `]R` moves forward one step in navigation history
- Navigation maintains correct position in stack
- Pressing `]R` at working version does nothing
- Each step shows the correct revision

---

### Requirement: Clear History on Context Change
The system SHALL clear the navigation history stack when the user changes file or navigates to a significantly different line.

#### Scenario: History cleared when changing files

**Given** a user has navigation history for line 50 in file A
**When** the user switches to file B
**Then** the system shall clear the navigation history stack
**And** reset the current position to 0 (working version)

**Acceptance Criteria:**
- File change is detected via VSCode active editor API
- Stack is cleared when file path changes
- New navigation starts fresh in new file

#### Scenario: History cleared when line changes significantly

**Given** a user has navigation history for line 50
**When** the user moves cursor to line 80 (>5 line difference)
**Then** the system shall clear the navigation history stack
**And** reset the current position to 0

**Acceptance Criteria:**
- Line number changes >±5 lines clear history
- Small line shifts (±5 lines) preserve history
- Line number is tracked from Neovim cursor position

---

### Requirement: Limit Stack Size
The system SHALL limit the navigation history stack to prevent excessive memory usage, using FIFO eviction when the limit is reached.

#### Scenario: Stack size limited to maximum

**Given** the MAX_HISTORY_SIZE is set to 50
**And** a user has navigated backward 50 times
**When** the user presses `[R` again
**Then** the system shall add the new state to the stack
**And** remove the oldest state from the stack
**And** maintain exactly 50 entries

**Acceptance Criteria:**
- Stack size never exceeds MAX_HISTORY_SIZE (default: 50)
- Oldest entries are evicted first (FIFO)
- Navigation continues to work correctly with limited stack
- MAX_HISTORY_SIZE is configurable via module constant

---

### Requirement: Handle Navigation Errors Gracefully
The system SHALL handle GitLens command failures and invalid stack states without crashing, falling back to safe defaults.

#### Scenario: GitLens command fails

**Given** a user presses `[R`
**When** `gitlens.diffLineWithPrevious` command fails
**Then** the system shall not modify the navigation stack
**And** log the error (if DEBUG mode enabled)
**And** continue to function normally

**Acceptance Criteria:**
- GitLens commands wrapped in pcall or error handling
- Failed commands don't corrupt stack state
- Errors are logged when DEBUG=1
- Module continues to function after errors

---

### Requirement: Provide Debug Logging
The system SHALL provide detailed debug logging of stack operations and navigation events when DEBUG mode is enabled.

#### Scenario: Debug mode shows stack operations

**Given** DEBUG flag is set to 1
**When** user performs navigation operations
**Then** the system shall log:
- Stack push/pop operations
- Context change detection
- Current stack size and position
- Navigation events

**Acceptance Criteria:**
- DEBUG flag follows same pattern as vscode-git-diff-navigation.lua
- All major operations are logged
- Logs include relevant context (file, line, stack state)
- Logs are readable and useful for debugging
