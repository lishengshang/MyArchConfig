function f -d "Random anime girl generator with Fastfetch"
    # ================= 配置区域 =================
    set -l CLEAN_CACHE_MODE true
    set -l DOWNLOAD_BATCH_SIZE 10
    set -l MAX_CACHE_LIMIT 100
    set -l MIN_TRIGGER_LIMIT 60
    set -l MAX_USED_LIMIT 50
    # ===========================================

    # --- 语言检测 ---
    set -l IS_ZH false
    if string match -q -r "^zh" "$LANG"
        set IS_ZH true
    end

    # --- 帮助信息 ---
    if test (count $argv) -gt 0; and test "$argv[1]" = "-h" -o "$argv[1]" = "--help"
        if test "$IS_ZH" = true
            echo "用法: f [fastfetch 参数]"
            echo "  f           : 随机二次元图片 + 系统信息"
            echo "  f --help    : 显示此帮助"
        else
            echo "Usage: f [fastfetch args]"
            echo "  f           : Random anime girl + system info"
            echo "  f --help    : Show this help"
        end
        return 0
    end

    # --- 目录配置 ---
    set -l CACHE_DIR "$HOME/.cache/fastfetch_waifu"
    set -l USED_DIR "$CACHE_DIR/used"
    set -l LOCK_FILE "/tmp/fastfetch_waifu.lock"
    mkdir -p "$CACHE_DIR" "$USED_DIR"

    # --- 后台补货任务 ---
    # 子 shell 自动加载 functions/ 下的 _f_* 函数，无需字符串注入。
    # 用 nohup + disown 让进程在 shell 退出后存活（fish 无 trap builtin）。
    function _f_background_job -V CACHE_DIR -V LOCK_FILE -V MIN_TRIGGER_LIMIT -V DOWNLOAD_BATCH_SIZE -V MAX_CACHE_LIMIT
        nohup fish -c "
            flock -n 200 || exit 1

            if not _f_check_network
                exit 0
            end

            set CACHE_DIR '$CACHE_DIR'
            set CURRENT_COUNT (find \$CACHE_DIR -maxdepth 1 -name '*.jpg' 2>/dev/null | wc -l)

            if test \$CURRENT_COUNT -lt $MIN_TRIGGER_LIMIT
                for i in (seq 1 $DOWNLOAD_BATCH_SIZE)
                    _f_download_image \$CACHE_DIR
                    sleep 0.5
                end
            end

            set FINAL_COUNT (find \$CACHE_DIR -maxdepth 1 -name '*.jpg' 2>/dev/null | wc -l)
            if test \$FINAL_COUNT -gt $MAX_CACHE_LIMIT
                set DELETE_START (math $MAX_CACHE_LIMIT + 1)
                ls -tp \$CACHE_DIR/*.jpg 2>/dev/null | tail -n +\$DELETE_START | xargs -I {} rm -- '{}'
            end
        " 200>\"$LOCK_FILE\" >/dev/null 2>&1 &
        disown
    end

    # --- 主逻辑 ---
    set -l FILES $CACHE_DIR/*.jpg
    set -l NUM_FILES (count $FILES)
    if test "$NUM_FILES" -eq 1; and not test -f "$FILES[1]"
        set NUM_FILES 0
        set FILES
    end

    set -l SELECTED_IMG ""

    if test "$NUM_FILES" -gt 0
        set -l RAND_INDEX (math (random) % $NUM_FILES + 1)
        set SELECTED_IMG "$FILES[$RAND_INDEX]"
        _f_background_job
    else
        echo "库存不足，正在下载..."
        if _f_check_network
            _f_download_image $CACHE_DIR
        else
            echo "网络异常，无法下载"
        end
        set FILES $CACHE_DIR/*.jpg
        if test -f "$FILES[1]"
            set SELECTED_IMG "$FILES[1]"
            _f_background_job
        end
    end

    # --- 显示图片 ---
    if test -n "$SELECTED_IMG"; and test -f "$SELECTED_IMG"
        fastfetch --logo "$SELECTED_IMG" --logo-preserve-aspect-ratio true $argv
        mv "$SELECTED_IMG" "$USED_DIR/"

        set -l used_files $USED_DIR/*.jpg
        set -l used_count (count $used_files)
        if test "$used_count" -eq 1; and not test -f "$used_files[1]"
            set used_count 0
        end

        if test "$used_count" -gt "$MAX_USED_LIMIT"
            set -l skip_lines (math "$MAX_USED_LIMIT" + 1)
            ls -tp "$USED_DIR"/*.jpg 2>/dev/null | tail -n +$skip_lines | xargs -I {} rm -- '{}'
        end

        if test "$CLEAN_CACHE_MODE" = true
            rm -rf "$HOME/.cache/fastfetch/images"
        end
    else
        echo "图片获取失败，显示默认 Logo"
        fastfetch $argv
    end
end
