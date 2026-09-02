#!/bin/bash
# hyprlock-music.sh - 找到正在播放的非浏览器播放器，输出其 metadata
# 排除：chromium, firefox, chrome, msedge, brave, plasma-browser-integration
# 没有播放器在播就输出 "♪ Not Playing"
#
# 依赖: playerctl (>= 2.4, 需要 --ignore-player 支持)
# 调用方: hyprlock.conf 的 cmd[update:2000]，锁屏期间每 2 秒执行一次，
#   因此必须把开销压到最低：单次 playerctl 调用（原实现每 2 秒要
#   N+1 次子进程: --list-all + 每播放器 status/metadata）。
#   playerctl 默认选第一个 Playing 的播放器，与原循环语义一致。

# 依赖缺失（如 tty 会话）时直接显示占位文本，不做无谓重试
command -v playerctl >/dev/null 2>&1 || { echo "♪ Not Playing"; exit 0; }

# --ignore-player 用前缀匹配实例名，覆盖 chromium.instance123 这类带后缀的名字。
# playerctl 按 Playing > Paused 优先级选播放器；输出带 status 前缀，
# 仅当选中播放器正在 Playing 才展示（与原循环只认 Playing 的语义一致）。
line=$(playerctl \
    --ignore-player chromium,firefox,chrome,msedge,brave,plasma-browser-integration \
    metadata --format "{{ status }}	{{ album }} - {{ artist }} - {{ title }}" 2>/dev/null)

status="${line%%$'\t'*}"
out="${line#*$'\t'}"

if [ "$status" = "Playing" ] && [ -n "$out" ]; then
    echo "$out"
else
    echo "♪ Not Playing"
fi
