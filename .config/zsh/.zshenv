# =============================================================================
# $ZDOTDIR/.zshenv — 非交互式 zsh 环境变量
# =============================================================================
# 被 ALL zsh 实例 source（包括非交互式脚本）。
# ZDOTDIR 由 ~/.zshenv 或 environment.d 设置，此处可直接使用。
#
# 大部分环境变量（XDG/EDITOR/LANG/PATH...）在：
#   ~/.config/environment.d/
# 由 systemd 加载，zsh/fish/GUI 程序共享。
# =============================================================================

# Zinit: 阻止它在加载时调用自己的 compinit
# 我们在 completions.zsh 中显式调用一次 compinit
export skip_global_compinit=1

# 兜底：如果 environment.d 还没加载（首次启动、修复模式等），
# 保证 PATH 至少包含 ~/.local/bin
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
