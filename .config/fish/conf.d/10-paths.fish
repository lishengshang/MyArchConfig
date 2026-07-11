# ============================================================================
# 10-paths.fish — PATH 配置
# ============================================================================

# 添加常用目录到 PATH（如果存在且未在 PATH 中）
# fish_add_path -g 全局, -m 移除重复后追加, -p 添加到前面
for dir in \
    $HOME/.local/bin \
    $HOME/.bun/bin \
    $HOME/.cargo/bin \
    $HOME/.local/share/fnm

    if test -d $dir
        fish_add_path -gmp $dir
    end
end

# 父 shell 可能注入了重复路径（如 zsh 多次 export PATH）
# 这里强制去重，保证 fish 内 PATH 干净
if status is-interactive
    set -l seen
    set -l clean
    for p in $PATH
        if not contains -- $p $seen
            set -a seen $p
            set -a clean $p
        end
    end
    set -gx PATH $clean
end
