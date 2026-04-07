return {
  {
    "saghen/blink.cmp",
    version = "*",
    event = "InsertEnter",
    cond = not vim.g.vscode,
    opts = {
      keymap = {
        preset = "default",
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },
}
