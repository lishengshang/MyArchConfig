#!/usr/bin/env bash
# Open clipboard history only when the opt-in watcher is enabled.
set -Eeuo pipefail

ENABLE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/niri/clipboard-history.enabled"
if [[ ! -e "$ENABLE_FILE" ]]; then
    notify-send "剪贴板历史已关闭" "如需启用，请创建 ~/.config/niri/clipboard-history.enabled" 2>/dev/null || true
    exit 0
fi

if ! command -v nirius >/dev/null 2>&1; then
    notify-send -u critical "剪贴板历史" "缺少命令: nirius" 2>/dev/null || true
    exit 1
fi

exec nirius focus-or-spawn --app-id cliphist-tui -- \
    kitty --single-instance --class cliphist-tui \
    -e "$HOME/.config/niri/scripts/clipboard-history-tui.sh"
