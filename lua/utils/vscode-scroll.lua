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

    await vscode.commands.executeCommand('cursorMove', { to: 'viewPortCenter' });
    if (DEBUG) logger.info('[scrollHalfPageUp] cursorMove completed');

    const editor = vscode.window.activeTextEditor;
    if (editor) {
      const pos = editor.selection.active;
      if (DEBUG) logger.info('[scrollHalfPageUp] position:', pos.line + 1, ':', pos.character);
      return { line: pos.line + 1, character: pos.character };
    }
    if (DEBUG) logger.info('[scrollHalfPageUp] no active editor');
    return null;
  ]], DEBUG))

  if DEBUG == 1 then
    if result then
      print(string.format("[scrollHalfPageUp] result: line=%d, col=%d", result.line or -1, result.character or -1))
    else
      print("[scrollHalfPageUp] result is nil")
    end
  end

  if result then
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

    await vscode.commands.executeCommand('cursorMove', { to: 'viewPortCenter' });
    if (DEBUG) logger.info('[scrollHalfPageDown] cursorMove completed');

    const editor = vscode.window.activeTextEditor;
    if (editor) {
      const pos = editor.selection.active;
      if (DEBUG) logger.info('[scrollHalfPageDown] position:', pos.line + 1, ':', pos.character);
      return { line: pos.line + 1, character: pos.character };
    }
    if (DEBUG) logger.info('[scrollHalfPageDown] no active editor');
    return null;
  ]], DEBUG))

  if DEBUG == 1 then
    if result then
      print(string.format("[scrollHalfPageDown] result: line=%d, col=%d", result.line or -1, result.character or -1))
    else
      print("[scrollHalfPageDown] result is nil")
    end
  end

  if result then
    vim.api.nvim_win_set_cursor(0, { result.line, result.character })
  end
end

return M
