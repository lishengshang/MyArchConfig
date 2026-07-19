# ============================================================================
# dota — dot add 的简写
# ============================================================================
# 镜像 zsh 的 dota() 函数（见 ~/.config/zsh/aliases.zsh）。
# 把新配置纳入版本控制。路径相对于 $HOME，可带前导 ./。
#
# 用法:
#   dota .config/foo/bar         # 跟踪 ~/.config/foo/bar
#   dota .config/foo ./baz       # 多个参数一起加
#
# 注意：本命令期望用户在 $HOME 下运行（与 zsh 版一致），
# 因为底层调用 `dot add <相对路径>`，git add 解析相对路径时
# 是相对于当前工作目录的。
# ============================================================================
function dota -d "dot add 简写：把新配置纳入版本控制（路径相对于 \$HOME）"
    if test (count $argv) -eq 0
        echo "用法: dota <路径>..." >&2
        echo "路径相对于 \$HOME，可带前导 ./" >&2
        return 1
    end
    for p in $argv
        # 去掉前导 ./ 让路径统一（正则 \. 是字面点号，避免误匹配 a/foo 等）
        set p (string replace -r -- '^\./' '' $p)
        if not test -e "$HOME/$p"
            echo "跳过（不存在）: $p" >&2
            continue
        end
        dot add "$p"
    end
end
