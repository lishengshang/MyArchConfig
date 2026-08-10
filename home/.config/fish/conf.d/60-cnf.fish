# ============================================================================
# 60-cnf.fish — command-not-found 处理器（Arch Linux pkgfile 集成）
# ============================================================================
# 命令不存在时，自动查找哪个 pacman 包提供它
# 依赖: pkgfile（pacman -S pkgfile && sudo pkgfile --update）
# ============================================================================

function fish_command_not_found
    set -l cmd $argv[1]

    # 如果有 pkgfile，使用它查找包
    if command -q pkgfile
        set -l pkgs (pkgfile -b -- $cmd 2>/dev/null)
        if test (count $pkgs) -gt 0
            printf "\n%s命令 '%s' 未找到。%s\n" (set_color red) $cmd (set_color normal)
            printf "%s可能在以下软件包中：%s\n" (set_color yellow) (set_color normal)
            for pkg in $pkgs
                printf "  %s•%s %s\n" (set_color cyan) (set_color normal) $pkg
            end
            printf "\n%s安装命令：%s sudo pacman -S %s\n\n" (set_color green) (set_color normal) $pkgs[1]
            return 127
        end
    end

    # 回退：原始错误
    printf "%sfish: %s未找到命令: %s%s\n" (set_color red) (set_color normal) (set_color yellow) $cmd
    return 127
end
