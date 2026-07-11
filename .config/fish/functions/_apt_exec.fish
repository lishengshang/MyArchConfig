function _apt_exec -a pkg_mgr flag -d "Run pacman (with sudo) or AUR helper"
    if test "$pkg_mgr" = pacman
        sudo pacman $flag $argv[3..]
    else
        $pkg_mgr $flag $argv[3..]
    end
end
