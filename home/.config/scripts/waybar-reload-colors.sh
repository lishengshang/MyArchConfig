#!/usr/bin/env bash
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

# colors.css is prepended and the template's own @import is dropped so the
# generated file is self-contained (no relative-import/symlink surprises).
{
    cat "$COLORS"
    sed '/^@import[[:space:]]\+"colors.css";[[:space:]]*$/d' "$TEMPLATE"
} > "$RUNTIME"

# If waybar was started with the runtime stylesheet, `reload_style_on_change`
# reloads it automatically after this same-inode write.
