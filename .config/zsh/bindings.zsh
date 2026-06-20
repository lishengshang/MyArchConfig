# =============================================================================
# bindings.zsh — Key bindings
# =============================================================================

# Use Emacs-style keybindings
bindkey -e

# --- Line editing ---
bindkey '^[[3~' delete-char             # Delete key
bindkey '^[[1;5C' forward-word          # Ctrl+Right
bindkey '^[[1;5D' backward-word         # Ctrl+Left
bindkey '^H' backward-kill-word         # Ctrl+Backspace

# --- Completion ---
bindkey '^[[Z' reverse-menu-complete    # Shift+Tab

# --- Autosuggestion accept ---
bindkey ',' autosuggest-accept

# --- Directory stack navigation ---
for index ({1..9}) alias "$index"="cd +${index}"; unset index

# --- fzf key bindings (Ctrl+T files, Ctrl+R history, Alt+C cd) ---
source /usr/share/fzf/key-bindings.zsh
