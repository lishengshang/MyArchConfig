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
#   --dry-run                 只打印会做什么，不实际执行（不 clone / 不 stow / 不装包）
#   --enable-units            启用仓库 unit 清单中的全部 systemd user units
#   --enable-units=UNIT,...   只启用指定的 systemd user units
#   -h, --help                显示帮助
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
ENABLE_UNITS=false
REQUESTED_UNITS=()
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --enable-units) ENABLE_UNITS=true ;;
        --enable-units=*)
            ENABLE_UNITS=true
            IFS=',' read -r -a REQUESTED_UNITS <<< "${arg#--enable-units=}"
            ;;
        -h|--help)
            sed -n '2,26p' "$0"
            exit 0
            ;;
        *)
            echo "未知参数: $arg" >&2
            echo "用法: $0 [--dry-run] [--enable-units[=UNIT,...]]" >&2
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
DEFAULT_MANAGED_UNITS=(
    dotfiles-autocommit.timer
    dotfiles-autocommit.service
    random-api-wallpaper.timer
    random-api-wallpaper.service
    awww-overview-daemon.service
    swayidle.service
)

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

# --- 3.5 创建 VS Code 本地 settings 生成物 ---
# settings.base.json 由 Git 管理；settings.json 由 Matugen 在本地生成并被 .gitignore 排除。
VSCODE_BASE="$HOME/.config/Code/User/settings.base.json"
VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
if $DRY_RUN; then
    echo "[dry-run] 如果 $VSCODE_SETTINGS 不存在，从 $VSCODE_BASE 创建本地副本"
else
    if [[ -r "$VSCODE_BASE" ]]; then
        # 清理旧版本 stow 到已删除 settings.json 的断链，但不碰用户自己的普通文件。
        if [[ -L "$VSCODE_SETTINGS" ]] && [[ "$(readlink "$VSCODE_SETTINGS")" == *"/settings.json" ]]; then
            rm -f -- "$VSCODE_SETTINGS"
        fi
        if [[ ! -e "$VSCODE_SETTINGS" ]]; then
            cp -- "$VSCODE_BASE" "$VSCODE_SETTINGS"
            echo "✓ 已创建 VS Code 本地 settings.json"
        fi
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

# --- 4.5 可选启用 systemd user units ---
# 默认不启用；使用 --enable-units 或 --enable-units=UNIT,... 显式启用。
MANAGED_UNITS=("${DEFAULT_MANAGED_UNITS[@]}")
if [[ -r "$DOTFILES_DIR/systemd-user-units.txt" ]]; then
    MANAGED_UNITS=()
    while IFS= read -r unit || [[ -n "$unit" ]]; do
        [[ -z "$unit" || "$unit" == \#* ]] && continue
        MANAGED_UNITS+=("$unit")
    done < "$DOTFILES_DIR/systemd-user-units.txt"
fi

if ((${#REQUESTED_UNITS[@]} > 0)); then
    for requested in "${REQUESTED_UNITS[@]}"; do
        if [[ ! " ${MANAGED_UNITS[*]} " == *" $requested "* ]]; then
            echo "错误: 不在 systemd-user-units.txt 中的 unit: $requested" >&2
            exit 1
        fi
    done
    UNITS_TO_ENABLE=("${REQUESTED_UNITS[@]}")
elif $ENABLE_UNITS; then
    UNITS_TO_ENABLE=("${MANAGED_UNITS[@]}")
else
    UNITS_TO_ENABLE=()
fi

if ((${#UNITS_TO_ENABLE[@]} == 0)); then
    echo "-> 跳过 systemd user units（使用 --enable-units 显式启用）"
elif $DRY_RUN; then
    for unit in "${UNITS_TO_ENABLE[@]}"; do
        echo "[dry-run] systemctl --user enable --now $unit"
    done
else
    echo "-> 启用 systemd user units ..."
    for unit in "${UNITS_TO_ENABLE[@]}"; do
        if systemctl --user enable --now "$unit" 2>/dev/null; then
            echo "✓ 已启用 $unit"
        else
            echo "⚠ 启用 $unit 失败（user manager 未就绪？）——登录图形会话后手动执行:"
            echo "  systemctl --user enable --now $unit"
        fi
    done
fi

# --- 5. 提示下一步 ---
cat <<'EOF'

✓ dotfiles 已初始化完成。

下一步:
    1. 安装软件包（可选）:
        bash ~/dotfiles/bootstrap.sh

    2. 重新加载 shell:
        exec zsh   # 或 exec fish

    3. （可选）启用 systemd user units:
        # 启用全部仓库 unit:
        bash ~/dotfiles/setup.sh --enable-units
        # 或只启用指定 unit:
        bash ~/dotfiles/setup.sh --enable-units=dotfiles-autocommit.timer
        # dotfiles-autocommit 默认只创建本地 commit，不会自动 push

    4. 开启 linger（让 timer 在未登录时也能跑，一次性命令）:
        sudo loginctl enable-linger $USER

    5. 检查状态:
        cd ~/dotfiles && git status

    6. 如果 matugen 主题色没生成（上一步自动生成失败）:
        放一张壁纸后跑: bash ~/.config/scripts/matugen-update.sh -f /path/to/wallpaper.jpg
EOF