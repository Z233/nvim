-- VSCode Git Diff Navigation Utilities
-- Hybrid approach: Lua for git operations, JS for VSCode commands

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

  -- Sort files
  table.sort(files)

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

-- Check if current tab is a git diff editor
function M.isInGitDiffEditor()
  return vscode.eval([[
    const activeTab = vscode.window.tabGroups.activeTabGroup.activeTab;
    const activeTabInput = activeTab?.input;
    return Boolean(activeTabInput?.modified && activeTabInput?.original && activeTabInput.original.scheme === 'git');
  ]])
end

-- Navigate to next change (intelligently handles file boundaries)
function M.goToNextChange()
  -- Get file list from git on Lua side
  local file_changes = getChangedFilesFromGit()
  local file_changes_json = toJSON(file_changes)

  if M.isInGitDiffEditor() then
    -- In diff editor
    vscode.eval(string.format([[
      const DEBUG = %d;
      const fileChanges = %s;
      if (DEBUG) logger.info('[goToNextChange] Starting in diff editor');
      if (DEBUG) logger.info('[goToNextChange] File changes from git:', fileChanges.length);

      var activeEditor = vscode.window.activeTextEditor;
      const lineBefore = activeEditor?.selection.active.line;
      if (DEBUG) logger.info('[goToNextChange] Line before:', lineBefore);

      await vscode.commands.executeCommand("workbench.action.compareEditor.nextChange");

      const lineAfter = activeEditor?.selection.active.line;
      if (DEBUG) logger.info('[goToNextChange] Line after:', lineAfter);

      const shouldOpenNextFile = !lineBefore || !lineAfter || !(lineAfter > lineBefore);
      if (DEBUG) logger.info('[goToNextChange] Should open next file:', shouldOpenNextFile);

      if (shouldOpenNextFile) {
        if (DEBUG) logger.info('[goToNextChange] Opening next file...');

        const activeTab = vscode.window.tabGroups.activeTabGroup.activeTab;
        const activeTabInput = activeTab?.input;
        const currentFilename = activeTabInput?.modified?.path;
        if (DEBUG) logger.info('[goToNextChange] Current filename:', currentFilename);

        if (!currentFilename || fileChanges.length === 0) {
          if (DEBUG) logger.info('[goToNextChange] No current file or no changes, closing');
          await vscode.commands.executeCommand("workbench.action.closeActiveEditor");
          return;
        }

        const currentIndex = fileChanges.findIndex((file) => file === currentFilename);
        if (DEBUG) logger.info('[goToNextChange] Current index:', currentIndex, '/', fileChanges.length);

        if (currentIndex === -1) {
          if (DEBUG) logger.info('[goToNextChange] Current file not in changes, closing editor');
          await vscode.commands.executeCommand("workbench.action.closeActiveEditor");
          return;
        }

        // Loop back to first file if at the end
        const nextIndex = (currentIndex + 1) %% fileChanges.length;
        const nextFile = fileChanges[nextIndex];
        if (DEBUG) logger.info('[goToNextChange] Next index:', nextIndex, '(wrapping:', currentIndex === fileChanges.length - 1, ')');
        if (DEBUG) logger.info('[goToNextChange] Next file:', nextFile);

        const isPreview = activeTab?.isPreview;
        if (!isPreview) {
          await vscode.commands.executeCommand("workbench.action.closeActiveEditor");
        }

        const nextFileUri = vscode.Uri.file(nextFile);
        await vscode.commands.executeCommand("git.openChange", nextFileUri);
        if (DEBUG) logger.info('[goToNextChange] Opened next file');
      } else {
        if (DEBUG) logger.info('[goToNextChange] Stayed in current file');
      }
    ]], DEBUG, file_changes_json))
  else
    -- In normal editor
    -- Get change bounds with caching
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
      if (DEBUG) logger.info('[goToNextChange] Starting in normal editor');
      if (DEBUG) logger.info('[goToNextChange] File changes from git:', fileChanges.length);

      var activeEditor = vscode.window.activeTextEditor;
      const lineBefore = activeEditor?.selection.active.line;

      await vscode.commands.executeCommand("workbench.action.editor.nextChange");

      const lineAfter = activeEditor?.selection.active.line;
      const shouldOpenNextFile = !lineBefore || !lineAfter || !(lineAfter > lineBefore);

      if (shouldOpenNextFile && fileChanges.length > 0) {
        if (DEBUG) logger.info('[goToNextChange] No more changes in current file, switching to next file');

        const currentFilename = activeEditor?.document.uri.path;
        if (DEBUG) logger.info('[goToNextChange] Current filename:', currentFilename);

        if (!currentFilename) return;

        const currentIndex = fileChanges.findIndex((file) => file === currentFilename);
        if (DEBUG) logger.info('[goToNextChange] Current index:', currentIndex, '/', fileChanges.length);

        if (currentIndex !== -1) {
          // Loop back to first file if at the end
          const nextIndex = (currentIndex + 1) %% fileChanges.length;
          const nextFile = fileChanges[nextIndex];
          if (DEBUG) logger.info('[goToNextChange] Opening next file in normal editor:', nextFile);

          const nextFileUri = vscode.Uri.file(nextFile);
          const bounds = changeBounds[nextFile];
          const firstChangeLine = bounds ? bounds.first : 1;
          if (DEBUG) logger.info('[goToNextChange] First change line:', firstChangeLine);

          // Open document and jump directly to the line
          const doc = await vscode.workspace.openTextDocument(nextFileUri);
          const editor = await vscode.window.showTextDocument(doc);
          const targetPos = new vscode.Position(firstChangeLine - 1, 0); // Convert to 0-based
          editor.selection = new vscode.Selection(targetPos, targetPos);
          editor.revealRange(new vscode.Range(targetPos, targetPos), vscode.TextEditorRevealType.InCenter);
        }
      }
    ]], DEBUG, file_changes_json, change_bounds_json))
  end
end

-- Navigate to previous change (intelligently handles file boundaries)
function M.goToPreviousChange()
  -- Get file list from git on Lua side
  local file_changes = getChangedFilesFromGit()
  local file_changes_json = toJSON(file_changes)

  if M.isInGitDiffEditor() then
    -- In diff editor
    vscode.eval(string.format([[
      const DEBUG = %d;
      const fileChanges = %s;
      if (DEBUG) logger.info('[goToPreviousChange] Starting in diff editor');
      if (DEBUG) logger.info('[goToPreviousChange] File changes from git:', fileChanges.length);

      var activeEditor = vscode.window.activeTextEditor;
      const lineBefore = activeEditor?.selection.active.line;

      await vscode.commands.executeCommand("workbench.action.compareEditor.previousChange");

      const lineAfter = activeEditor?.selection.active.line;

      const shouldOpenPreviousFile = !lineBefore || !lineAfter || !(lineAfter < lineBefore);

      if (shouldOpenPreviousFile) {
        if (DEBUG) logger.info('[goToPreviousChange] Opening previous file...');

        const activeTab = vscode.window.tabGroups.activeTabGroup.activeTab;
        const activeTabInput = activeTab?.input;
        const currentFilename = activeTabInput?.modified?.path;

        if (!currentFilename || fileChanges.length === 0) {
          await vscode.commands.executeCommand("workbench.action.closeActiveEditor");
          return;
        }

        const currentIndex = fileChanges.findIndex((file) => file === currentFilename);

        if (currentIndex === -1) {
          await vscode.commands.executeCommand("workbench.action.closeActiveEditor");
          return;
        }

        // Loop back to last file if at the beginning
        const previousIndex = currentIndex === 0 ? fileChanges.length - 1 : currentIndex - 1;
        const previousFile = fileChanges[previousIndex];
        const isPreview = activeTab?.isPreview;

        if (!isPreview) {
          await vscode.commands.executeCommand("workbench.action.closeActiveEditor");
        }

        const previousFileUri = vscode.Uri.file(previousFile);
        await vscode.commands.executeCommand("git.openChange", previousFileUri);
        await vscode.commands.executeCommand("workbench.action.compareEditor.previousChange");
      }
    ]], DEBUG, file_changes_json))
  else
    -- In normal editor
    -- Get change bounds with caching
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
      if (DEBUG) logger.info('[goToPreviousChange] Starting in normal editor');
      if (DEBUG) logger.info('[goToPreviousChange] File changes from git:', fileChanges.length);

      var activeEditor = vscode.window.activeTextEditor;
      const lineBefore = activeEditor?.selection.active.line;

      await vscode.commands.executeCommand("workbench.action.editor.previousChange");

      const lineAfter = activeEditor?.selection.active.line;
      const shouldOpenPreviousFile = !lineBefore || !lineAfter || !(lineAfter < lineBefore);

      if (shouldOpenPreviousFile && fileChanges.length > 0) {
        if (DEBUG) logger.info('[goToPreviousChange] No more changes in current file, switching to previous file');

        const currentFilename = activeEditor?.document.uri.path;
        if (DEBUG) logger.info('[goToPreviousChange] Current filename:', currentFilename);

        if (!currentFilename) return;

        const currentIndex = fileChanges.findIndex((file) => file === currentFilename);
        if (DEBUG) logger.info('[goToPreviousChange] Current index:', currentIndex, '/', fileChanges.length);

        if (currentIndex !== -1) {
          // Loop back to last file if at the beginning
          const previousIndex = currentIndex === 0 ? fileChanges.length - 1 : currentIndex - 1;
          const previousFile = fileChanges[previousIndex];
          if (DEBUG) logger.info('[goToPreviousChange] Opening previous file in normal editor:', previousFile);

          const previousFileUri = vscode.Uri.file(previousFile);
          const bounds = changeBounds[previousFile];
          const lastChangeLine = bounds ? bounds.last : 1;
          if (DEBUG) logger.info('[goToPreviousChange] Last change line:', lastChangeLine);

          // Open document and jump directly to the line
          const doc = await vscode.workspace.openTextDocument(previousFileUri);
          const editor = await vscode.window.showTextDocument(doc);
          const targetPos = new vscode.Position(lastChangeLine - 1, 0); // Convert to 0-based
          editor.selection = new vscode.Selection(targetPos, targetPos);
          editor.revealRange(new vscode.Range(targetPos, targetPos), vscode.TextEditorRevealType.InCenter);
        }
      }
    ]], DEBUG, file_changes_json, change_bounds_json))
  end
end

return M
