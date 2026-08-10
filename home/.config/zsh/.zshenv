# =============================================================================
# $ZDOTDIR/.zshenv - 非交互式 zsh 环境变量
# =============================================================================
# 被 ALL zsh 实例 source（包括非交互式脚本）。
# ZDOTDIR 由 ~/.zshenv 或 environment.d 设置，此处可直接使用。
#
# 大部分环境变量（XDG/EDITOR/LANG/PATH...）在：
#   ~/.config/environment.d/
# 由 systemd 加载，zsh/fish/GUI 程序共享。
# =============================================================================

# 兜底：如果 environment.d 还没加载（首次启动、修复模式等），
# 保证 PATH 至少包含 ~/.local/bin
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# 本地敏感环境变量（API keys 等，不纳入 dotfiles 版本控制）
# opencode.jsonc 通过 {env:VOLCENGINE_API_KEY} 引用这里的变量
# set -a 开启 allexport，确保变量导出到子进程（opencode 需要）
if [[ -r "$HOME/.config/opencode/.env" ]]; then
    set -a
    source "$HOME/.config/opencode/.env"
    set +a
fi
