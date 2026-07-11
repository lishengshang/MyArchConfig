# ============================================================================
# 30-bindings.fish — 键绑定
# ============================================================================
# fish 的 bind 在交互式中生效，使用 fish_user_key_bindings 函数
# 查看默认绑定: bind | bat
# ============================================================================

if status is-interactive
    # --- 行编辑增强 ---
    bind \cw backward-kill-word          # Ctrl+W 删除前一个词
    bind \e\[3\;5~ kill-word              # Ctrl+Delete 删除后一个词
    bind \e\[1\;5C forward-word           # Ctrl+Right 向前跳词
    bind \e\[1\;5D backward-word          # Ctrl+Left 向后跳词
    bind \cu backward-kill-line           # Ctrl+U 删到行首
    bind \ck kill-line                    # Ctrl+K 删到行尾

    # --- 历史搜索（不仅是上下箭头） ---
    bind \e\[A up-or-search               # ↑ 历史搜索
    bind \e\[B down-or-search             # ↓ 历史搜索
    bind \cp up-or-search                 # Ctrl+P
    bind \cn down-or-search               # Ctrl+N

    # --- 自动建议接受 ---
    bind \cf forward-char                 # Ctrl+F 接受一个字符
    bind \e\[C forward-char               # → 接受一个字符
    bind \cy accept-autosuggestion        # Ctrl+Y 接受整个建议

    # --- 编辑当前命令于编辑器 ---
    bind \cx\ce edit_command_buffer       # Ctrl+X Ctrl+E

    # --- 清屏 ---
    bind \cl clear-screen

    # --- 跳转上次目录 ---
    bind \e\< 'prevd; commandline -f repaint'   # Alt+< 上一个目录
    bind \e\> 'nextd; commandline -f repaint'   # Alt+> 下一个目录
end
