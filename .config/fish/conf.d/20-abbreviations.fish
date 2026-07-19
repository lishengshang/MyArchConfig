# ============================================================================
# 20-abbreviations.fish — Fish 缩写（按空格/回车自动展开）
# ============================================================================
# abbr 优势：
#   - 输入 gs 按空格，自动展开为 git status，可视化原始命令
#   - 比 alias 性能更好，保留所有原命令的补全
#   - 适合需要"看见"完整命令的场景（学习、复制、修改参数）
#
# 设计原则：
#   - 高频 git/docker/包管理用 abbr，输入后能看到完整命令
#   - 危险命令（rm/mv/cp）依然用 alias 添加安全标志
# ============================================================================

# --- Git ---
abbr -a g git
abbr -a gs git status
abbr -a gss git status -s
abbr -a ga git add
abbr -a gaa git add --all
abbr -a gap git add -p
abbr -a gc git commit
abbr -a gcm git commit -m
abbr -a gca git commit --amend
abbr -a gcan git commit --amend --no-edit
abbr -a gp git push
abbr -a gpf git push --force-with-lease
abbr -a gpl git pull
abbr -a gf git fetch
abbr -a gl 'git log --oneline --graph --decorate'
abbr -a gla 'git log --oneline --graph --decorate --all'
abbr -a gd git diff
abbr -a gds git diff --staged
abbr -a gb git branch
abbr -a gco git checkout
abbr -a gcb git checkout -b
abbr -a gsw git switch
abbr -a gst git stash
abbr -a gstp git stash pop
abbr -a gr git restore
abbr -a grs git restore --staged
abbr -a gm git merge
abbr -a grb git rebase
abbr -a grbi git rebase -i
abbr -a lg lazygit

# --- Dotfiles 裸仓库 ---
# dot/dota 是 functions（见 functions/dot.fish、functions/dota.fish），
# 镜像 zsh 的 dot()/dota() 实现（GIT_DIR=$HOME/.cfg GIT_WORK_TREE=$HOME git）。
# 补全见 completions/dot.fish、completions/dota.fish。
# 子命令直接用 `dot <TAB>` 补全即可（继承 git 补全）。

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
abbr -a fishrc '$EDITOR ~/.config/fish/config.fish'
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
