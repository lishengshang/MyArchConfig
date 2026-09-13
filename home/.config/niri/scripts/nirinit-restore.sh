#!/usr/bin/env bash
# 手动恢复上次会话的窗口布局
# 用法：按 niri 快捷键 Mod+Shift+G（绑定见 binds.kdl），或直接运行本脚本
#
# 与旧版的区别（改动原因见 MAINTENANCE_PLAN P3-17 / P3-18）
#   1. 恢复源改成 session.prev.json —— 由 nirinit-start.sh 在开机时冻结的
#      "上次会话"快照。旧版读的 session.json 每 300 秒就被当前状态覆盖，
#      导致开机满 5 分钟后恢复的其实是"当前会话"，会把应用重复开一份。
#   2. 恢复前先用 niri msg 取当前已有窗口，把已经在跑的 app 从待恢复列表里
#      剔除，只补缺失的 —— 因此可以随时反复按，不会越按越多。
#   3. 不再依赖 nirinit 的 --no-restore 参数（上游没有该参数，换机会装到原版）。
#
# 依赖: nirinit、jq、niri、flock、pkill / pgrep；notify-send、fuzzel 可选

set -euo pipefail

NIRINIT_BIN="$HOME/.cargo/bin/nirinit"
# 周期保存只作【崩溃/断电/被强杀时的兜底】：正常关机、重启、注销都由
# nirinit-flush.service 在 niri 退出前精确保存。所以这里取 30 分钟，
# 既不频繁写盘，又不至于在异常退出时丢太多。
# 注意：该值同时出现在 nirinit-start.sh（改一处需改两处）。
SAVE_INTERVAL=1800
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nirinit"
SESSION_FILE="$DATA_DIR/session.json"
PREV_FILE="$DATA_DIR/session.prev.json"
LOG_FILE="$DATA_DIR/nirinit.log"

for cmd in jq niri flock pkill pgrep; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "缺少依赖命令: $cmd" >&2
        exit 1
    fi
done

# 防重入：连按或误触时，两个恢复流程会互相 pkill 并各起一个 nirinit，
# 最终留下两个实例同时周期写 session.json（旧日志里已出现过交错记录）。
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/nirinit-restore-${UID:-$(id -u)}.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    notify-send "nirinit" "上一次会话恢复仍在进行中，已忽略本次触发" 2>/dev/null || true
    echo "已有恢复流程在运行（锁文件：$LOCK_FILE），忽略本次触发" >&2
    exit 0
fi

if [[ ! -x "$NIRINIT_BIN" ]]; then
    notify-send "nirinit" "找不到可执行的 $NIRINIT_BIN，无法恢复" --urgency=critical 2>/dev/null || true
    echo "nirinit 二进制不存在或不可执行: $NIRINIT_BIN" >&2
    exit 1
fi

if [[ ! -s "$PREV_FILE" ]]; then
    notify-send "nirinit" "还没有可恢复的会话快照（本次登录尚未冻结）" 2>/dev/null || true
    echo "会话快照不存在或为空: $PREV_FILE"
    exit 0
fi

# ── 取出当前已经在跑的 app_id ──────────────────────────────────────────────
RUNNING=""
if RUNNING=$(niri msg --json windows 2>/dev/null | jq -c '[.[].app_id | select(. != null)]' 2>/dev/null) \
   && [[ -n "$RUNNING" ]]; then
    :
else
    # 拿不到窗口列表时无法判断哪些已存在。此时不能静默照旧恢复，
    # 否则就是旧版"开出重复窗口"的行为，先问一句。
    echo "无法读取当前窗口列表，降级为确认式恢复" >&2
    ANSWER=$(printf '取消\n仍然恢复' | fuzzel --dmenu --prompt='读不到当前窗口，恢复可能重复，继续？ ' 2>/dev/null || true)
    if [[ "$ANSWER" != "仍然恢复" ]]; then
        echo "用户取消"
        exit 0
    fi
    RUNNING='[]'
fi

# ── 过滤：只保留当前没有在跑的那些窗口 ─────────────────────────────────────
TMP_SESSION=$(mktemp "$DATA_DIR/.session.XXXXXX")
trap 'rm -f "$TMP_SESSION"' EXIT

if ! jq --argjson running "$RUNNING" \
       '[.[] | select(.app_id as $a | ($running | index($a)) == null)]' \
       "$PREV_FILE" > "$TMP_SESSION"; then
    notify-send "nirinit" "会话快照解析失败，已中止恢复" --urgency=critical 2>/dev/null || true
    echo "无法解析会话快照: $PREV_FILE" >&2
    exit 1
fi

TO_RESTORE=$(jq 'length' "$TMP_SESSION")
TOTAL=$(jq 'length' "$PREV_FILE")
if [[ "$TO_RESTORE" -eq 0 ]]; then
    # 快照里的应用都已经在跑了。此时【不动】正在运行的 nirinit，
    # 只提示一下 —— 这也是"反复按不会出问题"的原因。
    notify-send "nirinit" "上次会话的 ${TOTAL} 个窗口都已在运行，无需恢复" 2>/dev/null || true
    echo "快照共 ${TOTAL} 个窗口，全部已在运行，无需恢复"
    exit 0
fi

ALREADY=$(jq --argjson r "$RUNNING" '[.[] | select(.app_id as $a | ($r | index($a)) != null)] | length' "$PREV_FILE")
echo "快照共 ${TOTAL} 个窗口，其中已在运行 ${ALREADY} 个，将恢复 ${TO_RESTORE} 个"

# ── 停掉旧的 nirinit，并确认真的退出了 ─────────────────────────────────────
# 必须在写入 session.json 之前完成：旧实例收到 SIGTERM 时会做最后一次保存，
# 把【当前】窗口状态写进 session.json，会覆盖掉我们准备恢复的过滤结果。
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
    notify-send "nirinit" "无法停止旧的 nirinit 实例，已中止恢复" --urgency=critical 2>/dev/null || true
    echo "旧 nirinit 实例仍在运行，中止以避免双实例同时写会话文件" >&2
    exit 1
fi

# ── 就位并重启 nirinit ─────────────────────────────────────────────────────
# mv 在同一文件系统内是原子的，nirinit 不会读到半截文件。
mv -f "$TMP_SESSION" "$SESSION_FILE"

# 9>&- 不能省：锁挂在 fd 9 上，nirinit 长期驻留，继承 fd 9 会导致锁永不释放。
"$NIRINIT_BIN" --save-interval "$SAVE_INTERVAL" 9>&- &
NIRINIT_PID=$!

# 探活两段：单次 sleep 0.5 只能覆盖"立刻失败"，覆盖不了稍慢的启动期退出。
sleep 0.5
if kill -0 "$NIRINIT_PID" 2>/dev/null; then
    sleep 1
fi
if ! kill -0 "$NIRINIT_PID" 2>/dev/null; then
    notify-send "nirinit" "会话恢复启动失败，请查看日志" --urgency=critical 2>/dev/null || true
    echo "nirinit 启动后立即退出，日志: $LOG_FILE" >&2
    exit 1
fi

notify-send "nirinit" "正在恢复 ${TO_RESTORE} 个窗口..." 2>/dev/null || true
echo "会话恢复已启动（${TO_RESTORE} 个窗口），日志: $LOG_FILE"
