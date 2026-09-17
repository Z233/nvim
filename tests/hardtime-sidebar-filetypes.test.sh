#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
nvim_bin=$(command -v nvim)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/config" "$tmp/state"
ln -s "$repo_root" "$tmp/config/nvim"

git_repo="$tmp/repo"
mkdir -p "$git_repo"
git -C "$git_repo" init -q .
printf 'a\nb\nc\n' >"$git_repo/tracked.txt"
git -C "$git_repo" add .
git -C "$git_repo" -c user.email=test@example.com -c user.name=test commit -qm init
printf 'a\nB\nc\nd\n' >"$git_repo/tracked.txt"

# Counts hardtime restriction warnings and focuses a window by filetype.
cat >"$tmp/probe.lua" <<'EOF'
_G.counted = 0
local notify = vim.notify
vim.notify = function(msg, ...)
  if type(msg) == "string" and msg:match("too soon") then
    _G.counted = _G.counted + 1
  end
  return notify(msg, ...)
end

_G.focus_filetype = function(pattern)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local filetype = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
    if filetype:match(pattern) then
      vim.api.nvim_set_current_win(win)
      return filetype
    end
  end
  return "not-found"
end
EOF

sessions=()
stop_sessions() {
  for sock in "${sessions[@]:-}"; do
    [ -S "$sock" ] && "$nvim_bin" --server "$sock" --remote-send ':qa!<CR>' >/dev/null 2>&1
  done
}
trap 'stop_sessions; rm -rf "$tmp"' EXIT

start_session() { # socket, then nvim arguments
  local sock=$1
  shift
  sessions+=("$sock")
  XDG_CONFIG_HOME="$tmp/config" XDG_STATE_HOME="$tmp/state" \
    nohup "$nvim_bin" --headless -i NONE --listen "$sock" "$@" \
    >"$tmp/server.log" 2>&1 &
  for _ in $(seq 1 60); do
    [ -S "$sock" ] && return 0
    sleep 0.25
  done
  echo "nvim did not start: $(cat "$tmp/server.log")" >&2
  exit 1
}

send() { "$nvim_bin" --server "$1" --remote-send "$2" >/dev/null 2>&1; }
ask() { "$nvim_bin" --server "$1" --remote-expr "luaeval(\"$2\")" 2>/dev/null; }

# Types repeated motions into $2 and prints the hardtime warning count.
motion_warnings() { # socket, filetype pattern
  local sock=$1 pattern=$2
  local focused
  focused=$(ask "$sock" "_G.focus_filetype('$pattern')")
  [ "$focused" != "not-found" ] || {
    echo "$focused"
    return 1
  }
  send "$sock" 'jjjjjjjjjjjjjjjjjjjj'
  sleep 1
  ask "$sock" '_G.counted'
}

failures=0
report() { # name, expected (none|some), actual
  local name=$1 expected=$2 actual=$3
  local ok=1
  case "$expected" in
    none) [ "$actual" = "0" ] || ok=0 ;;
    some) [ "$actual" -ge 1 ] 2>/dev/null || ok=0 ;;
  esac
  if [ "$ok" = 1 ]; then
    echo "ok   $name (warnings: $actual)"
  else
    echo "FAIL $name (expected $expected, got: $actual)"
    failures=$((failures + 1))
  fi
}

# Control: plain file buffer must keep hardtime active.
sock="$tmp/sock-file.sock"
start_session "$sock" "$git_repo/tracked.txt"
sleep 2
send "$sock" ":luafile $tmp/probe.lua<CR>"
sleep 0.5
send "$sock" 'jjjjjjjjjjjjjjjjjjjj'
sleep 1
report "file buffer" some "$(ask "$sock" '_G.counted')"

# Sidebar: neo-tree binds j/k to tree navigation, hardtime must stay off.
sock="$tmp/sock-neotree.sock"
start_session "$sock" "$git_repo"
sleep 2
send "$sock" ":luafile $tmp/probe.lua<CR>"
sleep 0.5
send "$sock" ':Neotree show<CR>'
sleep 1
report "neo-tree" none "$(motion_warnings "$sock" 'neo%-tree' || true)"

# Sidebar: CodeDiff explorer binds j/k to file navigation, hardtime must stay off.
sock="$tmp/sock-codediff.sock"
start_session "$sock" "$git_repo/tracked.txt"
sleep 2
send "$sock" ":luafile $tmp/probe.lua<CR>"
sleep 0.5
send "$sock" ':CodeDiff<CR>'
sleep 2
report "codediff-explorer" none "$(motion_warnings "$sock" 'codediff%-explorer' || true)"

[ "$failures" = 0 ] || exit 1
