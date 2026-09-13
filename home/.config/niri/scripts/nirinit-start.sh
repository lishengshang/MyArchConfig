#!/usr/bin/env bash
# nirinit 开机启动包装：先冻结"上次会话"快照，再正常启动 nirinit
# 由 config.kdl 的 spawn-at-startup 调用
#
# 为什么需要这一步
#   nirinit 每 300 秒用【当前】窗口状态覆盖 session.json，所以开机满 5 分钟后，
#   那个文件里存的已经不是"上次会话"而是"当前会话"了 —— 此时再执行恢复，
#   会把已经在跑的应用又开一份。
#
#   旧写法靠 nirinit 的 `--no-restore` 参数避免开机自动恢复，但该参数上游并没有：
#   本机二进制来自已丢失的 /tmp/nirinit 本地构建（见 MAINTENANCE_PLAN P3-18），
#   换机时 bootstrap.sh 用 `cargo install --locked nirinit` 装到的是原版，
#   而 clap 对未知参数会以退出码 2 直接失败 —— 会话保存会完全不工作，
#   且 niri 把子进程输出丢到 /dev/null，连报错都看不到。
#
#   这里改用"移走文件名"达到同样效果，且不依赖任何参数（原版 0.2.2 同样适用）：
#     开机把 session.json 移成 session.prev.json（冻结"上次会话"）
#     → nirinit 找不到会话文件，自然不会恢复
#     → 恢复改由 nirinit-restore.sh 从 prev.json 发起，任何时候都能按
#
# 依赖: nirinit、jq、flock

set -euo pipefail

NIRINIT_BIN="$HOME/.cargo/bin/nirinit"
# 周期保存只作【崩溃/断电/被强杀时的兜底】：正常关机、重启、注销都由
# nirinit-flush.service 在 niri 退出前精确保存。所以这里取 30 分钟，
# 既不频繁写盘，又不至于在异常退出时丢太多。
# 注意：该值同时出现在 nirinit-restore.sh（改一处需改两处）。
SAVE_INTERVAL=1800
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nirinit"
SESSION_FILE="$DATA_DIR/session.json"
PREV_FILE="$DATA_DIR/session.prev.json"

for cmd in jq flock; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "缺少依赖命令: $cmd（会话快照功能不可用）" >&2
        exit 1
    fi
done
if [[ ! -x "$NIRINIT_BIN" ]]; then
    echo "nirinit 不存在或不可执行: $NIRINIT_BIN" >&2
    exit 1
fi

mkdir -p "$DATA_DIR"

# 防重入：niri 重载配置时 spawn-at-startup 会再执行一次。若不拦，
# 第二次冻结会把"当前会话"当成"上次会话"覆盖掉真正的快照。
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/nirinit-start-${UID:-$(id -u)}.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "已有 nirinit 启动流程在运行，忽略本次"
    exit 0
fi

# 冻结每个登录会话只做一次。标记文件放 $XDG_RUNTIME_DIR（tmpfs，注销时清空），
# 因此同一次登录里 niri 重启不会重复冻结，重新登录则自然重置。
FROZEN_MARKER="${XDG_RUNTIME_DIR:-/tmp}/nirinit-frozen-${UID:-$(id -u)}"
if [[ ! -e "$FROZEN_MARKER" ]]; then
    # 只在 session.json 是【非空数组】时才覆盖 prev.json。
    # 原因：nirinit 启动时会因为找不到会话文件而立刻写一份新的（开机时通常是空的），
    # 若拿这个空文件去覆盖，就会把有用的上次会话快照毁掉。
    if [[ -s "$SESSION_FILE" ]] && jq -e 'type == "array" and length > 0' "$SESSION_FILE" >/dev/null 2>&1; then
        mv -f "$SESSION_FILE" "$PREV_FILE"
        echo "已冻结上次会话快照: $PREV_FILE"
    else
        echo "session.json 不存在或为空，保留现有快照不动"
    fi
    : > "$FROZEN_MARKER"
fi

# 启动 nirinit。此刻 session.json 已被移走或不存在，因此它不会恢复任何窗口，
# 只会立刻写一份新的 session.json 并开始周期保存。
# 用 exec 让本脚本进程直接变成 nirinit，这样 pkill -x nirinit 仍能按名匹配到它。
# 9>&- 不能省：flock 的锁挂在 fd 9 上，nirinit 是长期驻留进程，
# 继承 fd 9 会导致锁永不释放，之后 nirinit-start 再也跑不起来。
exec 9>&-
exec "$NIRINIT_BIN" --save-interval "$SAVE_INTERVAL"
