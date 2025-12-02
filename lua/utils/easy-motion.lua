local M = {}

local NAMESPACE = vim.api.nvim_create_namespace('EASYMOTION_NS')
local CHARS = vim.split('fjdkslgha;rueiwotyqpvbcnxmzFJDKSLGHARUEIWOTYQPVBCNXMZ', '')
local ESC = "\27"

vim.api.nvim_set_hl(0, "EasyMotionBackdrop", { fg = "#545c7e" })

local function apply_backdrop(bufnr, ns, line_start, line_end)
    local lines = vim.api.nvim_buf_get_lines(bufnr, line_start - 1, line_end, false)
    for i, line_text in ipairs(lines) do
        local line = line_start + i - 1
        if vim.fn.foldclosed(line) == -1 then
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
    
    apply_backdrop(bufnr, NAMESPACE, line_idx_start, line_idx_end)
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
        if vim.fn.foldclosed(line_idx) == -1 then
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
