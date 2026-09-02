#!/usr/bin/env bash
#
# screenshot.sh — 快速区域截图并复制到剪贴板。
#
# 功能: slurp 选区 → grim 截图 → wl-copy → 通知 (不落盘、不编辑)。
# 依赖: slurp、grim、wl-copy、notify-send
# 调用方: modules.jsonc 自定义模块 on-click (仅点击)。
# 复杂编辑场景用 power-screenshot.sh (fuzzel 菜单 + satty/swappy)。

COORDS=$(slurp)
if [ -z "$COORDS" ]; then
    exit 0
fi
# pw-play /usr/share/sounds/freedesktop/stereo/camera-shutter.oga > /dev/null 2>&1 &

# 先落盘成功再写剪贴板: 若直接 `grim - | wl-copy`, grim 失败时 wl-copy
# 会以空输入成功返回, 剪贴板被空内容覆盖且退出码看不出失败。
SHOT=$(mktemp /tmp/screenshot.XXXXXX.png)
if ! grim -g "$COORDS" "$SHOT"; then
    rm -f -- "$SHOT"
    notify-send -u critical "Screenshot" "截图失败 (grim)" 2>/dev/null || true
    exit 1
fi
wl-copy < "$SHOT"
rm -f -- "$SHOT"
notify-send "Screenshot" "copy to clipboard"
