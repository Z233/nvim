#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/config"
ln -s "$repo_root" "$tmp/config/nvim"

XDG_CONFIG_HOME="$tmp/config" nvim --headless -i NONE "$repo_root" \
  '+sleep 1500m' \
  '+lua local found = false; for _, w in ipairs(vim.api.nvim_list_wins()) do found = found or vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "neo-tree" end; if not found or vim.v.errmsg ~= "" then io.stderr:write("Directory startup failed: " .. vim.v.errmsg); vim.cmd("cquit 1") end' \
  '+messages' \
  '+qa!' >"$tmp/nvim.out" 2>&1

if grep -qF 'stack overflow' "$tmp/nvim.out"; then
  exit 1
fi
