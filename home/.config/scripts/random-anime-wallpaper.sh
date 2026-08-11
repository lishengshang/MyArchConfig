#!/bin/bash

# ================= 默认配置 =================
# 源池: name|url  (顺序不重要,运行时随机打乱)
SOURCES=(
    "dmoe|https://www.dmoe.cc/random.php"
    "moejue|https://random.MoeJue.cn/randbg?type=pc"
    "paugram|https://api.paugram.com/wallpaper/?source=sina"
    "paiii|https://t.paiii.cn/api/random"
    "yppp|https://api.yppp.net/pc.php"
    "uapis|https://uapis.cn/api/v1/random/image?category=acg&type=pc"
    "touhou|https://img.paulzzh.com/touhou/random?size=pc"
)

# 保底源: 其他源全部失败后再尝试
FALLBACK_SOURCE="alcy|https://t.alcy.cc/pc/"

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
    # $1: Title, $2: Body, 其余参数: 透传给 notify-send
    if [ "$SILENT_MODE" = false ]; then
        local title="$1" body="$2"
        shift 2
        notify-send "$title" "$body" "$@"
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

# 从源池构造本次尝试顺序 (随机打乱,或把指定源放最前,保底源永远最后)
# 输出 stdout: 每行一个 "name|url";返回 1 表示 FORCED_SOURCE 不存在
build_source_order() {
    local fallback_name="${FALLBACK_SOURCE%%|*}"
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
        # 保底源放在最后
        [ "$fallback_name" != "$FORCED_SOURCE" ] && echo "$FALLBACK_SOURCE"
    else
        printf '%s\n' "${SOURCES[@]}" | shuf
        echo "$FALLBACK_SOURCE"
    fi
}

# ================= 主逻辑 =================

mkdir -p "$SAVE_DIR"

# 单实例锁: timer 与手动调用并发时, 防止互踩下载文件与 waypaper 配置。
# mkdir+PID 自愈锁 (flock 的 fd 可能被外部进程继承导致永久占用)
LOCK_DIR="$SAVE_DIR/.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    LOCK_PID=$(cat "$LOCK_DIR/pid" 2>/dev/null)
    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
        exit 0
    fi
    rm -rf "$LOCK_DIR" 2>/dev/null
    mkdir "$LOCK_DIR" 2>/dev/null || exit 0
fi
echo "$$" > "$LOCK_DIR/pid"
trap 'rm -rf "$LOCK_DIR"' EXIT

# 纳秒+PID 保证同秒多次调用也不冲突
RAW_FILENAME="wall_$(date +%s%N)_$$.jpg"
RAW_PATH="${SAVE_DIR}/${RAW_FILENAME}"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# --- 1. 下载模块 (带心跳通知 + 多源降级) ---

if [ "$SILENT_MODE" = false ]; then
    (
        sleep 8
        while true; do
            notify-send "壁纸" "壁纸下载仍在进行中..." --expire-time=5000 --icon=drive-harddisk --replace-id=999
            sleep 8
        done
    ) &
    NOTIFY_PID=$!
else
    NOTIFY_PID=""
fi

send_notify "壁纸" "正在下载壁纸..." "--expire-time=5000"

# 构造源尝试顺序
SOURCE_ORDER=$(build_source_order)
if [ $? -ne 0 ]; then
    echo "错误: 未知源 '$FORCED_SOURCE'" >&2
    echo "可用源: ${SOURCES[*]//|*/ }" >&2
    send_notify "壁纸错误" "未知图源: $FORCED_SOURCE" "--urgency=critical"
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

    send_notify "壁纸" "正在尝试 [$SRC_NAME] ($ATTEMPT_COUNT/$MAX_SOURCE_ATTEMPTS)..." "--expire-time=3000"

    curl -L -s -A "$USER_AGENT" --connect-timeout 10 -m 120 -o "$RAW_PATH" "$SRC_URL"
    CURL_EXIT=$?

    if [ $CURL_EXIT -eq 0 ] && validate_image "$RAW_PATH"; then
        DOWNLOAD_OK=true
        USED_SOURCE_NAME="$SRC_NAME"
        break
    fi

    rm -f "$RAW_PATH"
done <<< "$SOURCE_ORDER"

# 保底源: 主循环只尝试前 MAX_SOURCE_ATTEMPTS 个, fallback 排在最后轮不到,
# 必须在循环结束后单独尝试
if [ "$DOWNLOAD_OK" = false ] && [ -n "$FALLBACK_SOURCE" ]; then
    FALLBACK_NAME="${FALLBACK_SOURCE%%|*}"
    FALLBACK_URL="${FALLBACK_SOURCE#*|}"
    send_notify "壁纸" "正在尝试保底源 [$FALLBACK_NAME]..." "--expire-time=3000"

    curl -L -s -A "$USER_AGENT" --connect-timeout 10 -m 120 -o "$RAW_PATH" "$FALLBACK_URL"
    CURL_EXIT=$?

    if [ $CURL_EXIT -eq 0 ] && validate_image "$RAW_PATH"; then
        DOWNLOAD_OK=true
        USED_SOURCE_NAME="$FALLBACK_NAME"
    else
        rm -f "$RAW_PATH"
    fi
fi

# 下载结束,杀掉心跳通知进程
if [ -n "$NOTIFY_PID" ]; then
    kill "$NOTIFY_PID" 2>/dev/null
    wait "$NOTIFY_PID" 2>/dev/null
fi

if [ "$DOWNLOAD_OK" = false ]; then
    send_notify "壁纸错误" "所有图源在 $MAX_SOURCE_ATTEMPTS 次尝试后均失败" "--urgency=critical"
    rm -f "$RAW_PATH"
    exit 1
fi

# --- 2. 智能超分模块 ---

FINAL_PATH="$RAW_PATH"
MSG_EXTRA="来自 $USED_SOURCE_NAME"

if [ "$ENABLE_UPSCALE" = true ]; then
    IMG_WIDTH=0
    if command -v identify &> /dev/null; then
        IMG_WIDTH=$(identify -format "%w" "$RAW_PATH")
    fi

    if [ "$IMG_WIDTH" -gt 0 ] && [ "$IMG_WIDTH" -lt "$UPSCALE_THRESHOLD" ] && command -v waifu2x-ncnn-vulkan &> /dev/null; then
        send_notify "壁纸" "正在超分放大图片..." "--expire-time=2000"
        UPSCALED_PATH="${RAW_PATH%.*}.png"

        if waifu2x-ncnn-vulkan -i "$RAW_PATH" -o "$UPSCALED_PATH" -n 1 -s 2; then
            FINAL_PATH="$UPSCALED_PATH"
            MSG_EXTRA="$MSG_EXTRA (已超分 2x)"
            rm "$RAW_PATH"
        else
            MSG_EXTRA="$MSG_EXTRA (超分失败)"
        fi
    else
        if [ "$IMG_WIDTH" -ge "$UPSCALE_THRESHOLD" ]; then
            MSG_EXTRA="$MSG_EXTRA (原图高分辨率)"
        else
            MSG_EXTRA="$MSG_EXTRA (原图)"
        fi
    fi
else
    MSG_EXTRA="$MSG_EXTRA (超分已禁用)"
fi

# --- 3. 应用模块 ---

if ! awww img "$FINAL_PATH" --transition-duration 2 --transition-type center --transition-fps 60; then
    send_notify "壁纸错误" "awww 应用壁纸失败" "--urgency=critical"
    # 清理本次下载的文件, 避免残留
    rm -f "$RAW_PATH"
    [ "$FINAL_PATH" != "$RAW_PATH" ] && rm -f "$FINAL_PATH"
    exit 1
fi

# 同步 waypaper 状态: 本脚本绕过 waypaper 直接调用 awww, 需手动更新 waypaper 的
# 当前壁纸记录, 否则 waypaper GUI 显示的"当前壁纸"会过期, matugen-update.sh /
# niri_set_overview_blur_dark_bg.sh 的 fallback 分支也会读到错误的壁纸路径.
WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"
if [ -f "$WAYPAPER_CONFIG" ]; then
    # 把绝对路径转成 ~ 形式, 与 waypaper 配置风格保持一致
    WALLPAPER_TILDE="${FINAL_PATH/#$HOME/\~}"
    # 路径中的 & | \ 会破坏 sed 替换 (& 展开为匹配文本, | 终止分隔符, \ 是转义符)
    WALLPAPER_TILDE_ESCAPED=$(printf '%s' "$WALLPAPER_TILDE" | sed 's/[&|\\]/\\&/g')
    sed -i "s|^wallpaper[[:space:]]*=.*|wallpaper = $WALLPAPER_TILDE_ESCAPED|" "$WAYPAPER_CONFIG"
fi

# --- 4. 钩子与清理 ---

(
    [ -x "$HOME/.config/scripts/matugen-update.sh" ] && "$HOME/.config/scripts/matugen-update.sh" "$FINAL_PATH" > /dev/null

    sleep 0.5

    [ -x "$HOME/.config/scripts/niri_set_overview_blur_dark_bg.sh" ] && "$HOME/.config/scripts/niri_set_overview_blur_dark_bg.sh" > /dev/null

    # 动态清理逻辑: 保留最近 KEEP_COUNT 张,按修改时间倒序
    # 用 find -printf + NUL 分隔处理文件名特殊字符;${line#* } 跳过 mtime 字段
    if [ "$ENABLE_CLEANUP" = true ]; then
        DELETE_START=$((KEEP_COUNT + 1))
        # 只清理脚本下载的 wall_* 文件, 豁免手动放入的精选图 (如 01-alcy-pc_*.webp)
        find "$SAVE_DIR" -maxdepth 1 -type f -name 'wall_*' -printf '%T@ %p\0' \
            | sort -z -k1,1 -rn \
            | tail -z -n +$DELETE_START \
            | while IFS= read -r -d '' line; do
                f="${line#* }"
                rm -- "$f" 2>/dev/null
            done
    fi
) &

send_notify "壁纸已更新" "Enjoy! $MSG_EXTRA"
