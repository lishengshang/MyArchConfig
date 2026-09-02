#!/usr/bin/env bash
# 手动恢复上次保存的 niri 会话
# 用法：直接运行此脚本，或绑定到 niri 快捷键 Mod+Alt+R
# 依赖: nirinit (~/.cargo/bin/nirinit)、notify-send、pkill

set -euo pipefail

NIRINIT_BIN="$HOME/.cargo/bin/nirinit"

# 二进制存在性检查: 后台启动的失败不会触发 set -e, 若不在这里拦截,
# 二进制缺失时仍会通知“正在恢复”造成假成功。
if [[ ! -x "$NIRINIT_BIN" ]]; then
    notify-send "nirinit" "找不到可执行的 $NIRINIT_BIN，无法恢复" --urgency=critical 2>/dev/null || true
    echo "nirinit 二进制不存在或不可执行: $NIRINIT_BIN" >&2
    exit 1
fi

# 先停掉后台只保存的 nirinit 实例; 等它真正退出再启动新实例,
# 避免旧实例正在刷写 session.json 时新实例读到半截文件 (固定 sleep 1 不可靠)。
pkill -x nirinit 2>/dev/null || true
for _ in 1 2 3 4 5 6 7 8 9 10; do
    pgrep -x nirinit >/dev/null 2>&1 || break
    sleep 0.2
done

# 检查会话文件是否存在
SESSION_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/nirinit/session.json"
if [[ ! -f "$SESSION_FILE" ]]; then
    notify-send "nirinit" "没有找到会话文件，无需恢复" 2>/dev/null
    echo "会话文件不存在: $SESSION_FILE"
    exit 0
fi

# 启动 nirinit（不带 --no-restore，会读取 session.json 恢复窗口）
# 恢复后继续常驻后台保存。启动后短探活确认进程还在,
# 否则启动即失败时不能报“已启动”。
"$NIRINIT_BIN" --save-interval 300 &
NIRINIT_PID=$!
sleep 0.5
if ! kill -0 "$NIRINIT_PID" 2>/dev/null; then
    notify-send "nirinit" "会话恢复启动失败，请查看日志" --urgency=critical 2>/dev/null || true
    echo "nirinit 启动后立即退出，日志: ${XDG_DATA_HOME:-$HOME/.local/share}/nirinit/nirinit.log" >&2
    exit 1
fi

notify-send "nirinit" "正在恢复上次会话..." 2>/dev/null
echo "会话恢复已启动，日志: ${XDG_DATA_HOME:-$HOME/.local/share}/nirinit/nirinit.log"
