function du
	if command -q dust
		command dust $argv
	else
		command du $argv
	end
end
