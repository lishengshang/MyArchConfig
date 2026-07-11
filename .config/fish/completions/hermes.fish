# Completions for hermes
complete -c hermes -f

# 主命令补全
complete -c hermes -n __fish_use_subcommand -a chat -d "Interactive chat"
complete -c hermes -n __fish_use_subcommand -a model -d "Select model"
complete -c hermes -n __fish_use_subcommand -a fallback -d "Manage fallback"
complete -c hermes -n __fish_use_subcommand -a secrets -d "Manage secrets"
complete -c hermes -n __fish_use_subcommand -a migrate -d "Migrate config"
complete -c hermes -n __fish_use_subcommand -a gateway -d "Messaging gateway"
complete -c hermes -n __fish_use_subcommand -a proxy -d "Local proxy"
complete -c hermes -n __fish_use_subcommand -a lsp -d "LSP management"
complete -c hermes -n __fish_use_subcommand -a setup -d "Setup wizard"
complete -c hermes -n __fish_use_subcommand -a skills -d "Manage skills"
complete -c hermes -n __fish_use_subcommand -a plugins -d "Manage plugins"
complete -c hermes -n __fish_use_subcommand -a sessions -d "Manage sessions"
complete -c hermes -n __fish_use_subcommand -a config -d "View config"
complete -c hermes -n __fish_use_subcommand -a doctor -d "Check dependencies"
complete -c hermes -n __fish_use_subcommand -a status -d "Show status"
complete -c hermes -n __fish_use_subcommand -a version -d "Show version"
complete -c hermes -n __fish_use_subcommand -a update -d "Update hermes"
complete -c hermes -n __fish_use_subcommand -a uninstall -d "Uninstall hermes"
complete -c hermes -n __fish_use_subcommand -a mcp -d "Manage MCP"
complete -c hermes -n __fish_use_subcommand -a tools -d "Configure tools"
complete -c hermes -n __fish_use_subcommand -a memory -d "Memory config"
complete -c hermes -n __fish_use_subcommand -a backup -d "Backup data"
complete -c hermes -n __fish_use_subcommand -a checkpoints -d "Inspect checkpoints"
complete -c hermes -n __fish_use_subcommand -a kanban -d "Collaboration board"
complete -c hermes -n __fish_use_subcommand -a cron -d "Cron jobs"
complete -c hermes -n __fish_use_subcommand -a webhook -d "Webhook subscriptions"
complete -c hermes -n __fish_use_subcommand -a debug -d "Debug tools"
complete -c hermes -n __fish_use_subcommand -a dump -d "Dump setup info"
complete -c hermes -n __fish_use_subcommand -a logs -d "View logs"
complete -c hermes -n __fish_use_subcommand -a dashboard -d "Web UI"
complete -c hermes -n __fish_use_subcommand -a profile -d "Manage profiles"
complete -c hermes -n __fish_use_subcommand -a completion -d "Generate completions"

# 全局选项
complete -c hermes -s h -l help -d "Show help"
complete -c hermes -l version -d "Show version"
complete -c hermes -s m -l model -d "Model to use" -r
complete -c hermes -l provider -d "Provider to use" -r
complete -c hermes -l yolo -d "Auto-accept mode"
complete -c hermes -l cli -d "CLI mode"
complete -c hermes -l dev -d "Developer mode"

# chat 子命令
complete -c hermes -n "__fish_seen_subcommand_from chat" -l resume -d "Resume session" -r
complete -c hermes -n "__fish_seen_subcommand_from chat" -l continue -d "Continue last session"

# model 子命令
complete -c hermes -n "__fish_seen_subcommand_from model" -a "gpt-4o gpt-4o-mini claude-3-opus claude-3-sonnet claude-3-haiku" -d "Model name"

# config 子命令
complete -c hermes -n "__fish_seen_subcommand_from config" -a show -d "Show config"
complete -c hermes -n "__fish_seen_subcommand_from config" -a edit -d "Edit config"
complete -c hermes -n "__fish_seen_subcommand_from config" -a path -d "Config path"
complete -c hermes -n "__fish_seen_subcommand_from config" -a set -d "Set value"
complete -c hermes -n "__fish_seen_subcommand_from config" -a check -d "Check config"

# mcp 子命令
complete -c hermes -n "__fish_seen_subcommand_from mcp" -a list -d "List servers"
complete -c hermes -n "__fish_seen_subcommand_from mcp" -a add -d "Add server"
complete -c hermes -n "__fish_seen_subcommand_from mcp" -a remove -d "Remove server"
complete -c hermes -n "__fish_seen_subcommand_from mcp" -a test -d "Test connection"

# skills 子命令
complete -c hermes -n "__fish_seen_subcommand_from skills" -a list -d "List skills"
complete -c hermes -n "__fish_seen_subcommand_from skills" -a install -d "Install skill"
complete -c hermes -n "__fish_seen_subcommand_from skills" -a uninstall -d "Uninstall skill"
complete -c hermes -n "__fish_seen_subcommand_from skills" -a search -d "Search skills"
complete -c hermes -n "__fish_seen_subcommand_from skills" -a browse -d "Browse skills"

# sessions 子命令
complete -c hermes -n "__fish_seen_subcommand_from sessions" -a list -d "List sessions"
complete -c hermes -n "__fish_seen_subcommand_from sessions" -a delete -d "Delete session"
complete -c hermes -n "__fish_seen_subcommand_from sessions" -a rename -d "Rename session"
complete -c hermes -n "__fish_seen_subcommand_from sessions" -a export -d "Export sessions"

# plugins 子命令
complete -c hermes -n "__fish_seen_subcommand_from plugins" -a list -d "List plugins"
complete -c hermes -n "__fish_seen_subcommand_from plugins" -a install -d "Install plugin"
complete -c hermes -n "__fish_seen_subcommand_from plugins" -a remove -d "Remove plugin"
complete -c hermes -n "__fish_seen_subcommand_from plugins" -a update -d "Update plugin"

# tools 子命令
complete -c hermes -n "__fish_seen_subcommand_from tools" -a list -d "List tools"
complete -c hermes -n "__fish_seen_subcommand_from tools" -a enable -d "Enable tool"
complete -c hermes -n "__fish_seen_subcommand_from tools" -a disable -d "Disable tool"
