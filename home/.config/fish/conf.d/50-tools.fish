# ============================================================================
# 50-tools.fish - 工具初始化（交互式 shell 专属）
# ============================================================================
# 所有需要 init 的工具集中在这里。用 _cached_init 缓存 init 脚本到
# ~/.cache/fish/init/，工具二进制更新时自动重建，避免每次启动都 fork
# 6 个子进程生成 init 脚本。
#
# 缓存命中判断：工具二进制的 mtime 比 cache 新就重建，否则用缓存。
# 手动重建：rm -rf ~/.cache/fish/init/
#
# 三层补全架构（详见 functions/fish-update-completions.fish）：
#   1. 工具自带补全（最准）                       ← XDG_DATA_HOME 运行时生成
#   2. 手写补全（dot/dota/y 等）                   ← ~/.config/fish/completions
#   3. carapace 兜底（2000+ 命令, on-demand）      ← 下面 carapace 段
#   4. fish 默认（文件/路径补全）
# 工具自带补全和手写补全都会覆盖 carapace（fish 后注册赢）。
# 健康检查: fish-comp-doctor
# ============================================================================

if status is-interactive
    set -g _tool_init_cache_dir ~/.cache/fish/init
    test -d $_tool_init_cache_dir; or mkdir -p $_tool_init_cache_dir

    # 缓存工具 init 输出。命中时直接 source 缓存文件，未命中时重建。
    # 参数：$argv[1]=缓存名  $argv[2..]=生成 init 的命令
    function _cached_init -d "Cache tool init output to speed up startup"
        set -l name $argv[1]
        set -l cmd $argv[2..]
        set -l bin (string split ' ' -- $cmd[1])[1]

        # 工具未装：跳过
        if not command -q $bin
            return
        end

        set -l cache $_tool_init_cache_dir/$name.fish

        # 缓存命中且工具未更新：直接 source
        if test -f $cache
            and test (command -v $bin) -nt $cache
            source $cache
            return
        end

        # 缓存未命中或工具已更新：重建
        $cmd >$cache 2>/dev/null
        if test -s $cache
            source $cache
        else
            rm -f $cache
        end
    end

    # --- Starship 提示符 ---
    _cached_init starship starship init fish

    # --- Zoxide 智能 cd（替代 cd） ---
    _cached_init zoxide zoxide init fish --cmd cd

    # --- uv shell 补全 ---
    _cached_init uv uv generate-shell-completion fish

    # --- mise：继续管理 Python/Ruby/Go 等非 Node 工具 ---
    _cached_init mise mise activate fish

    # --- fnm：统一管理 Node/npm/pi，并按目录自动切换 ---
    # fnm 必须在 mise shims 之后初始化，让 fnm 的 multishell 路径优先。
    if command -q fnm
        fnm env --use-on-cd --shell fish | source
        fnm use default --silent-if-unchanged >/dev/null 2>&1
    end

    # --- direnv 项目环境 ---
    _cached_init direnv direnv hook fish

    # --- carapace 通用补全引擎（兜底） ---
    # 安装: paru -S carapace-bin
    # 作用: 为 2000+ 命令提供 on-demand 补全，覆盖未生成自带补全的工具
    # 工具自带补全和手写补全会自动覆盖 carapace（后注册赢）
    # 健康检查: fish-comp-doctor
    if command -q carapace
        set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
        _cached_init carapace carapace _carapace fish
    end

    # --- 预加载自带补全（解决 carapace 占位问题） ---
    # fish 4.x 懒加载 fish_complete_path 依赖 `complete -c CMD` 钩子触发。
    # carapace 的 `complete --no-files CMD -a '...'` 注册后会"占位"，
    # 阻止 fish 加载对应的 CMD.fish（即使文件存在也不会 source）。
    # 这里显式 source 自带补全文件，让它们赢过 carapace（后注册覆盖先注册）。
    #
    # 只预加载"工具自带补全比 carapace 更准"的关键命令，避免全量 source
    # 拖慢启动。其他命令让 carapace 兜底即可。
    # mise 必须预加载: carapace 的 mise spec 有 bug (unsupported cmd prop
    # effect), 补全返回空, 只有自带补全 mise.fish 可用
    for cmd in opencode gh uv niri starship bat procs delta fd lazygit \
               git apt dot dota y zoxide eza rg mise
        # 手写补全优先，其次使用 ~/.local/share 下运行时生成的补全。
        for completions_dir in \
            ~/.config/fish/completions \
            "$XDG_DATA_HOME/fish/generated-completions"
            set -l f "$completions_dir/$cmd.fish"
            if test -f "$f"
                source "$f" 2>/dev/null
                break
            end
        end
    end

    # --- Atuin 神级历史搜索（接管 Ctrl+R） ---
    # --disable-up-arrow：↑ 保留 fish 原生前缀搜索，atuin 只接管 Ctrl+R
    # 与 zsh/integrations.zsh 策略一致
    _cached_init atuin atuin init fish --disable-up-arrow
end
