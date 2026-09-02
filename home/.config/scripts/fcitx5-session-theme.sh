#!/usr/bin/env bash
#
# fcitx5-session-theme.sh — 按会话类型选择 Fcitx5 ClassicUI 主题。
#
# 功能: 把对应会话的 classicui-{niri,kde}.conf 原子安装为运行时
#   classicui.conf，仅在内容变化时重启 fcitx5 生效。
# 用法: $0 niri|kde   (niri 会话启动 / stop-niri-session-services.sh 切 KDE 时调用)
# 依赖: install、cmp、fcitx5-remote
# 说明: 运行时 classicui.conf 有意由本脚本生成并被 Stow 忽略，
#   两份源 profile 保留在 dotfiles 仓库中。
#
# Select the Fcitx5 ClassicUI theme for the current desktop session.
set -Eeuo pipefail

session="${1:-}"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/fcitx5/conf"
case "$session" in
    niri) profile="$config_dir/classicui-niri.conf" ;;
    kde) profile="$config_dir/classicui-kde.conf" ;;
    *)
        echo "用法: $0 niri|kde" >&2
        exit 2
        ;;
esac

[[ -r "$profile" ]] || { echo "Fcitx5 profile not found: $profile" >&2; exit 1; }

target="$config_dir/classicui.conf"
tmp="$config_dir/.classicui.conf.tmp.$$"
# 异常退出时清理临时文件, 不在配置目录留残留
trap 'rm -f -- "$tmp"' EXIT
mkdir -p "$config_dir"

if [[ ! -f "$target" ]] || ! cmp -s "$profile" "$target"; then
    install -m 600 -- "$profile" "$tmp"
    mv -f -- "$tmp" "$target"
    # 仅在实际变更时重启: 会话启动反复调用时避免无谓重启输入法进程。
    # fcitx5 未运行时 -r 失败被静默，主题在下次启动时自然生效。
    fcitx5-remote -r >/dev/null 2>&1 || true
fi

printf 'Fcitx5 session theme profile: %s\n' "$session"
