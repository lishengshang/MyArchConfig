# =============================================================================
# aliases.zsh - 传统别名（abbr 之外的场景）
# =============================================================================
# 大部分 alias 已迁移到 abbreviations.zsh（按空格展开为完整命令）。
# 此文件保留以下场景的别名：
#   1. 透明替换：ls/cat/find/grep（不需要看到原命令）
#   2. 安全标志：rm/cp/mv 必须永远生效
#   3. 颜色：ip/diff 默认加 --color
#
# 透明替换的工具做存在性检查：未装时回退原命令，避免 "command not found"。
# =============================================================================

# --- 现代化透明替换（带存在性检查）---
# key=被替换命令  value=实际执行命令（第一个词用于存在性检查）
() {
    local cmd tool
    typeset -A _repl=(
        ls   'eza --icons --group-directories-first'
        cat  'bat --style=plain --paging=never'
        grep 'rg --smart-case'
        du   'dust'
        df   'duf'
        ps   'procs'
        top  'btop'
    )
    for cmd in ${(k)_repl}; do
        tool="${_repl[$cmd]%% *}"
        (( $+commands[$tool] )) && alias "$cmd=$_repl[$cmd]"
    done
}
# cd 由 integrations.zsh 中 zoxide --cmd cd 接管
# find 不替换：fd 语法与 find 不兼容，破坏脚本调用

# --- 安全标志（强制） ---
# --preserve-root 自 coreutils 8.x 起已是默认，无需显式声明
alias rm='rm -I'
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'

# --- 颜色 ---
alias ip='ip --color=auto'
alias diff='diff --color=auto'

# --- 杂项 ---
alias weather='curl -s "wttr.in/Wuhan?F&lang=zh"'

# --- 目录栈 ---
alias ds='dirs -v'
# 匿名函数：循环变量天然局部，不污染全局命名空间
() { local i; for i in {1..9}; do alias "$i"="cd +$i"; done }


# dotfiles 裸仓库
# 使用环境变量 GIT_DIR/GIT_WORK_TREE，让补全函数内部调用的 git 命令也能识别仓库
# GIT_DIR 在 ~/.cfg（隐藏路径，避免污染家目录）
dot() {
    GIT_DIR="$HOME/.cfg" GIT_WORK_TREE="$HOME" git "$@"
}
compdef dot=git

# dota: dot add 的简写，专门用于把新配置纳入白名单
# 用法: dota .config/foo/bar   （路径相对于 $HOME，可带前导 ./）
dota() {
    local p
    for p in "$@"; do
        # 去掉前导 ./ 让路径统一
        p="${p#./}"
        if [[ ! -e "$HOME/$p" ]]; then
            echo "跳过（不存在）: $p" >&2
            continue
        fi
        dot add "$p"
    done
}
compdef dota=git
