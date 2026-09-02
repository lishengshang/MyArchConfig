#!/usr/bin/env bash
#
# gtk-theme-by-time.sh — 按本地时钟切换 GTK 明暗主题 (18:00-07:00 为暗)。
#
# 功能: 通过 gsettings 切换 color-scheme/gtk-theme，并保护 Matugen 生成的
#   Adwaita-Matugen-* 图标主题；有实际变更时才重启 fcitx5 刷新输入法外观。
# 依赖: gsettings、fcitx5-remote、pgrep；GTK3 Adwaita 主题可选 (缺失时回退 Breeze)。
# 调用方: gtk-theme-by-time.timer (每天 07:00/18:00)。
# 说明: 有意用 gsettings 而非改 Stow 管理的 settings.ini，不碰仓库与 KDE/Qt 配置；
#   gtk-theme 由本脚本独占管理 (matugen-update.sh 只生成 CSS 颜色, 不写 gtk-theme)。
#
# Switch GTK/GNOME appearance by local wall clock.
set -Eeuo pipefail

# GTK theme scheduling belongs to the Niri session. KDE owns its own GTK
# appearance policy; do not overwrite it when the lingered user manager remains.
if ! pgrep -u "${UID:-$(id -u)}" -x niri >/dev/null 2>&1; then
    printf 'Niri is not running; leave the current GTK theme unchanged.\n'
    exit 0
fi

hour=$(date +%H)
hour=$((10#$hour))

# Adwaita icons are installed by default. The GTK3 Adwaita port is optional;
# use it when present and keep a valid Breeze fallback until it is installed.
if [[ -d /usr/share/themes/adw-gtk3 ]]; then
    GTK_LIGHT_THEME=adw-gtk3
    GTK_DARK_THEME=adw-gtk3-dark
else
    GTK_LIGHT_THEME=Breeze
    GTK_DARK_THEME=Breeze-Dark
fi

if (( hour >= 18 || hour < 7 )); then
    mode=dark
    color_scheme=prefer-dark
    gtk_theme="$GTK_DARK_THEME"
else
    mode=light
    color_scheme=prefer-light
    gtk_theme="$GTK_LIGHT_THEME"
fi

# 可写性检查: `gsettings writable` 无论可写与否退出码都是 0, 必须看输出文本;
# 不可写 (schema 缺失等) 时直接退出, 避免后面的 `set` 在 set -e 下裸崩。
for key in color-scheme gtk-theme; do
    if [[ "$(gsettings writable org.gnome.desktop.interface "$key")" != "true" ]]; then
        printf 'gsettings key %s not writable; abort.\n' "$key" >&2
        exit 1
    fi
done

# 幂等写入: 已是目标值则跳过, 全部无变更时不重启 fcitx5 (手动重复运行/
# timer 重复触发时避免无谓的输入法重启)。
changed=false
gset_if_changed() {
    local key="$1" value="$2" current
    current=$(gsettings get org.gnome.desktop.interface "$key" | tr -d "'")
    if [[ "$current" != "$value" ]]; then
        gsettings set org.gnome.desktop.interface "$key" "$value"
        changed=true
    fi
}

gset_if_changed color-scheme "$color_scheme"
gset_if_changed gtk-theme "$gtk_theme"
# Keep Matugen's completed Adwaita-derived icon theme across the day/night
# GTK switch. Fall back to plain Adwaita before the first color generation.
current_icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")
if [[ "$current_icon_theme" != Adwaita-Matugen-* ]]; then
    gsettings set org.gnome.desktop.interface icon-theme Adwaita
    changed=true
fi
# 仅在实际变更时刷新输入法外观; 未变更时跳过, 不白重启一次。
if [[ "$changed" == true ]]; then
    fcitx5-remote -r >/dev/null 2>&1 || true
fi

printf 'GTK theme: %s (mode=%s, hour=%02d, changed=%s)\n' "$gtk_theme" "$mode" "$hour" "$changed"
