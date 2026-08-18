#!/usr/bin/env bash
# =============================================================================
# update-pkglist.sh - 重新生成当前机器的显式包列表
# =============================================================================
# 生成:
#   packages/pkglist.generated.txt         - 原生包（pacman -Qqen）
#   packages/foreign-pkglist.generated.txt - AUR/外部包（pacman -Qqem）
#
# 根目录的 pkglist.txt / foreign-pkglist.txt 是兼容旧命令的软链。
# 手工 profile 位于 packages/*.txt 和 packages/aur/*.txt，不会被覆盖。
# =============================================================================
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
PACKAGES_DIR="$DOTFILES_DIR/packages"
mkdir -p "$PACKAGES_DIR"
cd "$DOTFILES_DIR"

if ! command -v pacman >/dev/null; then
    echo "错误: pacman 不存在，只能在 Arch 系发行版上运行" >&2
    exit 1
fi

pacman -Qqen > "$PACKAGES_DIR/pkglist.generated.txt"
pacman -Qqem > "$PACKAGES_DIR/foreign-pkglist.generated.txt"

# 兼容旧文档和手动命令；如果用户误删软链，下次运行会恢复。
ln -sfn packages/pkglist.generated.txt pkglist.txt
ln -sfn packages/foreign-pkglist.generated.txt foreign-pkglist.txt

printf '✓ 生成完成:\n'
printf '    packages/pkglist.generated.txt         (%s 个原生包)\n' "$(wc -l < "$PACKAGES_DIR/pkglist.generated.txt")"
printf '    packages/foreign-pkglist.generated.txt (%s 个 AUR 包)\n' "$(wc -l < "$PACKAGES_DIR/foreign-pkglist.generated.txt")"
printf '\n手工 profile 不会被覆盖，可用 bootstrap.sh --profile 选择。\n'
printf '如果要提交包列表:\n'
printf '    git -C ~/dotfiles add packages pkglist.txt foreign-pkglist.txt\n'
printf "    git -C ~/dotfiles commit -m 'update generated package lists'\n"
printf '    git -C ~/dotfiles push\n'
