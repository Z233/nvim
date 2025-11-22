## ADDED Requirements

### Requirement: File-Switching Navigation
The system SHALL provide dedicated keybindings for switching between git changed files independent of within-file change navigation.

#### Scenario: Next changed file from normal editor
- **WHEN** user presses `]gf` in a normal editor
- **THEN** system switches to the next file in the git changed files list and positions cursor at the first change

#### Scenario: Previous changed file from normal editor
- **WHEN** user presses `[gf` in a normal editor
- **THEN** system switches to the previous file in the git changed files list and positions cursor at the last change

#### Scenario: Next changed file from diff editor
- **WHEN** user presses `]gf` in a diff editor view
- **THEN** system closes current diff editor (if not preview) and opens git diff view for the next changed file

#### Scenario: Previous changed file from diff editor
- **WHEN** user presses `[gf` in a diff editor view
- **THEN** system closes current diff editor (if not preview) and opens git diff view for the previous changed file

#### Scenario: Wrap to first file at end
- **WHEN** user presses `]gf` while viewing the last changed file
- **THEN** system wraps around to the first changed file in the list

#### Scenario: Wrap to last file at beginning
- **WHEN** user presses `[gf` while viewing the first changed file
- **THEN** system wraps around to the last changed file in the list

#### Scenario: No changed files
- **WHEN** user presses `]gf` or `[gf` with no git changes
- **THEN** system does nothing (no navigation occurs)

## MODIFIED Requirements

### Requirement: Within-File Change Navigation
The system SHALL navigate between changes within the current file using `]d`/`[d` keybindings, wrapping at boundaries without switching files.

#### Scenario: Next change in normal editor
- **WHEN** user presses `]d` in a normal editor
- **THEN** cursor moves to the next change in the current file

#### Scenario: Previous change in normal editor
- **WHEN** user presses `[d` in a normal editor
- **THEN** cursor moves to the previous change in the current file

#### Scenario: Next change in diff editor
- **WHEN** user presses `]d` in a diff editor view
- **THEN** diff view scrolls to the next change within the current file comparison

#### Scenario: Previous change in diff editor
- **WHEN** user presses `[d` in a diff editor view
- **THEN** diff view scrolls to the previous change within the current file comparison

#### Scenario: Wrap to first change at end
- **WHEN** user presses `]d` while at the last change in the file
- **THEN** cursor wraps to the first change in the same file

#### Scenario: Wrap to last change at beginning
- **WHEN** user presses `[d` while at the first change in the file
- **THEN** cursor wraps to the last change in the same file

#### Scenario: No more changes (removed behavior)
- **WHEN** user presses `]d` or `[d` and navigation would previously have switched files
- **THEN** system wraps within the current file instead (file-switching behavior removed)

### Requirement: Git Changed Files Caching
The system SHALL cache the list of git changed files with a 2-second TTL to optimize performance for both within-file and file-switching navigation.

#### Scenario: Cache hit within TTL
- **WHEN** navigation functions are called within 2 seconds of the last git query
- **THEN** cached file list is used without executing new git commands

#### Scenario: Cache miss after TTL
- **WHEN** navigation functions are called more than 2 seconds after the last git query
- **THEN** git commands execute to refresh the changed files list and update the cache

#### Scenario: Shared cache across navigation types
- **WHEN** both `]d`/`[d` and `]gf`/`[gf` keybindings are used
- **THEN** both use the same cached git changed files list

### Requirement: Change Bounds Caching
The system SHALL cache the first and last change line numbers for all changed files with a 2-second TTL for efficient file-switching positioning.

#### Scenario: File switch positioning with cached bounds
- **WHEN** switching files with `]gf`/`[gf` and bounds are cached
- **THEN** cursor positions at the appropriate change line without re-parsing git diff output

#### Scenario: Bounds cache refresh
- **WHEN** bounds cache expires after 2 seconds
- **THEN** batch git diff command executes to refresh bounds for all changed files

#### Scenario: Normal editor file switching uses bounds
- **WHEN** `]gf` switches to next file in normal editor
- **THEN** cursor positions at the first change line using cached bounds

#### Scenario: Normal editor previous file switching uses bounds
- **WHEN** `[gf` switches to previous file in normal editor
- **THEN** cursor positions at the last change line using cached bounds
