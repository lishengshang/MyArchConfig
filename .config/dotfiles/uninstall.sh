#!/usr/bin/env bash
# =============================================================================
# uninstall.sh - 反向卸载 dotfiles 仓库
# =============================================================================
# 用法:
#   bash ~/.config/dotfiles/uninstall.sh           # 默认（会问确认）
#   bash ~/.config/dotfiles/uninstall.sh --force   # 跳过确认
#   bash ~/.config/dotfiles/uninstall.sh --dry-run # 只看会做什么，不执行
#
# 做的事:
#   1. 停止并禁用 systemd user timer（dotfiles-autocommit.*）
#   2. 删除裸仓库目录 ~/.cfg/（GIT_DIR，不影响 $HOME 下的配置文件）
#   3. 提示用户可选清理项（不自动执行）
#
# 不做的事（安全原则）:
#   - 不删 $HOME 下被 dotfiles 跟踪的配置文件（~/.zshenv, ~/.config/* 等）
#   - 不删 ~/.gitignore（你可能还想留着或手动清理）
#   - 不删 ~/.config/dotfiles/ 脚本本身（让你能再读一遍这个文件确认）
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
            sed -n '2,30p' "$0"
            exit 0
            ;;
        *)
            echo "未知参数: $arg" >&2
            echo "用法: $0 [--dry-run] [--force]" >&2
            exit 1
            ;;
    esac
done

GIT_DIR="$HOME/.cfg"

# --- 日志函数 ---
log()  { echo "[uninstall] $*"; }
warn() { echo "[uninstall] ⚠ $*" >&2; }
dry()  { echo "[dry-run] $*"; }

# --- 确认提示 ---
if ! $FORCE && ! $DRY_RUN; then
    cat <<'EOF'
即将卸载 dotfiles 裸仓库:
  - 停止 systemd user timer (dotfiles-autocommit.*)
  - 删除 ~/.cfg/ (裸仓库内部文件，不影响你的配置)

配置文件 (~/.zshenv, ~/.config/*) 不会被删除。
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

# --- 2. 删除裸仓库目录 ---
if [[ -d "$GIT_DIR" ]]; then
    if $DRY_RUN; then
        dry "rm -rf $GIT_DIR"
    else
        log "删除裸仓库目录 $GIT_DIR ..."
        rm -rf "$GIT_DIR"
        log "✓ $GIT_DIR 已删除"
    fi
else
    log "$GIT_DIR 不存在，跳过"
fi

# --- 3. 完成 + 提示可选清理项 ---
if $DRY_RUN; then
    echo
    dry "dry-run 完成。以上是会执行的操作，实际未执行。"
    exit 0
fi

cat <<EOF

✓ 卸载完成。

以下文件/目录未被自动删除（安全起见）:
  - ~/.gitignore                     (dotfiles 白名单策略文件)
  - ~/.zshenv                        (zsh 入口)
  - ~/.config/dotfiles/              (你正在运行的这个脚本所在目录)
  - ~/.config/systemd/user/dotfiles-autocommit.{service,timer}

如需彻底清理，手动执行:
    rm -rf ~/.gitignore ~/.zshenv ~/.config/dotfiles ~/.config/systemd/user/dotfiles-autocommit.*

或保留配置但只想清掉 git 痕迹:
    # 已经做了，无需额外操作
EOF
