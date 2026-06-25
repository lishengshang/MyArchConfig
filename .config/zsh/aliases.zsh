# =============================================================================
# aliases.zsh — 传统别名（abbr 之外的场景）
# =============================================================================
# 大部分 alias 已迁移到 abbreviations.zsh（按空格展开为完整命令）。
# 此文件保留以下场景的别名：
#   1. 透明替换：ls/cat/find/grep（不需要看到原命令）
#   2. 安全标志：rm/cp/mv 必须永远生效
#   3. 颜色：ip/diff 默认加 --color
# =============================================================================

# --- 现代化透明替换 ---
alias ls='eza --icons --group-directories-first'
alias cat='bat --style=plain --paging=never'
alias grep='rg --smart-case'
alias find='fd'
alias du='dust'
alias df='duf'
alias ps='procs'
alias top='btop'
# cd 由 integrations.zsh 中 zoxide --cmd cd 接管

# --- 安全标志（强制） ---
alias rm='rm -I --preserve-root'
alias chmod='chmod --preserve-root'
alias chown='chown --preserve-root'
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'

# --- 颜色 ---
alias ip='ip --color=auto'
alias diff='diff --color=auto'

# --- 目录栈 ---
alias ds='dirs -v'
for index ({1..9}) alias "$index"="cd +${index}"; unset index
