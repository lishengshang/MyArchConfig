#!/usr/bin/env bash

# 该脚本由全局 user timer 调度；linger 用户管理器在 KDE 中也会继续运行。
# 必须在最前面判断 Niri，不能等 waypaper/matugen 执行后再判断。
if ! pgrep -u "${UID:-$(id -u)}" -x niri >/dev/null 2>&1; then
    exit 0
fi

WALLPAPER_DIR="$HOME/Pictures/Wallpapers/api-random-download"
WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"
MATUGEN_UPDATE="$HOME/.config/scripts/matugen-update.sh"
BLUR_UPDATE="$HOME/.config/scripts/niri_set_overview_blur_dark_bg.sh"

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
if [ -f "$WAYPAPER_CONFIG" ]; then
    CURRENT=$(sed -n 's/^wallpaper[[:space:]]*=[[:space:]]*//p' "$WAYPAPER_CONFIG" | head -n1)
    CURRENT="${CURRENT/#\~/$HOME}"
    # 规范化: 配置路径可能含 ~/../ 或符号链接成分, 与 find 输出的规范路径保持一致
    CURRENT=$(realpath "$CURRENT" 2>/dev/null || echo "$CURRENT")
    [ -n "$CURRENT" ] && echo "$CURRENT" >> "$EXCLUDE_FILE"
fi

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

# 3. 应用壁纸 (waypaper 会写配置并触发 post_command)
waypaper --wallpaper "$SELECTED"

# 4. 记录历史 (只保留最近 NO_REPEAT 条)
echo "$SELECTED" >> "$HISTORY_FILE"
tail -n "$NO_REPEAT" "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"

# 5. 等待 waypaper 写入配置并应用
sleep 0.5

# 6. 读取 waypaper 实际选中的壁纸路径
WALLPAPER=""
if [ -f "$WAYPAPER_CONFIG" ]; then
    WALLPAPER=$(sed -n 's/^wallpaper[[:space:]]*=[[:space:]]*//p' "$WAYPAPER_CONFIG")
    WALLPAPER="${WALLPAPER/#\~/$HOME}"
fi

# 7. 显式更新颜色主题（避免 waypaper post_command 在 CLI 模式下失效）
# stderr 静默: post_command 可能已先行触发, 锁竞争时 matugen-update 会输出
# "已有实例在运行" 到 stderr (非错误, exit 0); 真失败仍会通过 notify-send 弹出
if [ -x "$MATUGEN_UPDATE" ]; then
    if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
        "$MATUGEN_UPDATE" -f "$WALLPAPER" 2>/dev/null
    else
        "$MATUGEN_UPDATE" -f 2>/dev/null
    fi
fi

# 8. 更新 overview 模糊背景
if [ -x "$BLUR_UPDATE" ]; then
    sleep 0.8
    "$BLUR_UPDATE"
fi
