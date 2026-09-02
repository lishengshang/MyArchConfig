#!/usr/bin/env bash
#
# matugen-select-type.sh — fuzzel 交互菜单，切换 Matugen 配色策略/明暗模式/主色索引。
#
# 功能: 弹出菜单选择后写入 ~/.cache/matugen-strategy/ 状态文件
#   (type/mode/index_mode，与 matugen-update.sh 读取的路径一致)，
#   再异步触发 wallpaper-post-command.sh --force，由常驻的
#   wallpaper-theme.service 低优先级完成取色与主题应用。
# 依赖: fuzzel、notify-send、wallpaper-post-command.sh
# 调用方: binds.kdl Mod+Alt+T、waybar matugen 模块中键；无命令行参数。
# 并发: 状态文件写入在共享 flock (matugen-strategy-write.lock) 内原子替换，
#   避免 matugen-update.sh 读到半截内容；不阻塞菜单交互本身。

CACHE_DIR="$HOME/.cache/matugen-strategy"
TYPE_FILE="$CACHE_DIR/type"
MODE_FILE="$CACHE_DIR/mode"
INDEX_MODE_FILE="$CACHE_DIR/index_mode"
POST_UPDATE="$HOME/.config/scripts/wallpaper-post-command.sh"

# --- 0. 确保缓存目录存在 ---
if [ ! -d "$CACHE_DIR" ]; then
    mkdir -p "$CACHE_DIR"
fi

# --- 1. 自动检测语言环境 ---
# 只检查语言相关变量, 避免 env | grep 误匹配任意环境变量
if [[ "$LANG" == *zh_CN* ]] || [[ "${LC_ALL:-}" == *zh_CN* ]] || [[ "${LC_MESSAGES:-}" == *zh_CN* ]]; then
    IS_CN=true
else
    IS_CN=false
fi

# --- 2. 读取当前模式 (Toggle) ---
CURRENT_MODE="dark"
if [ -f "$MODE_FILE" ]; then
    READ_MODE=$(cat "$MODE_FILE")
    if [[ "$READ_MODE" == "light" ]]; then
        CURRENT_MODE="light"
    fi
fi

CURRENT_INDEX_MODE="0" # 【修改點】：預設為 0
if [ -f "$INDEX_MODE_FILE" ]; then
    READ_INDEX_MODE=$(cat "$INDEX_MODE_FILE")
    if [[ "$READ_INDEX_MODE" == "random" ]]; then
        CURRENT_INDEX_MODE="random"
    fi
fi

# --- 3. 定义选项 (动态生成 Toggle 行) ---

# 模式 Toggle
if [ "$CURRENT_MODE" == "dark" ]; then
    if [ "$IS_CN" = true ]; then MODE_OPTION=">> 切换到亮色模式"; else MODE_OPTION=">> Switch to Light"; fi
else
    if [ "$IS_CN" = true ]; then MODE_OPTION=">> 切换到暗色模式"; else MODE_OPTION=">> Switch to Dark"; fi
fi

# 颜色 Index Toggle 
if [ "$CURRENT_INDEX_MODE" == "random" ]; then
    if [ "$IS_CN" = true ]; then INDEX_OPTION=">> 切换到第一主色"; else INDEX_OPTION=">> Switch to First Color"; fi
else
    if [ "$IS_CN" = true ]; then INDEX_OPTION=">> 切换到随机/轮换主色"; else INDEX_OPTION=">> Switch to Random/Cycle Color"; fi
fi

# 重新生成选项
if [ "$IS_CN" = true ]; then
    REGEN_OPTION=">> 重新生成"
else
    REGEN_OPTION=">> Regenerate"
fi

# 定义配色策略列表
if [ "$IS_CN" = true ]; then
    SCHEMES="默认点调 (scheme-tonal-spot)
鲜艳模式 (scheme-vibrant)
水果沙拉 (scheme-fruit-salad)
忠实还原 (scheme-fidelity)
表现增强 (scheme-expressive)
中性柔和 (scheme-neutral)
单色黑白 (scheme-monochrome)
彩虹混色 (scheme-rainbow)
内容优先 (scheme-content)"
    PROMPT_TEXT="Matugen 设置 > "
else
    SCHEMES="scheme-tonal-spot
scheme-fruit-salad
scheme-vibrant
scheme-fidelity
scheme-expressive
scheme-neutral
scheme-monochrome
scheme-rainbow
scheme-content"
    PROMPT_TEXT="Matugen Config > "
fi

# 合并选项
OPTIONS="${MODE_OPTION}
${INDEX_OPTION}
${REGEN_OPTION}
--------------------
${SCHEMES}"

# --- 4. Fuzzel 菜单 ---
if ! command -v fuzzel &>/dev/null; then
    notify-send -u critical "Matugen" "缺少依赖: fuzzel，请检查是否安装"
    exit 1
fi
SELECTED_LINE=$(echo "$OPTIONS" | fuzzel -d --prompt="$PROMPT_TEXT" --lines=14)
FUZZEL_EXIT=$?

# fuzzel 退出码: 实测无 Wayland 显示等启动失败与用户取消 (Esc) 都返回 1,
# 两者无法可靠区分, 统一静默退出; 仅对 ≥2 的异常退出码报错 (比原实现严格)。
if [ "$FUZZEL_EXIT" -ne 0 ] && [ "$FUZZEL_EXIT" -ne 1 ]; then
    notify-send -u critical "Matugen" "fuzzel 异常退出 (退出码 $FUZZEL_EXIT)" 2>/dev/null || true
    exit "$FUZZEL_EXIT"
fi
if [ -z "$SELECTED_LINE" ]; then
    exit 0
fi

# 过滤掉分隔线
if [[ "$SELECTED_LINE" == *"----"* ]]; then
    exit 0
fi

# --- 5. 提取真实参数 ---
# 通过字符串匹配识别控制选项
if [[ "$SELECTED_LINE" == *">>"* ]]; then
    if [[ "$SELECTED_LINE" == *"亮色"* ]] || [[ "$SELECTED_LINE" == *"Light"* ]]; then
        REAL_VALUE="light"
    elif [[ "$SELECTED_LINE" == *"暗色"* ]] || [[ "$SELECTED_LINE" == *"Dark"* ]]; then
        REAL_VALUE="dark"
    elif [[ "$SELECTED_LINE" == *"第一"* ]] || [[ "$SELECTED_LINE" == *"First"* ]]; then
        REAL_VALUE="0"
    elif [[ "$SELECTED_LINE" == *"随机"* ]] || [[ "$SELECTED_LINE" == *"Random"* ]]; then
        REAL_VALUE="random"
    elif [[ "$SELECTED_LINE" == *"重新生成"* ]] || [[ "$SELECTED_LINE" == *"Regenerate"* ]]; then
        REAL_VALUE="regenerate"
    else
        # 防御: 未知 >> 选项不当作有效值, 避免后续误写状态文件
        REAL_VALUE=""
    fi
else
    # 否则是具体策略，继续提取括号里的内容
    REAL_VALUE=$(echo "$SELECTED_LINE" | awk '{print $NF}' | tr -d '()')
fi

# --- 6. 执行逻辑 ---

# 状态文件原子写: tmp + mv 避免读方 (matugen-update.sh) 读到半截内容;
# 与写锁配合, 多实例/与读方交错时状态文件始终完整。
write_state() {
    local file="$1" value="$2" tmp
    tmp="${file}.tmp.$$"
    printf '%s\n' "$value" > "$tmp" && mv -f "$tmp" "$file"
}

if [ -n "$REAL_VALUE" ]; then

    # 共享写锁: 串行化状态文件写入 (锁文件与 matugen-update 锁目录分离,
    # 不与它的 mkdir+PID 锁互斥; 仅保护本脚本写的三个状态文件)。
    STATE_LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/matugen-strategy-write-${UID:-$(id -u)}.lock"
    exec 8>"$STATE_LOCK_FILE"
    flock 8

    # 根据 REAL_VALUE 保存对应的状态文件
    if [[ "$REAL_VALUE" == "regenerate" ]]; then
        # 仅触发更新，不修改任何文件状态
        if [ "$IS_CN" = true ]; then NOTIFY_MSG="正在重新生成颜色..."; else NOTIFY_MSG="Regenerating colors..."; fi
    elif [[ "$REAL_VALUE" == "dark" ]] || [[ "$REAL_VALUE" == "light" ]]; then
        write_state "$MODE_FILE" "$REAL_VALUE"
        if [ "$IS_CN" = true ]; then NOTIFY_MSG="已切换为: $REAL_VALUE"; else NOTIFY_MSG="Mode updated to: $REAL_VALUE"; fi
    elif [[ "$REAL_VALUE" == "0" ]] || [[ "$REAL_VALUE" == "random" ]]; then
        write_state "$INDEX_MODE_FILE" "$REAL_VALUE"
        if [ "$IS_CN" = true ]; then NOTIFY_MSG="颜色模式更新为: $REAL_VALUE"; else NOTIFY_MSG="Color strategy updated to: $REAL_VALUE"; fi
    else
        write_state "$TYPE_FILE" "$REAL_VALUE"
        if [ "$IS_CN" = true ]; then NOTIFY_MSG="色彩策略更新为: $REAL_VALUE"; else NOTIFY_MSG="Scheme updated to: $REAL_VALUE"; fi
    fi

    flock -u 8

    # 发送通知
    notify-send "Matugen" "$NOTIFY_MSG"

    # 颜色提取、应用主题和模糊背景都放到低优先级后台 worker，避免
    # fuzzel 关闭后立刻占满 CPU 让当前应用卡顿或闪烁。
    if [ -x "$POST_UPDATE" ]; then
        nohup "$POST_UPDATE" --force >/dev/null 2>&1 </dev/null &
    else
        notify-send "Error" "脚本未找到: $POST_UPDATE"
    fi
fi
