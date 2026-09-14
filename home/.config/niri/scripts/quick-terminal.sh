#!/bin/bash
# Mod+/ 快速终端的单实例调度：已有 quickterminal 窗口则召回到当前工作区
# 并聚焦；没有才新开。修复连按 Mod+/ 开出一串 kitty 浮窗的问题。
# 浮窗样式（左上角定位）由 rule.kdl 的 window-rule 决定，字号/透明度在
# 下方 kitty 参数里，与原 binds.kdl 内联写法保持一致。

set -u

STATE="${XDG_RUNTIME_DIR:-/tmp}/niri-quickterminal.last"

focus_existing() {
    local win_id ws_ref
    win_id="$(niri msg --json windows |
        jq -r '[.[] | select(.app_id=="quickterminal")][0].id // empty')"
    [ -n "$win_id" ] || return 1

    # 召回到当前工作区（取焦点所在；无焦点窗口时为活动的那个）
    ws_ref="$(niri msg --json workspaces |
        jq -r '[.[] | select(.is_focused or .is_active)]
                | (first(.[] | select(.is_focused)) // .[0])
                | if (.name // "") != "" then .name else (.idx | tostring) end')"
    [ -n "$ws_ref" ] &&
        niri msg action move-window-to-workspace --window-id "$win_id" "$ws_ref"
    niri msg action focus-window --id "$win_id"
}

spawn_new() {
    # 连按防抖：上次启动 0.8s 内的再次按下直接忽略——新窗口要几百毫秒
    # 才注册到 niri，此窗口查会误判"不存在"导致重复开窗
    local now last
    now="$(date +%s%3N)"
    last="$(cat "$STATE" 2>/dev/null || echo 0)"
    [ "$((now - last))" -lt 800 ] && return 0
    echo "$now" > "$STATE"

    exec kitty --class quickterminal \
        -o font_size=10.0 \
        -o background_opacity=0.8
}

focus_existing || spawn_new
