#!/usr/bin/env bash
# 手动恢复上次保存的 niri 会话
# 用法：直接运行此脚本，或绑定到 niri 快捷键 Mod+Alt+R

set -euo pipefail

# 先停掉后台只保存的 nirinit 实例
pkill -x nirinit 2>/dev/null || true
sleep 1

# 检查会话文件是否存在
SESSION_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/nirinit/session.json"
if [[ ! -f "$SESSION_FILE" ]]; then
    notify-send "nirinit" "没有找到会话文件，无需恢复" 2>/dev/null
    echo "会话文件不存在: $SESSION_FILE"
    exit 0
fi

# 启动 nirinit（不带 --no-restore，会读取 session.json 恢复窗口）
# 恢复后继续常驻后台保存
~/.cargo/bin/nirinit --save-interval 300 &

notify-send "nirinit" "正在恢复上次会话..." 2>/dev/null
echo "会话恢复已启动，日志: ${XDG_DATA_HOME:-$HOME/.local/share}/nirinit/nirinit.log"
