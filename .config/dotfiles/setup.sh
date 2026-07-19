#!/usr/bin/env bash
# =============================================================================
# setup.sh - 在一台全新 Arch 机器上一键初始化 dotfiles 裸仓库
# =============================================================================
# 用法（在新机器上执行）:
#   bash <(curl -fsSL https://raw.githubusercontent.com/lishengshang/MyArchConfig/main/.config/dotfiles/setup.sh)
# 或者先 clone 下来再执行:
#   git clone --bare https://github.com/lishengshang/MyArchConfig.git ~/.cfg
#   bash ~/.config/dotfiles/setup.sh
#
# 这个脚本做四件事:
#   1. 把裸仓库 clone 到 ~/.cfg（如果还没 clone）
#   2. 把工作区 checkout 到 $HOME（已存在的本地文件会先备份到 ~/.dotfiles-backup）
#   3. 设置 status.showUntrackedFiles=no，避免 status 列出整个家目录
#   4. 提示用户接下来运行 bootstrap.sh
# =============================================================================
set -euo pipefail

REMOTE="https://github.com/lishengshang/MyArchConfig.git"
GIT_DIR="$HOME/.cfg"
WORK_TREE="$HOME"

# --- 1. clone 裸仓库（如果不存在）---
if [[ ! -d "$GIT_DIR" ]]; then
    echo "→ 克隆裸仓库到 $GIT_DIR ..."
    git clone --bare "$REMOTE" "$GIT_DIR"
else
    echo "✓ $GIT_DIR 已存在，跳过 clone"
fi

# --- 2. checkout 到 $HOME（冲突文件先备份）---
backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"
conflicted=()
while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if [[ -e "$WORK_TREE/$f" && ! -L "$WORK_TREE/$f" ]]; then
        # 检查是否已被 dotfiles 跟踪（内容是否一致）
        if ! git --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" diff --quiet -- "$f" 2>/dev/null; then
            conflicted+=("$f")
        fi
    fi
done < <(git --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" ls-tree -r --name-only HEAD 2>/dev/null)

if (( ${#conflicted[@]} > 0 )); then
    echo "→ 以下本地文件与仓库版本冲突，备份到 $backup_dir :"
    printf '    %s\n' "${conflicted[@]}"
    mkdir -p "$backup_dir"
    for f in "${conflicted[@]}"; do
        mkdir -p "$backup_dir/$(dirname "$f")"
        mv -- "$WORK_TREE/$f" "$backup_dir/$f"
    done
fi

echo "→ checkout 工作区到 $WORK_TREE ..."
git --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" checkout -f

# --- 3. 设置仓库参数 ---
git --git-dir="$GIT_DIR" config --local status.showUntrackedFiles no
git --git-dir="$GIT_DIR" config --local core.excludesfile "$WORK_TREE/.gitignore"

# --- 4. 提示下一步 ---
cat <<'EOF'

✓ dotfiles 已初始化完成。

下一步:
    1. 重新加载 shell:
        exec zsh   # 或 exec fish

    2. 安装软件包（可选）:
        bash ~/.config/dotfiles/bootstrap.sh

    3. 检查状态:
        dot status

如果上一步有冲突文件被备份，可以在 ~/.dotfiles-backup-* 里找到。
EOF
