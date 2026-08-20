#!/usr/bin/env bash
#
# 统一锁屏入口（hyprlock）
#
# 自动锁屏（swayidle 超时 / before-sleep）与手动锁屏（快捷键 / 电源菜单 / waybar）
# 全部走这里，保证只用 hyprlock。
#
# 默认模式：启动锁屏并做短暂就绪检查后返回，适合手动锁屏和普通 idle timeout。
# --wait-ready：启动后最多等待 5 秒确认 hyprlock 建立，适合熄屏和 before-sleep，
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
if ! flock -n 9; then
    # 另一个实例正在启动。非等待调用方保持幂等返回；等待调用方
    # 必须等待现有实例真正建立，不能在竞态窗口中再启动第二个实例。
    if ! $WAIT_READY; then
        exit 0
    fi
    if wait_ready; then
        exit 0
    fi
    echo "已有 hyprlock 实例未能在 5 秒内建立" >&2
    exit 1
fi

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
if [[ ! -r "$HYPRLOCK_CONFIG" ]]; then
    echo "hyprlock 配置不存在或不可读: $HYPRLOCK_CONFIG" >&2
    exit 1
fi

# Matugen 主题文件是动态生成物。缺失时使用仓库中的静态暗色回退，
# 保证首次登录、缓存清理或网络壁纸失败时仍能可靠锁屏。
HYPRLOCK_COLORS="$HOME/.cache/matugen/hypr/colors.conf"
HYPRLOCK_FALLBACK="$HOME/.config/niri/hyprlock-colors-fallback.conf"
if [[ ! -r "$HYPRLOCK_COLORS" ]]; then
    if [[ ! -r "$HYPRLOCK_FALLBACK" ]]; then
        echo "hyprlock 动态颜色和回退文件都不存在" >&2
        exit 1
    fi
    install -D -m 600 -- "$HYPRLOCK_FALLBACK" "$HYPRLOCK_COLORS"
fi

hyprlock -c "$HYPRLOCK_CONFIG" &
hyprlock_pid=$!

# 所有调用方都应使用 --wait-ready；这里即使默认异步模式也做一次
# 短检查，避免 hyprlock 启动即失败却被当成成功锁屏。
if $WAIT_READY; then
    if ! wait_ready "$hyprlock_pid"; then
        kill "$hyprlock_pid" 2>/dev/null || true
        wait "$hyprlock_pid" 2>/dev/null || true
        echo "hyprlock 未能在 5 秒内建立" >&2
        exit 1
    fi
else
    if ! wait_ready "$hyprlock_pid" >/dev/null 2>&1; then
        echo "hyprlock 启动失败" >&2
        exit 1
    fi
fi
