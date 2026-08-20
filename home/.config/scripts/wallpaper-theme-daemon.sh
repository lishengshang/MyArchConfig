#!/usr/bin/env bash
# Resident wallpaper/theme worker. Requests are written atomically by
# wallpaper-post-command.sh; this process coalesces bursts and handles only
# the newest request.
set -Eeuo pipefail

MATUGEN_UPDATE="$HOME/.config/scripts/matugen-update.sh"
BLUR_UPDATE="$HOME/.config/scripts/niri_set_overview_blur_dark_bg.sh"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
REQUEST_DIR="$RUNTIME_DIR/wallpaper-theme"
REQUEST_FILE="$REQUEST_DIR/request"

# The unit may be enabled globally because the user manager lingers.  Do not
# keep a Niri-only worker alive in KDE or another desktop session.
if ! pgrep -u "${UID:-$(id -u)}" -x niri >/dev/null 2>&1; then
    exit 0
fi

mkdir -p "$REQUEST_DIR"

process_request() {
    local force wallpaper
    [[ -r "$REQUEST_FILE" ]] || return 0
    {
        IFS= read -r force || true
        IFS= read -r wallpaper || true
    } < "$REQUEST_FILE"

    if [[ "$force" == force ]]; then
        if [[ -n "$wallpaper" ]]; then
            "$MATUGEN_UPDATE" -f "$wallpaper" >/dev/null 2>&1 || true
        else
            "$MATUGEN_UPDATE" -f >/dev/null 2>&1 || true
        fi
    else
        if [[ -n "$wallpaper" ]]; then
            "$MATUGEN_UPDATE" "$wallpaper" >/dev/null 2>&1 || true
        else
            "$MATUGEN_UPDATE" >/dev/null 2>&1 || true
        fi
    fi

    # 模糊背景属于非关键任务，放在主题生成之后，并继承 systemd 的低资源权重。
    "$BLUR_UPDATE" >/dev/null 2>&1 || true
}

last_request=""
while :; do
    current_request=$(cat "$REQUEST_FILE" 2>/dev/null || true)
    if [[ -n "$current_request" && "$current_request" != "$last_request" ]]; then
        process_request
        last_request="$current_request"
        # 如果处理期间又来了新请求，立即进入下一轮；否则等待文件事件。
        continue
    fi

    # 监听目录而不是文件，兼容请求文件的原子替换。
    inotifywait -q -e create,close_write,moved_to "$REQUEST_DIR" >/dev/null 2>&1 || sleep 1
done
