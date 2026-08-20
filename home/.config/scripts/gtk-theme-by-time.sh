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

# Use GNOME's Adwaita icon set for GTK applications such as Nautilus.
# Waybar is launched with its own dark GTK theme and does not need Breeze icons.
for key in color-scheme gtk-theme; do
    gsettings writable org.gnome.desktop.interface "$key" >/dev/null
done

gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
# Keep Matugen's completed Adwaita-derived icon theme across the day/night
# GTK switch. Fall back to plain Adwaita before the first color generation.
current_icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")
if [[ "$current_icon_theme" != Adwaita-Matugen-* ]]; then
    gsettings set org.gnome.desktop.interface icon-theme Adwaita
fi
fcitx5-remote -r >/dev/null 2>&1 || true

printf 'GTK theme: %s (mode=%s, hour=%02d)\n' "$gtk_theme" "$mode" "$hour"
