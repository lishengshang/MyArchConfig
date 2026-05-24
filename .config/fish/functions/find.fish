function find
	if command -q fd
		command fd $argv
	else
		command find $argv
	end
end
