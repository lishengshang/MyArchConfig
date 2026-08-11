#!/usr/bin/env bash
#
# 统一锁屏入口（hyprlock）
#
# 自动锁屏（swayidle 超时 / before-sleep）与手动锁屏（快捷键 / 电源菜单 / waybar）
# 全部走这里，保证只用 hyprlock（不再使用 swaylock）。
#
# 设计要点：
#   - pgrep 防双实例：已锁定（hyprlock 运行中）则直接退出，
#     避免叠加第二个 hyprlock / 触发 niri 的"仅一个锁屏客户端"限制
#   - 后台启动 hyprlock 后立即返回，不阻塞调用方
#     （swayidle 的熄屏 / 休眠命令可继续执行）
#   - 无论从哪个路径调用，行为一致：锁定时幂等
#
set -euo pipefail

# 已锁定则跳过
if pgrep -x hyprlock >/dev/null 2>&1; then
    exit 0
fi

# 后台启动，立即返回（stderr 保持直通，systemd 环境下会进 journald）
hyprlock -c "$HOME/.config/niri/hyprlock.conf" &
