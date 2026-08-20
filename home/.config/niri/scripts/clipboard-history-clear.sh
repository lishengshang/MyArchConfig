#!/usr/bin/env bash
# Confirm before clearing the entire clipboard history database.
set -Eeuo pipefail

ENABLE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/niri/clipboard-history.enabled"
if [[ ! -e "$ENABLE_FILE" ]]; then
    notify-send "剪贴板历史已关闭" "没有正在使用的持久化历史" 2>/dev/null || true
    exit 0
fi

choice=$(printf '%s\n' '取消' '确认清空' | fuzzel --dmenu --lines 2 --width 20 --prompt '清空剪贴板历史？ ' 2>/dev/null || true)
if [[ "$choice" == '确认清空' ]]; then
    cliphist wipe >/dev/null
    state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/cliphist"
    mkdir -p "$state_dir"
    chmod 700 "$state_dir"
    : >"$state_dir/pinned.ids"
    chmod 600 "$state_dir/pinned.ids"
    notify-send "剪贴板" "历史已清空" 2>/dev/null || true
fi
