if status is-interactive
    # Commands to run in interactive sessions can go here
end
set fish_greeting ""
fish_add_path ~/.local/bin

# ---- dotfiles 裸仓库 alias ----
alias dotfiles='git --git-dir=$HOME/dotfiles --work-tree=$HOME'

starship init fish | source
zoxide init fish --cmd cd | source

