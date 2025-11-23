-- VSCode GitLens Diff Navigation Utilities
-- Hybrid approach: Lua for git operations, JS for VSCode/GitLens commands

local M = {}

local vscode = require("vscode-neovim")

local DEBUG = 0

-- Cache for git changed files
local cached_files = nil
local cache_timestamp = 0
local CACHE_TTL = 2000 -- 2 seconds

-- Cache for change bounds
local cached_bounds = nil
local bounds_cache_timestamp = 0
local BOUNDS_CACHE_TTL = 2000 -- 2 seconds

-- Get changed files using git command (Lua side)
local function getChangedFilesFromGit()
  local current_time = vim.loop.now()

  -- Return cached result if still valid
  if cached_files and (current_time - cache_timestamp) < CACHE_TTL then
    return cached_files
  end

  -- Get git root directory
  local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("%s+$", "")
  if vim.v.shell_error ~= 0 then
    cached_files = {}
    cache_timestamp = current_time
    return {}
  end

  -- Get changed files (both staged and unstaged)
  local cmd = "cd '" .. git_root .. "' && git diff --name-only HEAD && git diff --name-only --cached"
  local output = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    cached_files = {}
    cache_timestamp = current_time
    return {}
  end

  -- Parse output into file list
  local files = {}
  local seen = {}
  for line in output:gmatch("[^\r\n]+") do
    if line ~= "" and not seen[line] then
      seen[line] = true
      table.insert(files, git_root .. "/" .. line)
    end
  end

  -- Sort files to match VSCode file explorer tree order
  -- Files are ordered as they appear when expanding folders top-to-bottom
  table.sort(files, function(a, b)
    -- Split paths into components
    local a_parts = {}
    local b_parts = {}
    for part in a:gmatch("[^/]+") do
      table.insert(a_parts, part)
    end
    for part in b:gmatch("[^/]+") do
      table.insert(b_parts, part)
    end

    -- Compare directory by directory from root
    local min_len = math.min(#a_parts - 1, #b_parts - 1) -- Exclude filename
    for i = 1, min_len do
      if a_parts[i] ~= b_parts[i] then
        -- Different directories at this level - compare alphabetically
        return a_parts[i] < b_parts[i]
      end
    end

    -- All parent directories are the same
    -- If one path is deeper (has more directory levels), it comes first
    if #a_parts ~= #b_parts then
      return #a_parts > #b_parts -- Deeper paths first
    end

    -- Same depth, compare filenames
    return a_parts[#a_parts] < b_parts[#b_parts]
  end)

  cached_files = files
  cache_timestamp = current_time
  return files
end

-- Get first and last change line numbers for a file
local function getFileChangeBounds(file_path)
  local cmd = string.format("git diff HEAD '%s' 2>/dev/null", file_path)
  local output = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 or output == "" then
    return nil
  end

  local first_line = nil
  local last_line = nil
  local current_line = nil

  -- Parse diff output line by line
  -- Format: @@ -old_start,old_count +new_start,new_count @@
  for line in output:gmatch("[^\r\n]+") do
    -- Check for hunk header
    local new_start = line:match("@@ %-[%d,]+ %+(%d+),?[%d]* @@")
    if new_start then
      current_line = tonumber(new_start)
    elseif current_line then
      -- Track line numbers based on diff markers
      if line:match("^%+") and not line:match("^%+%+%+") then
        -- Added line: this is an actual change
        if not first_line then
          first_line = current_line
        end
        last_line = current_line
        current_line = current_line + 1
      elseif line:match("^%-") and not line:match("^%-%-%-") then
        -- Deleted line: record position but don't increment current_line
        if not first_line then
          first_line = current_line
        end
        last_line = current_line
      elseif not line:match("^\\") then
        -- Context line (no +/-): increment current_line
        current_line = current_line + 1
      end
    end
  end

  return first_line and { first = first_line, last = last_line } or nil
end

-- Get change bounds for all files with caching (batch optimized)
local function getChangeBoundsForAllFiles(file_list)
  local current_time = vim.loop.now()

  -- Return cached result if still valid
  if cached_bounds and (current_time - bounds_cache_timestamp) < BOUNDS_CACHE_TTL then
    return cached_bounds
  end

  -- Use single git diff command for all files with -U0 (zero context lines)
  if #file_list == 0 then
    cached_bounds = {}
    bounds_cache_timestamp = current_time
    return {}
  end

  -- Build command with all files
  local escaped_files = {}
  for _, file in ipairs(file_list) do
    table.insert(escaped_files, "'" .. file:gsub("'", "'\\''") .. "'")
  end
  local files_arg = table.concat(escaped_files, " ")
  local cmd = string.format("git diff -U0 HEAD %s 2>/dev/null", files_arg)
  local output = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 or output == "" then
    cached_bounds = {}
    bounds_cache_timestamp = current_time
    return {}
  end

  -- Parse batch output and group by file
  local bounds_map = {}
  local current_file = nil
  local current_line = nil

  for line in output:gmatch("[^\r\n]+") do
    -- Check for file header: +++ b/path/to/file
    local file_path = line:match("^%+%+%+ b/(.+)$")
    if file_path then
      -- Convert relative path to absolute
      local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("%s+$", "")
      current_file = git_root .. "/" .. file_path
      current_line = nil
    elseif current_file then
      -- Check for hunk header
      local new_start = line:match("@@ %-[%d,]+ %+(%d+),?[%d]* @@")
      if new_start then
        current_line = tonumber(new_start)
      elseif current_line then
        -- Track actual changes
        if line:match("^%+") and not line:match("^%+%+%+") then
          if not bounds_map[current_file] then
            bounds_map[current_file] = { first = current_line, last = current_line }
          else
            bounds_map[current_file].last = current_line
          end
          current_line = current_line + 1
        elseif line:match("^%-") and not line:match("^%-%-%-") then
          if not bounds_map[current_file] then
            bounds_map[current_file] = { first = current_line, last = current_line }
          else
            bounds_map[current_file].last = current_line
          end
        elseif not line:match("^\\") then
          current_line = current_line + 1
        end
      end
    end
  end

  cached_bounds = bounds_map
  bounds_cache_timestamp = current_time
  return bounds_map
end

-- Convert Lua table to JSON string for JavaScript
local function toJSON(tbl)
  if type(tbl) ~= "table" then
    return vim.inspect(tbl)
  end

  local items = {}
  for _, v in ipairs(tbl) do
    table.insert(items, '"' .. v:gsub('"', '\\"') .. '"')
  end
  return "[" .. table.concat(items, ", ") .. "]"
end

-- Execute VSCode navigation command and sync cursor position
local function executeNavigationWithCursorSync(command, debug_prefix)
  if DEBUG == 1 then
    local cursor_before = vim.api.nvim_win_get_cursor(0)
    print(string.format("[%s] BEFORE: line=%d, col=%d", debug_prefix, cursor_before[1], cursor_before[2]))
  end

  local result = vscode.eval(string.format([[
    const DEBUG = %d;

    // Execute the navigation command
    await vscode.commands.executeCommand("%s");

    // Get the new cursor position from VSCode
    const editor = vscode.window.activeTextEditor;
    if (editor) {
      const pos = editor.selection.active;
      if (DEBUG) logger.info('[%s] VSCode position after:', pos.line, ':', pos.character);
      return { line: pos.line + 1, character: pos.character };
    }
    return null;
  ]], DEBUG, command, debug_prefix))

  if DEBUG == 1 then
    if result then
      print(string.format("[%s] Got result: line=%d, col=%d", debug_prefix, result.line or -1, result.character or -1))
    else
      print(string.format("[%s] Got null result", debug_prefix))
    end
  end

  -- Sync the cursor position to Neovim
  if result and result.line then
    vim.api.nvim_win_set_cursor(0, {result.line, result.character})
    if DEBUG == 1 then
      local cursor_after = vim.api.nvim_win_get_cursor(0)
      print(string.format("[%s] AFTER (synced): line=%d, col=%d", debug_prefix, cursor_after[1], cursor_after[2]))
    end
  end
end

-- Check if current tab is a diff editor (supports both git:// and gitlens:// schemes)
function M.isInGitDiffEditor()
  return vscode.eval([[
    const activeTab = vscode.window.tabGroups.activeTabGroup.activeTab;
    const activeTabInput = activeTab?.input;
    // Support both gitlens:// and git:// schemes since GitLens commands may use either
    return Boolean(activeTabInput?.modified && activeTabInput?.original &&
      (activeTabInput.original.scheme === 'gitlens' || activeTabInput.original.scheme === 'git'));
  ]])
end

-- Navigate to next changed file
function M.goToNextFile()
  -- Get file list from git on Lua side
  local file_changes = getChangedFilesFromGit()
  local file_changes_json = toJSON(file_changes)

  if M.isInGitDiffEditor() then
    -- In diff editor - use gitlens.diffWithPrevious to maintain diff view
    vscode.eval(string.format([[
      const DEBUG = %d;
      const fileChanges = %s;
      if (DEBUG) logger.info('[goToNextFile] In diff editor, file changes:', fileChanges.length);

      const activeTab = vscode.window.tabGroups.activeTabGroup.activeTab;
      const activeTabInput = activeTab?.input;
      const currentFilename = activeTabInput?.modified?.path;
      if (DEBUG) logger.info('[goToNextFile] Current filename:', currentFilename);

      if (!currentFilename || fileChanges.length === 0) {
        if (DEBUG) logger.info('[goToNextFile] No current file or no changes');
        return;
      }

      const currentIndex = fileChanges.findIndex((file) => file === currentFilename);
      if (DEBUG) logger.info('[goToNextFile] Current index:', currentIndex, '/', fileChanges.length);

      if (currentIndex === -1) {
        if (DEBUG) logger.info('[goToNextFile] Current file not in changes');
        return;
      }

      // Loop back to first file if at the end
      const nextIndex = (currentIndex + 1) %% fileChanges.length;
      const nextFile = fileChanges[nextIndex];
      if (DEBUG) logger.info('[goToNextFile] Next index:', nextIndex, '(wrapping:', currentIndex === fileChanges.length - 1, ')');
      if (DEBUG) logger.info('[goToNextFile] Next file:', nextFile);

      // Close current editor if not preview
      const isPreview = activeTab?.isPreview;
      if (!isPreview) {
        await vscode.commands.executeCommand("workbench.action.closeActiveEditor");
      }

      // Use gitlens.diffWithPrevious to maintain diff view
      const nextFileUri = vscode.Uri.file(nextFile);
      await vscode.commands.executeCommand("gitlens.diffWithPrevious", nextFileUri);
      if (DEBUG) logger.info('[goToNextFile] Opened next file in diff view');
    ]], DEBUG, file_changes_json))
  else
    -- In normal editor - open in normal view
    local change_bounds_map = getChangeBoundsForAllFiles(file_changes)

    -- Convert to JSON format: {"path": {"first": 10, "last": 50}, ...}
    local bounds_json_parts = {}
    for file, bounds in pairs(change_bounds_map) do
      local escaped_file = file:gsub('"', '\\"')
      table.insert(bounds_json_parts, string.format('"%s":{"first":%d,"last":%d}', escaped_file, bounds.first, bounds.last))
    end
    local change_bounds_json = "{" .. table.concat(bounds_json_parts, ",") .. "}"

    vscode.eval(string.format([[
      const DEBUG = %d;
      const fileChanges = %s;
      const changeBounds = %s;
      if (DEBUG) logger.info('[goToNextFile] In normal editor, file changes:', fileChanges.length);

      var activeEditor = vscode.window.activeTextEditor;
      const currentFilename = activeEditor?.document.uri.path;
      if (DEBUG) logger.info('[goToNextFile] Current filename:', currentFilename);

      if (!currentFilename || fileChanges.length === 0) return;

      const currentIndex = fileChanges.findIndex((file) => file === currentFilename);
      if (DEBUG) logger.info('[goToNextFile] Current index:', currentIndex, '/', fileChanges.length);

      if (currentIndex !== -1) {
        // Loop back to first file if at the end
        const nextIndex = (currentIndex + 1) %% fileChanges.length;
        const nextFile = fileChanges[nextIndex];
        if (DEBUG) logger.info('[goToNextFile] Opening next file in normal editor:', nextFile);

        const nextFileUri = vscode.Uri.file(nextFile);
        const bounds = changeBounds[nextFile];
        const firstChangeLine = bounds ? bounds.first : 1;
        if (DEBUG) logger.info('[goToNextFile] First change line:', firstChangeLine);

        // Open in normal editor (not diff view)
        const doc = await vscode.workspace.openTextDocument(nextFileUri);
        const editor = await vscode.window.showTextDocument(doc);
        const targetPos = new vscode.Position(firstChangeLine - 1, 0);
        editor.selection = new vscode.Selection(targetPos, targetPos);
        editor.revealRange(new vscode.Range(targetPos, targetPos), vscode.TextEditorRevealType.InCenter);
      }
    ]], DEBUG, file_changes_json, change_bounds_json))
  end
end

-- Navigate to previous changed file
function M.goToPreviousFile()
  -- Get file list from git on Lua side
  local file_changes = getChangedFilesFromGit()
  local file_changes_json = toJSON(file_changes)

  if M.isInGitDiffEditor() then
    -- In diff editor - use gitlens.diffWithPrevious to maintain diff view
    vscode.eval(string.format([[
      const DEBUG = %d;
      const fileChanges = %s;
      if (DEBUG) logger.info('[goToPreviousFile] In diff editor, file changes:', fileChanges.length);

      const activeTab = vscode.window.tabGroups.activeTabGroup.activeTab;
      const activeTabInput = activeTab?.input;
      const currentFilename = activeTabInput?.modified?.path;
      if (DEBUG) logger.info('[goToPreviousFile] Current filename:', currentFilename);

      if (!currentFilename || fileChanges.length === 0) {
        if (DEBUG) logger.info('[goToPreviousFile] No current file or no changes');
        return;
      }

      const currentIndex = fileChanges.findIndex((file) => file === currentFilename);
      if (DEBUG) logger.info('[goToPreviousFile] Current index:', currentIndex, '/', fileChanges.length);

      if (currentIndex === -1) {
        if (DEBUG) logger.info('[goToPreviousFile] Current file not in changes');
        return;
      }

      // Loop back to last file if at the beginning
      const previousIndex = currentIndex === 0 ? fileChanges.length - 1 : currentIndex - 1;
      const previousFile = fileChanges[previousIndex];
      if (DEBUG) logger.info('[goToPreviousFile] Previous index:', previousIndex, '(wrapping:', currentIndex === 0, ')');
      if (DEBUG) logger.info('[goToPreviousFile] Previous file:', previousFile);

      // Close current editor if not preview
      const isPreview = activeTab?.isPreview;
      if (!isPreview) {
        await vscode.commands.executeCommand("workbench.action.closeActiveEditor");
      }

      // Use gitlens.diffWithPrevious to maintain diff view
      const previousFileUri = vscode.Uri.file(previousFile);
      await vscode.commands.executeCommand("gitlens.diffWithPrevious", previousFileUri);
      // Jump to last change in the diff view
      await vscode.commands.executeCommand("workbench.action.compareEditor.previousChange");
      if (DEBUG) logger.info('[goToPreviousFile] Opened previous file in diff view');
    ]], DEBUG, file_changes_json))
  else
    -- In normal editor - open in normal view
    local change_bounds_map = getChangeBoundsForAllFiles(file_changes)

    -- Convert to JSON format
    local bounds_json_parts = {}
    for file, bounds in pairs(change_bounds_map) do
      local escaped_file = file:gsub('"', '\\"')
      table.insert(bounds_json_parts, string.format('"%s":{"first":%d,"last":%d}', escaped_file, bounds.first, bounds.last))
    end
    local change_bounds_json = "{" .. table.concat(bounds_json_parts, ",") .. "}"

    vscode.eval(string.format([[
      const DEBUG = %d;
      const fileChanges = %s;
      const changeBounds = %s;
      if (DEBUG) logger.info('[goToPreviousFile] In normal editor, file changes:', fileChanges.length);

      var activeEditor = vscode.window.activeTextEditor;
      const currentFilename = activeEditor?.document.uri.path;
      if (DEBUG) logger.info('[goToPreviousFile] Current filename:', currentFilename);

      if (!currentFilename || fileChanges.length === 0) return;

      const currentIndex = fileChanges.findIndex((file) => file === currentFilename);
      if (DEBUG) logger.info('[goToPreviousFile] Current index:', currentIndex, '/', fileChanges.length);

      if (currentIndex !== -1) {
        // Loop back to last file if at the beginning
        const previousIndex = currentIndex === 0 ? fileChanges.length - 1 : currentIndex - 1;
        const previousFile = fileChanges[previousIndex];
        if (DEBUG) logger.info('[goToPreviousFile] Opening previous file in normal editor:', previousFile);

        const previousFileUri = vscode.Uri.file(previousFile);
        const bounds = changeBounds[previousFile];
        const lastChangeLine = bounds ? bounds.last : 1;
        if (DEBUG) logger.info('[goToPreviousFile] Last change line:', lastChangeLine);

        // Open in normal editor (not diff view)
        const doc = await vscode.workspace.openTextDocument(previousFileUri);
        const editor = await vscode.window.showTextDocument(doc);
        const targetPos = new vscode.Position(lastChangeLine - 1, 0);
        editor.selection = new vscode.Selection(targetPos, targetPos);
        editor.revealRange(new vscode.Range(targetPos, targetPos), vscode.TextEditorRevealType.InCenter);
      }
    ]], DEBUG, file_changes_json, change_bounds_json))
  end
end

-- Navigate to next change (stays within current file, wrapping at boundaries)
function M.goToNextChange()
  if M.isInGitDiffEditor() then
    -- In diff editor - navigate to next change and sync cursor position
    -- Uses workbench.action.compareEditor.nextChange which works with both git and GitLens diff views
    executeNavigationWithCursorSync("workbench.action.compareEditor.nextChange", "goToNextChange")
  else
    -- In normal editor - navigate to next change and sync cursor position
    executeNavigationWithCursorSync("workbench.action.editor.nextChange", "goToNextChange")
  end
end

-- Navigate to previous change (stays within current file, wrapping at boundaries)
function M.goToPreviousChange()
  if M.isInGitDiffEditor() then
    -- In diff editor - navigate to previous change and sync cursor position
    -- Uses workbench.action.compareEditor.previousChange which works with both git and GitLens diff views
    executeNavigationWithCursorSync("workbench.action.compareEditor.previousChange", "goToPreviousChange")
  else
    -- In normal editor - navigate to previous change and sync cursor position
    executeNavigationWithCursorSync("workbench.action.editor.previousChange", "goToPreviousChange")
  end
end

-- Switch from diff view to normal editor for the current file
function M.openCurrentFileInNormalEditor()
  vscode.eval(string.format([[
    const DEBUG = %d;

    // Check if we're in a diff editor (git or GitLens)
    const activeTab = vscode.window.tabGroups.activeTabGroup.activeTab;
    const activeTabInput = activeTab?.input;

    if (DEBUG) logger.info('[openCurrentFileInNormalEditor] Active tab input:', activeTabInput);

    // Check for diff view (supports both git:// and gitlens:// schemes)
    const isDiffEditor = Boolean(activeTabInput?.modified && activeTabInput?.original &&
      (activeTabInput.original.scheme === 'gitlens' || activeTabInput.original.scheme === 'git'));

    if (!isDiffEditor) {
      if (DEBUG) logger.info('[openCurrentFileInNormalEditor] Not in diff view, nothing to do');
      return;
    }

    // Get the file path and current cursor position
    const currentFilePath = activeTabInput?.modified?.path;

    const activeEditor = vscode.window.activeTextEditor;
    const currentPosition = activeEditor?.selection.active;

    if (DEBUG) logger.info('[openCurrentFileInNormalEditor] Current file:', currentFilePath);
    if (DEBUG) logger.info('[openCurrentFileInNormalEditor] Current position:', currentPosition?.line, ':', currentPosition?.character);

    if (!currentFilePath) {
      if (DEBUG) logger.info('[openCurrentFileInNormalEditor] No current file path');
      return;
    }

    // Close the diff editor
    await vscode.commands.executeCommand("workbench.action.closeActiveEditor");

    // Open the file in normal editor
    const fileUri = vscode.Uri.file(currentFilePath);
    const doc = await vscode.workspace.openTextDocument(fileUri);
    const editor = await vscode.window.showTextDocument(doc);

    // Restore cursor position if we had one
    if (currentPosition) {
      editor.selection = new vscode.Selection(currentPosition, currentPosition);
      editor.revealRange(new vscode.Range(currentPosition, currentPosition), vscode.TextEditorRevealType.InCenter);
      if (DEBUG) logger.info('[openCurrentFileInNormalEditor] Restored cursor position');
    }

    if (DEBUG) logger.info('[openCurrentFileInNormalEditor] Opened file in normal editor');
  ]], DEBUG))
end

return M
