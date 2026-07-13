return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "BufRead",
    cond = not vim.g.vscode,
    config = function()
      local parsers = {
        "bash",
        "css",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "tsx",
        "typescript",
        "vue",
        "yaml",
      }

      -- Only install missing parsers
      local info = require("nvim-treesitter.info")
      local installed = info.installed_parsers()
      local installed_set = {}
      for _, p in ipairs(installed) do
        installed_set[p] = true
      end
      for _, p in ipairs(parsers) do
        if not installed_set[p] then
          vim.cmd.TSInstall({ args = { p }, bang = true })
        end
      end

      vim.treesitter.language.register("markdown", "mdx")

      local filetype_to_parser = {
        sh = "bash",
        css = "css",
        html = "html",
        javascript = "javascript",
        javascriptreact = "javascript",
        json = "json",
        jsonc = "json",
        lua = "lua",
        markdown = "markdown",
        mdx = "markdown",
        tsx = "tsx",
        typescriptreact = "tsx",
        typescript = "typescript",
        vue = "vue",
        yaml = "yaml",
      }

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true }),
        callback = function(ev)
          local parser = filetype_to_parser[ev.match]
          if not parser then
            return
          end
          local ok = pcall(vim.treesitter.start, ev.buf, parser)
          if ok then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
