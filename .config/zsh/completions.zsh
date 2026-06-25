# =============================================================================
# completions.zsh — 补全系统初始化
# =============================================================================
# compinit 在此显式调用一次。所有 fpath 修改必须在 plugins.zsh 中完成。
# fast-syntax-highlighting 通过 atinit 钩子调用 zicompinit + zicdreplay，
# 但我们仍需在此为同步插件设置补全样式。
# =============================================================================

# --- compinit ---
zmodload zsh/complist

# 缓存 dump 24h，加速启动 ~30ms
local compdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d "${compdump:h}" ]] || mkdir -p "${compdump:h}"
if [[ -f "$compdump" && $(date -r "$compdump" +%j 2>/dev/null) == $(date +%j) ]]; then
    compinit -C -d "$compdump"
else
    compinit -d "$compdump"
fi

# --- 补全行为样式 ---
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z} r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# 仅 _match 完成的项目用原始模式
zstyle ':completion:*:match:*' original only

# 模糊补全允许 1 个错误
zstyle ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'

# --- 分组显示格式（中英文混排）---
zstyle ':completion:*:descriptions' format '%F{cyan}── %d ──%f'
zstyle ':completion:*:messages'     format '%F{purple} ── %d ──%f'
zstyle ':completion:*:warnings'     format '%F{red}── 无匹配 ──%f'
zstyle ':completion:*:corrections'  format '%F{yellow}── %d (errors: %e) ──%f'
zstyle ':completion:*:default'      list-prompt '%S%M matches%s'

# --- 进程补全（带高亮）---
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*( *[a-z])*=01;34=0=01'

# --- 文件名补全 ---
zstyle ':completion:*' special-dirs true   # . 和 .. 也补全

# ============================================================================
# fzf-tab（必须 zstyle 在它加载后生效，但它异步，所以这里只是声明）
# ============================================================================

# 关闭 zsh 默认菜单（让 fzf-tab 接管）
zstyle ':completion:*' menu no

# fzf-tab 选项
zstyle ':fzf-tab:*' fzf-flags '--height=40%' '--layout=reverse' '--border=rounded' '--info=inline'
zstyle ':fzf-tab:*' switch-group ',' '.'   # 用 , . 在分组间切换

# 各种命令的预览
zstyle ':fzf-tab:complete:cd:*' fzf-preview \
    'eza -1 --color=always --icons --group-directories-first $realpath 2>/dev/null || ls $realpath'

zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview \
    'eza -1 --color=always --icons --group-directories-first $realpath 2>/dev/null || ls $realpath'

zstyle ':fzf-tab:complete:(\\|*/|)ls:*' fzf-preview \
    'eza -1 --color=always --icons $realpath 2>/dev/null || ls $realpath'

zstyle ':fzf-tab:complete:(\\|*/|)cat:*' fzf-preview \
    'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null'

zstyle ':fzf-tab:complete:nvim:*' fzf-preview \
    'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null'

zstyle ':fzf-tab:complete:git-(add|diff|restore|show|stash):*' fzf-preview \
    'git diff --color=always $word 2>/dev/null | head -100'

zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
    'git log --color=always --oneline --graph $word 2>/dev/null | head -20'

zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
    'git log --color=always --oneline --graph 2>/dev/null | head -50'

zstyle ':fzf-tab:complete:kill:*' fzf-preview \
    'procs --pid=$word --color=always 2>/dev/null || ps -p $word -o cmd'

zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview \
    'SYSTEMD_COLORS=1 systemctl status $word'

zstyle ':fzf-tab:complete:man:*' fzf-preview \
    'man $word 2>/dev/null | head -50'

# 环境变量预览
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
    fzf-preview 'echo ${(P)word}'
