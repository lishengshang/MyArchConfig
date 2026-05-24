function df
	if command -q duf
		command duf $argv
	else
		command df $argv
	end
end
