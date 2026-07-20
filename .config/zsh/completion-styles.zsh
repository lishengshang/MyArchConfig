# =============================================================================
# completion-styles.zsh — compinit 补全行为 zstyle
# =============================================================================
# 在 compinit 之后设置，控制补全菜单、匹配、颜色、分组、模糊纠错等。
# fzf-tab 接管 Tab 后，部分项（如 menu select）只在 fzf-tab 未加载时作为回退。
# =============================================================================

# --- 补全器链：_complete → _match → _approximate ---
# 顺序：先精确，再模式匹配，最后容错（每级失败才进入下一级）
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*' menu select
# matcher-list：大小写不敏感（小写匹配大小写）+ 子串匹配（任意位置）
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z} r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- 显示：分组 + 颜色 + 缓存 ---
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$ZSH_COMP_CACHE_DIR/zcompcache"
zstyle ':completion:*' special-dirs true            # 补全 . 和 ..

# --- _match：用原始模式（不改变用户输入）---
zstyle ':completion:*:match:*' original only

# --- _approximate：最多容错 2 字符（数值化，比动态公式更稳）---
zstyle ':completion:*:approximate:*' max-errors 2 numeric

# --- 分组标题样式 ---
zstyle ':completion:*:descriptions' format '%F{cyan}── %d ──%f'
zstyle ':completion:*:messages'     format '%F{purple} ── %d ──%f'
zstyle ':completion:*:warnings'     format '%F{red}── 无匹配 ──%f'
zstyle ':completion:*:corrections'  format '%F{yellow}── %d (errors: %e) ──%f'
zstyle ':completion:*:default'      list-prompt '%S%M matches%s'

# --- 进程补全 ---
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*( *[a-z])*=01;34=0=01'
