# ============================================================================
# dota — dot add 的简写
# ============================================================================
# 镜像 zsh 的 dota() 函数（见 ~/.config/zsh/aliases.zsh）。
# 把新配置强制纳入版本控制。路径相对于 ~/dotfiles 仓库根。
#
# 用法:
#   dota home/.config/foo/bar     # 跟踪 home/.config/foo/bar
#   dota home/.config/foo bar     # 多个参数一起加
#
# 注意：底层调用 `dot add -f <路径>`（即 git -C ~/dotfiles add -f），
# 路径直接传给 git add，因此必须相对于 ~/dotfiles 仓库根，无需存在性检查。
# ============================================================================
function dota -d "dot add 简写：把新配置纳入版本控制（路径相对于 ~/dotfiles 仓库根）"
    if test (count $argv) -eq 0
        echo "用法: dota <路径>..." >&2
        echo "路径相对于 ~/dotfiles 仓库根，例如 dota home/.config/foo/bar" >&2
        return 1
    end
    dot add -f $argv
end
