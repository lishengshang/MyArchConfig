# =============================================================================
# functions.zsh — Shell 函数
# =============================================================================
# 原则：能用 abbr/alias 表达的不放函数；starship 能做的不自己造轮子。
# =============================================================================

# --- 创建目录并进入 ---
mkcd() {
    [[ -z "$1" ]] && { echo "用法: mkcd <目录>"; return 1 }
    mkdir -p -- "$1" && cd -- "$1"
}

# --- 跳到 git 仓库根 ---
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
