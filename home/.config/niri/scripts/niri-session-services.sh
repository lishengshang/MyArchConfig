#!/usr/bin/env bash
# 只在 Niri 会话中启动 Niri 专用的用户服务。
# user@UID.service 开启了 linger，不能依赖 graphical-session.target 自动隔离桌面。
set -Eeuo pipefail

export XDG_CURRENT_DESKTOP=niri
export XDG_SESSION_DESKTOP=niri

# environment.d 会在新登录时提供这些目录；这里再次显式整理并导入 PATH，
# 兼容 linger 的 user manager 在旧会话中保留了较短 PATH 的情况。
PATH="$HOME/.local/bin:$HOME/.local/share/uv/bin:$HOME/.cargo/bin:$HOME/.bun/bin:${PATH:-/usr/local/sbin:/usr/local/bin:/usr/bin}"
# 多次重载 Niri 时不累积重复 PATH 项。
PATH="$(printf '%s' "$PATH" | awk -v RS=: -v ORS=: '!seen[$0]++ && length($0)')"
PATH="${PATH%:}"
export PATH

# 将本次 Niri 的 Wayland/Niri 环境导入持久的 systemd user manager，
# 让 systemd 启动的 awww/swayidle 能连接当前 Niri 会话。
systemctl --user import-environment \
    PATH WAYLAND_DISPLAY DISPLAY NIRI_SOCKET XDG_CURRENT_DESKTOP \
    XDG_SESSION_TYPE XDG_SESSION_DESKTOP 2>/dev/null || true

dbus-update-activation-environment --systemd \
    PATH WAYLAND_DISPLAY DISPLAY NIRI_SOCKET XDG_CURRENT_DESKTOP \
    XDG_SESSION_TYPE XDG_SESSION_DESKTOP 2>/dev/null || true

# 这些服务不再挂在 default.target/timers.target 下，只由 Niri 显式启动。
systemctl --user start awww-overview-daemon.service
systemctl --user start random-api-wallpaper.timer
systemctl --user start swayidle.service
systemctl --user start gtk-theme-by-time.timer
