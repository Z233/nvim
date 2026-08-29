#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cat >"$tmp/check.lua" <<'EOF'
local repo = vim.env.REPO
vim.opt.runtimepath:prepend(repo)
vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/lazy/lazy.nvim")

require("lazy").setup({ { import = "plugins" } }, {
  root = vim.fn.stdpath("data") .. "/lazy",
  lockfile = repo .. "/lazy-lock.json",
  install = { missing = false },
  checker = { enabled = false },
  change_detection = { enabled = false },
})

require("lazy").load({ plugins = { "codediff.nvim" } })
if not vim.treesitter.query.get("typescript", "highlights") then
  error("TypeScript highlights unavailable after CodeDiff load")
end
EOF

if ! REPO="$repo_root" nvim --clean --headless -u NONE \
  "+luafile $tmp/check.lua" \
  "+lua if vim.v.errmsg ~= '' then vim.cmd('cquit 1') end" \
  +qa; then
  exit 1
fi
