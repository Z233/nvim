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

      local installed = require("nvim-treesitter.config").get_installed()
      local installed_set = {}
      for _, p in ipairs(installed) do
        installed_set[p] = true
      end

      local to_install = vim.tbl_filter(function(p)
        return not installed_set[p]
      end, parsers)

      if #to_install > 0 then
        require("nvim-treesitter.install").install(to_install)
      end

      vim.treesitter.language.register("markdown", "mdx")
    end,
  },
}
