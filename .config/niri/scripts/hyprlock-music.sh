#!/bin/bash
# hyprlock-music.sh - 找到正在播放的非浏览器播放器，输出其 metadata
# 排除：chromium, firefox, chrome, msedge, brave, plasma-browser-integration
# 没有播放器在播就输出 "♪ Not Playing"

for p in $(playerctl --list-all 2>/dev/null); do
    # 跳过浏览器类播放器（不展示浏览器标签页的媒体）
    case "$p" in
        chromium*|firefox*|chrome*|msedge*|brave*|plasma-browser-integration)
            continue
            ;;
    esac
    s=$(playerctl -p "$p" status 2>/dev/null)
    if [ "$s" = "Playing" ]; then
        out=$(playerctl -p "$p" metadata --format "♪ {{ album }} - {{ artist }} - {{ title }}" 2>/dev/null)
        [ -n "$out" ] && echo "$out" && exit 0
    fi
done

echo "♪ Not Playing"
