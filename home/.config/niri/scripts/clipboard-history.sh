#!/usr/bin/env bash
# Optional clipboard history watcher.
# It is deliberately opt-in because cliphist stores copied content persistently.
set -Eeuo pipefail

ENABLE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/niri/clipboard-history.enabled"

if [[ ! -e "$ENABLE_FILE" ]]; then
    exit 0
fi

for command_name in wl-paste cliphist; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        notify-send -u critical "剪贴板历史" "缺少命令: $command_name" 2>/dev/null || true
        exit 1
    fi
done

exec wl-paste --watch cliphist store
