# =============================================================================
# functions.zsh — Shell 函数
# =============================================================================
# 原则：能用 abbr/alias 表达的不放函数；P10K gitstatus 能做的不自己造轮子。
# =============================================================================

# --- 创建目录并进入 ---
mkcd() {
    [[ -z "$1" ]] && { echo "用法: mkcd <目录>"; return 1 }
    mkdir -p -- "$1" && cd -- "$1"
}

# --- 跳到 git 仓库根（注意：abbr 已不再占用 gr，故改名 groot）---
groot() {
    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null) \
        || { echo "错误: 不在 git 仓库中"; return 1 }
    cd -- "$root"
}

# --- 检查端口占用 ---
port() {
    [[ -z "$1" ]] && { echo "用法: port <端口号>"; return 1 }
    sudo lsof -i ":$1"
}

# --- 系统信息 ---
sysinfo() {
    print -P "%F{cyan}系统信息%f"
    echo "════════════════════════════════════"
    printf "%-12s %s\n" "OS:"     "$(awk -F= '/^PRETTY_NAME/{gsub(/"/,"",$2); print $2}' /etc/os-release)"
    printf "%-12s %s\n" "内核:"    "$(uname -r)"
    printf "%-12s %s\n" "Shell:"  "$SHELL ($ZSH_VERSION)"
    printf "%-12s %s\n" "运行:"    "$(uptime -p)"
    printf "%-12s %s\n" "内存:"    "$(free -h | awk '/^Mem:/ {print $3"/"$2}')"
    printf "%-12s %s\n" "磁盘(/):" "$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')"
    printf "%-12s %s\n" "包:"      "$(pacman -Q 2>/dev/null | wc -l) (pacman)"
}

# --- 备份 dotfiles ---
backup-dotfiles() {
    local backup_dir="$HOME/dotfiles-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p -- "$backup_dir"
    cp -- ~/.zshenv "$backup_dir/" 2>/dev/null
    cp -r -- ~/.config/zsh "$backup_dir/"
    cp -r -- ~/.config/fish "$backup_dir/" 2>/dev/null
    cp -r -- ~/.config/environment.d "$backup_dir/" 2>/dev/null
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

# --- 通用解压（无需装 atool/unp；按扩展名分发到系统工具）---
extract() {
    [[ -z "$1" ]] && { echo "用法: extract <file>"; return 1 }
    local f="$1"
    [[ -r "$f" ]] || { echo "错误: 无法读取 $f"; return 1 }
    case "$f" in
        *.tar.bz2|*.tbz2) tar xjf -- "$f" ;;
        *.tar.gz|*.tgz)   tar xzf -- "$f" ;;
        *.tar.xz|*.txz)   tar xJf -- "$f" ;;
        *.tar.zst|*.tzst) tar --zstd -xf -- "$f" ;;
        *.tar)            tar xf -- "$f" ;;
        *.bz2)            bunzip2 -- "$f" ;;
        *.gz)             gunzip -- "$f" ;;
        *.xz)             unxz -- "$f" ;;
        *.zst)            unzstd -- "$f" ;;
        *.zip)            unzip -- "$f" ;;
        *.7z)             7z x -- "$f" ;;
        *.rar)            unrar x -- "$f" ;;
        *.Z)              uncompress -- "$f" ;;
        *) echo "未知格式: $f"; return 1 ;;
    esac
}

# =============================================================================
# 已删除的函数（解释保留以备查）：
#   fo()               → 用 yazi (y) / fzf 直接 `nvim $(fzf)` 替代
#   fkill()            → 用 `btop` 或 `procs --tree` 交互替代
#   weather()          → 用 abbr `weather='curl -s wttr.in/Wuhan?F&lang=zh'`
#   __git_auto_fetch() → P10K gitstatus + vcs_info 已实时反映 ahead/behind
#   __git_watch_*      → 同上；inotify 在大 monorepo 会爆 watch 限额
# =============================================================================
