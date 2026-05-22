# =============================================================================
# completions.zsh — Completion system setup
# =============================================================================
# compinit is called EXACTLY ONCE, right here.
# All plugins and fpath entries must be set up BEFORE this file is sourced.
#
# Custom completions go in: ~/.config/zsh/completions/_<command>
# Regenerate with: hermes completion zsh > ~/.config/zsh/completions/_hermes
# =============================================================================

# --- Load and initialize completion system ---
autoload -Uz compinit
zmodload zsh/complist

# Always rebuild the dump. This is fast enough on modern machines and avoids
# the cache-staleness problems that break newly installed completion files.
# The dump file is still written so that zsh can mmap it for fast access.
compinit -d "${ZDOTDIR:-$HOME}/.zcompdump"

# --- Completion styles ---
# Completers: _complete (normal), _match (glob patterns like *gate*)
zstyle ':completion:*' completer _complete _match
zstyle ':completion:*' menu select
# Matcher 1: case-insensitive + prefix matching (gate -> gateway)
# Matcher 2: substring matching on both sides (fallback)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z} r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
# _match: only show completions not already covered by _complete
zstyle ':completion:*:match:*' original only

zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'

# --- fzf-tab previews ---
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --graph --color=always $word | head -20'
zstyle ':fzf-tab:complete:kill:*' fzf-preview 'procs --pid=$word --color=always'
