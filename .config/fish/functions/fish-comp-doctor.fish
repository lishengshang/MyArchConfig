# ============================================================================
# fish-comp-doctor - 补全系统健康检查
# ============================================================================
# 检查三层补全架构的状态：
#   1. 工具自带补全（completions/*.fish 由 fish-update-completions 生成）
#   2. carapace 兜底（CARAPACE_BRIDGES 配置 + 注册规则数）
#   3. fish 默认（路径补全）
#
# 用法: fish-comp-doctor [命令名]
#   不带参数：全局健康检查
#   带参数：检查指定命令的补全来源
# ============================================================================

function fish-comp-doctor -d "Fish completion system health check"
    set -l c_title (set_color --bold magenta)
    set -l c_label (set_color cyan)
    set -l c_ok (set_color green)
    set -l c_warn (set_color yellow)
    set -l c_bad (set_color red)
    set -l c_rst (set_color normal)

    # --- 单命令诊断 ---
    if test (count $argv) -gt 0
        set -l cmd $argv[1]
        echo "$c_title━━━ 补全诊断: $cmd $c_rst"
        echo ""

        # 是否安装
        if not command -q $cmd
            echo "  $c_bad✗ 工具未安装$c_rst"
            return 1
        end
        echo "  $c_ok✓ 已安装$c_rst: "(command -v $cmd)

        # 是否有 completions/ 文件
        set -l f ~/.config/fish/completions/$cmd.fish
        if test -f $f
            set -l lines (wc -l < $f | string trim)
            set -l size (stat -c %s $f)
            echo "  $c_ok✓ 工具自带补全$c_rst: $f ($lines 行, $size 字节)"
            echo "    来源: "(head -1 $f | string trim)
        else
            echo "  $c_warn⚠ 无工具自带补全$c_rst（运行 fish-update-completions $cmd 生成）"
        end

        # carapace 是否注册
        set -l carapace_rules (complete | string match -r -- "^complete.* $cmd " | count)
        if test $carapace_rules -gt 0
            echo "  $c_ok✓ carapace 注册$c_rst ($carapace_rules 条规则)"
            # 实测 carapace 补全是否真的返回内容
            set -l test_result (complete -C "$cmd " 2>/dev/null | head -1)
            if test -n "$test_result"
                echo "  $c_ok✓ 实际补全有效$c_rst: $test_result"
            else
                echo "  $c_warn⚠ carapace 注册但补全返回空$c_rst（工具可能不在 carapace 覆盖范围）"
            end
        else
            echo "  $c_warn⚠ carapace 未注册$c_rst"
        end

        # 实测 Tab 补全
        set -l actual (complete -C "$cmd " 2>/dev/null | head -3)
        if test -n "$actual"
            echo "  $c_ok✓ Tab 补全有效$c_rst:"
            for line in $actual
                echo "    $line"
            end
        else
            echo "  $c_bad✗ Tab 补全返回空$c_rst"
        end
        return 0
    end

    # --- 全局诊断 ---
    echo "$c_title━━━━━━━━━━━ 补全系统健康检查 ━━━━━━━━━━━$c_rst"
    echo ""

    # --- completions/ 目录 ---
    set -l comp_dir ~/.config/fish/completions
    set -l comp_count (ls $comp_dir/*.fish 2>/dev/null | count)
    echo "$c_label[1] completions/ 目录$c_rst"
    echo "  路径: $comp_dir"
    echo "  文件: $comp_count 个"
    echo ""

    # --- carapace 状态 ---
    echo "$c_label[2] carapace 兜底$c_rst"
    if command -q carapace
        echo "  $c_ok✓ 已安装$c_rst: "(carapace --version 2>/dev/null || echo "未知版本")
        echo "  桥接: $CARAPACE_BRIDGES"
        set -l carapace_rules (complete | grep -c carapace 2>/dev/null || echo 0)
        echo "  注册规则: $carapace_rules 条"
        set -l carapace_cache ~/.cache/fish/init/carapace.fish
        if test -f $carapace_cache
            echo "  缓存: $carapace_cache ("(wc -l < $carapace_cache | string trim)" 行)"
        else
            echo "  $c_warn⚠ 无缓存$c_rst（首次启动或 50-tools.fish 未执行）"
        end
    else
        echo "  $c_bad✗ 未安装$c_rst（paru -S carapace-bin）"
    end
    echo ""

    # --- 工具自带补全覆盖检查 ---
    echo "$c_label[3] 工具自带补全覆盖$c_rst"
    set -l managed_cmds niri starship uv gh bat delta fd lazygit procs mise
    set -l has_native 0
    set -l missing_native
    for cmd in $managed_cmds
        if command -q $cmd
            if test -f $comp_dir/$cmd.fish
                set has_native (math $has_native + 1)
            else
                set -a missing_native $cmd
            end
        end
    end
    echo "  已生成: $has_native / "(math $has_native + (count $missing_native))" 个支持工具"
    if test (count $missing_native) -gt 0
        echo "  $c_warn⚠ 缺失$c_rst: "(string join ' ' -- $missing_native)
        echo "  修复: fish-update-completions"
    else
        echo "  $c_ok✓ 全部已生成$c_rst"
    end
    echo ""

    # --- 实测常见命令补全 ---
    echo "$c_label[4] 实测补全（关键命令）$c_rst"
    set -l test_cmds git gh uv niri starship mise procs
    for cmd in $test_cmds
        if command -q $cmd
            set -l result (complete -C "$cmd " 2>/dev/null | head -1)
            if test -n "$result"
                printf "  %s✓%s %-12s %s\n" $c_ok $c_rst $cmd (string sub -l 50 -- $result)
            else
                printf "  %s✗%s %-12s %s\n" $c_bad $c_rst $cmd "(返回空)"
            end
        end
    end
    echo ""

    # --- 补全更新提示 ---
    echo "$c_label[5] 维护命令$c_rst"
    echo "  fish-update-completions          生成工具自带补全"
    echo "  fish-update-completions --force  强制重建"
    echo "  fish-update-completions --clean  清理孤儿"
    echo "  fish-comp-doctor <命令>           诊断单个命令"
end
