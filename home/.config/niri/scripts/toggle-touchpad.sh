#!/usr/bin/env bash
#
# toggle-touchpad.sh — 运行时切换 niri 触控板禁用状态
#
# 原理：翻转 config.kdl 中 touchpad 段的 `off` 配置。
# niri 监听配置文件变化并 live-reload，保存后立即生效：无需 sudo、无需重启。
# readlink -f 解析 symlink 指向的真实文件（dotfiles 部署），避免破坏 symlink。
#
# 依赖：niri 配置里 touchpad 段存在一行 `// off`（默认注释 = 触控板启用）

set -euo pipefail

CONFIG="$HOME/.config/niri/config.kdl"
REAL_CONFIG="$(readlink -f "$CONFIG")"

[[ -f "$REAL_CONFIG" ]] || { echo "配置文件不存在: $REAL_CONFIG" >&2; exit 1; }

# 检测：touchpad 段内 `off` 或 `disabled-on-external-mouse` 任一未注释 → 视为禁用中
if sed -n '/[[:space:]]*touchpad [{]/,/^[[:space:]]*}/p' "$REAL_CONFIG" \
   | grep -qE '^[[:space:]]*(off|disabled-on-external-mouse)([[:space:]]|$)'; then
    # 禁用中 → 启用：两个开关都注释掉
    sed -i -E '/[[:space:]]*touchpad [{]/,/^[[:space:]]*}/ s#^([[:space:]]*)(off|disabled-on-external-mouse)([[:space:]]*//.*)?$#\1// \2\3#' "$REAL_CONFIG"
    MSG="已启用"
else
    # 启用中 → 禁用：两个开关都取消注释
    sed -i -E '/[[:space:]]*touchpad [{]/,/^[[:space:]]*}/ s#^([[:space:]]*)// (off|disabled-on-external-mouse)([[:space:]]*//.*)?$#\1\2\3#' "$REAL_CONFIG"
    MSG="已禁用"
fi

notify-send "触控板" "$MSG" -t 1000 2>/dev/null || true
echo "触控板 $MSG（$REAL_CONFIG 已更新，niri 自动生效）"
