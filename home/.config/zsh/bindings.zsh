# =============================================================================
# bindings.zsh - 键绑定
# =============================================================================
# bindkey -e 已默认绑定：Ctrl+A/E（行首尾）、Ctrl+W（删前词）、
# Ctrl+U（删到行首）、Ctrl+K（删到行尾）等 emacs 标准键，不再重复。
#
# 不同终端对 Ctrl+方向键 / Ctrl+Backspace 发的 escape sequence 不同，
# 用 _bind_keys 尝试多个已知序列，匹配到哪个就用哪个。
# 若仍不生效：执行 `autoload -Uz zkbd; zkbd` 生成终端专属映射。
#
# Tab / Shift+Tab 绑定由 plugins.zsh 的 fzf-tab atload 钩子统一设置，
# 此处不绑，避免与 fzf-tab 异步加载后产生竞争。
# =============================================================================

# Emacs 风格（设定 Ctrl+A/E/W/U/K 等默认绑定）
bindkey -e

# zsh-abbr 默认键位（space 展开 / Enter 展开并执行）在 plugins.zsh 加载时
# 绑定，被上方的 `bindkey -e` 重置覆盖——这里重放，恢复缩写展开。
# 注意：^  (Ctrl+Space) 不恢复：按 README 约定保持 autosuggest-accept
#（zsh-autosuggestions 的 atload 会晚于此处绑定，最终生效）。
if (( ${+widgets[abbr-expand-and-insert]} )); then
    zle -N accept-line abbr-expand-and-accept
    bindkey " " abbr-expand-and-insert
    bindkey -M isearch "^ " abbr-expand-and-insert 2>/dev/null
    bindkey -M isearch " " magic-space 2>/dev/null
fi

# 尝试多个 escape sequence，匹配到就绑定（消除终端差异）
_bind_keys() {
    local widget=$1; shift
    local seq
    for seq in "$@"; do
        bindkey "$seq" "$widget" 2>/dev/null
    done
}

# --- 行编辑（终端相关键：多序列兜底）---
_bind_keys  delete-char           '^[[3~'   '^[[3;5~'  # Delete
_bind_keys  forward-word          '^[[1;5C' '^[[5C'    '^Oc'  '^[[1;3C'  # Ctrl+Right (含 tmux)
_bind_keys  backward-word         '^[[1;5D' '^[[5D'    '^Od'  '^[[1;3D'  # Ctrl+Left  (含 tmux)
_bind_keys  backward-kill-word    '^[[3;5~'  "^[^?"          # Ctrl+Backspace（多终端兜底）
bindkey '^H' backward-delete-char                                      # Backspace 删除前一个字符

# --- 插入上一命令的最后参数（zsh 内建 widget insert-last-word）---
# Alt+. 或 Alt+_ 均可（兼容 readline 习惯）
_bind_keys  insert-last-word      '^[.'     '^[_'               # Alt+. / Alt+_

# --- 补全 ---
# Tab 和 Shift+Tab 均由 fzf-tab 接管（见 plugins.zsh atload 钩子）
# 此处先绑兜底，fzf-tab 异步加载后覆盖
bindkey '^I'      expand-or-complete       # Tab
bindkey '^[[Z'    reverse-menu-complete   # Shift+Tab

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

# 清理 helper
unset -f _bind_keys

# ============================================================================
# fzf 键绑定（Ctrl+T 文件 / Alt+C cd）
# 只加载 key-bindings.zsh，不加载 completion.zsh（与 fzf-tab 冲突）
# Ctrl+R 由 atuin 接管（见 integrations.zsh）
# ============================================================================
[[ -r /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
