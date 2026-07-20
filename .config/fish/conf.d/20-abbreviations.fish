# ============================================================================
# 20-abbreviations.fish - Fish 缩写（按空格/回车自动展开）
# ============================================================================
# abbr 优势：
#   - 输入 gs 按空格，自动展开为 git status，可视化原始命令
#   - 比 alias 性能更好，保留所有原命令的补全
#   - 适合需要"看见"完整命令的场景（学习、复制、修改参数）
#
# 设计原则：
#   - 高频 git/docker/包管理用 abbr，输入后能看到完整命令
#   - 危险命令（rm/mv/cp）依然用 alias 添加安全标志（见 25-aliases.fish）
#
# fish 4.0+ 新能力：
#   - abbr --command git co checkout  # 只在 git 后展开，更精确
#   - abbr --position anywhere L '% | less'  # 任意位置展开
#   - abbr --function  # 用函数动态生成展开内容
# ============================================================================

if status is-interactive
    # --- Git 顶层 ---
    abbr -a g git
    abbr -a lg lazygit

    # --- Git 命令专属缩写（fish 4.0+，只在 `git <abbr>` 时展开） ---
    abbr -a --command git s status
    abbr -a --command git ss 'status -s'
    abbr -a --command git a add
    abbr -a --command git aa 'add --all'
    abbr -a --command git ap 'add -p'
    abbr -a --command git c commit
    abbr -a --command git cm 'commit -m'
    abbr -a --command git ca 'commit --amend'
    abbr -a --command git can 'commit --amend --no-edit'
    abbr -a --command git p push
    abbr -a --command git pf 'push --force-with-lease'
    abbr -a --command git pl pull
    abbr -a --command git f fetch
    abbr -a --command git l 'log --oneline --graph --decorate'
    abbr -a --command git la 'log --oneline --graph --decorate --all'
    abbr -a --command git d diff
    abbr -a --command git ds 'diff --staged'
    abbr -a --command git b branch
    abbr -a --command git co checkout
    abbr -a --command git cb 'checkout -b'
    abbr -a --command git sw switch
    abbr -a --command git st stash
    abbr -a --command git stp 'stash pop'
    abbr -a --command git r restore
    abbr -a --command git rs 'restore --staged'
    abbr -a --command git m merge
    abbr -a --command git rb rebase
    abbr -a --command git rbi 'rebase -i'

    # --- Docker ---
    abbr -a d docker
    abbr -a dc 'docker compose'
    abbr -a dps 'docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
    abbr -a dpsa 'docker ps -a'
    abbr -a di 'docker images'
    abbr -a dex 'docker exec -it'
    abbr -a dlog 'docker logs -f'
    abbr -a dstop 'docker stop (docker ps -aq)'
    abbr -a dclean 'docker system prune -af'

    # --- 现代化替代工具（abbr 形式：可看到完整命令） ---
    abbr -a ll 'eza -l --icons --group-directories-first --git --time-style=long-iso'
    abbr -a la 'eza -la --icons --group-directories-first --git'
    abbr -a lla 'eza -la --icons --group-directories-first --git --time-style=long-iso'
    abbr -a tree 'eza --tree --icons --level=2'
    abbr -a treea 'eza --tree --icons --level=3 -a'

    # --- 编辑器/导航 ---
    abbr -a v nvim
    abbr -a vim nvim
    abbr -a sv 'sudo nvim'

    # --- 目录跳转（fish 的 prevd/nextd） ---
    abbr -a -- - 'cd -'
    abbr -a .. 'cd ..'
    abbr -a ... 'cd ../..'
    abbr -a .... 'cd ../../..'

    # --- 系统（Arch） ---
    abbr -a pacup 'sudo pacman -Syu'
    abbr -a pacss 'pacman -Ss'
    abbr -a pacin 'sudo pacman -S'
    abbr -a pacrm 'sudo pacman -Rns'
    abbr -a pacclean 'sudo pacman -Sc'
    abbr -a paclist 'pacman -Qq | fzf --preview "pacman -Qi {}"'
    abbr -a yayup 'yay -Syu'
    abbr -a paruup 'paru -Syu'

    # --- 网络 ---
    abbr -a myip 'curl -s https://ipinfo.io/json | jq'
    abbr -a ports 'ss -tulanp'
    abbr -a ping 'ping -c 5'

    # --- Python ---
    abbr -a py python
    abbr -a py3 python3
    abbr -a venv 'python -m venv .venv'
    abbr -a activate 'source .venv/bin/activate.fish'

    # --- 配置快速编辑 ---
    abbr -a fishreload 'exec fish'
    abbr -a fishconf '$EDITOR ~/.config/fish/conf.d/'
    abbr -a fishabbr '$EDITOR ~/.config/fish/conf.d/20-abbreviations.fish'

    # --- 系统信息（轻量） ---
    abbr -a free 'free -h'
    abbr -a duh 'du -sh'
    abbr -a dfh 'df -h'

    # --- 实用快捷 ---
    abbr -a c clear
    abbr -a q exit
    abbr -a h 'history | head -50'
    abbr -a path 'echo $PATH | tr " " "\n"'

    # --- fish 4.0+ anywhere 缩写（光标停在 % 处） ---
    # 输入 L 自动变 | less，光标停在 | 前
    abbr -a L --position anywhere --set-cursor "% | less"
    # 输入 G 自动变 | rg，光标停在 | 前
    abbr -a G --position anywhere --set-cursor "% | rg"

    # --- fish 4.0+ 函数式缩写：!! 取上一条历史 ---
    # 替代 bash 的 sudo !!，输入 sudo !! 自动展开
    function _last_history_item -d "Echo last history item"
        echo $history[1]
    end
    abbr -a !! --position anywhere --function _last_history_item
end
