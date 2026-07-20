function y -d "Yazi file manager with directory switching"
    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    yazi $argv --cwd-file=$tmp
    if read -l -z cwd < $tmp
        and test -n "$cwd"
        and test "$cwd" != $PWD
        builtin cd -- $cwd
    end
    rm -f -- $tmp
end
