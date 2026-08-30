#!/usr/bin/env bash

# 经 stow symlink 调用时解析到 dotfiles 仓库内的真实目录
SCRIPT_DIR="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=../../scripts/wallpaper-lib.sh
source "$SCRIPT_DIR/../../scripts/wallpaper-lib.sh"

# 该脚本由 user timer 和快捷键共同调用；linger 用户管理器在 KDE 中也会继续运行。
# 必须在最前面判断 Niri，不能等 waypaper/matugen 执行后再判断。
if ! pgrep -u "${UID:-$(id -u)}" -x niri >/dev/null 2>&1; then
    exit 0
fi

# timer、快捷键和 waypaper post-command 可能同时触发；公共库的 flock 保证
# “选图 -> 写 waypaper -> Matugen -> overview 背景”是单实例的。
if ! wallpaper_lock_acquire "api-wallpaper"; then
    echo "random wallpaper update already running; skip" >&2
    exit 0
fi

WALLPAPER_DIR="$HOME/Pictures/Wallpapers/api-random-download"
# 防重复随机: 随机选择时排除最近切换过的 NO_REPEAT 张 (可按需修改)
NO_REPEAT=5
HISTORY_FILE="$HOME/.cache/random-wallpaper-history"

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Error: wallpaper directory not found: $WALLPAPER_DIR" >&2
    exit 1
fi

if ! command -v waypaper >/dev/null 2>&1; then
    echo "Error: waypaper is not installed" >&2
    exit 1
fi

# 1. 构建排除列表: 最近 NO_REPEAT 张历史 + 当前壁纸 (避免随机到刚切过的)
EXCLUDE_FILE=$(mktemp)
trap 'rm -f "$EXCLUDE_FILE"' EXIT
if [ -f "$HISTORY_FILE" ]; then
    tail -n "$NO_REPEAT" "$HISTORY_FILE" >> "$EXCLUDE_FILE"
fi
CURRENT=$(wallpaper_current)
[ -n "$CURRENT" ] && echo "$CURRENT" >> "$EXCLUDE_FILE"

# 2. 候选: 目录图片 - 排除列表, 再 shuf 随机选一张
SELECTED=""
if [ -s "$EXCLUDE_FILE" ]; then
    SELECTED=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) \
        | grep -vxFf "$EXCLUDE_FILE" \
        | shuf -n1)
fi
if [ -z "$SELECTED" ]; then
    # 兜底: 目录图片太少(全部在排除列表内)时, 从全部图片随机
    SELECTED=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) | shuf -n1)
fi

if [ -z "$SELECTED" ] || [ ! -f "$SELECTED" ]; then
    echo "Error: no wallpaper found in $WALLPAPER_DIR" >&2
    exit 1
fi

# 3. 应用壁纸。随机脚本自己安排异步主题更新，禁止 waypaper 再执行
# 同一个 post_command，否则会重复跑 Matugen 并再次生成模糊背景。
waypaper --no-post-command --wallpaper "$SELECTED"

# 4. 记录历史 (只保留最近 NO_REPEAT 条)
echo "$SELECTED" >> "$HISTORY_FILE"
tail -n "$NO_REPEAT" "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"

# 5. 主题和 overview 背景必须在后台处理（公共库）。颜色提取/模糊图生成不应阻塞
# wallpaper 命令或让 compositor 同步等待；worker 还会合并快速连续的切换。
wallpaper_run_post_command
