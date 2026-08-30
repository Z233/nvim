#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/config"
ln -s "$repo_root" "$tmp/config/nvim"

XDG_CONFIG_HOME="$tmp/config" nvim --headless -i NONE "$repo_root" \
  '+sleep 1500m' \
  '+messages' \
  '+qa!' >"$tmp/nvim.out" 2>&1

if grep -qF 'stack overflow' "$tmp/nvim.out"; then
  exit 1
fi
