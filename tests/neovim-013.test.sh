#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
artifacts=${1:-$(mktemp -d /tmp/nvim-013-e2e.XXXXXX)}
mkdir -p "$artifacts/config"
ln -sfn "$repo_root" "$artifacts/config/nvim"

cat >"$artifacts/check-new-file.lua" <<'EOF'
local ok, err = pcall(function()
  assert(vim.bo.filetype == "typescript", "New-file filetype missing")
  assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "New-file highlighting missing")
  assert(vim.v.errmsg == "", vim.v.errmsg)
end)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
EOF

# Start with a missing file so no BufRead can load the highlighting plugin.
XDG_CONFIG_HOME="$artifacts/config" "${NVIM:-nvim}" --headless -i NONE \
  "$artifacts/new.ts" '+sleep 1500m' "+luafile $artifacts/check-new-file.lua" \
  >"$artifacts/new-file.log" 2>&1 || { cat "$artifacts/new-file.log"; exit 1; }

cat >"$artifacts/probe.ts" <<'EOF'
export function greet() {
console.log("hello")
}
EOF

cat >"$artifacts/check.lua" <<'EOF'
local ok, err = pcall(function()
  assert(vim.fn.has("nvim-0.13") == 1, "Expected Neovim 0.13")
  assert(vim.wait(10000, function()
    local client = vim.lsp.get_clients({ bufnr = 0, name = "ts_ls" })[1]
    return client and client.initialized
  end), "TypeScript LSP did not attach")
  assert(vim.bo.filetype == "typescript", "TypeScript filetype missing")
  assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "Highlighting missing")
  vim.cmd("normal! gg=G")
  assert(vim.api.nvim_buf_get_lines(0, 1, 2, false)[1] == '  console.log("hello")', "Incorrect indentation")
  vim.fn.writefile(vim.api.nvim_buf_get_lines(0, 0, -1, false), vim.env.ARTIFACTS .. "/formatted.ts")
  assert(vim.fn.maparg("gd", "n") ~= "", "LSP keymaps missing")
  vim.cmd("doautocmd InsertEnter")
  assert(require("blink.cmp").get_lsp_capabilities().textDocument.completion, "Completion failed")

  assert(vim.v.errmsg == "", vim.v.errmsg)
  vim.fn.writefile({ vim.json.encode({
    version = vim.version(),
    executable = vim.v.progpath,
    lsp_clients = vim.tbl_map(function(client) return client.name end, vim.lsp.get_clients({ bufnr = 0 })),
    checks = { "startup", "typescript-lsp", "highlighting", "indentation", "keymaps", "completion", "new-file" },
    result = "passed",
  }) }, vim.env.ARTIFACTS .. "/result.json")
end)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
EOF

ARTIFACTS="$artifacts" XDG_CONFIG_HOME="$artifacts/config" "${NVIM:-nvim}" --headless -i NONE \
  "$artifacts/probe.ts" '+sleep 1500m' "+luafile $artifacts/check.lua" \
  >"$artifacts/startup.log" 2>&1 || { cat "$artifacts/startup.log"; exit 1; }
cat "$artifacts/result.json"
echo "Artifacts: $artifacts"
