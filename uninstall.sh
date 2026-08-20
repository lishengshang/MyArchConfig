#!/usr/bin/env bash
# =============================================================================
# uninstall.sh - 反向卸载 dotfiles（GNU Stow 方案）
# =============================================================================
# 用法:
#   bash ~/dotfiles/uninstall.sh                       # 默认：解除软链，保留仓库
#   bash ~/dotfiles/uninstall.sh --force               # 跳过确认
#   bash ~/dotfiles/uninstall.sh --remove-repo          # 明确删除仓库
#   bash ~/dotfiles/uninstall.sh --remove-repo --force  # 删除仓库且跳过确认
#   bash ~/dotfiles/uninstall.sh --dry-run              # 只看会做什么
#
# 默认行为（安全模式）:
#   1. 停止并禁用 dotfiles 管理的 systemd user units
#   2. 用 stow -D 撤销 home/ 包的软链
#   3. 保留 ~/dotfiles 仓库和配置真实内容
#
# 只有显式传入 --remove-repo 时，才会在确认后删除 ~/dotfiles。
# =============================================================================
set -euo pipefail

DRY_RUN=false
FORCE=false
REMOVE_REPO=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --force|-f) FORCE=true ;;
        --remove-repo) REMOVE_REPO=true ;;
        -h|--help)
            sed -n '2,26p' "$0"
            exit 0
            ;;
        *)
            echo "未知参数: $arg" >&2
            echo "用法: $0 [--dry-run] [--force] [--remove-repo]" >&2
            exit 1
            ;;
    esac
done

DOTFILES_DIR="$HOME/dotfiles"

# 这些 unit 都由本仓库提供或由本仓库 setup.sh 启用。
# 即使某个 unit 当前不存在，systemctl disable --now 的失败也不应阻止卸载。
MANAGED_UNITS=(
    dotfiles-autocommit.timer
    dotfiles-autocommit.service
    random-api-wallpaper.timer
    random-api-wallpaper.service
    awww-overview-daemon.service
    wallpaper-theme.service
    swayidle.service
)
if [[ -r "$DOTFILES_DIR/systemd-user-units.txt" ]]; then
    MANAGED_UNITS=()
    while IFS= read -r unit || [[ -n "$unit" ]]; do
        [[ -z "$unit" || "$unit" == \#* ]] && continue
        MANAGED_UNITS+=("$unit")
    done < "$DOTFILES_DIR/systemd-user-units.txt"
fi

# --- 日志函数 ---
log()  { echo "[uninstall] $*"; }
warn() { echo "[uninstall] ⚠ $*" >&2; }
dry()  { echo "[dry-run] $*"; }

# --- 确认提示 ---
if ! $FORCE && ! $DRY_RUN; then
    if $REMOVE_REPO; then
        cat <<'EOF'
即将彻底卸载 dotfiles:
  - 停止并禁用仓库管理的 systemd user units
  - stow -D 撤销 home/ 包的软链
  - 永久删除 ~/dotfiles/ 仓库及其中保存的配置真实内容

如果只是想解除软链并保留配置，请不要使用 --remove-repo。
EOF
    else
        cat <<'EOF'
即将解除 dotfiles 部署:
  - 停止并禁用仓库管理的 systemd user units
  - stow -D 撤销 home/ 包的软链
  - 保留 ~/dotfiles/ 仓库和其中的配置真实内容
EOF
    fi
    printf "继续？[y/N] "
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] || { echo "已取消"; exit 0; }
fi

# --- 1. 停止并禁用仓库管理的 systemd user units ---
if command -v systemctl >/dev/null 2>&1; then
    for unit in "${MANAGED_UNITS[@]}"; do
        if $DRY_RUN; then
            dry "systemctl --user disable --now $unit"
        else
            systemctl --user disable --now "$unit" 2>/dev/null || true
        fi
    done
else
    warn "未检测到 systemctl，跳过 user units"
fi

# --- 2. stow -D 撤销软链 ---
if [[ -d "$DOTFILES_DIR/home" ]]; then
    if $DRY_RUN; then
        dry "stow -d $DOTFILES_DIR -t $HOME -D home"
    else
        log "撤销 stow 软链 ..."
        stow -d "$DOTFILES_DIR" -t "$HOME" -D home 2>/dev/null \
            || warn "stow -D 遇到错误（可能有手动修改的软链），继续"
        log "✓ stow 软链已撤销"
    fi
else
    log "$DOTFILES_DIR/home 不存在，跳过 stow -D"
fi

# unit 文件可能刚刚因 stow -D 从 ~/.config/systemd/user 移除。
if ! $DRY_RUN && command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload 2>/dev/null || true
fi

# --- 3. 只有显式 --remove-repo 才删除仓库 ---
if $REMOVE_REPO; then
    if [[ -d "$DOTFILES_DIR" ]]; then
        if $DRY_RUN; then
            dry "rm -rf $DOTFILES_DIR"
        else
            log "删除仓库目录 $DOTFILES_DIR ..."
            rm -rf -- "$DOTFILES_DIR"
            log "✓ $DOTFILES_DIR 已删除"
        fi
    else
        log "$DOTFILES_DIR 不存在，跳过"
    fi
else
    log "保留仓库 $DOTFILES_DIR（如需删除，请重新运行并加 --remove-repo）"
fi

# --- 4. 完成 ---
if $DRY_RUN; then
    echo
    dry "dry-run 完成。以上是会执行的操作，实际未执行。"
    exit 0
fi

cat <<EOF

✓ dotfiles 卸载完成。

$(if $REMOVE_REPO; then
    echo "仓库和其中的配置真实内容已删除。"
else
    echo "仓库已保留: $DOTFILES_DIR"
    echo "如需重新部署: stow -d $DOTFILES_DIR -t \"\$HOME\" home"
fi)

已停止/禁用仓库管理的 systemd user units。
如需重新启用，请先重新 stow，再执行:
    systemctl --user daemon-reload
    systemctl --user enable --now dotfiles-autocommit.timer
EOF
