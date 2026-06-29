# =============================================================================
# bindings.zsh — 键绑定
# =============================================================================

# Emacs 风格
bindkey -e

# --- 行编辑 ---
bindkey '^[[3~'   delete-char              # Delete
bindkey '^[[1;5C' forward-word             # Ctrl+Right
bindkey '^[[1;5D' backward-word            # Ctrl+Left
bindkey '^H'      backward-kill-word       # Ctrl+Backspace（部分终端）
bindkey '^[^?'    backward-kill-word       # Alt+Backspace（兜底）
bindkey '^W'      backward-kill-word       # 标准 Ctrl+W
bindkey '^U'      backward-kill-line       # Ctrl+U 删到行首
bindkey '^K'      kill-line                # Ctrl+K 删到行尾

# --- 补全 ---
bindkey '^[[Z'    reverse-menu-complete    # Shift+Tab

# --- 自动建议接受 ---
# 键绑定在 plugins.zsh 的 zsh-autosuggestions atload 钩子中设置
# （widget 在插件异步加载后才存在）

# --- 编辑当前命令到编辑器 ---
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E'    edit-command-line        # Ctrl+X Ctrl+E

# --- 历史搜索（按前缀）---
bindkey '^[[A'    up-line-or-search        # ↑
bindkey '^[[B'    down-line-or-search      # ↓
bindkey '^P'      up-line-or-search
bindkey '^N'      down-line-or-search

# --- 目录栈快速跳转 ---
bindkey '^[<'     beginning-of-history     # Alt+<
bindkey '^[>'     end-of-history           # Alt+>

# --- 清屏 ---
bindkey '^L'      clear-screen

# ============================================================================
# fzf 键绑定（Ctrl+T 文件 / Ctrl+R 历史 / Alt+C cd）
# 来源：pacman -S fzf，路径稳定为 /usr/share/fzf/*.zsh
# ============================================================================
[[ -r /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -r /usr/share/fzf/completion.zsh   ]] && source /usr/share/fzf/completion.zsh
