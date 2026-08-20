#!/usr/bin/env bash
# Submit a wallpaper/theme update to the resident user service.  Waypaper's
# post_command must return immediately; the service performs all heavy work.
set -Eeuo pipefail

WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
REQUEST_DIR="$RUNTIME_DIR/wallpaper-theme"
REQUEST_FILE="$REQUEST_DIR/request"
FORCE=false

if [[ "${1:-}" == "--force" ]]; then
    FORCE=true
fi

wallpaper=""
if [[ -f "$WAYPAPER_CONFIG" ]]; then
    wallpaper=$(sed -n 's/^wallpaper[[:space:]]*=[[:space:]]*//p' "$WAYPAPER_CONFIG" | head -n1)
    wallpaper="${wallpaper/#\~/$HOME}"
    [[ -f "$wallpaper" ]] || wallpaper=""
fi

mkdir -p "$REQUEST_DIR"
tmp_file="$REQUEST_FILE.tmp.$$"
{
    if [[ "$FORCE" == true ]]; then
        printf 'force\n'
    else
        printf 'normal\n'
    fi
    printf '%s\n' "$wallpaper"
} > "$tmp_file"
mv -f -- "$tmp_file" "$REQUEST_FILE"
