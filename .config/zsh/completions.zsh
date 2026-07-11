# =============================================================================
# completions.zsh — compinit + 补全样式
# =============================================================================
# compinit 在此同步调用一次（保证 compdef 在 integrations.zsh 之前可用）。
# fast-syntax-highlighting 的 atinit 钩子只做 `zicdreplay`（重放队列），
# 不再重复 compinit。
# =============================================================================

zmodload zsh/complist

# --- compinit（一天复用一次缓存）---
autoload -Uz compinit

typeset -g ZSH_COMPCACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_COMPCACHE" ]] || mkdir -p "$ZSH_COMPCACHE"
typeset -g _zcompdump="$ZSH_COMPCACHE/zcompdump"

# (#qN.mh-24) = 该文件 mtime 在 24h 之内（新缓存）；有则 -C 跳过安全检查
if [[ -n ${_zcompdump}(#qN.mh-24) ]]; then
    compinit -C -d "$_zcompdump"
else
    compinit -d "$_zcompdump"
    # 异步把 dump 编译成 .zwc 字节码（mmap 友好，下次加载 ~5x 快）
    { [[ ! -f "$_zcompdump.zwc" || "$_zcompdump" -nt "$_zcompdump.zwc" ]] \
        && zcompile -R -- "$_zcompdump" } &!
fi
unset _zcompdump

# --- 补全行为 ---
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z} r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$ZSH_COMPCACHE/zcompcache"
zstyle ':completion:*' special-dirs true

# _match 完成的项目用原始模式
zstyle ':completion:*:match:*' original only
# 模糊补全允许 2 个错误（固定值，比动态公式更稳）
zstyle ':completion:*:approximate:*' max-errors 2 numeric

# --- 分组显示格式 ---
zstyle ':completion:*:descriptions' format '%F{cyan}── %d ──%f'
zstyle ':completion:*:messages'     format '%F{purple} ── %d ──%f'
zstyle ':completion:*:warnings'     format '%F{red}── 无匹配 ──%f'
zstyle ':completion:*:corrections'  format '%F{yellow}── %d (errors: %e) ──%f'
zstyle ':completion:*:default'      list-prompt '%S%M matches%s'

# --- 进程补全 ---
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*( *[a-z])*=01;34=0=01'

# ============================================================================
# fzf-tab（异步加载后接管补全菜单）
# ============================================================================

zstyle ':fzf-tab:*' fzf-flags '--height=40%' '--layout=reverse' '--border=rounded' '--info=inline'
zstyle ':fzf-tab:*' switch-group ',' '.'

# 行为增强
zstyle ':fzf-tab:*' continuous-trigger '/'         # 在 fzf 内按 / 直接进入子目录
zstyle ':fzf-tab:*' accept-line space             # 选中后回车接受补全并加空格，不直接执行
zstyle ':fzf-tab:*' show-group full                # 按 tag 分组（commands/branches/files...）
zstyle ':fzf-tab:*' single-group color header      # 单组时显示彩色 header
zstyle ':fzf-tab:*' prefix ''                      # 去掉候选前的 -- / - 前缀
zstyle ':fzf-tab:*' fzf-bindings 'ctrl-space:toggle' # Ctrl+Space 多选切换

# 通用 dir 预览
zstyle ':fzf-tab:complete:cd:*'             fzf-preview 'eza -1 --color=always --icons --group-directories-first $realpath 2>/dev/null || ls $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*'     fzf-preview 'eza -1 --color=always --icons --group-directories-first $realpath 2>/dev/null || ls $realpath'
zstyle ':fzf-tab:complete:(\\|*/|)ls:*'     fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || ls $realpath'

# 文件预览
zstyle ':fzf-tab:complete:(\\|*/|)cat:*'    fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:nvim:*'           fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null'

# Git 预览
zstyle ':fzf-tab:complete:git-(add|diff|restore|show|stash):*' fzf-preview 'git diff --color=always $word 2>/dev/null | head -100'
zstyle ':fzf-tab:complete:git-checkout:*'   fzf-preview 'git log --color=always --oneline --graph $word 2>/dev/null | head -20'
zstyle ':fzf-tab:complete:git-log:*'        fzf-preview 'git log --color=always --oneline --graph 2>/dev/null | head -50'

# 进程 / systemd / man
zstyle ':fzf-tab:complete:kill:*'           fzf-preview 'procs --pid=$word --color=always 2>/dev/null || ps -p $word -o cmd'
zstyle ':fzf-tab:complete:systemctl-*:*'    fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
zstyle ':fzf-tab:complete:man:*'            fzf-preview 'man $word 2>/dev/null | head -50'

# 环境变量
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
    fzf-preview 'echo ${(P)word}'
