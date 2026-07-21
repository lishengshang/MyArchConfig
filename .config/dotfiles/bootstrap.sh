#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh - 在新机器上 clone dotfiles 后运行，安装依赖软件包
# =============================================================================
# 用法:
#   bash ~/.config/dotfiles/bootstrap.sh
#
# 选项:
#   --dry-run  只打印会装什么，不实际安装
#   -h, --help 显示帮助
#
# 做的事:
#   1. 用 pacman 安装 pkglist.txt 里的原生包
#   2. 用 paru/yay 安装 foreign-pkglist.txt 里的 AUR 包
#   3. 不强制覆盖已装包，pacman/paru 自己会跳过
#
# 注意: 这个脚本只装包，不动配置。配置由 setup.sh 通过 git checkout 完成。
# =============================================================================
set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            sed -n '2,22p' "$0"
            exit 0
            ;;
        *)
            echo "未知参数: $arg" >&2
            echo "用法: $0 [--dry-run]" >&2
            exit 1
            ;;
    esac
done

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGLIST="$DOTFILES_DIR/pkglist.txt"
FOREIGN_PKGLIST="$DOTFILES_DIR/foreign-pkglist.txt"

if [[ ! -r "$PKGLIST" ]]; then
    echo "错误: 找不到 $PKGLIST" >&2
    echo "请先在另一台已配置好的机器上运行:" >&2
    echo "    bash ~/.config/dotfiles/update-pkglist.sh" >&2
    exit 1
fi

if $DRY_RUN; then
    echo "=== [dry-run] 不实际安装，只显示会装什么 ==="
    echo
fi

# --- 1. 原生包 ---
echo "-> 安装 pacman 原生包 ($(wc -l < "$PKGLIST") 个) ..."
if $DRY_RUN; then
    echo "[dry-run] sudo pacman -S --needed --noconfirm - < $PKGLIST"
    echo "[dry-run] 包列表前 10 行:"
    head -n 10 "$PKGLIST" | sed 's/^/    /'
    local_count=$(wc -l < "$PKGLIST")
    (( local_count > 10 )) && echo "    ... (共 $local_count 个)"
elif command -v pacman >/dev/null; then
    sudo pacman -S --needed --noconfirm - < "$PKGLIST"
else
    echo "警告: pacman 不存在，跳过原生包安装" >&2
fi

# --- 2. AUR 包 ---
if [[ -r "$FOREIGN_PKGLIST" ]] && (( $(wc -l < "$FOREIGN_PKGLIST") > 0 )); then
    echo "-> 安装 AUR 包 ($(wc -l < "$FOREIGN_PKGLIST") 个) ..."
    if $DRY_RUN; then
        if command -v paru >/dev/null; then
            aur_helper="paru"
        elif command -v yay >/dev/null; then
            aur_helper="yay"
        else
            aur_helper="(未安装 paru/yay)"
        fi
        echo "[dry-run] $aur_helper -S --needed --noconfirm - < $FOREIGN_PKGLIST"
        echo "[dry-run] AUR 包列表前 10 行:"
        head -n 10 "$FOREIGN_PKGLIST" | sed 's/^/    /'
        foreign_count=$(wc -l < "$FOREIGN_PKGLIST")
        (( foreign_count > 10 )) && echo "    ... (共 $foreign_count 个)"
    elif command -v paru >/dev/null; then
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
if $DRY_RUN; then
    echo "=== [dry-run] 以上是会安装的包，实际未执行。去掉 --dry-run 真实安装。 ==="
else
    echo "✓ bootstrap 完成"
    echo "下一步: exec zsh  重新加载 shell"
fi
