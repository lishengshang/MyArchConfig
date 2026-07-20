function fkill -d "Fuzzy-find and kill a process"
    if not command -q fzf
        echo "需要 fzf"
        return 1
    end

    # 优先用 procs(更清晰的输出),fallback 到 ps
    set -l pid
    if command -q procs
        set pid (procs 2>/dev/null | fzf \
            --multi \
            --header='[Tab 多选, 选择要 kill 的进程]' \
            --preview='ps -p {1} -o pid,ppid,user,%cpu,%mem,etime,cmd' \
            --preview-window=right:hidden \
            | awk 'NR>1 {print $1}')
    end
    if test -z "$pid"
        set pid (ps -ef | sed 1d | fzf --multi --header='[选择要 kill 的进程, Tab 多选]' | awk '{print $2}')
    end

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
