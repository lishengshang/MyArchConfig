#!/usr/bin/env bash
# ~/.config/niri/scripts/auto-update-cache.sh

# 监听配置目录变化，自动更新缓存
inotifywait -m -e modify,create,delete "$HOME/.config/niri/" --include '\.kdl$' | \
while read -r directory events filename; do
    # 延迟 2 秒，防止频繁更新
    sleep 2
    rm -f "$HOME/.cache/niri-hotkeys/hotkeys.cache" \
          "$HOME/.cache/niri-hotkeys/timestamp"
    notify-send "Niri" "检测到配置变更，快捷键缓存已更新" -t 2000
done