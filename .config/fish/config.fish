if status is-interactive
    # Commands to run in interactive sessions can go here
end
set fish_greeting ""
fish_add_path ~/.local/bin

# ---- dotfiles 裸仓库 alias ----
alias dotfiles='git --git-dir=$HOME/dotfiles --work-tree=$HOME'

starship init fish | source
zoxide init fish --cmd cd | source

function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

function cat
	if command -q bat
		command bat $argv
	else
		command cat $argv
	end
end

function ls
	if command -q eza
		command eza --icons $argv
	else
		command ls $argv
	end
end
function lt
	if command -q eza
		command eza --icons --tree $argv
	else
		command ls --tree $argv 2>/dev/null || command ls -R $argv
	end
end
