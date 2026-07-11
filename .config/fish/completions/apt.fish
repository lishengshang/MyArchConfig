# Completions for apt (Arch package manager wrapper)
complete -c apt -f

# 子命令补全
complete -c apt -n __fish_use_subcommand -a update -d "Sync databases and update system"
complete -c apt -n __fish_use_subcommand -a upgrade -d "Sync databases and update system"
complete -c apt -n __fish_use_subcommand -a install -d "Install packages"
complete -c apt -n __fish_use_subcommand -a remove -d "Remove packages and dependencies"
complete -c apt -n __fish_use_subcommand -a search -d "Search for packages"
complete -c apt -n __fish_use_subcommand -a show -d "Show package details"
complete -c apt -n __fish_use_subcommand -a clean -d "Clean package cache"
complete -c apt -n __fish_use_subcommand -a orphans -d "List orphaned packages"
complete -c apt -n __fish_use_subcommand -a help -d "Show help"
complete -c apt -n __fish_use_subcommand -s h -l help -d "Show help"

# install 子命令的包补全
complete -c apt -n "__fish_seen_subcommand_from install" -xa "(pacman -Slq)"

# remove 子命令的已安装包补全
complete -c apt -n "__fish_seen_subcommand_from remove" -xa "(pacman -Qq)"

# search 子命令的补全
complete -c apt -n "__fish_seen_subcommand_from search" -xa "(pacman -Slq)"

# show 子命令的包补全
complete -c apt -n "__fish_seen_subcommand_from show" -xa "(pacman -Slq)"
