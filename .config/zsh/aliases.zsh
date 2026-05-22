# =============================================================================
# aliases.zsh — Command aliases
# =============================================================================
# Note: Some modern replacement tools (eza, bat, rg, etc.) are loaded
# asynchronously via zinit. They may not be available for the first ~1 second
# after shell start. Add a guard if this causes issues.
# =============================================================================

# --- Modern replacements ---
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first --git --time-style=long-iso'
alias la='eza -la --icons --group-directories-first --git'
alias tree='eza --tree --icons --level=2'
alias cat='bat --style=plain --paging=never'
alias less='bat'
alias grep='rg --smart-case'
alias find='fd'
alias du='dust'
alias ps='procs'
alias top='btm'
alias cd='z'       # zoxide smart jump
alias cdi='zi'     # zoxide interactive

# --- Navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# --- File operations ---
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'

# --- Safety ---
alias rm='rm -I --preserve-root'
alias chmod='chmod --preserve-root'
alias chown='chown --preserve-root'

# --- System (Arch Linux) ---
alias pacup='sudo pacman -Syu'
alias pacss='pacman -Ss'
alias pacrm='sudo pacman -Rns'
alias pacclean='sudo pacman -Sc && yay -Sc'
alias paclist='pacman -Qq | fzf --preview "pacman -Qi {}"'
alias yayup='yay -Syu'

# --- Git ---
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gds='git diff --staged'
alias gb='git branch'
alias gco='git checkout'
alias gpl='git pull'
alias gst='git stash'
alias lg='lazygit'

# --- Docker ---
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dstop='docker stop $(docker ps -aq)'
alias drm='docker rm $(docker ps -aq)'
alias dclean='docker system prune -af'

# --- Network ---
alias myip='curl -s https://ipinfo.io/json | jq'
alias ports='ss -tulanp'

# --- Editors ---
alias vim='nvim'

# --- Config management ---
alias zshrc='$EDITOR ~/.config/zsh/zshrc'
alias zshreload='exec zsh'
alias aliasrc='$EDITOR ~/.config/zsh/aliases.zsh'
alias envrc='$EDITOR ~/.config/zsh/env.zsh'

# --- Misc ---
alias py='python'
alias ip='ip -color=auto'
alias df='df -h'
alias free='free -h'
alias y='yazi'
alias ya='yazi'

# -----------------------------------------------------------------------------
# Dotfiles 管理：`dot` 函数（裸仓库位于 $HOME/dotfiles/.git，工作区是 $HOME）
# 使用方式：dot add .config/niri
# -----------------------------------------------------------------------------
if [[ -d "$HOME/dotfiles" ]]; then
	dot() {
		git --git-dir="$HOME/dotfiles/.git" --work-tree="$HOME" "$@"
	}
else
	# 提供一个占位函数以避免误用；实际使用前请确保已运行 setup-bare-repo.sh
	dot() {
		echo "Error: $HOME/dotfiles 不存在；先运行 ~/dotfiles/setup-bare-repo.sh 或修改路径。"
	}
fi

