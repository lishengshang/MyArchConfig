# =============================================================================
# plugins.zsh — Zinit plugin manager and all plugins
# =============================================================================
# IMPORTANT: This file sets up fpath and loads all plugins.
# compinit runs LATER in completions.zsh (after all plugins are declared).
#
# Strategy:
#   - Critical/small plugins load synchronously (no 'wait lucid')
#   - Heavy/cosmetic plugins use 'wait lucid' for faster startup
#   - All completion files are symlinked into ~/.local/share/zinit/completions
#     by zinit, which is on fpath so compinit finds them
# =============================================================================

# --- fpath setup (must be BEFORE compinit) ---
# Zinit-managed completions (system/generated, lower priority)
fpath=("$HOME/.local/share/zinit/completions" $fpath)
# Custom completion files (hermes, fnm, docker, etc. — higher priority)
fpath=("$HOME/.config/zsh/completions" $fpath)

# --- Install & load Zinit ---
ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"
if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
    print -P "%F{33}Installing Zinit Plugin Manager...%f"
    command mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" --depth=1 && \
        print -P "%F{34}Zinit installed successfully%f" || \
        print -P "%F{196}Zinit clone failed%f"
fi

source "$ZINIT_HOME/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# --- Zinit annexes (required for gh-r, rust, etc.) ---
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# --- Oh-My-Zsh libraries (synchronous: small, required for completions) ---
zinit light-mode for \
    OMZL::clipboard.zsh \
    OMZL::history.zsh \
    OMZL::key-bindings.zsh \
    OMZL::completion.zsh

# --- Powerlevel10k theme (synchronous: needed for instant prompt) ---
zinit ice depth=1
zinit light romkatv/powerlevel10k

# --- Async plugins (deferred loading for faster startup) ---
zinit wait lucid light-mode for \
    zsh-users/zsh-autosuggestions \
    zdharma-continuum/fast-syntax-highlighting \
    zdharma-continuum/history-search-multi-word

# fzf-tab: enhances tab completion with fzf (must load after compinit, so async is fine)
zinit wait lucid for \
    Aloxaf/fzf-tab

# zoxide: smarter cd with interactive selection
zinit wait lucid as"command" from"gh-r" \
    mv"zoxide-* -> zoxide" pick"zoxide/zoxide" \
    atload'eval "$(zoxide init zsh)"' for \
    ajeetdsouza/zoxide

# --- CLI tools from GitHub releases (async) ---
zinit wait lucid as"command" from"gh-r" for \
    mv"fd* -> fd" pick"fd/fd" \
        sharkdp/fd \
    mv"bat* -> bat" pick"bat/bat" \
        sharkdp/bat \
    mv"eza* -> eza" pick"eza/eza" \
        eza-community/eza \
    mv"ripgrep* -> rg" pick"rg/rg" \
        BurntSushi/ripgrep \
    pick"sd" \
        chmln/sd \
    mv"delta* -> delta" pick"delta/delta" \
        dandavison/delta \
    mv"hyperfine* -> hyperfine" pick"hyperfine/hyperfine" \
        sharkdp/hyperfine \
    mv"dust* -> dust" pick"dust/dust" \
        bootandy/dust \
    mv"procs* -> procs" pick"procs/procs" \
        dalance/procs \
    mv"btm* -> btm" pick"btm/btm" \
        ClementTsang/bottom

# fzf (async)
zinit wait lucid as"program" from"gh-r" pick"fzf" for \
    junegunn/fzf

# forgit: interactive git operations via fzf (async)
zinit wait lucid for \
    wfxr/forgit
