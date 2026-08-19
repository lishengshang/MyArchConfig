#!/usr/bin/env bash
# 启动 overview 专用 awww daemon。
#
# systemd user service 不应该把 WAYLAND_DISPLAY 写死成 wayland-0/wayland-1：
# Wayland socket 名称取决于登录顺序和会话环境。优先使用 systemd 导入的
# WAYLAND_DISPLAY；如果环境没有导入，则从当前用户的 runtime 目录中选择一个
# 可用 socket 作为 fallback。
set -Eeuo pipefail

# 该 unit 曾被 default.target 全局启动；KDE 中必须立即退出，避免
# awww-daemon 连接 KDE 的 Wayland socket 后反复崩溃。
if ! pgrep -u "${UID:-$(id -u)}" -x niri >/dev/null 2>&1; then
    exit 0
fi

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
WAIT_SECONDS=30

socket_path_for_display() {
    local display="$1"
    if [[ "$display" == /* ]]; then
        printf '%s\n' "$display"
    else
        printf '%s/%s\n' "$RUNTIME_DIR" "$display"
    fi
}

valid_display() {
    local display="$1"
    [[ -n "$display" ]] && [[ -S "$(socket_path_for_display "$display")" ]]
}

select_display() {
    local display path candidate newest newest_mtime mtime

    # 正常路径：Niri 通过 session environment 导入当前显示器名称。
    display="${WAYLAND_DISPLAY:-}"
    if valid_display "$display"; then
        printf '%s\n' "$display"
        return 0
    fi

    # fallback：选择 runtime 目录中最近创建/修改的 Wayland socket。
    # 通常 compositor socket 是 wayland-0 或 wayland-1；这里不假设具体编号。
    newest=""
    newest_mtime=-1
    for path in "$RUNTIME_DIR"/wayland-*; do
        [[ -S "$path" ]] || continue
        mtime=$(stat -c '%Y' "$path" 2>/dev/null || printf '0')
        if [[ -z "$newest" ]] || (( mtime >= newest_mtime )); then
            newest="$path"
            newest_mtime=$mtime
        fi
    done

    if [[ -n "$newest" ]]; then
        basename "$newest"
        return 0
    fi
    return 1
}

for _ in $(seq 1 $((WAIT_SECONDS * 10))); do
    if WAYLAND_DISPLAY_SELECTED=$(select_display); then
        export WAYLAND_DISPLAY="$WAYLAND_DISPLAY_SELECTED"
        printf '[awww-overview-daemon] using WAYLAND_DISPLAY=%s\n' "$WAYLAND_DISPLAY" >&2
        exec /usr/bin/awww-daemon -n overview
    fi
    sleep 0.1
done

echo "[awww-overview-daemon] no Wayland socket found in $RUNTIME_DIR" >&2
exit 1
