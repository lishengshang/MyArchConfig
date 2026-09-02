#!/usr/bin/env bash
#
# random-api-wallpaper.sh — 从本地壁纸库随机挑一张并应用 (不联网)。
#
# 功能: 在 ~/Pictures/Wallpapers/api-random-download 里随机选图 (排除最近 5 张与当前壁纸)，
#   优先直调 awww 应用，失败回退 waypaper；同步 waypaper 记录与历史文件，
#   最后触发主题后处理 (matugen 取色/模糊背景，由常驻 wallpaper-theme.service 异步执行)。
# 依赖: awww 或 waypaper、wallpaper-lib.sh；壁纸库由 random-anime-wallpaper.sh (Mod+Shift+F10) 下载积累。
# 调用方: random-api-wallpaper.timer (每 8 分钟)、快捷键 (Mod+F10)；无命令行参数。
# 并发: 与下载脚本共用公共库的 "wallpaper-switch" flock，全程单实例。

# 经 stow symlink 调用时解析到 dotfiles 仓库内的真实目录
SCRIPT_DIR="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=../../scripts/wallpaper-lib.sh
source "$SCRIPT_DIR/../../scripts/wallpaper-lib.sh"

# 该脚本由 user timer 和快捷键共同调用；linger 用户管理器在 KDE 中也会继续运行。
# 必须在最前面判断 Niri，不能等 waypaper/matugen 执行后再判断。
if ! pgrep -u "${UID:-$(id -u)}" -x niri >/dev/null 2>&1; then
    exit 0
fi

# timer、快捷键和下载脚本 (random-anime-wallpaper.sh) 可能同时触发；统一使用同一把
# 公共库 flock，保证 “选图/下载 -> 写 waypaper -> awww -> post-command” 全程单实例。
if ! wallpaper_lock_acquire "wallpaper-switch"; then
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

if ! command -v awww >/dev/null 2>&1 && ! command -v waypaper >/dev/null 2>&1; then
    echo "Error: neither awww nor waypaper is installed" >&2
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

# 3. 应用壁纸。优先直调 awww，省去每 8 分钟拉起一次完整 waypaper 进程的开销
# (与 random-anime-wallpaper.sh 同一范式)。awww 不可用/失败时回退 waypaper。
# stderr 保留进 journal 便于排障; 短过渡与下载脚本观感对齐。
if command -v awww >/dev/null 2>&1 && awww img "$SELECTED" --transition-duration 0.3 --transition-type fade; then
    # 绕过 waypaper 时手动同步其当前壁纸记录 (公共库)，保证 GUI 与 fallback 读取一致。
    wallpaper_sync_waypaper "$SELECTED"
elif command -v waypaper >/dev/null 2>&1; then
    # 随机脚本自己安排主题更新，禁止 waypaper 再执行同一个 post_command，
    # 否则会重复跑 Matugen 并再次生成模糊背景。
    waypaper --no-post-command --wallpaper "$SELECTED"
else
    echo "Error: failed to apply wallpaper with awww and waypaper is unavailable" >&2
    exit 1
fi

# 4. 记录历史 (只保留最近 NO_REPEAT 条)
echo "$SELECTED" >> "$HISTORY_FILE"
tail -n "$NO_REPEAT" "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"

# 5. 主题和 overview 背景必须在后台处理（公共库）。颜色提取/模糊图生成不应阻塞
# wallpaper 命令或让 compositor 同步等待；worker 还会合并快速连续的切换。
wallpaper_run_post_command
