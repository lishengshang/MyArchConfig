#!/bin/bash

# ================= 默认配置 =================
# 源池: name|url  (顺序不重要,运行时随机打乱)
SOURCES=(
    "alcy|https://t.alcy.cc/pc/"
    "dmoe|https://www.dmoe.cc/random.php"
    "moejue|https://random.MoeJue.cn/randbg?type=pc"
    "paugram|https://api.paugram.com/wallpaper/?source=sina"
    "paiii|https://t.paiii.cn/api/random"
    "yppp|https://api.yppp.net/pc.php"
    "uapis|https://uapis.cn/api/v1/random/image?category=acg&type=pc"
    "touhou|https://img.paulzzh.com/touhou/random?size=pc"
)

SAVE_DIR="$HOME/Pictures/Wallpapers/api-random-download"

# 自动清理时保留最近多少张图片
KEEP_COUNT=1000

# 阈值: 宽度小于此值(即1080P及以下)才进行超分,2K/4K 原图直出
UPSCALE_THRESHOLD=2200

# 失败降级: 最多尝试多少个源
MAX_SOURCE_ATTEMPTS=3

# 默认开关状态 (可被参数覆盖)
ENABLE_CLEANUP=true   # 默认清理旧图片
ENABLE_UPSCALE=true   # 默认开启智能超分
SILENT_MODE=false     # 默认开启通知
FORCED_SOURCE=""      # 默认随机; 用 -S <name> 指定

# ================= 参数解析 =================
usage() {
    echo "用法: $(basename $0) [-k] [-n] [-s] [-S <name>] [-h]"
    echo "  -k           (Keep)    保留模式: 不清理旧壁纸"
    echo "  -n           (No Up)  禁用超分: 无论分辨率多少,都直接使用原图"
    echo "  -s           (Silent) 静默模式: 不发送任何 notify-send 通知"
    echo "  -S <name>    (Source) 指定使用某个源 (alcy/dmoe/moejue/paugram/paiii/yppp/uapis/touhou)"
    echo "  -h           帮助信息"
    exit 0
}

while getopts "knS:sh" opt; do
  case $opt in
    k) ENABLE_CLEANUP=false ;;
    n) ENABLE_UPSCALE=false ;;
    s) SILENT_MODE=true ;;
    S) FORCED_SOURCE="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# ================= 辅助函数 =================

send_notify() {
    # $1: Title, $2: Body, $3: Extra Args (optional)
    if [ "$SILENT_MODE" = false ]; then
        notify-send "$1" "$2" $3
    fi
}

# 校验下载结果: 文件存在 + 大小 >= 20KB + MIME 是 image/*
# 用法: validate_image <path>  -> 返回 0 成功 / 1 失败
validate_image() {
    local f="$1"
    [ -f "$f" ] || return 1
    [ "$(wc -c < "$f")" -ge 20480 ] || return 1
    local mime
    mime=$(file --mime-type -b "$f")
    [[ "$mime" == image/* ]] || return 1
    return 0
}

# 从源池构造本次尝试顺序 (随机打乱,或把指定源放最前)
# 输出 stdout: 每行一个 "name|url";返回 1 表示 FORCED_SOURCE 不存在
build_source_order() {
    if [ -n "$FORCED_SOURCE" ]; then
        local found=""
        for s in "${SOURCES[@]}"; do
            if [ "${s%%|*}" = "$FORCED_SOURCE" ]; then
                found="$s"
                break
            fi
        done
        [ -z "$found" ] && return 1
        echo "$found"
        for s in "${SOURCES[@]}"; do
            [ "$s" = "$found" ] && continue
            echo "$s"
        done | shuf
    else
        printf '%s\n' "${SOURCES[@]}" | shuf
    fi
}

# ================= 主逻辑 =================

mkdir -p "$SAVE_DIR"
RAW_FILENAME="wall_$(date +%s).jpg"
RAW_PATH="${SAVE_DIR}/${RAW_FILENAME}"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# --- 1. 下载模块 (带心跳通知 + 多源降级) ---

if [ "$SILENT_MODE" = false ]; then
    (
        sleep 8
        while true; do
            notify-send "Wallpaper" "Downloading is still in progress..." --expire-time=5000 --icon=drive-harddisk --replace-id=999
            sleep 8
        done
    ) &
    NOTIFY_PID=$!
else
    NOTIFY_PID=""
fi

send_notify "Wallpaper" "Downloading..." "--expire-time=5000"

# 构造源尝试顺序
SOURCE_ORDER=$(build_source_order)
if [ $? -ne 0 ]; then
    echo "错误: 未知源 '$FORCED_SOURCE'" >&2
    echo "可用源: ${SOURCES[*]//|*/ }" >&2
    send_notify "Wallpaper Error" "未知源: $FORCED_SOURCE" "--urgency=critical"
    exit 1
fi
ATTEMPT_COUNT=0
DOWNLOAD_OK=false
USED_SOURCE_NAME=""

# 依次尝试,最多 MAX_SOURCE_ATTEMPTS 个源,首个成功即用
while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    ATTEMPT_COUNT=$((ATTEMPT_COUNT + 1))
    if [ "$ATTEMPT_COUNT" -gt "$MAX_SOURCE_ATTEMPTS" ]; then
        break
    fi

    SRC_NAME="${entry%%|*}"
    SRC_URL="${entry#*|}"

    send_notify "Wallpaper" "尝试 [$SRC_NAME] ($ATTEMPT_COUNT/$MAX_SOURCE_ATTEMPTS)..." "--expire-time=3000"

    curl -L -s -A "$USER_AGENT" --connect-timeout 10 -m 120 -o "$RAW_PATH" "$SRC_URL"
    CURL_EXIT=$?

    if [ $CURL_EXIT -eq 0 ] && validate_image "$RAW_PATH"; then
        DOWNLOAD_OK=true
        USED_SOURCE_NAME="$SRC_NAME"
        break
    fi

    rm -f "$RAW_PATH"
done <<< "$SOURCE_ORDER"

# 下载结束,杀掉心跳通知进程
if [ -n "$NOTIFY_PID" ]; then
    kill "$NOTIFY_PID" 2>/dev/null
    wait "$NOTIFY_PID" 2>/dev/null
fi

if [ "$DOWNLOAD_OK" = false ]; then
    send_notify "Wallpaper Error" "All sources failed after $MAX_SOURCE_ATTEMPTS attempts" "--urgency=critical"
    rm -f "$RAW_PATH"
    exit 1
fi

# --- 2. 智能超分模块 ---

FINAL_PATH="$RAW_PATH"
MSG_EXTRA="from $USED_SOURCE_NAME"

if [ "$ENABLE_UPSCALE" = true ]; then
    IMG_WIDTH=0
    if command -v identify &> /dev/null; then
        IMG_WIDTH=$(identify -format "%w" "$RAW_PATH")
    fi

    if [ "$IMG_WIDTH" -gt 0 ] && [ "$IMG_WIDTH" -lt "$UPSCALE_THRESHOLD" ] && command -v waifu2x-ncnn-vulkan &> /dev/null; then
        send_notify "Wallpaper" "Upscaling image..." "--expire-time=2000"
        UPSCALED_PATH="${RAW_PATH%.*}.png"

        if waifu2x-ncnn-vulkan -i "$RAW_PATH" -o "$UPSCALED_PATH" -n 1 -s 2; then
            FINAL_PATH="$UPSCALED_PATH"
            MSG_EXTRA="$MSG_EXTRA (Upscaled 2x)"
            rm "$RAW_PATH"
        else
            MSG_EXTRA="$MSG_EXTRA (Upscale Failed)"
        fi
    else
        if [ "$IMG_WIDTH" -ge "$UPSCALE_THRESHOLD" ]; then
            MSG_EXTRA="$MSG_EXTRA (Original High-Res)"
        else
            MSG_EXTRA="$MSG_EXTRA (Original)"
        fi
    fi
else
    MSG_EXTRA="$MSG_EXTRA (Upscale Disabled)"
fi

# --- 3. 应用模块 ---

awww img "$FINAL_PATH" --transition-duration 2 --transition-type center --transition-fps 60

# --- 4. 钩子与清理 ---

(
    [ -x "$HOME/.config/scripts/matugen-update.sh" ] && "$HOME/.config/scripts/matugen-update.sh" "$FINAL_PATH" > /dev/null

    sleep 0.5

    [ -x "$HOME/.config/scripts/niri_set_overview_blur_dark_bg.sh" ] && "$HOME/.config/scripts/niri_set_overview_blur_dark_bg.sh" > /dev/null

    # 动态清理逻辑: 保留最近 KEEP_COUNT 张,按修改时间倒序
    # 用 find -printf + NUL 分隔处理文件名特殊字符;${line#* } 跳过 mtime 字段
    if [ "$ENABLE_CLEANUP" = true ]; then
        DELETE_START=$((KEEP_COUNT + 1))
        find "$SAVE_DIR" -maxdepth 1 -type f -printf '%T@ %p\0' \
            | sort -z -k1,1 -rn \
            | tail -z -n +$DELETE_START \
            | while IFS= read -r -d '' line; do
                f="${line#* }"
                rm -- "$f" 2>/dev/null
            done
    fi
) &

send_notify "Wallpaper Updated" "Enjoy! $MSG_EXTRA"
