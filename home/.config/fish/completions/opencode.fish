# Completions for opencode
complete -c opencode -f

# 主命令补全
complete -c opencode -n __fish_use_subcommand -a completion -d "Generate shell completion script"
complete -c opencode -n __fish_use_subcommand -a acp -d "Start ACP server"
complete -c opencode -n __fish_use_subcommand -a mcp -d "Manage MCP servers"
complete -c opencode -n __fish_use_subcommand -a attach -d "Attach to running server"
complete -c opencode -n __fish_use_subcommand -a run -d "Run with a message"
complete -c opencode -n __fish_use_subcommand -a debug -d "Debugging tools"
complete -c opencode -n __fish_use_subcommand -a providers -d "Manage providers"
complete -c opencode -n __fish_use_subcommand -a agent -d "Manage agents"
complete -c opencode -n __fish_use_subcommand -a upgrade -d "Upgrade opencode"
complete -c opencode -n __fish_use_subcommand -a uninstall -d "Uninstall opencode"
complete -c opencode -n __fish_use_subcommand -a serve -d "Start headless server"
complete -c opencode -n __fish_use_subcommand -a web -d "Start web interface"
complete -c opencode -n __fish_use_subcommand -a models -d "List available models"
complete -c opencode -n __fish_use_subcommand -a stats -d "Show token usage"
complete -c opencode -n __fish_use_subcommand -a export -d "Export session data"
complete -c opencode -n __fish_use_subcommand -a import -d "Import session data"
complete -c opencode -n __fish_use_subcommand -a github -d "Manage GitHub agent"
complete -c opencode -n __fish_use_subcommand -a pr -d "Fetch and checkout PR"
complete -c opencode -n __fish_use_subcommand -a session -d "Manage sessions"
complete -c opencode -n __fish_use_subcommand -a plugin -d "Install plugin"
complete -c opencode -n __fish_use_subcommand -a db -d "Database tools"

# 全局选项
complete -c opencode -s h -l help -d "Show help"
complete -c opencode -s v -l version -d "Show version"

# attach 子命令
complete -c opencode -n "__fish_seen_subcommand_from attach" -l port -d "Server port" -r

# run 子命令
complete -c opencode -n "__fish_seen_subcommand_from run" -l model -d "Model to use" -r
complete -c opencode -n "__fish_seen_subcommand_from run" -l provider -d "Provider to use" -r

# models 子命令
complete -c opencode -n "__fish_seen_subcommand_from models" -a "(opencode models 2>/dev/null | string match -r '^\S+' | head -20)"
