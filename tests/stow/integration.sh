#!/usr/bin/env bash
# 验证 GNU Stow 可以在干净的临时 HOME 中部署和撤销 home/ 包。
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
TMP_HOME=$(mktemp -d)
trap 'rm -rf -- "$TMP_HOME"' EXIT

fail() {
    echo "STOW_FAIL: $*" >&2
    exit 1
}

assert_deployed() {
    local target="$1"
    local expected="$2"
    # Stow 可能把整个目录折叠为目录软链，因此目标文件本身不一定是软链。
    [[ -e "$target" || -L "$target" ]] || fail "部署文件不存在: $target"
    [[ "$(readlink -f "$target")" == "$(readlink -f "$expected")" ]] \
        || fail "部署目标错误: $target"
}

assert_absent() {
    local target="$1"
    [[ ! -e "$target" && ! -L "$target" ]] || fail "撤销后仍存在: $target"
}

command -v stow >/dev/null 2>&1 || fail "stow 未安装"

# 使用临时 HOME，绝不触碰当前用户的 ~/.config。
stow -d "$REPO_DIR" -t "$TMP_HOME" home

assert_deployed "$TMP_HOME/.zshenv" "$REPO_DIR/home/.zshenv"
assert_deployed "$TMP_HOME/.bashrc" "$REPO_DIR/home/.bashrc"
assert_deployed "$TMP_HOME/.bash_profile" "$REPO_DIR/home/.bash_profile"
assert_deployed "$TMP_HOME/.bash_logout" "$REPO_DIR/home/.bash_logout"
assert_deployed "$TMP_HOME/.config/niri/config.kdl" "$REPO_DIR/home/.config/niri/config.kdl"
assert_deployed "$TMP_HOME/.config/waybar/config.jsonc" "$REPO_DIR/home/.config/waybar/config.jsonc"
assert_deployed "$TMP_HOME/.config/Code/User/settings.base.json" \
            "$REPO_DIR/home/.config/Code/User/settings.base.json"
assert_deployed "$TMP_HOME/.config/systemd/user/dotfiles-autocommit.timer" \
            "$REPO_DIR/home/.config/systemd/user/dotfiles-autocommit.timer"

stow -d "$REPO_DIR" -t "$TMP_HOME" -D home

assert_absent "$TMP_HOME/.zshenv"
assert_absent "$TMP_HOME/.bashrc"
assert_absent "$TMP_HOME/.bash_profile"
assert_absent "$TMP_HOME/.bash_logout"
assert_absent "$TMP_HOME/.config/niri/config.kdl"
assert_absent "$TMP_HOME/.config/waybar/config.jsonc"
assert_absent "$TMP_HOME/.config/Code/User/settings.base.json"
assert_absent "$TMP_HOME/.config/systemd/user/dotfiles-autocommit.timer"

printf 'STOW_PASS: deploy and undeploy in temporary HOME\n'
