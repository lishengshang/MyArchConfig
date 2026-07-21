#!/usr/bin/env bash

TIMER="random-api-wallpaper.timer"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$1" "$2"
    fi
}

if systemctl --user is-active --quiet "$TIMER"; then
    systemctl --user disable --now "$TIMER"
    notify "自动壁纸已关闭" "每 5 分钟随机切换已停止"
else
    systemctl --user enable --now "$TIMER"
    systemctl --user start random-api-wallpaper.service
    notify "自动壁纸已开启" "每 5 分钟随机切换已启动"
fi
