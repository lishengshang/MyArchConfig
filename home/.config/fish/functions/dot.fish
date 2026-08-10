# ============================================================================
# dot — 在 ~/dotfiles 仓库里执行 git 命令（GNU Stow + 普通 git 方案）
# ============================================================================
# 镜像 zsh 的 dot() 函数（见 ~/.config/zsh/aliases.zsh）。
# ~/dotfiles 是普通 git 仓库，由 GNU Stow 部署软链到 $HOME；
# 直接用 `git -C ~/dotfiles` 即可，无需环境变量，补全也天然正常。
#
# 用法:
#   dot status                  # 看哪些文件有变动
#   dot diff                    # 看具体改了什么
#   dot add home/.config/foo    # 跟踪新文件（路径相对于仓库根）
#   dot commit -m "xx"          # 提交
#   dot push                    # 推送
# ============================================================================
function dot -d "在 ~/dotfiles 仓库里执行 git 命令"
    git -C "$HOME/dotfiles" $argv
end
