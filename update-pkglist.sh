#!/usr/bin/env bash
# =============================================================================
# update-pkglist.sh - 重新生成 pacman 包列表
# =============================================================================
# 用法:
#   bash ~/dotfiles/update-pkglist.sh
#
# 生成:
#   pkglist.txt         - 显式安装的原生包（pacman -Qqen）
#   foreign-pkglist.txt - 显式安装的 AUR/外部包（pacman -Qqem）
#
# 建议时机:
#   - 装了新软件后
#   - 升级大版本前
#   - 每月一次（可挂 systemd user timer）
# =============================================================================
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
cd "$DOTFILES_DIR"

if ! command -v pacman >/dev/null; then
    echo "错误: pacman 不存在，只能在 Arch 系发行版上运行" >&2
    exit 1
fi

pacman -Qqen > pkglist.txt
pacman -Qqem > foreign-pkglist.txt

echo "✓ 生成完成:"
echo "    pkglist.txt         ($(wc -l < pkglist.txt) 个原生包)"
echo "    foreign-pkglist.txt ($(wc -l < foreign-pkglist.txt) 个 AUR 包)"
echo
echo "如果要把变更提交到 dotfiles:"
echo "    git -C ~/dotfiles add pkglist.txt foreign-pkglist.txt"
echo "    git -C ~/dotfiles commit -m 'update pkglist'"
echo "    git -C ~/dotfiles push"