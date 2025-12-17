local M = {}

local NAMESPACE = vim.api.nvim_create_namespace('EASYMOTION_NS')
local CHARS = vim.split('fjdkslgha;rueiwotyqpvbcnxmzFJDKSLGHARUEIWOTYQPVBCNXMZ', '')
local ESC = "\27"

vim.api.nvim_set_hl(0, "EasyMotionBackdrop", { fg = "#545c7e" })

-- Get visible line ranges from VSCode (excludes folded regions)
-- Returns { ranges: array, startLine: number, endLine: number } or nil
local function get_vscode_visible_info()
    local vscode = require("vscode-neovim")
    local result = vscode.eval([[
        const editor = vscode.window.activeTextEditor;
        if (editor) {
            const visibleRanges = editor.visibleRanges;
            let ranges = [];
            let minLine = Infinity;
            let maxLine = -1;
            for (const range of visibleRanges) {
                const start = range.start.line + 1;
                const end = range.end.line + 1;
                ranges.push({ start: start, end: end });
                minLine = Math.min(minLine, start);
                maxLine = Math.max(maxLine, end);
            }
            return { ranges: ranges, startLine: minLine, endLine: maxLine };
        }
        return null;
    ]])
    if result and type(result) == "table" and result.ranges then
        return result
    end
    return nil
end

-- Check if a line is visible (not inside a folded region)
local function is_line_visible(line, vscode_ranges)
    if vim.g.vscode and vscode_ranges then
        for _, range in ipairs(vscode_ranges) do
            if line >= range.start and line <= range["end"] then
                return true
            end
        end
        return false
    else
        return vim.fn.foldclosed(line) == -1
    end
end

local function apply_backdrop(bufnr, ns, line_start, line_end, vscode_ranges)
    local lines = vim.api.nvim_buf_get_lines(bufnr, line_start - 1, line_end, false)
    for i, line_text in ipairs(lines) do
        local line = line_start + i - 1
        if is_line_visible(line, vscode_ranges) then
            local line_len = #line_text
            if line_len > 0 then
                vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
                    hl_group = "EasyMotionBackdrop",
                    end_row = line - 1,
                    end_col = line_len,
                    priority = 10000,
                    strict = false,
                })
            end
        end
    end
end

function M.jump()
    local line_idx_start, line_idx_end = vim.fn.line('w0'), vim.fn.line('w$')
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1)

    -- Get VSCode visible info if in VSCode environment
    local vscode_ranges = nil
    if vim.g.vscode then
        local vscode_info = get_vscode_visible_info()
        if vscode_info then
            line_idx_start = vscode_info.startLine
            line_idx_end = vscode_info.endLine
            vscode_ranges = vscode_info.ranges
        end
    end

    local char1 = vim.fn.nr2char( vim.fn.getchar() --[[@as number]] )
    if char1 == ESC then
        vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1)
        return
    end

    local char2 = vim.fn.nr2char( vim.fn.getchar() --[[@as number]] )
    if char2 == ESC then
        vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1)
        return
    end
    
    apply_backdrop(bufnr, NAMESPACE, line_idx_start, line_idx_end, vscode_ranges)
    vim.cmd("redraw")

    local char_idx = 1
    ---@type table<string, {line: integer, col: integer, id: integer}>
    local extmarks = {}
    local lines = vim.api.nvim_buf_get_lines(bufnr, line_idx_start - 1, line_idx_end, false)
    local needle = char1 .. char2

    local is_case_sensitive = needle ~= string.lower(needle)

    for lines_i, line_text in ipairs(lines) do
        if not is_case_sensitive then
            line_text = string.lower(line_text)
        end
        local line_idx = lines_i + line_idx_start - 1
        -- skip folded lines
        if is_line_visible(line_idx, vscode_ranges) then
            for i = 1, #line_text do
                if line_text:sub(i, i + 1) == needle and char_idx <= #CHARS then
                    local overlay_char = CHARS[char_idx]
                    local linenr = line_idx_start + lines_i - 2
                    local col = i - 1
                    local id = vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, linenr, col + 2, {
                        virt_text = { { overlay_char, 'CurSearch' } },
                        virt_text_pos = 'overlay',
                        hl_mode = 'replace',
                        priority = 10,
                    })
                    extmarks[overlay_char] = { line = linenr, col = col, id = id }
                    char_idx = char_idx + 1
                    if char_idx > #CHARS then
                        goto break_outer
                    end
                end
            end
        end
    end
    ::break_outer::

    vim.cmd("redraw")

    -- otherwise setting extmarks and waiting for next char is on the same frame
    vim.schedule(function()
        local next_char = vim.fn.nr2char(vim.fn.getchar() --[[@as number]])
        if next_char ~= ESC and extmarks[next_char] then
            local pos = extmarks[next_char]
            -- to make <C-o> work
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { pos.line + 1, pos.col })
        end
        -- clear extmarks
        vim.api.nvim_buf_clear_namespace(0, NAMESPACE, 0, -1)
    end)
end

return M
