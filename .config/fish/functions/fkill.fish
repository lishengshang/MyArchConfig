function fkill -d "Fuzzy-find and kill a process"
    if not command -q fzf
        echo "需要 fzf"
        return 1
    end

    set -l pid (ps -ef | sed 1d | fzf --multi --header='[选择要 kill 的进程, Tab 多选]' | awk '{print $2}')

    if test -n "$pid"
        set -l sig SIGTERM
        if test (count $argv) -gt 0
            set sig $argv[1]
        end
        for p in $pid
            echo "kill -$sig $p"
            kill -$sig $p
        end
    end
end
