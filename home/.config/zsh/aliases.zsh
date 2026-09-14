# =============================================================================
# aliases.zsh - 传统别名（abbr 之外的场景）
# =============================================================================
# 大部分 alias 已迁移到 abbreviations.zsh（按空格展开为完整命令）。
# 此文件保留以下场景的别名：
#   1. 透明替换：ls/cat/du/df/top（不需要看到原命令）
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
        du   'dust'
        df   'duf'
        top  'btop'
    )
    for cmd in ${(k)_repl}; do
        tool="${_repl[$cmd]%% *}"
        (( $+commands[$tool] )) && alias "$cmd=$_repl[$cmd]"
    done
}
# cd 由 integrations.zsh 中 zoxide --cmd cd 接管
# find/grep/ps 不替换（与 fish/conf.d/25-aliases.fish 的决策保持一致）：
#   find: fd 语法与 find 不兼容，破坏脚本调用
#   grep: rg 的 -E/-h 等参数语义与 grep 不同，会炸交互式管道
#   ps:   `ps aux` 会被 procs 当作过滤器，静默返回空结果

# --- 安全标志（强制） ---
# --preserve-root 自 coreutils 8.x 起已是默认，无需显式声明
alias rm='rm -I'
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'

# --- 颜色 ---
alias ip='ip --color=auto'
alias diff='diff --color=auto'

# --- 目录栈 ---
# PUSHD_MINUS 已开启（options.zsh）：`cd -N` 才对应 `dirs -v` 显示的编号
alias ds='dirs -v'


# =============================================================================
# dotfiles 管理函数（GNU Stow + 普通 git 方案）
# =============================================================================
# 迁移说明:
#   旧方案用 bare repo（GIT_DIR=$HOME/.cfg GIT_WORK_TREE=$HOME），
#   dot() 通过环境变量让 git 识别仓库。
#   新方案改为 ~/dotfiles 普通 git 仓库 + GNU Stow 部署软链，
#   dot() 直接用 `git -C ~/dotfiles`，无需环境变量，补全也天然正常。
#
#   旧 _dot() 补全函数不再需要（普通 git 补全自动生效），
#   但保留 dota() 简写函数方便日常使用。
# =============================================================================

# dot: 在 ~/dotfiles 仓库里执行 git 命令
# 用法: dot status / dot diff / dot add ... / dot commit -m "..." / dot push
dot() {
    git -C "$HOME/dotfiles" "$@"
}

# dota: dot add -f 的简写，专门用于把新配置强制纳入跟踪
# 用法: dota home/.config/foo/bar   （路径相对于 ~/dotfiles 仓库根）
dota() {
    dot add -f "$@"
}

# --- 便捷缩写 ---
# dots/dotd/dotds/dotl/dotc/dotp 已迁移到 abbreviations.zsh（abbr 展开可见完整命令）