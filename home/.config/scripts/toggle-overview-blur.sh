#!/bin/bash
# =============================================================================
# toggle-overview-blur.sh - 开关 niri 总览(Mod+O)的模糊暗化背景
# =============================================================================
# 逻辑: 基于 awww-overview-daemon.service 的运行状态切换。
#   开启: 启动 daemon 并立即应用当前壁纸的模糊缓存
#   关闭: 停止 daemon (总览背景恢复为未模糊状态)
# 由 waybar 启动器按钮中键调用 (modules.jsonc custom/applauncher); 也可手动运行。
# =============================================================================

SERVICE="awww-overview-daemon.service"
BLUR_SCRIPT="$HOME/.config/scripts/niri_set_overview_blur_dark_bg.sh"

if systemctl --user is-active --quiet "$SERVICE"; then
    systemctl --user stop "$SERVICE"
    notify-send "Overview Blur" "模糊背景已关闭"
else
    systemctl --user start "$SERVICE"
    # 等待 daemon 冷启动就绪后应用当前壁纸模糊 (start 幂等, 已在运行则无延迟)
    sleep 1
    if [ -x "$BLUR_SCRIPT" ]; then
        "$BLUR_SCRIPT" >/dev/null 2>&1
    fi
    notify-send "Overview Blur" "模糊背景已开启"
fi
