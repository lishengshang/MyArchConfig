#!/usr/bin/env bash
# =============================================================================
# auto-commit.sh - 自动检测 dotfiles 变更并 commit + push
# =============================================================================
# 由 systemd user timer dotfiles-autocommit.timer 每天凌晨调用
# 也可以手动运行: bash ~/.config/dotfiles/auto-commit.sh
#
# 逻辑:
#   1. 检查工作区是否干净（dot status --porcelain）
#   2. 有变更:
#      a. 生成 commit message（包含改动文件摘要 + 时间戳）
#      b. dot add -A（.gitignore 已兜底排除所有不该跟踪的）
#      c. dot commit
#      d. dot pull --rebase（避免远程有新 commit 时 push 被拒）
#      e. dot push
#   3. 无变更: 静默退出
#
# 日志: systemd journal (journalctl --user -u dotfiles-autocommit)
# =============================================================================
set -euo pipefail

GIT_DIR="$HOME/.cfg"
WORK_TREE="$HOME"
export GIT_DIR GIT_WORK_TREE="$WORK_TREE"

LOG_PREFIX="[dotfiles-auto]"

# 静默 git 调用
g() { git --git-dir="$GIT_DIR" --work-tree="$WORK_TREE" "$@"; }

log() { echo "$LOG_PREFIX $*"; }

# --- 1. 检查是否有变更 ---
# status --porcelain 输出为空 = 干净
if g status --porcelain | grep -q .; then
    :
else
    log "工作区干净，无需提交"
    exit 0
fi

# --- 2. 生成 commit message ---
# 收集改动的文件分类统计
changes=$(g status --porcelain)
added=$(echo "$changes" | grep -c '^A\|^??' || true)
modified=$(echo "$changes" | grep -c '^ M\|^M ' || true)
deleted=$(echo "$changes" | grep -c '^ D\|^D ' || true)

# 取改动文件列表（最多 5 个，超出显示 "..."）
files=$(echo "$changes" | awk '{print $2}' | head -5 | tr '\n' ',' | sed 's/,$//')
total=$(echo "$changes" | wc -l)
if (( total > 5 )); then
    files="$files, ... (共 $total 个文件)"
fi

# 当前时间
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

msg="auto: $timestamp

改动文件 ($total): $files
- 新增/未跟踪: $added
- 修改: $modified
- 删除: $deleted

(由 systemd timer dotfiles-autocommit.timer 自动提交)"

# --- 3. add + commit ---
log "检测到 $total 个文件变更，开始提交..."

# dot add -A 安全性说明:
#   .gitignore 已经用 /* + 白名单模式兜底，自动 add 不会误加缓存/敏感文件
#   白名单外的所有文件（.ssh/.gnupg/.cache/.bash_history 等）都进不来
g add -A

if ! g diff --cached --quiet; then
    g commit -q -m "$msg"
    log "✓ commit 完成"
else
    log "暂存后无变更可提交（可能是只删了未跟踪文件），跳过"
    exit 0
fi

# --- 4. pull --rebase（防止远程有新 commit） ---
log "拉取远程更新..."
# pull --rebase 成功的几种情况:
#   - "Successfully rebased"     (有新 commit 需要 rebase)
#   - "Already up to date"        (英文，最新)
#   - "当前分支 ... 是最新的"      (中文，最新)
#   - "Successfully fetched"     (有 fetch 但没变化)
#   - "更新至" / "已是最新"
pull_output=$(g pull --rebase origin main 2>&1) || true
log "$pull_output"

if echo "$pull_output" | grep -qiE "conflict|失败|error|fatal|couldn't|unable"; then
    log "⚠ pull --rebase 失败或有冲突，跳过 push（请手动处理: dot status / dot rebase --abort）"
    exit 1
fi

# --- 5. push ---
log "推送到 GitHub..."
if g push origin main 2>&1 | grep -qE "Everything up-to-date|-> main"; then
    log "✓ push 完成"
else
    log "⚠ push 失败，请手动检查"
    exit 1
fi

# --- 6. 输出最终状态 ---
log "本次自动提交完成"
g log --oneline -1
