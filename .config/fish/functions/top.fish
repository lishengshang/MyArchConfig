function top
	if command -q btop
		command btop $argv
	else
		command top $argv
	end
end
