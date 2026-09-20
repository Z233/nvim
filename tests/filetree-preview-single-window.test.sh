#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
nvim_bin=$(command -v nvim)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/config" "$tmp/state" "$tmp/tree"
ln -s "$repo_root" "$tmp/config/nvim"
printf 'alpha\n' >"$tmp/tree/aaa.txt"

# Drives the neo-tree preview entry point the same way the plugin does.
cat >"$tmp/probe.lua" <<'EOF'
_G.messages = function()
  return vim.fn.execute("messages")
end

_G.state = function()
  return require("neo-tree.sources.manager").get_state_for_window()
end

_G.press_preview = function()
  local state = _G.state()
  if not state or not state.resolved_mappings or not state.resolved_mappings.P then
    return "no-mapping"
  end
  state.resolved_mappings.P.handler()
  return "pressed"
end

_G.preview_active = function()
  return tostring(require("neo-tree.sources.common.preview").is_active())
end

_G.only_neotree = function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
      vim.api.nvim_set_current_win(win)
      vim.cmd("only")
      return "ok"
    end
  end
  return "no-neotree"
end

_G.current_file = function()
  return vim.fn.expand("%:t")
end
EOF

sessions=()
stop_sessions() {
  for sock in "${sessions[@]:-}"; do
    [ -S "$sock" ] && "$nvim_bin" --server "$sock" --remote-send ':qa!<CR>' >/dev/null 2>&1
  done
}
trap 'stop_sessions; rm -rf "$tmp"' EXIT

sock="$tmp/sock.sock"
sessions+=("$sock")
XDG_CONFIG_HOME="$tmp/config" XDG_STATE_HOME="$tmp/state" \
  nohup "$nvim_bin" --headless -i NONE --listen "$sock" "$tmp/tree" \
  >"$tmp/server.log" 2>&1 &
for _ in $(seq 1 60); do
  [ -S "$sock" ] && break
  sleep 0.25
done
[ -S "$sock" ] || {
  echo "nvim did not start: $(cat "$tmp/server.log")" >&2
  exit 1
}

send() { "$nvim_bin" --server "$sock" --remote-send "$1" >/dev/null 2>&1; }
ask() { "$nvim_bin" --server "$sock" --remote-expr "luaeval(\"$1\")" 2>/dev/null; }

failures=0
report() { # name, expected, actual
  if [ "$2" = "$3" ]; then
    echo "ok   $1 ($3)"
  else
    echo "FAIL $1 (expected $2, got $3)"
    failures=$((failures + 1))
  fi
}

sleep 2
send ":luafile $tmp/probe.lua<CR>"
sleep 1
report "neo-tree opened" "ok" "$(ask '_G.only_neotree()')"

# Single window: preview must stay off instead of erroring.
sleep 0.5
report "preview press" "pressed" "$(ask '_G.press_preview()')"
sleep 1
report "preview inactive" "nil" "$(ask '_G.preview_active()')"
messages=$(ask '_G.messages()')
case "$messages" in
  *"truth"* | *"appropriate window for preview"*)
    echo "FAIL preview errors on a single window"
    echo "$messages" >&2
    failures=$((failures + 1))
    ;;
  *) echo "ok   no preview errors" ;;
esac

# The file must still open in a new split.
send 'G'
sleep 0.5
send '<CR>'
sleep 1
report "file opened" "aaa.txt" "$(ask '_G.current_file()')"

# Two windows: preview must work again.
send ':wincmd h | vsplit<CR>'
sleep 1
report "preview press with two windows" "pressed" "$(ask '_G.press_preview()')"
sleep 1
report "preview active with two windows" "true" "$(ask '_G.preview_active()')"

[ "$failures" = 0 ] || exit 1
