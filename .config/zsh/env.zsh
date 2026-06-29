# =============================================================================
# env.zsh — 交互式 zsh 环境变量
# =============================================================================
# 大部分通用变量（XDG/EDITOR/LANG/PATH/FZF_DEFAULT_*）已经在
# ~/.config/environment.d/ 中定义，systemd 加载后全 shell 共享。
#
# 此文件只放：
#   - zsh 特有的（HISTSIZE, SPROMPT...）
#   - 需要 shell 逻辑（条件、命令替换）的变量
#   - 兜底（environment.d 未生效时，如 SSH/tmux/非 systemd 会话）
# =============================================================================

# --- 兜底：EDITOR / LANG（environment.d 未加载时）---
: "${EDITOR:=nvim}"
: "${VISUAL:=$EDITOR}"
: "${LANG:=en_US.UTF-8}"
export EDITOR VISUAL LANG

# --- History ---
HISTSIZE=100000
SAVEHIST=100000
# HISTFILE 路径符合 XDG 规范，依赖 XDG_STATE_HOME（environment.d 已设）
export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
# 确保目录存在
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"

# --- 慢命令自动报告耗时（>5s）---
REPORTTIME=5
# 自定义 time 格式（配合 REPORTTIME 和手动 `time cmd`）
TIMEFMT=$'real %*E  user %*U  sys %*S  cpu %P  maxmem %M KB'

# --- 命名目录（cd ~code / ~cfg / ~dl；prompt 里也显示短名）---
hash -d code="$HOME/Code" \
        docs="$HOME/Documents" \
        dl="$HOME/Downloads" \
        cfg="$HOME/.config" \
        zsh="$ZDOTDIR" 2>/dev/null

# --- FZF 命令（systemd environment.d 兜底）---
# FZF_DEFAULT_COMMAND / FZF_CTRL_T_COMMAND / FZF_ALT_C_COMMAND
# 定义在 ~/.config/environment.d/ 中，全 shell 共享。
# 只在 environment.d 未生效时（SSH/tmux/非 systemd 会话）做 fallback。
: "${FZF_DEFAULT_COMMAND:=fd --type f --hidden --follow --exclude .git}"
: "${FZF_CTRL_T_COMMAND:=fd --type f --hidden --follow --exclude .git}"
: "${FZF_ALT_C_COMMAND:=fd --type d --hidden --follow --exclude .git}"
export FZF_DEFAULT_COMMAND FZF_CTRL_T_COMMAND FZF_ALT_C_COMMAND

# --- FZF zsh 主题（命令仍由 environment.d 提供）---
export FZF_DEFAULT_OPTS='
    --height 50%
    --layout=reverse
    --border=rounded
    --info=inline
    --prompt="❯ "
    --pointer="▶"
    --marker="✓"
    --color=fg:#c0caf5,bg:-1,hl:#7aa2f7
    --color=fg+:#c0caf5,bg+:#1f2335,hl+:#7dcfff
    --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
    --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
'

# 文件预览 (Ctrl+T)
if command -v bat &>/dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
fi

# 目录预览 (Alt+C)
if command -v eza &>/dev/null; then
    export FZF_ALT_C_OPTS="--preview 'eza --tree --icons --color=always --level=2 {}'"
fi

# 历史搜索 (Ctrl+R)
export FZF_CTRL_R_OPTS='--preview "echo {}" --preview-window down:3:wrap --bind "ctrl-/:toggle-preview"'

# --- Atuin（init 在 integrations.zsh）---

# --- zsh 命令纠错提示 ---
export SPROMPT="Correct '%R' to '%r'? [nyae]: "

# --- LS_COLORS ---
# 优先 vivid（缓存 ~/.cache/vivid/lscolors，仅在 vivid 二进制变化时刷新），
# 失败或不存在则回退 dircolors -b。
__init_lscolors() {
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/vivid/lscolors"
    if (( $+commands[vivid] )); then
        if [[ ! -s "$cache" ]] || [[ "$cache" -ot "$commands[vivid]" ]]; then
            mkdir -p "${cache:h}"
            vivid generate molokai > "$cache" 2>/dev/null || rm -f "$cache"
        fi
        [[ -s "$cache" ]] && { export LS_COLORS="$(<"$cache")"; return 0 }
    fi
    # 兜底：dircolors
    (( $+commands[dircolors] )) && eval "$(dircolors -b 2>/dev/null)"
}
__init_lscolors
unfunction __init_lscolors
