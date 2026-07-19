#!/usr/bin/env bash
# ~/.config/niri/scripts/auto-update-cache.sh
# 监听 niri 配置目录变化，自动删除快捷键缓存，让 niri-binds 下次重新生成。
# 带 debounce：攒够 DEBOUNCE_SEC 静默期才处理一次，避免改一次配置弹多次通知。

set -euo pipefail

WATCH_DIR="$HOME/.config/niri"
CACHE_DIR="$HOME/.cache/niri-hotkeys"
DEBOUNCE_SEC=2

command -v inotifywait >/dev/null 2>&1 || {
    printf '[auto-update-cache] 缺少 inotifywait，退出\n' >&2
    exit 1
}
mkdir -p "$CACHE_DIR"

# inotifywait 持续输出事件；read -t 实现 debounce：
# 每收到一个事件后，循环吞掉 DEBOUNCE_SEC 内的后续事件，直到静默才处理。
inotifywait -m -e modify,create,delete "$WATCH_DIR" --include '\.kdl$' 2>/dev/null | \
while true; do
    # 阻塞等第一个事件（丢弃字段，只用副作用：进入循环）
    read -r _ _ _ || exit 0
    # 吞掉 debounce 窗口内的后续事件
    while read -r -t "$DEBOUNCE_SEC" _ _ _; do
        :
    done
    rm -f "$CACHE_DIR/hotkeys.cache" "$CACHE_DIR/timestamp"
    notify-send "Niri" "检测到配置变更，快捷键缓存已更新" -t 2000
done
