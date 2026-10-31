#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin"
cat > "$tmp/bin/pbpaste" <<'EOF'
#!/bin/sh
printf 'paste-probe'
EOF
chmod +x "$tmp/bin/pbpaste"

# OSC 52 is sent to attached UIs, not headless stdout.
PATH="$tmp/bin:$PATH" TERM=xterm-256color script -q "$tmp/copy.out" nvim --clean -u NONE -i NONE \
  "+luafile $repo_root/lua/config/options.lua" \
  "+call setreg('+', ['copy-probe'], 'v')" \
  +qa >/dev/null 2>&1

grep -F $'\033]52;c;Y29weS1wcm9iZQ==\033\\' "$tmp/copy.out" >/dev/null

PATH="$tmp/bin:$PATH" nvim --clean --headless -u NONE -i NONE \
  "+luafile $repo_root/lua/config/options.lua" \
  "+put +" \
  "+write! $tmp/paste.out" \
  +qa >/dev/null 2>&1

grep -Fx 'paste-probe' "$tmp/paste.out" >/dev/null
