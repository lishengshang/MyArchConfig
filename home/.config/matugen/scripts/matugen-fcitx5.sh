#!/usr/bin/env bash
# Generate independent light/dark Fcitx5 themes from the current wallpaper.
# This deliberately uses a minimal Matugen config so Waybar and other targets
# are not regenerated a second time just to switch Fcitx5's appearance.
set -Eeuo pipefail

WALLPAPER="${1:-$HOME/.cache/.current_wallpaper}"
SOURCE_INDEX="${2:-0}"
STRATEGY="${3:-scheme-tonal-spot}"
PALETTE_FILE="${4:-}"
ACTIVE_MODE="${5:-dark}"
[[ "$ACTIVE_MODE" == light || "$ACTIVE_MODE" == dark ]] || ACTIVE_MODE=dark
TEMPLATE="$HOME/.config/matugen/templates/fcitx5-theme.conf"
OUTPUT_ROOT="$HOME/.local/share/fcitx5/themes"

[[ -f "$WALLPAPER" ]] || { echo "Fcitx5 theme: wallpaper not found: $WALLPAPER" >&2; exit 1; }
[[ -f "$TEMPLATE" ]] || { echo "Fcitx5 theme template not found: $TEMPLATE" >&2; exit 1; }
[[ "$SOURCE_INDEX" =~ ^[0-4]$ ]] || SOURCE_INDEX=0

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/matugen-fcitx5.XXXXXX")
trap 'rm -rf -- "$TMP_DIR"' EXIT

if [[ "$ACTIVE_MODE" == dark ]]; then
    MODES=(dark light)
else
    MODES=(light dark)
fi

for mode in "${MODES[@]}"; do
    output_dir="$OUTPUT_ROOT/Matugen-${mode^}"
    mkdir -p "$output_dir"
    config="$TMP_DIR/$mode.toml"

    # The template uses `.default.hex`, which always resolves to the dark
    # variant regardless of --mode.  Bind each field to the explicit mode
    # variant so Matugen-Light and Matugen-Dark actually differ.
    mode_template="$TMP_DIR/fcitx5-$mode.conf"
    sed "s/\.default\.hex/."${mode}".hex/g" "$TEMPLATE" > "$mode_template"

    cat >"$config" <<EOF
[config]
reload_apps = false

[templates.fcitx5]
input_path = "$mode_template"
output_path = "$output_dir/theme.conf"
EOF

    if [[ -n "$PALETTE_FILE" && -f "$PALETTE_FILE" ]]; then
        matugen json "$PALETTE_FILE" \
            --config "$config" \
            --type "$STRATEGY" \
            --mode "$mode" \
            --quiet
    else
        matugen image "$WALLPAPER" \
            --config "$config" \
            --type "$STRATEGY" \
            --mode "$mode" \
            --source-color-index "$SOURCE_INDEX" \
            --quiet
    fi
    sed -i "0,/^Name=Matugen$/s//Name=Matugen-${mode^}/" "$output_dir/theme.conf"

    # Reload as soon as the currently visible mode is ready. The other mode is
    # generated afterward for the next day/night switch.
    if [[ "$mode" == "$ACTIVE_MODE" ]]; then
        fcitx5-remote -r >/dev/null 2>&1 || true
    fi
done
