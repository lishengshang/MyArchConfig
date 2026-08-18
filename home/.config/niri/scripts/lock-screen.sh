#!/usr/bin/env bash
#
# 统一锁屏入口（hyprlock）
#
# 自动锁屏（swayidle 超时 / before-sleep）与手动锁屏（快捷键 / 电源菜单 / waybar）
# 全部走这里，保证只用 hyprlock。
#
# 默认模式：启动锁屏后立即返回，适合手动锁屏和普通 idle timeout。
# --wait-ready：启动后等待 hyprlock 进程建立，适合熄屏和 before-sleep，
#               避免锁屏命令返回后系统立即 suspend。
#
set -Eeuo pipefail

WAIT_READY=false
for arg in "$@"; do
    case "$arg" in
        --wait-ready) WAIT_READY=true ;;
        -h|--help)
            cat <<'EOF'
用法: lock-screen.sh [--wait-ready]

  默认          启动 hyprlock 后立即返回
  --wait-ready  等待 hyprlock 建立后再返回，供 suspend/熄屏流程使用
EOF
            exit 0
            ;;
        *)
            echo "未知参数: $arg" >&2
            exit 2
            ;;
    esac
done

# 使用用户 runtime 目录锁住“检查并启动”这段临界区，防止多个入口同时通过 pgrep。
LOCK_ROOT="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
[[ -d "$LOCK_ROOT" ]] || LOCK_ROOT=/tmp
LOCK_FILE="$LOCK_ROOT/dotfiles-hyprlock-${UID:-$(id -u)}.lock"
exec 9>"$LOCK_FILE"
flock -n 9 || {
    # 另一个实例正在启动；如果调用方要求等待，继续观察现有 hyprlock。
    if ! $WAIT_READY; then
        exit 0
    fi
}

is_locked() {
    pgrep -x -u "${UID:-$(id -u)}" hyprlock >/dev/null 2>&1
}

wait_ready() {
    local pid="${1:-}"
    for _ in $(seq 1 50); do
        if is_locked; then
            return 0
        fi
        if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
            return 1
        fi
        sleep 0.1
    done
    return 1
}

# 已锁定则幂等返回；--wait-ready 视为已满足。
if is_locked; then
    exit 0
fi

HYPRLOCK_CONFIG="$HOME/.config/niri/hyprlock.conf"
hyprlock -c "$HYPRLOCK_CONFIG" &
hyprlock_pid=$!

if $WAIT_READY; then
    if ! wait_ready "$hyprlock_pid"; then
        echo "hyprlock 未能在 5 秒内建立" >&2
        exit 1
    fi
fi
