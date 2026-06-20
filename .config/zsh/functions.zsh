# =============================================================================
# functions.zsh — Shell helper functions
# =============================================================================

# --- Create directory and enter it ---
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# --- Universal archive extractor ---
extract() {
  if [[ ! -f "$1" ]]; then
    echo "'$1' is not a valid file"
    return 1
  fi
  case "$1" in
    *.tar.bz2) tar xjf "$1"   ;;
    *.tar.gz)  tar xzf "$1"   ;;
    *.bz2)     bunzip2 "$1"   ;;
    *.rar)     unrar x "$1"   ;;
    *.gz)      gunzip "$1"    ;;
    *.tar)     tar xf "$1"    ;;
    *.tbz2)    tar xjf "$1"   ;;
    *.tgz)     tar xzf "$1"   ;;
    *.zip)     unzip "$1"     ;;
    *.Z)       uncompress "$1";;
    *.7z)      7z x "$1"      ;;
    *)         echo "'$1' cannot be extracted via extract()" ;;
  esac
}

# --- Fuzzy-find file and open in editor ---
fv() {
  local file
  file=$(fd --type f --hidden --exclude .git 2>/dev/null | \
         fzf --height=40% --border --preview 'bat --color=always --style=numbers --line-range=:500 {}')
  [[ -n "$file" ]] && ${EDITOR:-nvim} "$file"
}

# --- Fuzzy-find file and copy path to clipboard ---
ff() {
  local file
  file=$(fd --type f --hidden --exclude .git 2>/dev/null | \
         fzf --height=40% --border --preview 'bat --color=always --line-range :50 {}')
  if [[ -n "$file" ]]; then
    echo "$file" | xclip -selection clipboard
    echo "Path copied: $file"
  fi
}

# --- Jump to git repo root ---
gr() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -n "$root" ]]; then
    cd "$root"
  else
    echo "Not in a git repository"
    return 1
  fi
}

# --- Fuzzy-find and kill a process ---
fkill() {
  local pid
  pid=$(ps aux --sort=-%cpu | fzf --height=40% --header-lines=1 | awk '{print $2}')
  if [[ -n "$pid" ]]; then
    echo "Kill process $pid? (y/N)"
    read -r confirm
    [[ "$confirm" =~ ^[Yy]$ ]] && kill "$pid"
  fi
}

# --- Check port usage ---
port() {
  if [[ -z "$1" ]]; then
    echo "Usage: port <number>"
    return 1
  fi
  sudo lsof -i ":$1"
}

# --- Create Python venv ---
venv() {
  local name="${1:-.venv}"
  python -m venv "$name"
  echo "Virtual environment created: $name"
  echo "Activate with: source $name/bin/activate"
}

# --- Git repository stats ---
gstat() {
  echo "Repository Statistics"
  echo "========================"
  echo "Commits:     $(git rev-list --count HEAD 2>/dev/null || echo 'N/A')"
  echo "Branches:   $(git branch 2>/dev/null | wc -l)"
  echo ""
  echo "Top contributors:"
  git shortlog -sn --all 2>/dev/null | head -10
  echo ""
  echo "Recent changes (last 10 commits):"
  git diff --stat HEAD~10 HEAD 2>/dev/null || echo "  (less than 10 commits)"
}

# --- System info overview ---
sysinfo() {
  echo "System Information"
  echo "========================"
  echo "OS:       $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
  echo "Kernel:   $(uname -r)"
  echo "Shell:    $SHELL"
  echo "Uptime:   $(uptime -p 2>/dev/null || uptime)"
  echo "Memory:   $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
  echo "Disk (/): $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
  echo ""
  echo "Packages: $(pacman -Q 2>/dev/null | wc -l) (pacman)"
}

# --- Quick weather check ---
weather() {
  curl -s "wttr.in/${1:-Wuhan}?F&lang=zh" | head -30
}

# --- Backup dotfiles ---
backup-dotfiles() {
  local backup_dir="$HOME/dotfiles-backup-$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$backup_dir"
  cp ~/.zshenv "$backup_dir/"
  cp -r ~/.config/zsh "$backup_dir/"
  cp ~/.p10k.zsh "$backup_dir/" 2>/dev/null
  echo "Dotfiles backed up to: $backup_dir"
}

# --- Auto-refresh git status via inotifywait ---
# Requires: inotify-tools (install: sudo pacman -S inotify-tools)
# Watches the current git repo's working tree; on file change, sends USR1
# to trigger prompt refresh automatically.
__git_watch_pid=0

__git_watch_start() {
  __git_watch_stop

  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
  [[ -z "$git_root" ]] && return 0

  # Silently skip if inotifywait is not installed
  (( $+commands[inotifywait] )) || return 0

  inotifywait -r -m -q \
    -e modify,create,delete,move,close_write \
    --exclude '(\.git/|node_modules/|__pycache__/|\.venv/|target/|build/|dist/|\.cache/)' \
    "$git_root" 2>/dev/null | while read -r; do
    kill -USR1 $$ 2>/dev/null || exit
  done &!
  __git_watch_pid=$!
}

__git_watch_stop() {
  (( __git_watch_pid )) && kill $__git_watch_pid 2>/dev/null
  __git_watch_pid=0
}

TRAPUSR1() {
  p10k refresh 2>/dev/null
  zle reset-prompt 2>/dev/null
}

__git_watch_chpwd() { __git_watch_start }
add-zsh-hook chpwd __git_watch_chpwd

__git_watch_exit() { __git_watch_stop }
add-zsh-hook zshexit __git_watch_exit

# Start watching on initial load
__git_watch_start

# --- Chezmoi helper ---
chez() {
  case "$1" in
    add)    shift && chezmoi add "$@"   ;;
    apply)  chezmoi apply               ;;
    edit)   shift && chezmoi edit "$@"  ;;
    diff)   chezmoi diff                ;;
    status) chezmoi status              ;;
    cd)     cd "$(chezmoi source-path)" ;;
    *)      chezmoi "$@"                ;;
  esac
}
