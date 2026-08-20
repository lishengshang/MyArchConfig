#!/usr/bin/env bash
# Clipboard history UI with pinned entries and confirmation before deletion.
# Pins store only cliphist IDs, not another copy of the clipboard contents.
set -Eeuo pipefail

ENABLE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/niri/clipboard-history.enabled"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/cliphist"
PIN_FILE="$STATE_DIR/pinned.ids"

if [[ ! -e "$ENABLE_FILE" ]]; then
    notify-send "剪贴板历史已关闭" "创建 ~/.config/niri/clipboard-history.enabled 后再使用" 2>/dev/null || true
    exit 0
fi

for command_name in cliphist fzf fuzzel wl-copy; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        notify-send -u critical "剪贴板历史" "缺少命令: $command_name" 2>/dev/null || true
        exit 1
    fi
done

mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"
touch "$PIN_FILE"
chmod 600 "$PIN_FILE"

is_pinned() {
    grep -Fqx -- "$1" "$PIN_FILE"
}

toggle_pin() {
    local id="$1" tmp
    tmp=$(mktemp "$STATE_DIR/pinned.ids.XXXXXX")
    if is_pinned "$id"; then
        grep -Fxv -- "$id" "$PIN_FILE" >"$tmp" || true
        notify-send "剪贴板" "已取消固定第 $id 条记录" 2>/dev/null || true
    else
        cat "$PIN_FILE" >"$tmp"
        printf '%s\n' "$id" >>"$tmp"
        notify-send "剪贴板" "已固定第 $id 条记录" 2>/dev/null || true
    fi
    sort -n -u "$tmp" >"$PIN_FILE"
    rm -f -- "$tmp"
}

confirm() {
    local prompt="$1" choice
    choice=$(printf '%s\n' '取消' '确认' | fuzzel --dmenu --lines 2 --width 18 --prompt "$prompt " 2>/dev/null || true)
    [[ "$choice" == '确认' ]]
}

build_menu() {
    local id content
    # First pass: pinned items (★) at the top
    cliphist list | while IFS=$'\t' read -r id content; do
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        if is_pinned "$id"; then
            printf '★\t%s\t%s\n' "$id" "$content"
        fi
    done
    # Second pass: unpinned items below
    cliphist list | while IFS=$'\t' read -r id content; do
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        if ! is_pinned "$id"; then
            printf ' \t%s\t%s\n' "$id" "$content"
        fi
    done
}

while true; do
    selected=$(build_menu | fzf \
        --no-sort \
        --delimiter=$'\t' \
        --with-nth='1,3..' \
        --tabstop=1 \
        --height=100% \
        --layout=reverse \
        --border \
        --prompt='剪贴板> ' \
        --header=$'Enter/^F 粘贴 · ^P 固定 · ^X 删除\nAlt-X 清空 · ^R 刷新' \
        --expect=ctrl-p,ctrl-x,alt-x,ctrl-r,ctrl-f \
        2>/dev/null || true)

    [[ -n "$selected" ]] || exit 0

    action=$(printf '%s\n' "$selected" | head -n1)
    row=$(printf '%s\n' "$selected" | tail -n +2)
    [[ -n "$row" ]] || exit 0

    id=$(printf '%s\n' "$row" | cut -f2)
    preview=$(printf '%s\n' "$row" | cut -f3-)
    [[ "$id" =~ ^[0-9]+$ ]] || continue
    original=$(printf '%s\t%s\n' "$id" "$preview")

    case "$action" in
        ctrl-r)
            continue
            ;;
        ctrl-p)
            toggle_pin "$id"
            ;;
        ctrl-x)
            if is_pinned "$id"; then
                if confirm "确认删除第 $id 条（星标）？"; then
                    printf '%s\n' "$original" | cliphist delete >/dev/null
                    sed -i -E "/^${id}$/d" "$PIN_FILE"
                fi
            else
                printf '%s\n' "$original" | cliphist delete >/dev/null
            fi
            ;;
        alt-x)
            if confirm "确认清空全部剪贴板历史？"; then
                cliphist wipe >/dev/null
                : >"$PIN_FILE"
                notify-send "剪贴板" "历史已清空" 2>/dev/null || true
                exit 0
            fi
            ;;
        *)
            # Enter and Ctrl-F both paste the selected full cliphist record.
            printf '%s\n' "$original" | cliphist decode | wl-copy 2>/dev/null
            exit 0
            ;;
    esac
done
