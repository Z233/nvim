return {
  {
    "Goose97/timber.nvim",
    version = "*",
    event = "VeryLazy",
    config = function()
      local ts_fn_utils = require("utils.treesitter-function-name")
      local js_default_log_template = [[console.debug('[%function_name] %log_target', %log_target);]]

      require("timber").setup({
        template_placeholders = {
          function_name = ts_fn_utils.find_function_name,
        },
        log_templates = {
          default = {
            javascript = js_default_log_template,
            typescript = js_default_log_template,
            astro = js_default_log_template,
            vue = js_default_log_template,
            jsx = js_default_log_template,
            tsx = js_default_log_template,
          },
        },
      })
    end,
  },
  {
    "kkew3/jieba.vim",
    branch = "rust",
    build = "JIEBA_VIM_INSTALL_NVIM=1 ./build.sh",
    event = "BufRead",
    init = function()
      vim.g.jieba_vim_lazy = 1
      vim.g.jieba_vim_keymap = 1
    end,
  },
}
