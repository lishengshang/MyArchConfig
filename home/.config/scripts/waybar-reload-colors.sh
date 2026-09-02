#!/usr/bin/env bash
#
# waybar-reload-colors.sh — 生成 waybar 运行时样式表, 触发热重载。
#
# 功能: 把 colors.css 前置拼接进 style.css (剔除其中的 @import 行),
#   生成自包含的 style.runtime.css。waybar 以 `-s style.runtime.css` 启动
#   且开启 reload_style_on_change 时, 同 inode 原地写入会自动热重载。
# 依赖: sed/cat；waybar 需以 -s 指向本脚本生成的 runtime 文件 (隐式契约)。
# 调用方: matugen config.toml post_hook、niri 会话启动、Mod+F2/Mod+F4 共 4 处，
#   可并发触发，故用 flock 串行化写入 (仍保持同 inode 原地写, 不能用 rename)。
#
# Build Waybar's runtime stylesheet and let `reload_style_on_change` pick it up.
#
# Why: Waybar watches the stylesheet passed with `-s`, but style.css is a Stow
# symlink and `@import "colors.css"` is not re-read by SIGUSR2.  In-place writes
# to a real runtime file (not a rename, and not touch) reliably trigger a hot
# style reload with no cold restart and no visible disappearance.
set -Eeuo pipefail

BASE_DIR="$HOME/.config/waybar"
COLORS="$BASE_DIR/colors.css"
TEMPLATE="$BASE_DIR/style.css"
RUNTIME="$BASE_DIR/style.runtime.css"

[[ -f "$COLORS" ]] || { echo "waybar colors.css missing" >&2; exit 1; }
[[ -f "$TEMPLATE" ]] || { echo "waybar style.css missing" >&2; exit 1; }

# 并发防护: matugen post_hook 与 Mod+F2/F4 可能同时触发; 两个进程同时从
# offset 0 覆盖写时, 若 colors.css 在两实例读取之间被更新会拼出不一致内容。
# flock 串行化写入; 写入方式保持同 inode 重定向 (rename 换 inode 不触发热重载)。
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-reload-colors-${UID:-$(id -u)}.lock"
exec 9>"$LOCK_FILE"
flock 9

# colors.css is prepended and the template's own @import is dropped so the
# generated file is self-contained (no relative-import/symlink surprises).
{
    cat "$COLORS"
    sed '/^@import[[:space:]]\+"colors.css";[[:space:]]*$/d' "$TEMPLATE"
} > "$RUNTIME"

# If waybar was started with the runtime stylesheet, `reload_style_on_change`
# reloads it automatically after this same-inode write.
