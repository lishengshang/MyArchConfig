#!/usr/bin/env bash
# =============================================================================
# toggle-overview-blur.sh - 开关 niri 总览(Mod+O)的模糊暗化背景
# =============================================================================
# 逻辑: 基于 awww-overview-daemon.service 的运行状态切换。
#   开启: 启动 daemon 并立即应用当前壁纸的模糊缓存 (下游脚本自带
#         flock + socket 就绪轮询, 无需在此固定 sleep)
#   关闭: 停止 daemon (总览背景恢复为未模糊状态)
# 由 waybar 启动器按钮中键调用 (modules.jsonc custom/applauncher); 也可手动运行。
# 依赖: systemctl (user)、notify-send、niri_set_overview_blur_dark_bg.sh
# =============================================================================

SERVICE="awww-overview-daemon.service"
BLUR_SCRIPT="$HOME/.config/scripts/niri_set_overview_blur_dark_bg.sh"

fail() {
    notify-send "Overview Blur" "$1" --urgency=critical 2>/dev/null || true
    echo "$1" >&2
    exit 1
}

if systemctl --user is-active --quiet "$SERVICE"; then
    # 校验 systemctl 结果, 失败时不能报“已关闭”造成状态与实际相反
    systemctl --user stop "$SERVICE" || fail "停止 $SERVICE 失败"
    notify-send "Overview Blur" "模糊背景已关闭"
else
    systemctl --user start "$SERVICE" || fail "启动 $SERVICE 失败"
    # 应用当前壁纸模糊; 下游脚本内部会等 daemon socket 就绪 (冷启动兼容),
    # 不需要在这里固定 sleep。失败时如实报错而非静默报“已开启”。
    if [ -x "$BLUR_SCRIPT" ]; then
        "$BLUR_SCRIPT" >/dev/null 2>&1 || fail "模糊背景应用失败 (见 $BLUR_SCRIPT)"
    else
        fail "缺少下游脚本: $BLUR_SCRIPT"
    fi
    notify-send "Overview Blur" "模糊背景已开启"
fi
