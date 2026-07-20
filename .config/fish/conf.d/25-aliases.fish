# ============================================================================
# 25-aliases.fish - 别名（特殊场景，无法用 abbr 替代）
# ============================================================================
# alias 与 abbr 的区别：
#   - alias 是真正的命令替换，无法看到原始命令
#   - 适合：安全标志(rm -I)、强制选项(ip --color)、透明工具替换
#
# 设计原则（与 zsh/aliases.zsh 保持一致）：
#   - 透明替换工具做存在性检查：未装时回退原命令，避免脚本炸
#   - 不替换 find/grep/ps：语法不兼容会破坏脚本和管道
#   - 安全标志必须永远生效
# ============================================================================

if status is-interactive
    # --- 现代化透明替换（带存在性检查，未装时回退原命令） ---
    # 注意：grep/find/ps 不做透明替换 —— 语义不兼容会破坏脚本和管道
    #   grep: rg 默认不读 stdin、参数不同，`something | grep x` 会失败
    #   find: fd 默认忽略 .gitignore、参数完全不同、不支持 -exec/-delete
    #   ps:   procs 输出格式/参数完全不同
    set -l _repls \
        "ls:eza --icons --group-directories-first" \
        "cat:bat --style=plain --paging=never" \
        "du:dust" \
        "df:duf" \
        "top:btop"
    for pair in $_repls
        set -l kv (string split : -- $pair)
        set -l bin (string split ' ' -- $kv[2])[1]
        if command -q $bin
            alias $kv[1] $kv[2]
        end
    end

    # --- 安全标志（强制永远生效） ---
    # --preserve-root 自 coreutils 8.x 起已是默认，无需显式声明
    alias rm 'rm -I'
    alias cp 'cp -iv'
    alias mv 'mv -iv'
    alias mkdir 'mkdir -pv'

    # --- 颜色增强（默认就该有） ---
    alias ip 'ip --color=auto'
    alias diff 'diff --color=auto'
end
