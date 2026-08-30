#!/usr/bin/env bash
# wallpaper-lib.sh — Niri 壁纸脚本公共库。
# 由 random-anime-wallpaper.sh（下载）与 random-api-wallpaper.sh（本地随机）
# source 复用，统一锁、通知、waypaper 记录同步与主题后处理触发。
# 仅定义函数与常量，source 时无副作用。

WALLPAPER_WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"

# 单实例锁: timer 与快捷键并发触发时防互踩。
# flock + 用户 runtime 目录，进程退出自动释放，无残留锁问题（占用 fd 9）。
# 用法: wallpaper_lock_acquire <name> || exit 0
wallpaper_lock_acquire() {
    local lock_root="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
    [[ -d "$lock_root" ]] || lock_root=/tmp
    exec 9>"$lock_root/wallpaper-$1-${UID:-$(id -u)}.lock"
    flock -n 9
}

# 通知封装: 设 WALLPAPER_SILENT=true 时静默; 其余参数透传 notify-send
wallpaper_notify() {
    [ "${WALLPAPER_SILENT:-false}" = true ] && return 0
    local title="$1" body="$2"
    shift 2
    notify-send "$title" "$body" "$@" 2>/dev/null
}

# 读取 waypaper 记录的当前壁纸（展开 ~ 并规范化路径），无记录时输出空串
wallpaper_current() {
    [ -f "$WALLPAPER_WAYPAPER_CONFIG" ] || return 0
    local cur
    cur=$(sed -n 's/^wallpaper[[:space:]]*=[[:space:]]*//p' "$WALLPAPER_WAYPAPER_CONFIG" | head -n1)
    cur="${cur/#\~/$HOME}"
    [ -z "$cur" ] && return 0
    realpath "$cur" 2>/dev/null || printf '%s' "$cur"
}

# 同步壁纸路径到 waypaper 配置（脚本绕过 waypaper 直接调用 awww 时，
# waypaper GUI / fallback 分支才能读到正确路径）。路径转 ~ 形式并转义 sed 特殊字符。
wallpaper_sync_waypaper() {
    [ -f "$WALLPAPER_WAYPAPER_CONFIG" ] || return 0
    local tilde="${1/#$HOME/\~}"
    local escaped
    escaped=$(printf '%s' "$tilde" | sed 's/[&|\\]/\\&/g')
    sed -i "s|^wallpaper[[:space:]]*=.*|wallpaper = $escaped|" "$WALLPAPER_WAYPAPER_CONFIG"
}

# 触发主题后处理（matugen 取色 / 模糊背景）。
# 本脚本只写一个请求文件，真正的重活由常驻的 wallpaper-theme.service 执行。
# 必须同步前台调用: 若从 Type=oneshot 的 systemd service（如 random-api-wallpaper.timer）
# 内 nohup & 异步拉起，主脚本退出时子进程会被 KillMode=control-group 连坐杀掉，
# 请求文件写不进去，导致 overview 模糊背景与主题停留在旧壁纸。
wallpaper_run_post_command() {
    local post="$HOME/.config/scripts/wallpaper-post-command.sh"
    [ -x "$post" ] && "$post" >/dev/null 2>&1 || true
}
