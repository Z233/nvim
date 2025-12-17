-- VSCode Half-page Scroll with Cursor Centered
-- Scrolls half page and centers cursor, syncing position back to Neovim

local M = {}

local vscode = require("vscode-neovim")

local DEBUG = 0

function M.scrollHalfPageUp()
  if DEBUG == 1 then
    print("[scrollHalfPageUp] called")
  end

  local result = vscode.eval(string.format([[
    const DEBUG = %d;

    if (DEBUG) logger.info('[scrollHalfPageUp] executing');

    await vscode.commands.executeCommand('editorScroll', { to: 'up', by: 'halfPage' });
    if (DEBUG) logger.info('[scrollHalfPageUp] editorScroll completed');

    const editor = vscode.window.activeTextEditor;
    if (editor) {
      // Use visibleRanges to find truly visible lines (excludes folded regions)
      const visibleRanges = editor.visibleRanges;
      let visibleLines = [];
      for (const range of visibleRanges) {
        for (let i = range.start.line; i <= range.end.line; i++) {
          visibleLines.push(i);
        }
      }

      if (visibleLines.length > 0) {
        // Move cursor to the center of visible lines
        const centerIndex = Math.floor(visibleLines.length / 2);
        const targetLine = visibleLines[centerIndex];
        const currentChar = editor.selection.active.character;

        if (DEBUG) logger.info('[scrollHalfPageUp] visibleLines:', visibleLines.length, 'targetLine:', targetLine + 1);

        // Set cursor position directly without using cursorMove command
        const newPos = new vscode.Position(targetLine, currentChar);
        editor.selection = new vscode.Selection(newPos, newPos);

        if (DEBUG) logger.info('[scrollHalfPageUp] position:', targetLine + 1, ':', currentChar);
        return { line: targetLine + 1, character: currentChar };
      }
    }
    if (DEBUG) logger.info('[scrollHalfPageUp] no active editor or no visible lines');
    return null;
  ]], DEBUG))

  if DEBUG == 1 then
    if result then
      print(string.format("[scrollHalfPageUp] result: line=%d, col=%d", result.line or -1, result.character or -1))
    else
      print("[scrollHalfPageUp] result is nil")
    end
  end

  if result and type(result) == "table" and result.line then
    vim.api.nvim_win_set_cursor(0, { result.line, result.character })
  end
end

function M.scrollHalfPageDown()
  if DEBUG == 1 then
    print("[scrollHalfPageDown] called")
  end

  local result = vscode.eval(string.format([[
    const DEBUG = %d;

    if (DEBUG) logger.info('[scrollHalfPageDown] executing');

    await vscode.commands.executeCommand('editorScroll', { to: 'down', by: 'halfPage' });
    if (DEBUG) logger.info('[scrollHalfPageDown] editorScroll completed');

    const editor = vscode.window.activeTextEditor;
    if (editor) {
      // Use visibleRanges to find truly visible lines (excludes folded regions)
      const visibleRanges = editor.visibleRanges;
      let visibleLines = [];
      for (const range of visibleRanges) {
        for (let i = range.start.line; i <= range.end.line; i++) {
          visibleLines.push(i);
        }
      }

      if (visibleLines.length > 0) {
        // Move cursor to the center of visible lines
        const centerIndex = Math.floor(visibleLines.length / 2);
        const targetLine = visibleLines[centerIndex];
        const currentChar = editor.selection.active.character;

        if (DEBUG) logger.info('[scrollHalfPageDown] visibleLines:', visibleLines.length, 'targetLine:', targetLine + 1);

        // Set cursor position directly without using cursorMove command
        const newPos = new vscode.Position(targetLine, currentChar);
        editor.selection = new vscode.Selection(newPos, newPos);

        if (DEBUG) logger.info('[scrollHalfPageDown] position:', targetLine + 1, ':', currentChar);
        return { line: targetLine + 1, character: currentChar };
      }
    }
    if (DEBUG) logger.info('[scrollHalfPageDown] no active editor or no visible lines');
    return null;
  ]], DEBUG))

  if DEBUG == 1 then
    if result then
      print(string.format("[scrollHalfPageDown] result: line=%d, col=%d", result.line or -1, result.character or -1))
    else
      print("[scrollHalfPageDown] result is nil")
    end
  end

  if result and type(result) == "table" and result.line then
    vim.api.nvim_win_set_cursor(0, { result.line, result.character })
  end
end

return M
