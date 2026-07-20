# ============================================================================
# zz-bindings-override.fish - 最终键绑定覆盖
# ============================================================================
# conf.d 按字母序加载，zz- 前缀确保最后加载（在所有插件 conf.d 之后）。
# 集中处理所有自定义绑定和插件冲突覆盖。
#
# 冲突解决策略（与 zsh/integrations.zsh 一致）：
#   - atuin 接管 ctrl-r（更强：SQLite + 模糊 + 跨机同步）
#   - fzf 保留其他绑定（ctrl-alt-f 文件 / ctrl-alt-l git / ctrl-alt-s git status）
#
# 注意：fish 4.x 不再自动调用 fish_user_key_bindings 函数，插件通过
#   --on-variable fish_key_bindings 事件注册绑定。自定义绑定放这里更可靠。
# ============================================================================

if status is-interactive
    # atuin 接管 ctrl-r（覆盖 fzf.fish 的 _fzf_search_history）
    if functions -q _atuin_search
        bind ctrl-r _atuin_search
        bind -M insert ctrl-r _atuin_search 2>/dev/null
    end

    # Ctrl+X Ctrl+E 在 $EDITOR 中编辑当前命令行（emacs/bash 经典绑定）
    bind ctrl-x,ctrl-e edit_command_buffer
    bind -M insert ctrl-x,ctrl-e edit_command_buffer
end
