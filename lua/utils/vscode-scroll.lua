-- VSCode Half-page Scroll with Cursor Centered
-- Scrolls half page and centers cursor, syncing position back to Neovim

local M = {}

local vscode = require("vscode-neovim")

local function scrollHalfPage(direction)
  local result = vscode.eval(string.format([[
    await vscode.commands.executeCommand('editorScroll', { to: '%s', by: 'halfPage' });

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

        const newPos = new vscode.Position(targetLine, currentChar);
        editor.selection = new vscode.Selection(newPos, newPos);

        return { line: targetLine + 1, character: currentChar };
      }
    }
    return null;
  ]], direction))

  if result and type(result) == "table" and result.line then
    vim.api.nvim_win_set_cursor(0, { result.line, result.character })
  end
end

function M.scrollHalfPageUp()
  scrollHalfPage("up")
end

function M.scrollHalfPageDown()
  scrollHalfPage("down")
end

return M
