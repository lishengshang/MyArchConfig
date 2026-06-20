# =============================================================================
# env.zsh — interactive-shell environment variables
# =============================================================================
# Only sourced for interactive shells (from zshrc).
# Non-interactive PATH additions go in ~/.zshenv.

# --- Editor ---
export EDITOR='nvim'
export VISUAL='nvim'

# --- Locale ---
export LANG=zh_CN.UTF-8

# --- History ---
HISTSIZE=100000
SAVEHIST=100000
export HISTFILE="$XDG_STATE_HOME/zsh/history"

# --- FZF ---
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'

# --- Atuin (disabled binding, if installed) ---
export ATUIN_NOBIND='true'

# --- Colors (for ls, eza, completion menus, etc.) ---
export LS_COLORS="di=1;34:ln=1;36:ex=1;32"

# --- Command correction prompt ---
export SPROMPT="Correct '%R' to '%r'? [nyae]: "
