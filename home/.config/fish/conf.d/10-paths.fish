# ============================================================================
# 10-paths.fish - PATH 配置
# ============================================================================
# fish_add_path -g 全局添加, -m 移除重复后追加, -p 添加到前面
# fish_user_paths 是 universal 变量, 会被自动 prepend 到 PATH
#
# 注意: environment.d/20-path.conf 已设置基础 PATH(systemd 加载, 全 shell 共享)
# 这里只补充 environment.d 不便处理的: 需要存在性检查的目录
# ============================================================================

# 添加常用目录到 PATH(如果存在)
# fish_add_path -m 自带去重, 无需手动去重
for dir in \
    $HOME/.local/bin \
    $HOME/.bun/bin \
    $HOME/.cargo/bin

    if test -d $dir
        fish_add_path -gm $dir
    end
end
