#!/usr/bin/env bash
# KDE 登录时停止仍由 linger 用户管理器保留的 Niri 专用服务。
set -u

for unit in \
    swayidle.service \
    random-api-wallpaper.timer \
    random-api-wallpaper.service \
    awww-overview-daemon.service; do
    systemctl --user stop "$unit" 2>/dev/null || true
done
