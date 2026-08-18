# ============================================================================
# 00-env.fish - Fish 特有环境变量
# ============================================================================
# 大部分通用变量(XDG/EDITOR/LANG/FZF_DEFAULT_*/BUN_INSTALL/...)
# 已迁移到 ~/.config/environment.d/, systemd 在用户会话启动时加载
# 让 zsh / fish / bash / GUI 程序全部共享。
#
# 本文件只保留：fish 特有的或需要 fish 逻辑判断的变量
# ============================================================================

# 关闭默认欢迎语(无需 -x, 不需要导出给子进程)
set -g fish_greeting ''

# 工具自带的 Fish 补全是运行时生成物，不写入 dotfiles 仓库。
# fish-update-completions.fish 会写入这个目录，fish_complete_path 负责懒加载。
set -l generated_completions "$XDG_DATA_HOME/fish/generated-completions"
if not contains -- "$generated_completions" $fish_complete_path
    set -g fish_complete_path "$generated_completions" $fish_complete_path
end

# 兜底: environment.d 未生效时(首次登录、修复模式、SSH)
# 保证 XDG 系列至少有合理默认
test -z "$XDG_CONFIG_HOME"; and set -gx XDG_CONFIG_HOME $HOME/.config
test -z "$XDG_CACHE_HOME";  and set -gx XDG_CACHE_HOME $HOME/.cache
test -z "$XDG_DATA_HOME";   and set -gx XDG_DATA_HOME $HOME/.local/share
test -z "$XDG_STATE_HOME";  and set -gx XDG_STATE_HOME $HOME/.local/state
test -z "$EDITOR";  and set -gx EDITOR nvim
test -z "$VISUAL";  and set -gx VISUAL nvim
test -z "$LANG";    and set -gx LANG zh_CN.UTF-8

# MANPAGER 含特殊字符, environment.d 不太好写, 放这里兜底
test -z "$MANPAGER"; and set -gx MANPAGER 'nvim +Man!'

# 本地敏感环境变量（API keys 等，不纳入 dotfiles 版本控制）
# opencode.jsonc 通过 {env:VOLCENGINE_API_KEY} 引用这里的变量
# fish 的 source 不支持 KEY=VALUE 语法，这里逐行解析（单行注释/空行自动跳过）
if test -r "$HOME/.config/opencode/.env"
    while read -l line
        set -l kv (string split -m 1 '=' -- "$line")
        if test (count $kv) -eq 2
            set -gx $kv[1] $kv[2]
        end
    end < "$HOME/.config/opencode/.env"
end
