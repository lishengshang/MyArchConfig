# =============================================================================
# abbreviations.zsh - zsh-abbr 缩写一次性 seed
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

    # 缩写定义表：key=缩写  value=展开命令
    typeset -A _abbrs=(
        # --- Git ---
        g     'git'
        gs    'git status'
        gss   'git status -s'
        ga    'git add'
        gaa   'git add --all'
        gap   'git add -p'
        gc    'git commit'
        gcm   'git commit -m'
        gca   'git commit --amend'
        gcan  'git commit --amend --no-edit'
        gp    'git push'
        gpf   'git push --force-with-lease'
        gpl   'git pull'
        gf    'git fetch'
        gl    'git log --oneline --graph --decorate'
        gla   'git log --oneline --graph --decorate --all'
        gd    'git diff'
        gds   'git diff --staged'
        gb    'git branch'
        gco   'git checkout'
        gcb   'git checkout -b'
        gsw   'git switch'
        gst   'git stash'
        gstp  'git stash pop'
        # 注：不创建 gr=git restore，避免和 functions.zsh 的 groot() 冲突
        grs   'git restore --staged'
        gm    'git merge'
        grb   'git rebase'
        grbi  'git rebase -i'
        lg    'lazygit'

        # --- Docker ---
        d     'docker'
        dc    'docker compose'
        dps   'docker ps --format "table {{.ID}}{{\"\t\"}}{{.Names}}{{\"\t\"}}{{.Status}}{{\"\t\"}}{{.Ports}}"'
        dpsa  'docker ps -a'
        di    'docker images'
        dex   'docker exec -it'
        dlog  'docker logs -f'
        dstop 'docker stop $(docker ps -aq) 2>/dev/null'
        dclean='docker system prune -af'

        # --- 现代化列表 ---
        ll    'eza -l --icons --group-directories-first --git --time-style=long-iso'
        la    'eza -la --icons --group-directories-first --git'
        lla   'eza -la --icons --group-directories-first --git --time-style=long-iso'
        tree  'eza --tree --icons --level=2'
        treea 'eza --tree --icons --level=3 -a'

        # --- 编辑器 ---
        v     'nvim'
        vim   'nvim'
        sv    'sudo -E nvim'

        # --- 目录跳转 ---
        ..    'cd ..'
        ...   'cd ../..'
        ....  'cd ../../..'

        # --- Arch 包管理 ---
        pacup    'sudo pacman -Syu'
        pacss    'pacman -Ss'
        pacin    'sudo pacman -S'
        pacrm    'sudo pacman -Rns'
        pacclean 'sudo pacman -Sc'
        paclist  'pacman -Qq | fzf --preview "pacman -Qi {}"'
        yayup    'yay -Syu'
        paruup   'paru -Syu'

        # --- 网络 ---
        myip  'curl -s https://ipinfo.io/json | jq'
        ports 'ss -tulanp'
        ping  'ping -c 5'

        # --- Python ---
        py       'python'
        py3      'python3'
        venv     'python -m venv .venv'
        activate 'source .venv/bin/activate'

        # --- 配置编辑 ---
        zshrc     '$EDITOR ~/.config/zsh/.zshrc'
        zshreload 'exec zsh'
        aliasrc   '$EDITOR ~/.config/zsh/aliases.zsh'
        abbrc     '$EDITOR ~/.config/zsh/abbreviations.zsh'
        envrc     '$EDITOR ~/.config/zsh/env.zsh'

        # --- 系统信息 / 通用 ---
        free 'free -h'
        duh  'du -sh'
        dfh  'df -h'
        path 'echo $PATH | tr ":" "\n"'
        c    'clear'
        q    'exit'
        h    'history | tail -50'
    )

    local k
    for k in ${(ok)_abbrs}; do
        abbr add -q --force "$k=${_abbrs[$k]}"
    done

    echo "✓ 已重新生成 $ABBR_USER_ABBREVIATIONS_FILE"
}

# 首次启动或 store 为空 -> 自动 seed 一次
if [[ ! -s "$ABBR_USER_ABBREVIATIONS_FILE" ]]; then
    (( ${+functions[abbr]} )) && abbr-seed >/dev/null 2>&1
fi
