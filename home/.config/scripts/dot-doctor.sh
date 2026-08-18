#!/usr/bin/env bash
# dot-doctor.sh - 检查 dotfiles 部署、核心依赖和关键运行时状态。
set -uo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
ERRORS=0
WARNINGS=0

ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ⚠ %s\n' "$*"; WARNINGS=$((WARNINGS + 1)); }
fail() { printf '  ✗ %s\n' "$*" >&2; ERRORS=$((ERRORS + 1)); }
section() { printf '\n== %s ==\n' "$*"; }

check_command() {
    local command_name="$1"
    local required="${2:-required}"
    if command -v "$command_name" >/dev/null 2>&1; then
        ok "$command_name: $(command -v "$command_name")"
    elif [[ "$required" == optional ]]; then
        warn "$command_name 未安装（对应功能不可用）"
    else
        fail "$command_name 未安装"
    fi
}

check_link() {
    local target="$1"
    local expected="$2"
    if [[ ! -e "$target" && ! -L "$target" ]]; then
        fail "缺少部署文件: $target"
        return
    fi
    if [[ "$(readlink -f "$target" 2>/dev/null || true)" == "$(readlink -f "$expected" 2>/dev/null || true)" ]]; then
        ok "Stow 链接: $target"
    else
        warn "不是预期的 Stow 链接: $target"
    fi
}

section "仓库"
if [[ -d "$DOTFILES_DIR/.git" ]]; then
    ok "Git 仓库: $DOTFILES_DIR"
    if [[ -n "$(git -C "$DOTFILES_DIR" status --porcelain 2>/dev/null)" ]]; then
        warn "工作区存在未提交修改"
    else
        ok "工作区干净"
    fi
else
    fail "不是 Git 仓库或目录不存在: $DOTFILES_DIR"
fi

section "核心命令"
for command_name in git stow zsh fish mise niri waybar fuzzel; do
    check_command "$command_name"
done

section "可选功能依赖"
for command_name in matugen waypaper awww wl-paste wl-copy cliphist ddcutil pactl hyprlock \
                   swayidle wl-screenrec grim slurp satty notify-send carapace atuin direnv \
                   niri-sidebar nirinit niriusd; do
    check_command "$command_name" optional
done

section "关键 Stow 链接"
check_link "$HOME/.zshenv" "$DOTFILES_DIR/home/.zshenv"
check_link "$HOME/.config/niri/config.kdl" "$DOTFILES_DIR/home/.config/niri/config.kdl"
check_link "$HOME/.config/waybar/config.jsonc" "$DOTFILES_DIR/home/.config/waybar/config.jsonc"
check_link "$HOME/.config/systemd/user/dotfiles-autocommit.timer" \
           "$DOTFILES_DIR/home/.config/systemd/user/dotfiles-autocommit.timer"

section "生成文件边界"
if git -C "$DOTFILES_DIR" check-ignore -q home/.config/fish/fish_variables; then
    ok "fish_variables 已忽略"
else
    fail "fish_variables 未被忽略"
fi
if git -C "$DOTFILES_DIR" check-ignore -q home/.config/niri/colors.kdl; then
    ok "Matugen colors.kdl 已忽略"
else
    fail "Matugen colors.kdl 未被忽略"
fi
if git -C "$DOTFILES_DIR" check-ignore -q home/.config/Code/User/settings.json; then
    ok "VS Code 动态 settings.json 已忽略"
else
    fail "VS Code 动态 settings.json 未被忽略"
fi

section "Fish 运行时补全"
GENERATED_COMPLETIONS="${XDG_DATA_HOME:-$HOME/.local/share}/fish/generated-completions"
if [[ -d "$GENERATED_COMPLETIONS" ]]; then
    ok "生成补全目录: $GENERATED_COMPLETIONS"
else
    warn "生成补全目录不存在（首次运行 fish-update-completions 后创建）"
fi

section "外部 user service"
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    if systemctl --user list-unit-files 2>/dev/null | grep -q '^clipsync-git\.service'; then
        ok "clipsync-git.service 已安装"
    else
        warn "clipsync-git.service 未安装（Waybar 剪贴板同步按钮不可用）"
    fi
else
    warn "user systemd manager 不可用，跳过外部 service 检查"
fi

section "Systemd user units"
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    for unit in dotfiles-autocommit.timer random-api-wallpaper.timer awww-overview-daemon.service swayidle.service; do
        if systemctl --user is-enabled "$unit" >/dev/null 2>&1; then
            ok "$unit 已启用"
        else
            warn "$unit 未启用"
        fi
    done
else
    warn "user systemd manager 不可用，跳过 unit 检查"
fi

section "Niri 配置"
if command -v niri >/dev/null 2>&1 && [[ -f "$HOME/.config/niri/config.kdl" ]]; then
    if niri validate -c "$HOME/.config/niri/config.kdl" >/dev/null 2>&1; then
        ok "Niri 配置有效"
    else
        fail "Niri 配置验证失败"
    fi
else
    warn "niri 或配置不存在，跳过验证"
fi

printf '\n总结: %d 个错误, %d 个警告\n' "$ERRORS" "$WARNINGS"
(( ERRORS == 0 ))
