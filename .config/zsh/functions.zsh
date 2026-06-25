# =============================================================================
# functions.zsh — Shell 函数
# =============================================================================

# --- 创建目录并进入 ---
mkcd() {
    [[ -z "$1" ]] && { echo "用法: mkcd <目录>"; return 1; }
    mkdir -p "$1" && cd "$1"
}

# --- 通用解压 ---
extract() {
    if [[ ! -f "$1" ]]; then
        echo "错误: '$1' 不是有效文件"
        return 1
    fi
    case "$1" in
        *.tar.bz2|*.tbz2) tar xjf "$1"   ;;
        *.tar.gz|*.tgz)   tar xzf "$1"   ;;
        *.tar.xz|*.txz)   tar xJf "$1"   ;;
        *.tar.zst)        tar --use-compress-program=unzstd -xf "$1" ;;
        *.tar)            tar xf "$1"    ;;
        *.bz2)            bunzip2 "$1"   ;;
        *.gz)             gunzip "$1"    ;;
        *.xz)             unxz "$1"      ;;
        *.zst)            unzstd "$1"    ;;
        *.rar)            unrar x "$1"   ;;
        *.zip)            unzip "$1"     ;;
        *.7z)             7z x "$1"      ;;
        *.Z)              uncompress "$1";;
        *)                echo "错误: '$1' 无法被 extract 处理"; return 1 ;;
    esac
}

# --- 模糊查找并打开 ---
fv() {
    local file
    file=$(fd --type f --hidden --exclude .git 2>/dev/null | \
           fzf --height=50% --border --preview 'bat --color=always --style=numbers --line-range=:500 {}')
    [[ -n "$file" ]] && ${EDITOR:-nvim} "$file"
}

# --- 模糊查找并复制路径 ---
ff() {
    local file
    file=$(fd --type f --hidden --exclude .git 2>/dev/null | \
           fzf --height=50% --border --preview 'bat --color=always --line-range :50 {}')
    if [[ -n "$file" ]]; then
        if command -v wl-copy &>/dev/null; then
            echo -n "$file" | wl-copy
            echo "✓ Wayland 剪贴板: $file"
        elif command -v xclip &>/dev/null; then
            echo -n "$file" | xclip -selection clipboard
            echo "✓ X11 剪贴板: $file"
        else
            echo "$file"
        fi
    fi
}

# --- 跳到 git 仓库根 ---
gr() {
    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -n "$root" ]]; then
        cd "$root"
    else
        echo "错误: 不在 git 仓库中"
        return 1
    fi
}

# --- 模糊查找并杀进程 ---
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | \
          fzf --multi --height=50% --border --header='[Tab 多选, Enter 确认]' | \
          awk '{print $2}')
    if [[ -n "$pid" ]]; then
        local sig="${1:-TERM}"
        echo "$pid" | xargs kill -"$sig" && echo "✓ 已发送 SIG$sig"
    fi
}

# --- 检查端口占用 ---
port() {
    [[ -z "$1" ]] && { echo "用法: port <端口号>"; return 1; }
    sudo lsof -i ":$1"
}

# --- 系统信息 ---
sysinfo() {
    print -P "%F{cyan}系统信息%f"
    echo "════════════════════════════════════"
    printf "%-12s %s\n" "OS:"    "$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    printf "%-12s %s\n" "内核:"   "$(uname -r)"
    printf "%-12s %s\n" "Shell:" "$SHELL ($ZSH_VERSION)"
    printf "%-12s %s\n" "运行:"   "$(uptime -p)"
    printf "%-12s %s\n" "内存:"   "$(free -h | awk '/^Mem:/ {print $3"/"$2}')"
    printf "%-12s %s\n" "磁盘(/)" "$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')"
    printf "%-12s %s\n" "包:"     "$(pacman -Q 2>/dev/null | wc -l) (pacman)"
}

# --- 天气 ---
weather() {
    curl -s "wttr.in/${1:-Wuhan}?F&lang=zh" | head -30
}

# --- 备份 dotfiles ---
backup-dotfiles() {
    local backup_dir="$HOME/dotfiles-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    cp ~/.zshenv "$backup_dir/" 2>/dev/null
    cp -r ~/.config/zsh "$backup_dir/"
    cp -r ~/.config/fish "$backup_dir/" 2>/dev/null
    cp -r ~/.config/environment.d "$backup_dir/" 2>/dev/null
    echo "✓ 备份至: $backup_dir"
}

# --- yazi 包装：退出后 cd 到目标目录（与 fish 行为一致）---
y() {
    local tmp cwd
    tmp=$(mktemp -t "yazi-cwd.XXXXXX")
    yazi "$@" --cwd-file="$tmp"
    if cwd=$(<"$tmp") && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# --- Git auto-fetch（异步，进入 repo 时静默拉取最新 ref） ---
__git_auto_fetch() {
    git rev-parse --is-inside-work-tree &>/dev/null || return
    # 避免高频：5 分钟内不重复 fetch
    local fetch_head="$(git rev-parse --git-dir 2>/dev/null)/FETCH_HEAD"
    if [[ -f "$fetch_head" ]]; then
        local age=$(( $(date +%s) - $(stat -c %Y "$fetch_head") ))
        (( age < 300 )) && return
    fi
    (git fetch --quiet --all --prune 2>/dev/null &) >/dev/null 2>&1
}
add-zsh-hook chpwd __git_auto_fetch

# ============================================================================
# git 文件监控（inotifywait）—— 优化版
# 修复：旧版每次 cd 都会泄漏进程，新版用 pid 文件 + 严格清理
# ============================================================================
__git_watch_pid=0

__git_watch_stop() {
    if (( __git_watch_pid > 0 )); then
        kill $__git_watch_pid 2>/dev/null
        # 等待真正退出
        wait $__git_watch_pid 2>/dev/null
    fi
    __git_watch_pid=0
}

__git_watch_start() {
    __git_watch_stop

    (( $+commands[inotifywait] )) || return 0

    local git_root
    git_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
    [[ -z "$git_root" || ! -d "$git_root" ]] && return 0

    # 跳过过大的仓库（>5000 文件，可能是 node_modules / monorepo）
    local file_count
    file_count=$(git -C "$git_root" ls-files 2>/dev/null | wc -l)
    (( file_count > 5000 )) && return 0

    inotifywait -r -m -q \
        -e modify,create,delete,move,close_write \
        --exclude '(\.git/|node_modules/|__pycache__/|\.venv/|target/|build/|dist/|\.cache/|\.next/)' \
        "$git_root" 2>/dev/null | while read -r; do
        kill -USR1 $$ 2>/dev/null || exit
    done &!
    __git_watch_pid=$!
}

TRAPUSR1() {
    p10k display -r 2>/dev/null  # p10k v1.19+ API
    p10k refresh 2>/dev/null      # 旧 API 兼容
    zle reset-prompt 2>/dev/null
}

add-zsh-hook chpwd __git_watch_start
add-zsh-hook zshexit __git_watch_stop

# 初始启动
__git_watch_start
