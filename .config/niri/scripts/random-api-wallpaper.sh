#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers/api-random-download"
WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"
MATUGEN_UPDATE="$HOME/.config/scripts/matugen-update.sh"
BLUR_UPDATE="$HOME/.config/scripts/niri_set_overview_blur_dark_bg.sh"

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Error: wallpaper directory not found: $WALLPAPER_DIR" >&2
    exit 1
fi

if ! command -v waypaper >/dev/null 2>&1; then
    echo "Error: waypaper is not installed" >&2
    exit 1
fi

# 1. 随机切换壁纸
waypaper --folder "$WALLPAPER_DIR" --random

# 2. 等待 waypaper 写入配置并应用
sleep 0.5

# 3. 读取 waypaper 实际选中的壁纸路径
WALLPAPER=""
if [ -f "$WAYPAPER_CONFIG" ]; then
    WALLPAPER=$(sed -n 's/^wallpaper[[:space:]]*=[[:space:]]*//p' "$WAYPAPER_CONFIG")
    WALLPAPER="${WALLPAPER/#\~/$HOME}"
fi

# 4. 显式更新颜色主题（避免 waypaper post_command 在 CLI 模式下失效）
if [ -x "$MATUGEN_UPDATE" ]; then
    if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
        "$MATUGEN_UPDATE" -f "$WALLPAPER"
    else
        "$MATUGEN_UPDATE" -f
    fi
fi

# 5. 更新 overview 模糊背景
if [ -x "$BLUR_UPDATE" ]; then
    sleep 0.8
    "$BLUR_UPDATE"
fi
