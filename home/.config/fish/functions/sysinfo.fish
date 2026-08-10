function sysinfo -d "Display system information overview"
    set -l c_label (set_color cyan)
    set -l c_val (set_color normal)
    set -l c_title (set_color --bold magenta)

    printf "%s系统信息%s\n" "$c_title" "$c_val"
    echo "════════════════════════════════════"
    printf "%sOS:%s       %s\n"      "$c_label" "$c_val" (grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
    printf "%s内核:%s     %s\n"      "$c_label" "$c_val" (uname -r)
    printf "%sShell:%s    %s\n"      "$c_label" "$c_val" "$SHELL"
    printf "%s运行时间:%s %s\n"      "$c_label" "$c_val" (uptime -p 2>/dev/null || uptime)
    printf "%s内存:%s     %s\n"      "$c_label" "$c_val" (LC_ALL=C free -h | awk '/^Mem:/ {print $3 "/" $2}')
    printf "%s磁盘(/):%s  %s\n"      "$c_label" "$c_val" (command df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')
    printf "%sCPU:%s      %s\n"      "$c_label" "$c_val" (grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | string trim)

    if command -q pacman
        printf "%s软件包:%s   %s (pacman)\n" "$c_label" "$c_val" (pacman -Q 2>/dev/null | count)
    end
end
