#!/usr/bin/env bash
# Clipboard watcher - niri-clip v0.2: 优先 Rust daemon (SQLite WAL)，回退 cliphist
set -Eeuo pipefail

ENABLE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/niri/clipboard-history.enabled"
if [[ ! -e "$ENABLE_FILE" ]]; then
    exit 0
fi

# 优先 Rust
if command -v niri-clip >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1; then
    exec niri-clip daemon
fi

# 回退：cliphist
for cmd in wl-paste cliphist; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        notify-send -u critical "剪贴板历史" "缺少命令: $cmd" 2>/dev/null || true
        exit 1
    fi
done
exec wl-paste --watch cliphist store
