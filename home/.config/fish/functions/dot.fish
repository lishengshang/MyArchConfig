# ============================================================================
# dot — 管理 dotfiles 裸仓库（~/.cfg）
# ============================================================================
# 镜像 zsh 的 dot() 函数（见 ~/.config/zsh/aliases.zsh）。
# 通过 GIT_DIR/GIT_WORK_TREE 环境变量把 git 指向裸仓库：
#   GIT_DIR=$HOME/.cfg        裸仓库内部文件位置
#   GIT_WORK_TREE=$HOME       工作区是整个家目录
# 使用环境变量而非 --git-dir/--work-tree 选项，是因为补全函数内部
# 调用的 git 命令也能识别仓库（与 zsh 实现保持一致）。
#
# 用法:
#   dot status          # 看哪些文件有变动
#   dot diff            # 看具体改了什么
#   dot add .config/foo # 跟踪新文件（需先在 ~/.gitignore 白名单里）
#   dot commit -m "xx"  # 提交
#   dot push            # 推送
# ============================================================================
function dot -d "管理 dotfiles 裸仓库（~/.cfg）"
    GIT_DIR="$HOME/.cfg" GIT_WORK_TREE="$HOME" git $argv
end
