#!/usr/bin/env bash
# ~/.config/niri/scripts/auto-update-cache.sh
# 监听 niri 配置目录变化，自动删除快捷键缓存，让 niri-binds 下次重新生成。
# 带 debounce：攒够 DEBOUNCE_SEC 静默期才处理一次，避免改一次配置弹多次通知。
#
# 依赖: inotifywait (inotify-tools)、notify-send
# 调用方: config.kdl 的 spawn-at-startup（每个 niri 会话一份，脚本内用 flock 防多实例）

set -euo pipefail

# 多实例锁: 会话重启残留/多次登录可能叠加多个实例, 重复监听与重复通知。
# flock 非阻塞抢锁, 拿不到说明已有实例在监听, 直接退出 (进程退出自动释放锁)。
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/auto-update-cache-${UID:-$(id -u)}.lock"
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

# 注意：~/.config/niri 是 symlink 目录（指向 dotfiles repo），inotify 只监听
# 到链接本身的变化，收不到真实文件的修改事件。readlink -f 解析到真实目录。
WATCH_DIR="$(readlink -f "$HOME/.config/niri")"
CACHE_DIR="$HOME/.cache/niri-hotkeys"
DEBOUNCE_SEC=2

command -v inotifywait >/dev/null 2>&1 || {
    printf '[auto-update-cache] 缺少 inotifywait，退出\n' >&2
    exit 1
}
mkdir -p "$CACHE_DIR"

# inotifywait 持续输出事件；read -t 实现 debounce：
# 每收到一个事件后，循环吞掉 DEBOUNCE_SEC 内的后续事件，直到静默才处理。
# 事件集必须包含 close_write/moved_to: 编辑器 (vim/VSCode) 与 sed -i 都是
# “写临时文件 + rename 覆盖”的原子保存, 只产生 moved_to 而不产生 modify,
# 缺了它们会导致保存配置后缓存不失效。
inotifywait -m -e modify,create,delete,close_write,moved_to "$WATCH_DIR" --include '\.kdl$' 2>/dev/null | \
while true; do
    # 阻塞等第一个事件（丢弃字段，只用副作用：进入循环）
    read -r _ _ _ || exit 0
    # 吞掉 debounce 窗口内的后续事件
    while read -r -t "$DEBOUNCE_SEC" _ _ _; do
        :
    done
    rm -f "$CACHE_DIR/hotkeys.cache" "$CACHE_DIR/timestamp"
    # 通知失败 (如会话早期守护进程未就绪) 不能杀掉监听链, 否则
    # inotifywait 变孤儿且缓存从此不再更新; 缓存删除本身已成功。
    notify-send "Niri" "检测到配置变更，快捷键缓存已更新" -t 2000 || true
done
