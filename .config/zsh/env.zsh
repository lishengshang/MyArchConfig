# =============================================================================
# env.zsh — 交互式 zsh 环境变量
# =============================================================================
# 大部分通用变量（XDG/EDITOR/LANG/PATH/FZF_DEFAULT_*）已经在
# ~/.config/environment.d/ 中定义，systemd 加载后全 shell 共享。
#
# 此文件只放：
#   - zsh 特有的（HISTSIZE, SPROMPT...）
#   - 需要 shell 逻辑（条件、命令替换）的变量
# =============================================================================

# --- History ---
HISTSIZE=100000
SAVEHIST=100000
# HISTFILE 路径符合 XDG 规范，依赖 XDG_STATE_HOME（environment.d 已设）
export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
# 确保目录存在
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"

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

# --- Atuin 禁用（如果未来装了避免按 Ctrl+R 冲突）---
export ATUIN_NOBIND='true'

# --- zsh 命令纠错提示 ---
export SPROMPT="Correct '%R' to '%r'? [nyae]: "

# --- LS_COLORS（如果系统没自动生成 dircolors）---
# 注意：你之前手写的 LS_COLORS 太简单，会破坏 fzf-tab list-colors
# 改用 vivid（如果装了）或 dircolors 标准配色
if command -v vivid &>/dev/null; then
    export LS_COLORS="$(vivid generate molokai 2>/dev/null)"
elif [[ -z "$LS_COLORS" ]] && command -v dircolors &>/dev/null; then
    eval "$(dircolors -b 2>/dev/null)"
fi
