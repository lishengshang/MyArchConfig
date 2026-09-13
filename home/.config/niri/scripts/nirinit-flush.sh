#!/usr/bin/env bash
# 在 niri 退出【之前】把当前窗口布局保存下来
# 由 nirinit-flush.service 的 ExecStop 调用，不要手动直接跑（手动跑只会把 nirinit 停掉）
#
# 为什么需要它
#   nirinit 自己会随 niri 一起被杀，而那时 niri 的 IPC socket 已经断了，
#   它的收尾保存会失败 —— 本机实测 42 次关闭里失败 23 次（55%），
#   报错固定为 "Connection reset by peer"。
#   nirinit-flush.service 排在 graphical-session.target 之前停止，而 niri.service
#   声明了 Before=graphical-session.target、比它更晚停止，所以本脚本运行时 niri
#   仍然活着 → 此时让 nirinit 收尾保存，必然成功。
#
# 设计约束
#   1. 幂等：nirinit 没在运行时必须安全无操作地退出（用户可能已手动关掉它）。
#   2. 不重启 nirinit：会话马上就要结束，重新拉起没有意义；下次登录由
#      config.kdl 的 spawn-at-startup 负责（先经 nirinit-start.sh 冻结快照）。
#   3. 不用 set -e：这是关机钩子，任何非致命失败都不该让单元失败或拖慢关机。
#
# 依赖: pkill / pgrep；jq 可选（仅用于报告窗口数）

set -uo pipefail

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nirinit"
SESSION_FILE="$DATA_DIR/session.json"

if ! command -v pkill >/dev/null 2>&1 || ! command -v pgrep >/dev/null 2>&1; then
    echo "缺少 pkill/pgrep，无法执行收尾保存" >&2
    exit 0                      # 不失败：关机流程不应被这个钩子阻挡
fi

if ! pgrep -x nirinit >/dev/null 2>&1; then
    echo "nirinit 未在运行，无需收尾保存（快照保持上一次的内容）"
    exit 0
fi

# 在 niri 仍存活时让 nirinit 走它的正常收尾路径
pkill -x nirinit 2>/dev/null || true
for _ in $(seq 1 25); do                 # 正常 SIGTERM：最多等 5s
    pgrep -x nirinit >/dev/null 2>&1 || break
    sleep 0.2
done
if pgrep -x nirinit >/dev/null 2>&1; then
    pkill -9 -x nirinit 2>/dev/null || true
    for _ in $(seq 1 15); do             # 强杀后最多再等 3s
        pgrep -x nirinit >/dev/null 2>&1 || break
        sleep 0.2
    done
fi
if pgrep -x nirinit >/dev/null 2>&1; then
    echo "无法停止 nirinit，收尾保存未完成；快照保持上一次的内容" >&2
    exit 0                      # 仍然不失败：这是关机钩子
fi

if [[ -s "$SESSION_FILE" ]]; then
    if command -v jq >/dev/null 2>&1; then
        echo "已收尾保存当前布局（$(jq 'length' "$SESSION_FILE" 2>/dev/null || echo '?') 个窗口）→ $SESSION_FILE"
    else
        echo "已收尾保存当前布局 → $SESSION_FILE"
    fi
else
    echo "收尾保存后 session.json 为空；快照保持上一次的内容（下次登录由非空校验保护，不会覆盖旧快照）"
fi

exit 0
