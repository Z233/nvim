return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    cond = not vim.g.vscode,
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    cond = not vim.g.vscode,
    dependencies = { "mason.nvim" },
    opts = {
      ensure_installed = {
        "ts_ls",
        "vue_ls",
        "lua_ls",
        "jsonls",
        "yamlls",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = "BufRead",
    cond = not vim.g.vscode,
    dependencies = {
      "mason.nvim",
      "mason-lspconfig.nvim",
    },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_keymaps", { clear = true }),
        callback = function(ev)
          local bufnr = ev.buf
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          map("n", "gd", vim.lsp.buf.definition, "Goto Definition")
          map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
          map("n", "gI", vim.lsp.buf.implementation, "Goto Implementation")
          map("n", "gy", vim.lsp.buf.type_definition, "Goto Type Definition")
          map("n", "gr", function()
            local fzf_ok, fzf = pcall(require, "fzf-lua")
            if fzf_ok then
              fzf.lsp_references()
            else
              vim.lsp.buf.references()
            end
          end, "References")
          map("n", "K", vim.lsp.buf.hover, "Hover")
          map("n", "<Esc>", function()
            local noice_docs = package.loaded["noice.lsp.docs"]
            if noice_docs then
              noice_docs.hide(noice_docs.get("hover"))
            end

            local float_win = vim.b[bufnr].lsp_floating_preview
            if
              float_win
              and vim.api.nvim_win_is_valid(float_win)
              and vim.api.nvim_win_get_config(float_win).relative ~= ""
            then
              vim.api.nvim_win_close(float_win, false)
            end
            vim.cmd("noh")
          end, "Close LSP hover")
          map("n", "gK", vim.lsp.buf.signature_help, "Signature Help")
          map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")

          map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
          map("n", "<leader>cf", function()
            vim.lsp.buf.format({ async = true })
          end, "Format")

          map("n", "]d", function()
            vim.diagnostic.jump({ count = 1, float = true })
          end, "Next Diagnostic")
          map("n", "[d", function()
            vim.diagnostic.jump({ count = -1, float = true })
          end, "Prev Diagnostic")
          map("n", "]e", function()
            vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
          end, "Next Error")
          map("n", "[e", function()
            vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
          end, "Prev Error")
        end,
      })

      local vue_language_server_path = vim.fn.stdpath("data")
        .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

      local servers = {
        ts_ls = {
          init_options = {
            plugins = {
              {
                name = "@vue/typescript-plugin",
                location = vue_language_server_path,
                languages = { "vue" },
              },
            },
          },
          filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
            "vue",
          },
        },
        vue_ls = {},
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        },
        jsonls = {},
        yamlls = {},
      }

      for server, config in pairs(servers) do
        config.capabilities = capabilities
        vim.lsp.config(server, config)
      end

      vim.lsp.enable(vim.tbl_keys(servers))
    end,
  },
}
