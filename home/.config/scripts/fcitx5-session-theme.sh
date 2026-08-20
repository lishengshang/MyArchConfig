#!/usr/bin/env bash
# Select the Fcitx5 ClassicUI theme for the current desktop session.
# The active classicui.conf is intentionally runtime-generated and ignored by
# Stow; the two source profiles remain tracked in the dotfiles repository.
set -Eeuo pipefail

session="${1:-}"
case "$session" in
    niri) profile="$HOME/.config/fcitx5/conf/classicui-niri.conf" ;;
    kde) profile="$HOME/.config/fcitx5/conf/classicui-kde.conf" ;;
    *)
        echo "用法: $0 niri|kde" >&2
        exit 2
        ;;
esac

[[ -r "$profile" ]] || { echo "Fcitx5 profile not found: $profile" >&2; exit 1; }

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/fcitx5/conf"
target="$config_dir/classicui.conf"
tmp="$config_dir/.classicui.conf.tmp.$$"
mkdir -p "$config_dir"

if [[ ! -f "$target" ]] || ! cmp -s "$profile" "$target"; then
    install -m 600 -- "$profile" "$tmp"
    mv -f -- "$tmp" "$target"
fi

fcitx5-remote -r >/dev/null 2>&1 || true
printf 'Fcitx5 session theme profile: %s\n' "$session"
