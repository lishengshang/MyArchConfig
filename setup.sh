#!/usr/bin/env bash
# =============================================================================
# setup.sh - 在一台全新 Arch 机器上一键初始化 dotfiles（GNU Stow 方案）
# =============================================================================
# 用法（在新机器上执行）:
#   bash <(curl -fsSL https://raw.githubusercontent.com/lishengshang/MyArchConfig/main/setup.sh)
# 或者先 clone 下来再执行:
#   git clone https://github.com/lishengshang/MyArchConfig.git ~/dotfiles
#   bash ~/dotfiles/setup.sh
#
# 选项:
#   --dry-run  只打印会做什么，不实际执行（不 clone / 不 stow / 不装包）
#   -h, --help 显示帮助
#
# 这个脚本做五件事:
#   1. 确保 stow 已安装（没有则 pacman 装）
#   2. 把仓库 clone 到 ~/dotfiles（如果还没 clone）
#   3. 用 stow 把 home/ 包部署到 $HOME（创建软链）
#   4. 重生成 matugen 主题产物（colors.* 文件不进 git，换机器需重新生成）
#   5. 提示用户接下来运行 bootstrap.sh + 启用 systemd timer
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

# dry-run 时不让 set -e 把脚本搞挂：把真正会失败的命令包进 run 函数
if $DRY_RUN; then
    run() { echo "[dry-run] $*"; }
else
    run() { echo "-> $*"; "$@"; }
fi

REMOTE="https://github.com/lishengshang/MyArchConfig.git"
DOTFILES_DIR="$HOME/dotfiles"

# --- 1. 确保 stow 已安装 ---
if ! command -v stow &>/dev/null; then
    if $DRY_RUN; then
        echo "[dry-run] sudo pacman -S --needed --noconfirm stow"
    else
        echo "-> 安装 stow ..."
        sudo pacman -S --needed --noconfirm stow
        echo "✓ stow 已安装"
    fi
else
    echo "✓ stow 已存在，跳过安装"
fi

# --- 2. clone 仓库（如果不存在）---
if [[ ! -d "$DOTFILES_DIR" ]]; then
    if $DRY_RUN; then
        echo "[dry-run] git clone $REMOTE $DOTFILES_DIR"
    else
        run git clone "$REMOTE" "$DOTFILES_DIR"
    fi
else
    echo "✓ $DOTFILES_DIR 已存在，跳过 clone"
fi

# --- 3. 用 stow 部署 home/ 包到 $HOME ---
# stow -d ~/dotfiles -t "$HOME" home
# 会在 $HOME 下创建指向 ~/dotfiles/home/ 的软链
# 如果 $HOME 下已有同名文件（非软链），stow 会报冲突
if $DRY_RUN; then
    echo "[dry-run] stow -d $DOTFILES_DIR -t $HOME home"
    echo "[dry-run] 若有冲突，stow 会报错，需手动处理（备份或删除冲突文件）"
else
    echo "-> stow 部署 home/ 包到 $HOME ..."
    if stow -d "$DOTFILES_DIR" -t "$HOME" home; then
        echo "✓ stow 部署完成"
    else
        echo "⚠ stow 部署遇到冲突，请手动处理:"
        echo "  1. 备份或删除 $HOME 下的冲突文件"
        echo "  2. 重新运行: stow -d $DOTFILES_DIR -t $HOME home"
        echo "  或用 --adopt 让 stow 接管（原文件移入仓库）:"
        echo "  stow -d $DOTFILES_DIR -t $HOME --adopt home"
        exit 1
    fi
fi

# --- 4. 重生成 matugen 主题产物 ---
# matugen 的 colors.* 产物是生成物，不进 git（见 .gitignore 黑名单）。
# 新机器 stow 后这些文件不存在，需要跑一次 matugen-update.sh 重新生成。
# 前提: 本地已有一张壁纸。失败不致命——会打印提示让用户手动跑。
MATUGEN_UPDATE="$HOME/.config/scripts/matugen-update.sh"
if $DRY_RUN; then
    echo "[dry-run] bash $MATUGEN_UPDATE -f   (生成所有 colors 产物)"
else
    if [[ -f "$MATUGEN_UPDATE" ]] && command -v matugen &>/dev/null; then
        echo "-> 重生成 matugen 主题产物..."
        if bash "$MATUGEN_UPDATE" -f </dev/null 2>&1 | tail -20; then
            echo "✓ matugen 主题已重生成"
        else
            echo "⚠ matugen 自动生成失败（可能本地还没有壁纸）"
            echo "  放一张壁纸后手动跑: bash $MATUGEN_UPDATE -f /path/to/wallpaper.jpg"
        fi
    else
        echo "⚠ 未检测到 matugen 或 matugen-update.sh，跳过主题生成"
        echo "  安装 matugen 后手动跑: bash $MATUGEN_UPDATE -f"
    fi
fi

# --- 5. 提示下一步 ---
cat <<'EOF'

✓ dotfiles 已初始化完成。

下一步:
    1. 安装软件包（可选）:
        bash ~/dotfiles/bootstrap.sh

    2. 重新加载 shell:
        exec zsh   # 或 exec fish

    3. 启用自动提交 timer:
        systemctl --user enable --now dotfiles-autocommit.timer

    4. 开启 linger（让 timer 在未登录时也能跑，一次性命令）:
        sudo loginctl enable-linger $USER

    5. 检查状态:
        cd ~/dotfiles && git status

    6. 如果 matugen 主题色没生成（上一步自动生成失败）:
        放一张壁纸后跑: bash ~/.config/scripts/matugen-update.sh -f /path/to/wallpaper.jpg
EOF