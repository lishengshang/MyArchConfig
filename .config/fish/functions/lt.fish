function lt
	if command -q eza
		command eza --icons --tree $argv
	else
		command ls --tree $argv 2>/dev/null || command ls -R $argv
	end
end
