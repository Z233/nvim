#!/bin/bash
set -euo pipefail

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/.ssh"
printf 'Host example\n  HostName example.com\n' > "$tmp/.ssh/config"

output=$(nvim --headless --cmd 'set noswapfile' "+edit $tmp/.ssh/config" \
  '+enew' "+file $tmp/unknown" '+setfiletype rexmod_test_missing' \
  '+lua if vim.v.errmsg ~= "" then vim.cmd("cquit 1") end' '+qall!' 2>&1) || {
  printf '%s\n' "$output"
  exit 1
}
if [[ "$output" == *'Error'* ]]; then
  printf '%s\n' "$output"
  exit 1
fi
