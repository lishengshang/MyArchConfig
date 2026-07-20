# ============================================================================
# fish-update-completions - 批量生成工具自带的 fish 补全
# ============================================================================
# 三层补全架构（优先级从高到低）：
#   1. 工具自带补全（最准，支持动态子命令）  ← 本函数生成
#   2. carapace 兜底（2000+ 命令，on-demand 调用）
#   3. fish 默认（文件/路径补全）
#
# fish 的 complete 规则后注册覆盖先注册：
#   - carapace 在 50-tools.fish 启动时注册（先）
#   - completions/*.fish 在 Tab 时懒加载（后，覆盖 carapace）
# 因此工具自带补全放在 completions/ 会自动赢过 carapace。
#
# 用法:
#   fish-update-completions          # 生成所有支持的
#   fish-update-completions gh       # 只生成指定工具
#   fish-update-completions --force  # 强制重建
#   fish-update-completions --clean  # 删除工具不再装时的孤儿补全
# ============================================================================

function fish-update-completions -d "Generate tool-native fish completions"
    set -l force 0
    set -l clean 0
    set -l targets

    for arg in $argv
        switch $arg
            case -f --force
                set force 1
            case -c --clean
                set clean 1
            case -h --help
                echo "用法: fish-update-completions [工具...] [选项]"
                echo ""
                echo "选项:"
                echo "  -f, --force   强制重建（即使已存在）"
                echo "  -c, --clean   删除工具不再安装的孤儿补全"
                echo "  -h, --help    显示此帮助"
                echo ""
                echo "不带参数：生成所有支持的工具补全"
                return 0
            case '*'
                set -a targets $arg
        end
    end

    # --- 清理孤儿补全（仅清理本函数管理的工具） ---
    if test $clean -eq 1
        echo "清理孤儿补全（仅本函数生成的）..."
        set -l managed_cmds niri starship uv gh bat delta fd lazygit procs mise
        set -l removed 0
        for cmd in $managed_cmds
            set -l f ~/.config/fish/completions/$cmd.fish
            if test -f $f
                and not command -q $cmd
                rm -f -- $f
                echo "  删除: $cmd（工具未装）"
                set removed (math $removed + 1)
            end
        end
        echo "汇总: 删除 $removed 个孤儿补全"
        return 0
    end

    # --- 工具补全生成器映射表 ---
    # 格式: "工具名|生成命令|处理方式"
    # 处理方式: stdout=直接输出 fish 补全  file=写到 cwd 的 <name>.fish
    set -l generators \
        "niri|niri completions fish|stdout" \
        "starship|starship completions fish|stdout" \
        "uv|uv generate-shell-completion fish|stdout" \
        "gh|gh completion -s fish|stdout" \
        "bat|bat --completion fish|stdout" \
        "delta|delta --generate-completion fish|stdout" \
        "fd|fd --gen-completions fish|stdout" \
        "lazygit|lazygit completion fish|stdout" \
        "procs|procs --gen-completion fish|file" \
        "mise|mise completion fish|stdout"

    # --- 遍历生成 ---
    set -l updated 0
    set -l skipped 0
    set -l failed 0

    for entry in $generators
        set -l parts (string split '|' -- $entry)
        set -l cmd $parts[1]
        set -l gen_cmd $parts[2]
        set -l mode $parts[3]

        # 如果指定了 targets，只处理列表中的
        if test (count $targets) -gt 0
            and not contains -- $cmd $targets
            continue
        end

        # 工具未装：跳过
        if not command -q $cmd
            continue
        end

        set -l out_file ~/.config/fish/completions/$cmd.fish

        # 已存在且非强制：跳过
        if test -f $out_file
            and test $force -eq 0
            set skipped (math $skipped + 1)
            continue
        end

        echo -n "  $cmd: "

        # 特殊处理：mise 需要前置（usage-cli 依赖说明）
        if test "$cmd" = mise
            if not command -q usage
                echo "跳过（需要 usage-cli，未装）"
                set skipped (math $skipped + 1)
                continue
            end
        end

        # 特殊处理：opencode 的 yargs 补全是 zsh 格式，不能用
        # （不放入 generators 表，跳过逻辑留作记录）

        switch $mode
            case stdout
                if eval $gen_cmd >$out_file.tmp 2>/dev/null
                    and test -s $out_file.tmp
                    mv -f $out_file.tmp $out_file
                    echo "✓ 生成 ("(wc -l < $out_file | string trim)" 行)"
                    set updated (math $updated + 1)
                else
                    rm -f $out_file.tmp
                    echo "✗ 失败"
                    set failed (math $failed + 1)
                end
            case file
                # procs 风格：写到当前目录的 <name>.fish
                set -l prev_dir $PWD
                cd /tmp
                if eval $gen_cmd 2>/dev/null
                    and test -f /tmp/$cmd.fish
                    mv -f /tmp/$cmd.fish $out_file
                    echo "✓ 生成 ("(wc -l < $out_file | string trim)" 行)"
                    set updated (math $updated + 1)
                else
                    rm -f /tmp/$cmd.fish
                    echo "✗ 失败"
                    set failed (math $failed + 1)
                end
                cd $prev_dir
        end
    end

    echo ""
    echo "汇总: 更新 $updated / 跳过 $skipped / 失败 $failed"
    echo ""
    echo "提示:"
    echo "  - 补全文件懒加载，立即生效（无需重启 fish）"
    echo "  - 重新生成: fish-update-completions --force"
    echo "  - 清理孤儿: fish-update-completions --clean"
end
