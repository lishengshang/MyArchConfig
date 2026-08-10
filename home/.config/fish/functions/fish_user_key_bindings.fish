# ============================================================================
# fish_user_key_bindings.fish - 自定义键绑定（fish 官方标准覆盖点）
# ============================================================================
# fish 4.x 在 __fish_config_interactive 中自动调用本函数
# （见 share/functions/__fish_config_interactive.fish:100-101）:
#   1. 先执行 $fish_key_bindings（默认 fish_default_key_bindings）
#   2. 再调用 fish_user_key_bindings（若定义）
#
# 调用时机: 第一个 prompt 显示时（fish_prompt 事件），
# 此时 conf.d/ 已全部加载 —— 所以这里的绑定可以覆盖插件绑定。
#
# 冲突解决策略（与 zsh/integrations.zsh 一致）:
#   - atuin 接管 ctrl-r（更强：SQLite + 模糊 + 跨机同步）
#   - fzf.fish 保留其他绑定（ctrl-alt-f 文件 / ctrl-alt-l git log /
#     ctrl-alt-s git status / ctrl-v 变量 / ctrl-alt-p 进程）
#
# 注意: 不要再使用 `bind --erase --all <key>` —— 实测该语法会擦除
# 所有自定义绑定（含本文件和其他插件的），而不是只擦除指定键。
# 需要解绑单个键时用 `bind --erase <key>`（当前模式）。
# ============================================================================

function fish_user_key_bindings
    # atuin 接管 ctrl-r（覆盖 fzf.fish 的 _fzf_search_history）
    if functions -q _atuin_search
        bind ctrl-r _atuin_search
        bind -M insert ctrl-r _atuin_search 2>/dev/null
    end

    # Ctrl+X Ctrl+E 在 $EDITOR 中编辑当前命令行（emacs/bash 经典绑定）
    bind ctrl-x,ctrl-e edit_command_buffer
    bind -M insert ctrl-x,ctrl-e edit_command_buffer
end
