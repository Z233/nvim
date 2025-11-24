
-- Manages navigation history for line-level diff views

local M = {}

local vscode = require("vscode-neovim")

local DEBUG = 0

-- Constants
local MAX_HISTORY_SIZE = 50

-- History state
local history = {
  stack = {},            -- Array of revision info: { sha, file, line }
  current_index = 0,     -- Current position in stack (0 = working version)
  file_path = nil,       -- Last tracked file path
  line_number = nil,     -- Last tracked line number
}

-- Get current context including revision SHA if in diff view
local function getCurrentContext()
  local result = vscode.eval(string.format([[
    const DEBUG = %d;
    const editor = vscode.window.activeTextEditor;
    if (!editor) return null;

    const filePath = editor.document.uri.path;
    const lineNumber = editor.selection.active.line + 1; // Convert to 1-based

    // Check if we're in a GitLens diff view
    const activeTab = vscode.window.tabGroups.activeTabGroup.activeTab;
    const activeTabInput = activeTab?.input;
    const isGitLensDiff = Boolean(activeTabInput?.original?.scheme === 'gitlens');

    let revisionSha = null;
    if (isGitLensDiff) {
      // Use the same extraction logic as in goToPreviousRevision
      const uris = [
        activeTabInput?.original?.toString(),
        activeTabInput?.modified?.toString()
      ].filter(Boolean);

      for (const uri of uris) {
        // Try to decode query parameter: ?%%7B%%22ref%%22%%3A%%22407446b%%22%%7D -> {"ref":"407446b"}
        try {
          const queryMatch = uri.match(/\?(.+)$/);
          if (queryMatch) {
            const decoded = decodeURIComponent(queryMatch[1]);
            const jsonMatch = decoded.match(/"ref"\s*:\s*"([a-f0-9]{7,40})"/);
            if (jsonMatch) {
              revisionSha = jsonMatch[1];
              break;
            }
          }
        } catch (e) {
          // Ignore errors
        }

        // Fallback: try path-based extraction
        if (!revisionSha) {
          let match = uri.match(/\/([a-f0-9]{7,40})\//);
          if (!match) {
            match = uri.match(/([a-f0-9]{40})/);
          }
          if (match) {
            revisionSha = match[1];
            break;
          }
        }
      }
    }

    return {
      file: filePath,
      line: lineNumber,
      sha: revisionSha
    };
  ]], DEBUG))

  return result
end

-- Check if context has changed significantly
local function hasContextChanged(current_context)
  if not current_context then
    return true
  end

  -- File changed
  if history.file_path ~= current_context.file then
    return true
  end

  -- Line changed significantly (more than ±5 lines)
  if history.line_number and current_context.line then
    local line_diff = math.abs(current_context.line - history.line_number)
    if line_diff > 5 then
      return true
    end
  end

  return false
end

-- Clear history stack
local function clearHistory()
  history.stack = {}
  history.current_index = 0
end

-- Push current state to history stack
local function pushToStack(context)
  -- If we're not at the end of the stack, truncate forward history
  if history.current_index > 0 and history.current_index < #history.stack then
    for i = #history.stack, history.current_index + 1, -1 do
      table.remove(history.stack, i)
    end
  end

  -- Add new state to stack
  table.insert(history.stack, {
    file = context.file,
    line = context.line,
    sha = context.sha,
    timestamp = vim.loop.now()
  })

  -- Enforce stack size limit (FIFO eviction)
  if #history.stack > MAX_HISTORY_SIZE then
    table.remove(history.stack, 1)
  end

  history.current_index = #history.stack
end

-- Update tracked context
local function updateTrackedContext(context)
  history.file_path = context.file
  history.line_number = context.line
end

-- Go to previous revision ([R)
function M.goToPreviousRevision()
  -- Get current context BEFORE navigation
  local current_context = getCurrentContext()
  if not current_context then
    return
  end

  -- Check if context changed
  local context_changed = hasContextChanged(current_context)
  if context_changed then
    clearHistory()
  end

  -- Build the JS code without string.format to avoid escaping issues
  local js_code = [[
    const DEBUG = ]] .. DEBUG .. [[;

    await vscode.commands.executeCommand("gitlens.diffLineWithPrevious");

    // Wait a bit for the diff view to fully load
    await new Promise(resolve => setTimeout(resolve, 100));

    // NOW get the SHA from the newly opened diff view
    const activeTab = vscode.window.tabGroups.activeTabGroup.activeTab;
    const activeTabInput = activeTab?.input;

    // Check both original and modified URIs
    const originalScheme = activeTabInput?.original?.scheme;
    const modifiedScheme = activeTabInput?.modified?.scheme;
    const isGitLensDiff = originalScheme === 'gitlens' || modifiedScheme === 'gitlens';

    let revisionSha = null;
    if (isGitLensDiff) {
      // First, try to get SHA from query parameter (most reliable)
      const uris = [
        activeTabInput?.original?.toString(),
        activeTabInput?.modified?.toString()
      ].filter(Boolean);

      for (const uri of uris) {
        // Try to decode query parameter: ?%7B%22ref%22%3A%22407446b%22%7D -> {"ref":"407446b"}
        try {
          const queryMatch = uri.match(/\?(.+)$/);
          if (queryMatch) {
            const decoded = decodeURIComponent(queryMatch[1]);
            const jsonMatch = decoded.match(/"ref"\s*:\s*"([a-f0-9]{7,40})"/);
            if (jsonMatch) {
              revisionSha = jsonMatch[1];
              break;
            }
          }
        } catch (e) {
          // Ignore errors
        }

        // Fallback: try path-based extraction
        if (!revisionSha) {
          let match = uri.match(/\/([a-f0-9]{7,40})\//);
          if (!match) {
            match = uri.match(/([a-f0-9]{40})/);
          }
          if (match) {
            revisionSha = match[1];
            break;
          }
        }
      }
    }

    return revisionSha;
  ]]

  -- Execute GitLens command and get the SHA of the opened revision
  local success, result = pcall(function()
    return vscode.eval(js_code)
  end)

  if not success then
    return
  end

  -- Check if we extracted a SHA
  if not result or result == vim.NIL then
    return
  end

  -- Check if SHA is same as the last one in stack (duplicate detection)
  if #history.stack > 0 and history.stack[#history.stack].sha == result then
    return
  end

  -- Push state with the SHA we just got
  local state_to_push = {
    file = current_context.file,
    line = current_context.line,
    sha = result  -- The SHA from the diff view we just opened
  }

  pushToStack(state_to_push)

  -- Update tracked context
  updateTrackedContext(state_to_push)
end

-- Go to next revision (]R)
function M.goToNextRevision()
  -- Check if at end of history (working version)
  if history.current_index == 0 or #history.stack == 0 then
    return
  end

  -- Decrement current_index
  history.current_index = history.current_index - 1

  -- If at working version, close diff view
  if history.current_index == 0 then
    local success, err = pcall(function()
      vscode.eval([[
        // Check if we're in a diff editor
        const activeTab = vscode.window.tabGroups.activeTabGroup.activeTab;
        const activeTabInput = activeTab?.input;
        const isDiffEditor = Boolean(activeTabInput?.modified && activeTabInput?.original);

        if (isDiffEditor) {
          // Get the file path before closing
          const filePath = activeTabInput?.modified?.path;

          // Close the diff editor
          await vscode.commands.executeCommand("workbench.action.closeActiveEditor");

          // Open the file in normal editor
          if (filePath) {
            const fileUri = vscode.Uri.file(filePath);
            const doc = await vscode.workspace.openTextDocument(fileUri);
            await vscode.window.showTextDocument(doc);
          }
        }
      ]])
    end)

    -- Clear the stack when returning to working version
    clearHistory()

    return
  end

  -- Navigate to state at stack[current_index]
  local target_state = history.stack[history.current_index]
  if not target_state then
    -- Fall back to working version
    history.current_index = 0
    clearHistory()
    return
  end

  -- Update tracked context to target state
  updateTrackedContext(target_state)

  -- Navigate to the specific revision in the stack
  local success, err = pcall(function()
    -- Escape the file path for JavaScript
    local escaped_file = target_state.file:gsub("\\", "\\\\"):gsub("'", "\\'")
    local sha_value = target_state.sha or "nil"

    vscode.eval([[
      const targetSha = ']] .. sha_value .. [[';
      const targetFile = ']] .. escaped_file .. [[';
      const targetLine = ]] .. target_state.line .. [[;

      if (!targetSha || targetSha === 'nil') {
        // No SHA stored - this is the working version state
        // Close the diff and open the file normally
        const activeTab = vscode.window.tabGroups.activeTabGroup.activeTab;
        const isDiffEditor = Boolean(activeTab?.input?.modified && activeTab?.input?.original);

        if (isDiffEditor) {
          await vscode.commands.executeCommand("workbench.action.closeActiveEditor");
          const fileUri = vscode.Uri.file(targetFile);
          const doc = await vscode.workspace.openTextDocument(fileUri);
          const editor = await vscode.window.showTextDocument(doc);
          const pos = new vscode.Position(targetLine - 1, 0);
          editor.selection = new vscode.Selection(pos, pos);
          editor.revealRange(new vscode.Range(pos, pos), vscode.TextEditorRevealType.InCenter);
        }
      } else {
        // Open the specific revision
        // Use GitLens command to open line diff for specific SHA
        const fileUri = vscode.Uri.file(targetFile);
        const line = targetLine - 1; // Convert to 0-based

        // Close current diff first
        await vscode.commands.executeCommand("workbench.action.closeActiveEditor");

        // Open the file at the target line
        const doc = await vscode.workspace.openTextDocument(fileUri);
        const editor = await vscode.window.showTextDocument(doc);
        const pos = new vscode.Position(line, 0);
        editor.selection = new vscode.Selection(pos, pos);

        // Execute GitLens diff command with the specific SHA
        // This opens a diff comparing the target SHA with its previous version
        await vscode.commands.executeCommand('gitlens.diffLineWithPrevious', fileUri, {
          line: line,
          sha: targetSha
        });
      }
    ]])
  end)
end

return M
