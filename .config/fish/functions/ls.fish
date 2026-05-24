function ls
	if command -q eza
		command eza --icons $argv
	else
		command ls $argv
	end
end
