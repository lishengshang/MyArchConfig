#!/usr/bin/env bash
# Open clipboard history - niri-clip v0.4 independent
set -Eeuo pipefail
ENABLE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/niri/clipboard-history.enabled"
if [[ ! -e "$ENABLE_FILE" ]]; then
    notify-send "剪贴板历史已关闭" "创建 ~/.config/niri/clipboard-history.enabled 后再使用" 2>/dev/null || true
    exit 0
fi
# 直接用 niri spawn 新窗口，不复用旧的 --single-instance 旧窗口会显示陈旧 fzf
# 若已有旧窗口，先关掉（避免 focus-or-spawn 复用空历史）
if nirius focus --app-id cliphist-tui 2>/dev/null; then
    niri msg action close-window 2>/dev/null || true
    sleep 0.15
fi
exec niri msg action spawn -- "kitty" "--class" "cliphist-tui" "-e" "niri-clip" "tui"
