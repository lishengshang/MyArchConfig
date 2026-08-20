#!/usr/bin/env bash
# KDE 登录时停止仍由 linger 用户管理器保留的 Niri 专用服务。
set -u

for unit in \
    swayidle.service \
    random-api-wallpaper.timer \
    random-api-wallpaper.service \
    awww-overview-daemon.service \
    wallpaper-theme.service \
    gtk-theme-by-time.timer \
    gtk-theme-by-time.service; do
    systemctl --user stop "$unit" 2>/dev/null || true
done

# KDE owns its own Fcitx5 Plasma theme; switch the runtime profile after
# stopping Niri-only services. This script is OnlyShowIn=KDE.
"$HOME/.config/scripts/fcitx5-session-theme.sh" kde 2>/dev/null || true
