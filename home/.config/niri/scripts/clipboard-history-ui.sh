#!/usr/bin/env bash
# niri-clip - 独立剪贴板历史 (Mod+V)
set -Eeuo pipefail
# 若已有旧窗口，先关掉避免复用陈旧 fzf
if nirius focus --app-id niri-clip 2>/dev/null; then
    niri msg action close-window 2>/dev/null || true
    sleep 0.12
fi
exec niri msg action spawn -- "kitty" "--class" "niri-clip" "-e" "niri-clip" "tui"
