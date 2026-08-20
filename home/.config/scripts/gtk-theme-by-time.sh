#!/usr/bin/env bash
# Switch GTK/GNOME appearance by local wall clock.
# This intentionally uses GSettings instead of editing Stow-managed gtk settings.ini,
# so KDE/Qt settings and the dotfiles repository are not modified.
set -Eeuo pipefail

# GTK theme scheduling belongs to the Niri session. KDE owns its own GTK
# appearance policy; do not overwrite it when the lingered user manager remains.
if ! pgrep -u "${UID:-$(id -u)}" -x niri >/dev/null 2>&1; then
    printf 'Niri is not running; leave the current GTK theme unchanged.\n'
    exit 0
fi

hour=$(date +%H)
hour=$((10#$hour))

if (( hour >= 18 || hour < 7 )); then
    mode=dark
    color_scheme=prefer-dark
    gtk_theme=Breeze-Dark
    icon_theme=breeze-dark
else
    mode=light
    color_scheme=prefer-light
    gtk_theme=Breeze
    icon_theme=breeze
fi

for key in color-scheme gtk-theme icon-theme; do
    gsettings writable org.gnome.desktop.interface "$key" >/dev/null
done

gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
fcitx5-remote -r >/dev/null 2>&1 || true

printf 'GTK theme: %s (mode=%s, hour=%02d)\n' "$gtk_theme" "$mode" "$hour"
