# Specification: Git Diff Navigation

**Capability:** `git-diff-navigation`
**Version:** 1.0.0
**Status:** Active

## Purpose

Provides keyboard-driven navigation for git changes in VSCode, supporting both diff editor views and normal editor views with intelligent context switching.

## ADDED Requirements

### Requirement: Detect GitLens/Git Diff Editor Context
The system SHALL detect when the user is viewing a file in a diff editor, supporting both `git://` and `gitlens://` URI schemes.

#### Scenario: User opens diff view via GitLens

**Given** a user has a git repository with uncommitted changes
**When** the user opens a changed file via GitLens `diffWithPrevious` command (resulting in `git://` scheme)
**Then** the system shall recognize this as a diff editor context
**And** navigation commands shall use diff-aware behavior with cursor synchronization

**Acceptance Criteria:**
- `isInGitDiffEditor()` returns `true` when `activeTabInput.original.scheme === 'git'` OR `'gitlens'`
- Both `git://` and `gitlens://` schemes are supported
- Navigation maintains diff view when switching between files
- Cursor position syncs correctly for `]d`/`[d` navigation

---

### Requirement: Switch from Diff View to Normal Editor
The system SHALL allow users to switch from a diff view (opened by GitLens or native git) to a normal editor view while preserving cursor position.

#### Scenario: User switches from diff view to normal editor

**Given** a user is viewing a file in diff view (opened via GitLens or native git)
**And** the cursor is at a specific line and character position
**When** the user invokes the "open in normal editor" command
**Then** the system shall close the diff editor
**And** open the modified file in a normal editor
**And** restore the cursor to the same line and character position
**And** center the viewport on the cursor position

**Acceptance Criteria:**
- `openCurrentFileInNormalEditor()` detects `original.scheme === 'git'` OR `'gitlens'`
- Cursor position is preserved across the view switch
- The normal editor opens the working copy (not a git revision)

---

## ADDED Requirements

### Requirement: GitLens as Primary Diff View
The system SHALL use GitLens commands for opening diff views, which provide enhanced features while maintaining compatibility with standard git:// URI scheme.

#### Scenario: Open file in diff view via GitLens

**Given** a user is in a normal editor viewing a file with uncommitted changes
**When** the user presses `<leader>gd`
**Then** the system shall execute `gitlens.diffWithPrevious` command
**And** open the file in diff view (using `git://` scheme)
**And** display GitLens enhanced diff interface

**Acceptance Criteria:**
- `<leader>gd` keymap triggers `gitlens.diffWithPrevious` instead of `git.openChange`
- Resulting tab has `original.scheme === 'git'` (GitLens uses standard git scheme)
- Diff view shows GitLens enhanced features

#### Scenario: Switch between files in diff view

**Given** a workspace with multiple changed files
**And** user is in diff view for one file
**When** user navigates to next/previous file using `]gf` or `[gf`
**Then** the system shall use `gitlens.diffWithPrevious` to open the next/previous file
**And** maintain diff view context

**Acceptance Criteria:**
- `goToNextFile()` uses `gitlens.diffWithPrevious` when in diff view
- `goToPreviousFile()` uses `gitlens.diffWithPrevious` when in diff view
- Navigation preserves diff context across file switches

### Requirement: Sync Cursor Position in Diff View Navigation
The system SHALL synchronize cursor position between VSCode and Neovim when using `workbench.action.compareEditor.nextChange` and `workbench.action.compareEditor.previousChange` commands in diff views.

#### Scenario: Navigate changes within diff view with cursor sync

**Given** a user is viewing a file in diff view
**And** the file has multiple changes
**When** the user presses `]d` to go to next change
**Then** the system shall execute `workbench.action.compareEditor.nextChange`
**And** read the new cursor position from VSCode
**And** synchronize the cursor position to Neovim
**And** the cursor shall move to the next change location

**Acceptance Criteria:**
- `goToNextChange()` executes command and syncs cursor when in diff view
- `goToPreviousChange()` executes command and syncs cursor when in diff view
- Commands work seamlessly with both git and GitLens diff views
- Navigation wraps at file boundaries
- Cursor position matches between VSCode and Neovim after navigation

---

## Unchanged Requirements

The following requirements are standard navigation patterns that exist in the codebase but are not part of this change.
