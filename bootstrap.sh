#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh - 安装生成包列表和可选手工 profile 中的软件包
# =============================================================================
# 用法:
#   bash ~/dotfiles/bootstrap.sh
#   bash ~/dotfiles/bootstrap.sh --profile core,niri,laptop
#
# 选项:
#   --profile NAME[,NAME...]  额外安装 packages/NAME.txt 和 packages/aur/NAME.txt
#   --aur-helper NAME         选择 auto、paru 或 yay（默认 auto）
#   --dry-run                 只打印会装什么，不实际安装
#   -h, --help                显示帮助
#
# 默认只安装当前机器的 generated package lists；手工 profile 必须显式选择。
# 这个脚本只装包，不动配置。配置由 setup.sh 通过 stow 部署完成。
# =============================================================================
set -euo pipefail

DRY_RUN=false
AUR_HELPER_MODE=auto
PROFILES=()
while (($# > 0)); do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --profile)
            [[ $# -ge 2 ]] || { echo "错误: --profile 需要参数，例如 --profile core,niri" >&2; exit 1; }
            profile_arg="$2"
            IFS=',' read -r -a profile_parts <<< "$profile_arg"
            PROFILES+=("${profile_parts[@]}")
            shift 2
            ;;
        --profile=*)
            profile_arg="${1#--profile=}"
            IFS=',' read -r -a profile_parts <<< "$profile_arg"
            PROFILES+=("${profile_parts[@]}")
            shift
            ;;
        --aur-helper)
            [[ $# -ge 2 ]] || { echo "错误: --aur-helper 需要 auto、paru 或 yay" >&2; exit 1; }
            AUR_HELPER_MODE="$2"
            shift 2
            ;;
        --aur-helper=*)
            AUR_HELPER_MODE="${1#--aur-helper=}"
            shift
            ;;
        -h|--help)
            sed -n '2,19p' "$0"
            exit 0
            ;;
        *)
            echo "未知参数: $1" >&2
            echo "用法: $0 [--profile NAME[,NAME...]] [--aur-helper auto|paru|yay] [--dry-run]" >&2
            exit 1
            ;;
    esac
done

case "$AUR_HELPER_MODE" in
    auto|paru|yay) ;;
    *)
        echo "错误: --aur-helper 只能是 auto、paru 或 yay" >&2
        exit 1
        ;;
esac

DOTFILES_DIR="$HOME/dotfiles"
PACKAGES_DIR="$DOTFILES_DIR/packages"
PKGLIST="$PACKAGES_DIR/pkglist.generated.txt"
FOREIGN_PKGLIST="$PACKAGES_DIR/foreign-pkglist.generated.txt"

# 兼容尚未迁移的旧 clone。
[[ -r "$PKGLIST" ]] || PKGLIST="$DOTFILES_DIR/pkglist.txt"
[[ -r "$FOREIGN_PKGLIST" ]] || FOREIGN_PKGLIST="$DOTFILES_DIR/foreign-pkglist.txt"

if [[ ! -r "$PKGLIST" ]]; then
    echo "错误: 找不到 generated package list" >&2
    echo "请先运行: bash ~/dotfiles/update-pkglist.sh" >&2
    exit 1
fi

PROFILE_FILES=()
AUR_PROFILE_FILES=()
for profile in "${PROFILES[@]}"; do
    if [[ ! "$profile" =~ ^[A-Za-z0-9_-]+$ ]]; then
        echo "错误: 非法 profile 名称: $profile" >&2
        exit 1
    fi
    profile_file="$PACKAGES_DIR/$profile.txt"
    aur_profile_file="$PACKAGES_DIR/aur/$profile.txt"
    if [[ -r "$profile_file" ]]; then
        PROFILE_FILES+=("$profile_file")
    else
        echo "错误: 找不到 profile: $profile_file" >&2
        exit 1
    fi
    [[ -r "$aur_profile_file" ]] && AUR_PROFILE_FILES+=("$aur_profile_file")
done

# 读取包文件：忽略空行和 # 注释，并去重。
collect_packages() {
    local file line
    for file in "$@"; do
        [[ -r "$file" ]] || continue
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%%#*}"
            line="${line#"${line%%[![:space:]]*}"}"
            line="${line%"${line##*[![:space:]]}"}"
            [[ -n "$line" ]] && printf '%s\n' "$line"
        done < "$file"
    done | awk '!seen[$0]++'
}

native_files=("$PKGLIST" "${PROFILE_FILES[@]}")
aur_files=("$FOREIGN_PKGLIST" "${AUR_PROFILE_FILES[@]}")
mapfile -t native_packages < <(collect_packages "${native_files[@]}")
mapfile -t aur_packages < <(collect_packages "${aur_files[@]}")

if $DRY_RUN; then
    echo "=== [dry-run] 不实际安装，只显示会装什么 ==="
    echo "原生包来源: ${#native_packages[@]} 个"
    echo "AUR 包来源: ${#aur_packages[@]} 个"
    if ((${#PROFILES[@]} > 0)); then
        echo "额外 profile: ${PROFILES[*]}"
    fi
    echo "AUR helper 策略: $AUR_HELPER_MODE"
    echo
fi

# --- 1. 原生包 ---
if ((${#native_packages[@]} > 0)); then
    echo "-> 安装 pacman 原生包 (${#native_packages[@]} 个) ..."
    if $DRY_RUN; then
        printf '%s\n' "${native_packages[@]:0:10}" | sed 's/^/    /'
        ((${#native_packages[@]} > 10)) && echo "    ... (共 ${#native_packages[@]} 个)"
    elif command -v pacman >/dev/null; then
        sudo pacman -S --needed --noconfirm "${native_packages[@]}"
    else
        echo "警告: pacman 不存在，跳过原生包安装" >&2
    fi
fi

# --- 2. AUR helper ---
select_aur_helper() {
    case "$AUR_HELPER_MODE" in
        paru)
            command -v paru >/dev/null && printf 'paru\n'
            ;;
        yay)
            command -v yay >/dev/null && printf 'yay\n'
            ;;
        auto)
            if command -v paru >/dev/null; then
                printf 'paru\n'
            elif command -v yay >/dev/null; then
                printf 'yay\n'
            fi
            ;;
    esac
}

build_aur_helper() {
    local helper="$1"
    local package_dir="${helper}-bin"
    local package_url="https://aur.archlinux.org/${package_dir}.git"
    local build_dir="/tmp/$package_dir"

    rm -rf -- "$build_dir"
    if git clone "$package_url" "$build_dir" \
        && (cd "$build_dir" && makepkg -si --noconfirm); then
        rm -rf -- "$build_dir"
        echo "✓ $helper 安装成功"
        return 0
    fi
    rm -rf -- "$build_dir"
    return 1
}

bootstrap_aur_helper() {
    if $DRY_RUN; then
        echo "[dry-run] sudo pacman -S --needed --noconfirm base-devel git"
        case "$AUR_HELPER_MODE" in
            paru) echo "[dry-run] bootstrap paru-bin" ;;
            yay) echo "[dry-run] bootstrap yay-bin" ;;
            auto) echo "[dry-run] 尝试 paru-bin，失败后 fallback 到 yay-bin" ;;
        esac
        return 0
    fi

    sudo pacman -S --needed --noconfirm base-devel git
    case "$AUR_HELPER_MODE" in
        paru) build_aur_helper paru ;;
        yay) build_aur_helper yay ;;
        auto)
            build_aur_helper paru || build_aur_helper yay
            ;;
    esac
}

if ((${#aur_packages[@]} > 0)); then
    aur_helper="$(select_aur_helper || true)"
    if [[ -z "$aur_helper" ]]; then
        echo "-> 未检测到指定的 AUR helper（策略: $AUR_HELPER_MODE），开始 bootstrap..."
        if ! bootstrap_aur_helper; then
            echo "✗ AUR helper bootstrap 失败，跳过 AUR 包安装" >&2
            aur_packages=()
        fi
    fi
fi

# --- 3. AUR 包 ---
if ((${#aur_packages[@]} > 0)); then
    aur_helper="$(select_aur_helper || true)"
    echo "-> 安装 AUR 包 (${#aur_packages[@]} 个，helper: ${aur_helper:-未安装}) ..."
    if $DRY_RUN; then
        if [[ -z "$aur_helper" ]]; then
            if [[ "$AUR_HELPER_MODE" == auto ]]; then
                aur_helper='paru（失败后 yay）'
            else
                aur_helper="$AUR_HELPER_MODE"
            fi
        fi
        echo "[dry-run] $aur_helper -S --needed --noconfirm ${aur_packages[*]}"
        printf '%s\n' "${aur_packages[@]:0:10}" | sed 's/^/    /'
        ((${#aur_packages[@]} > 10)) && echo "    ... (共 ${#aur_packages[@]} 个)"
    elif [[ -n "$aur_helper" ]]; then
        "$aur_helper" -S --needed --noconfirm "${aur_packages[@]}"
    else
        echo "警告: AUR helper 不存在，跳过 AUR 包安装" >&2
        printf '%s\n' "${aur_packages[@]}" >&2
    fi
fi

echo
if $DRY_RUN; then
    echo "=== [dry-run] 以上是会安装的包，实际未执行。 ==="
else
    echo "✓ bootstrap 完成"
    echo "下一步: exec zsh  重新加载 shell"
fi
