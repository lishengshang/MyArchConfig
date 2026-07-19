#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh - 在新机器上 clone dotfiles 后运行，安装依赖软件包
# =============================================================================
# 用法:
#   bash ~/.config/dotfiles/bootstrap.sh
#
# 做的事:
#   1. 用 pacman 安装 pkglist.txt 里的原生包
#   2. 用 paru/yay 安装 foreign-pkglist.txt 里的 AUR 包
#   3. 不强制覆盖已装包，pacman/paru 自己会跳过
#
# 注意: 这个脚本只装包，不动配置。配置由 setup.sh 通过 git checkout 完成。
# =============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGLIST="$DOTFILES_DIR/pkglist.txt"
FOREIGN_PKGLIST="$DOTFILES_DIR/foreign-pkglist.txt"

if [[ ! -r "$PKGLIST" ]]; then
    echo "错误: 找不到 $PKGLIST" >&2
    echo "请先在另一台已配置好的机器上运行:" >&2
    echo "    bash ~/.config/dotfiles/update-pkglist.sh" >&2
    exit 1
fi

# --- 1. 原生包 ---
echo "-> 安装 pacman 原生包 ($(wc -l < "$PKGLIST") 个) ..."
if command -v pacman >/dev/null; then
    sudo pacman -S --needed --noconfirm - < "$PKGLIST"
else
    echo "警告: pacman 不存在，跳过原生包安装" >&2
fi

# --- 2. AUR 包 ---
if [[ -r "$FOREIGN_PKGLIST" ]] && (( $(wc -l < "$FOREIGN_PKGLIST") > 0 )); then
    echo "-> 安装 AUR 包 ($(wc -l < "$FOREIGN_PKGLIST") 个) ..."
    if command -v paru >/dev/null; then
        paru -S --needed --noconfirm - < "$FOREIGN_PKGLIST"
    elif command -v yay >/dev/null; then
        yay -S --needed --noconfirm - < "$FOREIGN_PKGLIST"
    else
        echo "警告: paru/yay 都不存在，跳过 AUR 包安装" >&2
        echo "请手动安装以下 AUR 包:" >&2
        cat "$FOREIGN_PKGLIST" >&2
    fi
fi

echo
echo "✓ bootstrap 完成"
echo "下一步: exec zsh  重新加载 shell"
