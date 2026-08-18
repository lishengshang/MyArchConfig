#!/usr/bin/env bash
# =============================================================================
# auto-commit.sh - 自动检测 dotfiles 变更并创建本地 commit
# =============================================================================
# 由 systemd user timer dotfiles-autocommit.timer 每 3 天调用。
# 默认只 commit，不访问远程、不执行 push。
#
# 手动确认远程状态后，如需同时 pull/rebase + push：
#   bash ~/dotfiles/auto-commit.sh --push
#
# 逻辑:
#   1. 使用 flock 防止 timer 与手动执行并发
#   2. 检查工作区是否干净
#   3. 筛选配置源文件后 git add + git commit
#   4. 默认结束；只有显式 --push 才 pull --rebase + push
# =============================================================================
set -euo pipefail

PUSH=false
for arg in "$@"; do
    case "$arg" in
        --push) PUSH=true ;;
        -h|--help)
            sed -n '2,18p' "$0"
            exit 0
            ;;
        *)
            echo "未知参数: $arg" >&2
            echo "用法: $0 [--push]" >&2
            exit 1
            ;;
    esac
done

DOTFILES_DIR="$HOME/dotfiles"
LOG_PREFIX="[dotfiles-auto]"
LOCK_ROOT="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"
[[ -d "$LOCK_ROOT" ]] || LOCK_ROOT=/tmp
LOCK_FILE="$LOCK_ROOT/dotfiles-autocommit-${UID:-$(id -u)}.lock"

log() { echo "$LOG_PREFIX $*"; }
g() { git "$@"; }

if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    log "仓库不存在或不是 Git 仓库: $DOTFILES_DIR" >&2
    exit 1
fi
cd "$DOTFILES_DIR"

# systemd timer、手动命令和不同 Agent 可能同时触发；非阻塞获取锁即可。
# 锁文件位于 XDG_RUNTIME_DIR，fallback 到 /tmp 时带 UID，避免用户间冲突。
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    log "已有实例运行，跳过本次执行"
    exit 0
fi

# 自动提交范围：配置源文件和仓库根目录下的维护脚本。
# 不自动提交文档、包列表、Agent 状态和生成文件；这些内容由人工审查后提交。
COMMIT_PATHS=(
    home
    ':(exclude)home/.config/fish/fish_variables'
    ':(glob,exclude)home/.config/**/colors.*'
    ':(glob,exclude)home/.config/**/generated.*'
    ':(exclude)home/.config/fish/conf.d/35-pager-matugen.fish'
    ':(exclude)home/.config/Code/User/settings.json'
)
for path in ./*.sh; do
    [[ -f "$path" ]] && COMMIT_PATHS+=("${path#./}")
done

# --- 1. 检查是否有变更 ---
changes=$(g status --porcelain=v1)
if [[ -z "$changes" ]]; then
    log "工作区干净，无需提交"
    exit 0
fi

# --- 2. 只暂存允许自动提交的源文件 ---
log "检测到工作区变更，筛选自动提交范围..."
g add -A -- "${COMMIT_PATHS[@]}"

# 重新读取暂存区：commit message 只描述本次允许提交的内容。
# `git diff` 没有 porcelain 输出，使用 name-status 保留路径信息。
staged_changes=$(g diff --cached --name-status)
if [[ -z "$staged_changes" ]]; then
    log "没有符合自动提交范围的变更，跳过（其他变更保持原状）"
    exit 0
fi

# --- 3. 生成 commit message ---
total=$(printf '%s\n' "$staged_changes" | awk 'NF { count++ } END { print count + 0 }')
added=$(printf '%s\n' "$staged_changes" | awk '$1 == "A" { count++ } END { print count + 0 }')
modified=$(printf '%s\n' "$staged_changes" | awk '$1 == "M" || $1 == "R" || $1 == "C" { count++ } END { print count + 0 }')
deleted=$(printf '%s\n' "$staged_changes" | awk '$1 == "D" { count++ } END { print count + 0 }')

# name-status 的第二列开始是路径，保留路径中的空格。
files=$(printf '%s\n' "$staged_changes" | cut -f2- | head -n 5 | paste -sd, -)
if (( total > 5 )); then
    files="$files, ... (共 $total 个文件)"
fi

timestamp=$(date '+%Y-%m-%d %H:%M:%S')
msg="auto: $timestamp

改动文件 ($total): $files
- 新增/未跟踪: $added
- 修改: $modified
- 删除: $deleted

(由 systemd timer dotfiles-autocommit.timer 自动提交；默认不 push)"

# --- 4. commit 允许范围 ---
log "检测到 $total 个允许提交的文件变更，开始本地提交..."
# 即使用户此前手动暂存了文档等其他路径，也不能被本次自动 commit 带走。
g commit -q -m "$msg" -- "${COMMIT_PATHS[@]}"
log "✓ 本地 commit 完成"

# --- 4. 显式 --push 才同步远程 ---
if ! $PUSH; then
    log "本次仅本地提交，未执行 pull/push"
    log "如需同步远程，请先检查状态后运行: bash $DOTFILES_DIR/auto-commit.sh --push"
    g log --oneline -1
    exit 0
fi

log "显式启用远程同步，拉取远程更新..."
if ! pull_output=$(g pull --rebase 2>&1); then
    log "$pull_output"
    log "⚠ pull --rebase 失败或存在冲突，本地 commit 已保留；请手动处理"
    exit 1
fi
[[ -n "$pull_output" ]] && log "$pull_output"

log "推送到远程..."
if ! push_output=$(g push 2>&1); then
    log "$push_output"
    log "⚠ push 失败，请手动检查远程、凭证和网络"
    exit 1
fi
[[ -n "$push_output" ]] && log "$push_output"
log "✓ push 完成"
g log --oneline -1
