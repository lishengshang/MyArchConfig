#!/bin/bash
# Mod+Esc: 如果聚焦窗口是浮动的就关闭它
FOCUSED=$(niri msg focused-window 2>/dev/null)
if echo "$FOCUSED" | grep -q "Is floating: yes"; then
    niri msg action close-window
fi
