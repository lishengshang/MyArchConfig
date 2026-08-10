function apt -d "Smart Arch package manager wrapper"
    set -l is_zh 0
    if string match -q -r "^zh_" "$LC_ALL" "$LC_MESSAGES" "$LANG"
        set is_zh 1
    end

    set -l has_shorin 0
    if command -q shorin
        set has_shorin 1
    end

    if test (count $argv) -eq 0
        if test $is_zh -eq 1
            echo "用法: apt <命令> [软件包...]"
            echo "运行 'apt help' 查看可用命令。"
        else
            echo "Usage: apt <command> [package...]"
            echo "Run 'apt help' for valid commands."
        end
        return 1
    end

    set -l action $argv[1]
    set -e argv[1]

    switch $action
        case help -h --help
            set -l c_cmd (set_color cyan)
            set -l c_hl (set_color yellow)
            set -l c_rst (set_color normal)

            if test $is_zh -eq 1
                echo "Arch 包管理器包装器 (优先级: "$c_hl"paru > yay > pacman"$c_rst")"
                echo ""
                echo "命令:"
                echo "  "$c_cmd"update"$c_rst"    同步数据库并更新系统 (-Syu)"
                echo "  "$c_cmd"install"$c_rst"   安装软件包 (-S)"
                echo "  "$c_cmd"remove"$c_rst"    彻底卸载软件包及依赖 (-Rns)"
                echo "  "$c_cmd"search"$c_rst"    搜索软件包 (-Ss)"
                echo "  "$c_cmd"show"$c_rst"      显示软件包详细信息 (-Si)"
                echo "  "$c_cmd"clean"$c_rst"     清理下载缓存 (-Sc)"
                echo "  "$c_cmd"orphans"$c_rst"   查看孤立软件包"
            else
                echo "Arch Package Manager Wrapper (Routing: "$c_hl"paru > yay > pacman"$c_rst")"
                echo ""
                echo "Commands:"
                echo "  "$c_cmd"update"$c_rst"    Sync databases and update system (-Syu)"
                echo "  "$c_cmd"install"$c_rst"   Install packages (-S)"
                echo "  "$c_cmd"remove"$c_rst"    Remove packages and dependencies (-Rns)"
                echo "  "$c_cmd"search"$c_rst"    Search for packages (-Ss)"
                echo "  "$c_cmd"show"$c_rst"      Show package details (-Si)"
                echo "  "$c_cmd"clean"$c_rst"     Clean package cache (-Sc)"
                echo "  "$c_cmd"orphans"$c_rst"   List orphaned packages"
            end

        case update upgrade
            _apt_run -Syu

        case install
            if test (count $argv) -eq 0
                if test $is_zh -eq 1
                    echo "错误：请指定要安装的软件包。"
                else
                    echo "Error: Specify packages to install."
                end
                return 1
            end
            if test "$argv[1]" = "ui" -a (count $argv) -eq 1 -a $has_shorin -eq 1
                shorin pac
                return 0
            end
            _apt_run -S $argv

        case remove
            if test (count $argv) -eq 0
                if test $is_zh -eq 1
                    echo "错误：请指定要卸载的软件包。"
                else
                    echo "Error: Specify packages to remove."
                end
                return 1
            end
            if test "$argv[1]" = "ui" -a (count $argv) -eq 1 -a $has_shorin -eq 1
                shorin pacr
                return 0
            end
            _apt_run -Rns $argv

        case search
            if test (count $argv) -eq 0
                if test $is_zh -eq 1
                    echo "错误：请指定搜索词。"
                else
                    echo "Error: Specify search term."
                end
                return 1
            end
            _apt_run -Ss $argv

        case show
            if test (count $argv) -eq 0
                if test $is_zh -eq 1
                    echo "错误：请指定要查看的软件包。"
                else
                    echo "Error: Specify package to show."
                end
                return 1
            end
            _apt_run -Si $argv

        case clean
            _apt_run -Sc

        case orphans
            set -l orphans (pacman -Qtdq)
            if test (count $orphans) -gt 0
                if test $is_zh -eq 1
                    echo "孤立软件包:"
                else
                    echo "Orphaned packages:"
                end
                echo $orphans
            else
                if test $is_zh -eq 1
                    echo "没有孤立软件包。"
                else
                    echo "No orphaned packages."
                end
            end

        case '*'
            if test $is_zh -eq 1
                echo "错误：不支持的命令: $action"
            else
                echo "Error: Unsupported command: $action"
            end
            return 1
    end
end
