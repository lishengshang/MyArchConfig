#!/usr/bin/env bash
# Generate independent light/dark Fcitx5 themes from the current wallpaper.
# This deliberately uses a minimal Matugen config so Waybar and other targets
# are not regenerated a second time just to switch Fcitx5's appearance.
set -Eeuo pipefail

WALLPAPER="${1:-$HOME/.cache/.current_wallpaper}"
SOURCE_INDEX="${2:-0}"
STRATEGY="${3:-scheme-tonal-spot}"
TEMPLATE="$HOME/.config/matugen/templates/fcitx5-theme.conf"
OUTPUT_ROOT="$HOME/.local/share/fcitx5/themes"

[[ -f "$WALLPAPER" ]] || { echo "Fcitx5 theme: wallpaper not found: $WALLPAPER" >&2; exit 1; }
[[ -f "$TEMPLATE" ]] || { echo "Fcitx5 theme template not found: $TEMPLATE" >&2; exit 1; }
[[ "$SOURCE_INDEX" =~ ^[0-4]$ ]] || SOURCE_INDEX=0

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/matugen-fcitx5.XXXXXX")
trap 'rm -rf -- "$TMP_DIR"' EXIT

for mode in light dark; do
    output_dir="$OUTPUT_ROOT/Matugen-${mode^}"
    mkdir -p "$output_dir"
    config="$TMP_DIR/$mode.toml"
    cat >"$config" <<EOF
[config]
reload_apps = false

[templates.fcitx5]
input_path = "$TEMPLATE"
output_path = "$output_dir/theme.conf"
EOF

    matugen image "$WALLPAPER" \
        --config "$config" \
        --type "$STRATEGY" \
        --mode "$mode" \
        --source-color-index "$SOURCE_INDEX" \
        --quiet
    sed -i "0,/^Name=Matugen$/s//Name=Matugen-${mode^}/" "$output_dir/theme.conf"
done
