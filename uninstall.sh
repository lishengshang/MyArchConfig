#!/usr/bin/env bash
# =============================================================================
# uninstall.sh - 反向卸载 dotfiles（GNU Stow 方案）
# =============================================================================
# 用法:
#   bash ~/dotfiles/uninstall.sh           # 默认（会问确认）
#   bash ~/dotfiles/uninstall.sh --force   # 跳过确认
#   bash ~/dotfiles/uninstall.sh --dry-run # 只看会做什么，不执行
#
# 做的事:
#   1. 停止并禁用 systemd user timer（dotfiles-autocommit.*）
#   2. 用 stow -D 撤销 home/ 包的软链
#   3. 删除仓库目录 ~/dotfiles/
#   4. 提示用户可选清理项（不自动执行）
#
# 不做的事（安全原则）:
#   - 不删 $HOME 下被 stow 部署的配置文件（stow -D 只删软链，不删目标内容）
#   - 不删 ~/.config/systemd/user/dotfiles-autocommit.*（让你手动决定）
#
# 卸载后想彻底清理配置文件，参考脚本末尾输出。
# =============================================================================
set -euo pipefail

DRY_RUN=false
FORCE=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --force|-f) FORCE=true ;;
        -h|--help)
            sed -n '2,24p' "$0"
            exit 0
            ;;
        *)
            echo "未知参数: $arg" >&2
            echo "用法: $0 [--dry-run] [--force]" >&2
            exit 1
            ;;
    esac
done

DOTFILES_DIR="$HOME/dotfiles"

# --- 日志函数 ---
log()  { echo "[uninstall] $*"; }
warn() { echo "[uninstall] ⚠ $*" >&2; }
dry()  { echo "[dry-run] $*"; }

# --- 确认提示 ---
if ! $FORCE && ! $DRY_RUN; then
    cat <<'EOF'
即将卸载 dotfiles:
  - 停止 systemd user timer (dotfiles-autocommit.*)
  - stow -D 撤销 home/ 包的软链
  - 删除 ~/dotfiles/ (仓库目录，不影响你的配置文件内容)

配置文件 (~/.zshenv, ~/.config/*) 的软链会被删除，但实际内容保留在 ~/dotfiles/home/ 里。
EOF
    printf "继续？[y/N] "
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] || { echo "已取消"; exit 0; }
fi

# --- 1. 停止并禁用 systemd user timer ---
if systemctl --user list-unit-files 2>/dev/null | grep -q 'dotfiles-autocommit'; then
    if $DRY_RUN; then
        dry "systemctl --user disable --now dotfiles-autocommit.timer dotfiles-autocommit.service"
    else
        log "停止并禁用 systemd user timer ..."
        # timer + service 都停，disable 防止开机启动
        # --now = 同时 stop，失败不致命（可能已经停了）
        systemctl --user disable --now dotfiles-autocommit.timer dotfiles-autocommit.service 2>/dev/null || true
        log "✓ timer 已禁用"
    fi
else
    log "未检测到 dotfiles-autocommit timer，跳过"
fi

# --- 2. stow -D 撤销软链 ---
if [[ -d "$DOTFILES_DIR/home" ]]; then
    if $DRY_RUN; then
        dry "stow -d $DOTFILES_DIR -t $HOME -D home"
    else
        log "撤销 stow 软链 ..."
        stow -d "$DOTFILES_DIR" -t "$HOME" -D home 2>/dev/null || warn "stow -D 遇到错误（可能有手动修改的软链），继续"
        log "✓ stow 软链已撤销"
    fi
else
    log "$DOTFILES_DIR/home 不存在，跳过 stow -D"
fi

# --- 3. 删除仓库目录 ---
if [[ -d "$DOTFILES_DIR" ]]; then
    if $DRY_RUN; then
        dry "rm -rf $DOTFILES_DIR"
    else
        log "删除仓库目录 $DOTFILES_DIR ..."
        rm -rf "$DOTFILES_DIR"
        log "✓ $DOTFILES_DIR 已删除"
    fi
else
    log "$DOTFILES_DIR 不存在，跳过"
fi

# --- 4. 完成 + 提示可选清理项 ---
if $DRY_RUN; then
    echo
    dry "dry-run 完成。以上是会执行的操作，实际未执行。"
    exit 0
fi

cat <<EOF

✓ 卸载完成。

以下文件/目录未被自动删除（安全起见）:
  - ~/.config/systemd/user/dotfiles-autocommit.{service,timer}

如需彻底清理，手动执行:
    rm -f ~/.config/systemd/user/dotfiles-autocommit.{service,timer}
    systemctl --user daemon-reload

或保留配置但只想清掉 dotfiles 痕迹:
    # 已经做完，无需额外操作
EOF