#!/usr/bin/env bash
#
# toggle-random-api-wallpaper.sh — 开关自动随机壁纸（random-api-wallpaper.timer）。
#
# 调用方: binds.kdl Mod+Alt+F10。
# 依赖: systemctl (user)、notify-send。
# 行为: timer 停止时启动 timer 并立即触发一次 service；运行时停止 timer。

# 只允许在 Niri 中控制这个 Niri 专用 timer；不要重新 enable 到全局 timers.target，
# 否则切到 KDE 后 linger user manager 仍会继续调度它。
if ! pgrep -u "${UID:-$(id -u)}" -x niri >/dev/null 2>&1; then
    exit 0
fi

TIMER="random-api-wallpaper.timer"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$1" "$2"
    fi
}

if systemctl --user is-active --quiet "$TIMER"; then
    systemctl --user stop "$TIMER"
    notify "自动壁纸已关闭" "每 8 分钟随机切换已停止"
else
    systemctl --user start "$TIMER"
    systemctl --user start random-api-wallpaper.service
    notify "自动壁纸已开启" "每 8 分钟随机切换已启动"
fi
