#!/usr/bin/env bash
# Restart the optional clipboard history watcher without assuming clipsync-git.
set -Eeuo pipefail

ENABLE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/niri/clipboard-history.enabled"
if [[ ! -e "$ENABLE_FILE" ]]; then
    notify-send "剪贴板历史已关闭" "未启动持久化剪贴板记录" 2>/dev/null || true
    exit 0
fi

pkill -u "${UID:-$(id -u)}" -f '(^|/)wl-paste --watch cliphist store$' 2>/dev/null || true
sleep 0.3
nohup "$HOME/.config/niri/scripts/clipboard-history.sh" \
    >/dev/null 2>&1 &

# clipsync-git 是外部可选组件；安装时才尝试重启，避免固定报错。
if systemctl --user list-unit-files --no-legend clipsync-git.service 2>/dev/null \
    | grep -q '^clipsync-git\.service[[:space:]]'; then
    systemctl --user restart clipsync-git.service
fi
