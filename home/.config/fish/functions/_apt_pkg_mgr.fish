# ============================================================================
# _apt_pkg_mgr - 解析可用的 AUR 助手或 pacman
# ============================================================================
# 优先级: paru > yay > pacman
# 返回: 命令名(paru/yay/pacman)
# ============================================================================
function _apt_pkg_mgr -d "Resolve AUR helper or pacman (paru > yay > pacman)"
    command -s paru; or command -s yay; or echo pacman
end

# ============================================================================
# _apt_run - 用解析到的包管理器执行命令(pacman 加 sudo)
# ============================================================================
# 参数: $argv[1]=flag(如 -S)  $argv[2..]=额外参数
# 用法: _apt_run -Syu  /  _apt_run -S foo bar
# ============================================================================
function _apt_run -d "Run pkg mgr with flag (sudo for pacman)"
    set -l flag $argv[1]
    set -l mgr (_apt_pkg_mgr)
    if test "$mgr" = pacman
        sudo pacman $flag $argv[2..]
    else
        $mgr $flag $argv[2..]
    end
end
