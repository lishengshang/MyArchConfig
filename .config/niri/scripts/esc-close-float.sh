#!/usr/bin/env bash
# Mod+Esc: 如果聚焦窗口是浮动的就关闭它
# 用 niri 的 JSON 输出 + jq 提取 is_floating，避免依赖文本格式

niri msg --json focused-window 2>/dev/null \
    | jq -e '.is_floating' >/dev/null 2>&1 \
    && niri msg action close-window
