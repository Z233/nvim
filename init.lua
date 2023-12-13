-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

local function paste_as_plain_text(paste_mode)
    local clipboard_content = vim.fn.getreg('+')
    local processed_content = clipboard_content:gsub("%s+", " ")
    vim.fn.setreg('"', processed_content)
    
    if paste_mode == 'P' then
        vim.api.nvim_put({processed_content}, 'l', false, true)
    else
        vim.api.nvim_put({processed_content}, 'c', true, true)
    end
end

vim.api.nvim_create_user_command('PastePlainText', function(opts)
    paste_as_plain_text(opts.args)
end, { nargs = '?' })