# =============================================================================
# abbreviations.zsh — zsh-abbr 缩写一次性 seed
# =============================================================================
# 设计：
#   zsh-abbr 启动时会自动从 $ABBR_USER_ABBREVIATIONS_FILE 读取所有缩写，
#   完全不需要在 .zshrc 里调用 `abbr add`。所以本文件只有两个职责：
#     1. 提供 `abbr-seed` 函数，把默认缩写一次性写进 store 文件
#     2. 首次启动或 store 为空时自动调用一次 seed
#
# 之后增删缩写：直接 `abbr add foo=bar` / `abbr erase foo`，
# zsh-abbr 会把变更落盘到 store，下次启动自动加载，零运行时开销。
# =============================================================================

# 缩写存储路径（与 zsh-abbr 默认值保持一致）
: "${ABBR_USER_ABBREVIATIONS_FILE:=$HOME/.config/zsh-abbr/user-abbreviations}"
export ABBR_USER_ABBREVIATIONS_FILE

abbr-seed() {
    (( ${+functions[abbr]} )) || { echo "zsh-abbr 未加载，先 source plugins.zsh"; return 1 }

    # 清空旧缩写，避免重复（仅 seed 时使用）
    abbr erase $(abbr list-abbreviations 2>/dev/null) &>/dev/null

    # ----- Git -----
    abbr add -q --force g='git'
    abbr add -q --force gs='git status'
    abbr add -q --force gss='git status -s'
    abbr add -q --force ga='git add'
    abbr add -q --force gaa='git add --all'
    abbr add -q --force gap='git add -p'
    abbr add -q --force gc='git commit'
    abbr add -q --force gcm='git commit -m'
    abbr add -q --force gca='git commit --amend'
    abbr add -q --force gcan='git commit --amend --no-edit'
    abbr add -q --force gp='git push'
    abbr add -q --force gpf='git push --force-with-lease'
    abbr add -q --force gpl='git pull'
    abbr add -q --force gf='git fetch'
    abbr add -q --force gl='git log --oneline --graph --decorate'
    abbr add -q --force gla='git log --oneline --graph --decorate --all'
    abbr add -q --force gd='git diff'
    abbr add -q --force gds='git diff --staged'
    abbr add -q --force gb='git branch'
    abbr add -q --force gco='git checkout'
    abbr add -q --force gcb='git checkout -b'
    abbr add -q --force gsw='git switch'
    abbr add -q --force gst='git stash'
    abbr add -q --force gstp='git stash pop'
    # 注：不再创建 `gr=git restore`，避免和 functions.zsh 的 groot() 冲突
    abbr add -q --force grs='git restore --staged'
    abbr add -q --force gm='git merge'
    abbr add -q --force grb='git rebase'
    abbr add -q --force grbi='git rebase -i'
    abbr add -q --force lg='lazygit'

    # ----- Dotfiles 裸仓库 -----
    # abbr add -q --force dot='git --git-dir=$HOME/dotfiles --work-tree=$HOME'
    # abbr add -q --force dots='git --git-dir=$HOME/dotfiles --work-tree=$HOME status'
    # abbr add -q --force dotd='git --git-dir=$HOME/dotfiles --work-tree=$HOME diff'
    # abbr add -q --force dotl='git --git-dir=$HOME/dotfiles --work-tree=$HOME log --oneline --graph --decorate -15'
    # abbr add -q --force dota='git --git-dir=$HOME/dotfiles --work-tree=$HOME add -f'
    # abbr add -q --force dotc='git --git-dir=$HOME/dotfiles --work-tree=$HOME commit -m'
    # abbr add -q --force dotca='git --git-dir=$HOME/dotfiles --work-tree=$HOME commit -am'
    # abbr add -q --force dotp='git --git-dir=$HOME/dotfiles --work-tree=$HOME push'

    # ----- Docker -----
    abbr add -q --force d='docker'
    abbr add -q --force dc='docker compose'
    abbr add -q --force dps='docker ps --format "table {{.ID}}{{\"\t\"}}{{.Names}}{{\"\t\"}}{{.Status}}{{\"\t\"}}{{.Ports}}"'
    abbr add -q --force dpsa='docker ps -a'
    abbr add -q --force di='docker images'
    abbr add -q --force dex='docker exec -it'
    abbr add -q --force dlog='docker logs -f'
    abbr add -q --force dstop='docker stop $(docker ps -aq) 2>/dev/null'
    abbr add -q --force dclean='docker system prune -af'

    # ----- 现代化列表 -----
    abbr add -q --force ll='eza -l --icons --group-directories-first --git --time-style=long-iso'
    abbr add -q --force la='eza -la --icons --group-directories-first --git'
    abbr add -q --force lla='eza -la --icons --group-directories-first --git --time-style=long-iso'
    abbr add -q --force tree='eza --tree --icons --level=2'
    abbr add -q --force treea='eza --tree --icons --level=3 -a'

    # ----- 编辑器 -----
    abbr add -q --force v='nvim'
    abbr add -q --force vim='nvim'
    abbr add -q --force sv='sudo -E nvim'

    # ----- 目录跳转 -----
    abbr add -q --force ..='cd ..'
    abbr add -q --force ...='cd ../..'
    abbr add -q --force ....='cd ../../..'

    # ----- Arch 包管理 -----
    abbr add -q --force pacup='sudo pacman -Syu'
    abbr add -q --force pacss='pacman -Ss'
    abbr add -q --force pacin='sudo pacman -S'
    abbr add -q --force pacrm='sudo pacman -Rns'
    abbr add -q --force pacclean='sudo pacman -Sc'
    abbr add -q --force paclist='pacman -Qq | fzf --preview "pacman -Qi {}"'
    abbr add -q --force yayup='yay -Syu'
    abbr add -q --force paruup='paru -Syu'

    # ----- 网络 -----
    abbr add -q --force myip='curl -s https://ipinfo.io/json | jq'
    abbr add -q --force ports='ss -tulanp'
    abbr add -q --force ping='ping -c 5'

    # ----- Python -----
    abbr add -q --force py='python'
    abbr add -q --force py3='python3'
    abbr add -q --force venv='python -m venv .venv'
    abbr add -q --force activate='source .venv/bin/activate'

    # ----- 配置编辑 -----
    abbr add -q --force zshrc='$EDITOR ~/.config/zsh/.zshrc'
    abbr add -q --force zshreload='exec zsh'
    abbr add -q --force aliasrc='$EDITOR ~/.config/zsh/aliases.zsh'
    abbr add -q --force abbrc='$EDITOR ~/.config/zsh/abbreviations.zsh'
    abbr add -q --force envrc='$EDITOR ~/.config/zsh/env.zsh'

    # ----- 系统信息 / 通用 -----
    abbr add -q --force free='free -h'
    abbr add -q --force duh='du -sh'
    abbr add -q --force dfh='df -h'
    abbr add -q --force path='echo $PATH | tr ":" "\n"'
    abbr add -q --force c='clear'
    abbr add -q --force q='exit'
    abbr add -q --force h='history | tail -50'

    echo "✓ 已重新生成 $ABBR_USER_ABBREVIATIONS_FILE"
}

# 首次启动或 store 为空 → 自动 seed 一次
if [[ ! -s "$ABBR_USER_ABBREVIATIONS_FILE" ]]; then
    (( ${+functions[abbr]} )) && abbr-seed >/dev/null 2>&1
fi
