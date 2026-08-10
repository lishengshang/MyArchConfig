# ============================================================================
# dot 补全 — 镜像 zsh 的 _dot (见 ~/.config/zsh/aliases.zsh)
# ============================================================================
# 为什么不用 `complete -c dot -w git`:
#   carapace 在 50-tools.fish 中为 git 注册了
#     complete -c "git" -f -a '(_carapace_completer "git")'
#   `dot -w git` 会继承这条规则，carapace 内部调用 `git status` 在非 git
#   工作目录下失败，把 "ERR (致命错误：不是 Git 仓库...)" 作为补全候选返回。
#
# 解决方案：
#   - 顶层子命令手动定义（用 __fish_use_subcommand 限定只在第一参数位置出现）
#   - 路径类子命令 add/rm/mv/restore 用文件路径补全（仿照 zsh 的 _files）
#   - 分支类子命令 checkout/switch 用 dot 查询分支（dot 函数已设置
#     GIT_DIR=$HOME/.cfg，调用 git branch 能正确识别裸仓库）
# ============================================================================

# --- 顶层子命令（按字母序，仅在第一参数位置出现）---
complete -c dot -f -n '__fish_use_subcommand' -a add        -d "Add file contents to the staging area"
complete -c dot -f -n '__fish_use_subcommand' -a am         -d "Apply patches from a mailbox"
complete -c dot -f -n '__fish_use_subcommand' -a annotate   -d "Annotate file lines with commit information"
complete -c dot -f -n '__fish_use_subcommand' -a apply       -d "Apply a patch to files and/or to the index"
complete -c dot -f -n '__fish_use_subcommand' -a archive     -d "Create an archive of files from a named tree"
complete -c dot -f -n '__fish_use_subcommand' -a bisect      -d "Use binary search to find the commit that introduced a bug"
complete -c dot -f -n '__fish_use_subcommand' -a blame       -d "Show what revision and author last modified each line"
complete -c dot -f -n '__fish_use_subcommand' -a branch      -d "List, create, or delete branches"
complete -c dot -f -n '__fish_use_subcommand' -a cat-file    -d "Provide content or type info for repository objects"
complete -c dot -f -n '__fish_use_subcommand' -a checkout    -d "Switch branches or restore working tree files"
complete -c dot -f -n '__fish_use_subcommand' -a cherry-pick -d "Apply the changes introduced by some existing commits"
complete -c dot -f -n '__fish_use_subcommand' -a clean       -d "Remove untracked files from the working tree"
complete -c dot -f -n '__fish_use_subcommand' -a clone       -d "Clone a repository into a new directory"
complete -c dot -f -n '__fish_use_subcommand' -a commit      -d "Record changes to the repository"
complete -c dot -f -n '__fish_use_subcommand' -a config      -d "Get and set repository or global options"
complete -c dot -f -n '__fish_use_subcommand' -a describe    -d "Give an object a human readable name based on an available ref"
complete -c dot -f -n '__fish_use_subcommand' -a diff        -d "Show changes between commits, commit and working tree"
complete -c dot -f -n '__fish_use_subcommand' -a fetch       -d "Download objects and refs from another repository"
complete -c dot -f -n '__fish_use_subcommand' -a grep        -d "Print lines matching a pattern"
complete -c dot -f -n '__fish_use_subcommand' -a init        -d "Create an empty Git repository or reinitialize an existing one"
complete -c dot -f -n '__fish_use_subcommand' -a log         -d "Show commit logs"
complete -c dot -f -n '__fish_use_subcommand' -a merge       -d "Join two or more development histories together"
complete -c dot -f -n '__fish_use_subcommand' -a mv          -d "Move or rename a file, a directory, or a symlink"
complete -c dot -f -n '__fish_use_subcommand' -a pull        -d "Fetch from and integrate with another repository"
complete -c dot -f -n '__fish_use_subcommand' -a push        -d "Update remote refs along with associated objects"
complete -c dot -f -n '__fish_use_subcommand' -a rebase      -d "Reapply commits on top of another base tip"
complete -c dot -f -n '__fish_use_subcommand' -a reflog      -d "Manage reflog information"
complete -c dot -f -n '__fish_use_subcommand' -a remote      -d "Manage set of tracked repositories"
complete -c dot -f -n '__fish_use_subcommand' -a reset       -d "Reset current HEAD to the specified state"
complete -c dot -f -n '__fish_use_subcommand' -a restore     -d "Restore working tree files"
complete -c dot -f -n '__fish_use_subcommand' -a revert      -d "Revert some existing commits"
complete -c dot -f -n '__fish_use_subcommand' -a rm          -d "Remove files from the working tree and from the index"
complete -c dot -f -n '__fish_use_subcommand' -a show        -d "Show various types of objects"
complete -c dot -f -n '__fish_use_subcommand' -a stash       -d "Stash the changes in a dirty working directory"
complete -c dot -f -n '__fish_use_subcommand' -a status      -d "Show the working tree status"
complete -c dot -f -n '__fish_use_subcommand' -a switch      -d "Switch branches"
complete -c dot -f -n '__fish_use_subcommand' -a tag         -d "Create, list, delete or verify a tag object"
complete -c dot -f -n '__fish_use_subcommand' -a worktree    -d "Manage multiple working trees"

# --- 路径补全（add/rm/mv/restore，仿照 zsh _dot 的 _files 分支）---
# 当前 word 不以 - 开头时才补全文件路径（跳过选项如 -A、--force）
# 必须把当前 word 传给 __fish_complete_path，否则它返回 cwd 下所有路径
# 没有前缀过滤，无法匹配像 .config/f 这样的输入。
complete -c dot -n '__fish_seen_subcommand_from add rm mv restore; and not string match -q -- "-*" (commandline -ct)' -a '(__fish_complete_path (commandline -ct))'

# --- 分支补全（checkout/switch，调用 dot 自身查询分支）---
# 关键: 必须用 dot（而非 git）来查询，dot 函数内部会设置 GIT_DIR/GIT_WORK_TREE
# 环境变量，git 才能识别裸仓库 ~/.cfg。否则在 ~/.config/fish 等非 git 目录下
# 会失败。
complete -c dot -n '__fish_seen_subcommand_from checkout switch; and not string match -q -- "-*" (commandline -ct)' -a '(dot branch --format="%(refname:short)" 2>/dev/null)' -d "Branch"
