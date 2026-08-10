# ============================================================================
# 40-fzf.fish — FZF 配置
# ============================================================================
# FZF_DEFAULT_COMMAND / FZF_CTRL_T_COMMAND / FZF_ALT_C_COMMAND
# 已在 ~/.config/environment.d/ 中为所有 shell 共享定义。
# 此文件仅做兜底（environment.d 未生效时）和 fish 特色配置。
# 实际键绑定由 fzf.fish 插件提供（Ctrl+R 历史 / Ctrl+Alt+F 文件 / Ctrl+Alt+L git）
# ============================================================================

if status is-interactive; and command -q fzf
    # --- 兜底：environment.d 未加载时用默认值 ---
    test -z "$FZF_DEFAULT_COMMAND"
    and set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'

    test -z "$FZF_CTRL_T_COMMAND"
    and set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND

    test -z "$FZF_ALT_C_COMMAND"
    and set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'

    # --- 主题（FZF_DEFAULT_OPTS 含特殊字符不便放在 environment.d） ---
    if test -z "$FZF_DEFAULT_OPTS"
        set -gx FZF_DEFAULT_OPTS '
            --height 50%
            --layout=reverse
            --border=rounded
            --info=inline
            --prompt="❯ "
            --pointer="▶"
            --marker="✓"
            --color=fg:#c0caf5,bg:-1,hl:#7aa2f7
            --color=fg+:#c0caf5,bg+:#1f2335,hl+:#7dcfff
            --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
            --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
        '
    end

    # --- 预览（只要 bat/eza 存在就覆盖默认） ---
    if command -q bat
        set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
    end

    if command -q eza
        set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --icons --color=always --level=2 {}'"
    end

    # --- 历史搜索预览 ---
    if test -z "$FZF_CTRL_R_OPTS"
        set -gx FZF_CTRL_R_OPTS '
            --preview "echo {}"
            --preview-window down:3:wrap
            --bind "ctrl-/:toggle-preview"
        '
    end
end
