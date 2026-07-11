# ============================================================================
# 25-aliases.fish — 别名（特殊场景，无法用 abbr 替代）
# ============================================================================
# alias 与 abbr 的区别：
#   - alias 是真正的命令替换，无法看到原始命令
#   - 适合：安全标志(rm -I)、强制选项(ip --color)、不希望展开的场景
# ============================================================================

# --- 现代化替代（透明替换，不需要看到原命令） ---
alias ls 'eza --icons --group-directories-first'
alias cat 'bat --style=plain --paging=never'
alias grep 'rg --smart-case'
alias find fd
alias du dust
alias df duf
alias ps procs
alias top btop

# --- 安全标志（必须永远生效） ---
alias rm 'rm -I --preserve-root'
alias chmod 'chmod --preserve-root'
alias chown 'chown --preserve-root'
alias cp 'cp -iv'
alias mv 'mv -iv'
alias mkdir 'mkdir -pv'

# --- 颜色增强（默认就该有） ---
alias ip 'ip --color=auto'
alias diff 'diff --color=auto'

# --- yazi（你的现有 y 函数已处理 cwd，保留） ---
# y 是 function，不在这里
