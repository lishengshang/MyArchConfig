function lt -d "List files as tree"
    if command -q eza
        command eza --icons --tree --level=3 --group-directories-first --color=auto $argv
    else
        command find . -maxdepth 3 -print | head -100
    end
end
